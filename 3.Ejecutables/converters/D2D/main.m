#import <Foundation/Foundation.h>
#import <DCKV/DCKV.h>

//D2D

//https://raw.githubusercontent.com/jacquesfauquex/DICOM_contextualizedKey-values/master/mapxmldicom/mapxmldicom.xsd


int visibleRelativeFiles(NSFileManager *fileManager, NSString *base, NSArray *mountPoints, NSMutableArray *paths)
{
   BOOL isDirectory=false;
   for (NSString *relativeMountPoint in mountPoints)
   {
      NSString *lastPathComponent=[relativeMountPoint lastPathComponent];
      if ([lastPathComponent hasPrefix:@"."]) continue;
      if ([lastPathComponent hasPrefix:@"DISCARDED"]) continue;
      if ([lastPathComponent hasPrefix:@"ORIGINALS"]) continue;
      if ([lastPathComponent hasPrefix:@"COERCED"]) continue;
      NSString *absoluteMountPoint=[[[base stringByAppendingPathComponent:relativeMountPoint] stringByExpandingTildeInPath] stringByResolvingSymlinksInPath];

      if ([fileManager fileExistsAtPath:absoluteMountPoint isDirectory:&isDirectory])
      {
         if (isDirectory)
         {
            NSError *error;
            NSArray *contents=[fileManager contentsOfDirectoryAtPath:absoluteMountPoint error:&error];
            
            if (error)
            {
               LOG_WARNING(@"bad directory path %@",absoluteMountPoint);
               return failure;
            }
            
            NSMutableArray *contentsPaths=[NSMutableArray array];
            for (NSString *name in contents)
            {
               [contentsPaths addObject:[relativeMountPoint stringByAppendingPathComponent:name]];
            }
            
            if (visibleRelativeFiles(fileManager,base,contentsPaths, paths) != success) return failure;
         }
         else [paths addObject:relativeMountPoint];
      }
   }
   return success;
}


int enclosingDirectoryWritable(NSFileManager *fileManager, NSMutableSet *writableDirSet, NSString *filePath)
{
   NSString *dirPath=[filePath stringByDeletingLastPathComponent];
   if ([writableDirSet containsObject:dirPath]) return success;
   BOOL isDirectory;
   NSError *error;
   if ([fileManager fileExistsAtPath:dirPath isDirectory:&isDirectory])
   {
      if (isDirectory)
      {
         [writableDirSet addObject:dirPath];
         return success;
      }
      LOG_ERROR(@"should be directory:%@",dirPath);
      return failure;
   }
   if([fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&error])
   {
      [writableDirSet addObject:dirPath];
      return success;
   }
   LOG_ERROR(@"can not create dir: %@",dirPath);
   return failure;
}


enum {
   D2Dcommand=0,
   D2DreceiverDirPath,
   D2DcoercedDirPath
} D2DcommandArgs;

int main(int argc, const char * argv[]) {
   @autoreleasepool {

      NSProcessInfo *processInfo=[NSProcessInfo processInfo];
      NSArray *args=[processInfo arguments];
      if (args.count!=3)//stdin
      {
         NSLog(@"Should be: D2D sourceDirPath coercedDirPath discardedDirPath originalsDirPath. Was: %@",args.description);
         exit(failure);
      }

      NSError *error=nil;
      NSFileManager *fileManager=[NSFileManager defaultManager];
      //used to stream openjpeg ins and outs
      if (  ![fileManager fileExistsAtPath:@"stdout.j2k"]
          &&![fileManager createSymbolicLinkAtPath:@"stdout.j2k" withDestinationPath:@"/dev/stdout" error:&error]
          ) NSLog(@"could not create symlink stdout.j2k: %@",[error description]);
      if (  ![fileManager fileExistsAtPath:@"stdin.rawl"]
          &&![fileManager createSymbolicLinkAtPath:@"stdin.rawl" withDestinationPath:@"/dev/stdin" error:&error]
          ) NSLog(@"could not create symlink stdin.rawl: %@",[error description]);

      
#pragma mark  input
      NSString *receivedDirPath=[args[D2DreceiverDirPath] stringByAppendingPathComponent:@"RECEIVED"];
      NSMutableArray *inputPaths=[NSMutableArray array];
      if (!visibleRelativeFiles(fileManager, receivedDirPath, [fileManager contentsOfDirectoryAtPath:receivedDirPath error:&error] , inputPaths))
      {
         LOG_ERROR(@"error reading directory %@",receivedDirPath);
         exit(failure);
      }

      
#pragma mark environment

      NSDictionary *environment=processInfo.environment;
      LOG_DEBUG(@"environment:\r%@",[environment description]);

      
#pragma mark D2DlogLevel
      if (environment[@"D2DlogLevel"])
      {
         NSUInteger logLevel=[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:environment[@"D2DlogLevel"]];
         if (logLevel!=NSNotFound) ODLogLevel=(ODLogLevelEnum)logLevel;
         else ODLogLevel=4;//ERROR (default)
      }
      else ODLogLevel=4;//ERROR (default)
      
      
#pragma mark D2DlogPath
      NSString *logPath=environment[@"D2DlogPath"];
       
      if (logPath)
      {
          BOOL isDirectory=false;
          if ([fileManager fileExistsAtPath:[logPath stringByDeletingLastPathComponent] isDirectory:&isDirectory] && isDirectory)
          {
              if ([logPath hasSuffix:@".log"])
                  freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
              else freopen([[logPath stringByAppendingPathExtension:@".log"] cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
          }
          else
          {
              LOG_ERROR(@"bad log path (dir does not exist): %@",logPath);
              exit(1);
          }
      }
      else if ([fileManager fileExistsAtPath:@"/Volumes/LOG"]) freopen([@"/Volumes/LOG/D2D.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      else freopen([@"/Users/Shared/D2D.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);


#pragma mark D2DcompressJ2K
      BOOL compressJ2K=environment[@"D2DcompressJ2K"] && [environment[@"D2DcompressJ2K"] isEqualToString:@"true"];

      
#pragma mark D2DjsonDataset
      NSString *jsonDatasetString=environment[@"D2DjsonDataset"];
      NSDictionary *overridingDatasetDict;
      if (!jsonDatasetString || !jsonDatasetString.length) overridingDatasetDict=@{};
      else overridingDatasetDict=[NSJSONSerialization JSONObjectWithData:[jsonDatasetString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
      if (!overridingDatasetDict)
      {
         NSLog(@"bad overriding dataset: %@",[error description]);
         exit(failure);
      }
      

#pragma mark - processing
      NSMutableSet *receiverDirSet=[NSMutableSet set];
      NSMutableSet *coercedDirSet=[NSMutableSet set];
#pragma mark loop

      NSMutableData *inputData=[NSMutableData data];
      for (NSString *relativeInputPath in inputPaths)
      {
         NSString *receivedFilePath=[receivedDirPath stringByAppendingPathComponent:relativeInputPath];
#pragma mark · parse
         [inputData appendData:[NSData dataWithContentsOfFile:receivedFilePath]];
         
         NSMutableDictionary *parsedAttrs=[NSMutableDictionary dictionary];//parsing
         NSMutableDictionary *blobDict=[NSMutableDictionary dictionary];
         NSMutableDictionary *nativeAttrs=[NSMutableDictionary dictionary];//removed from parsing
         NSMutableDictionary *j2kAttrs=[NSMutableDictionary dictionary];//added compressing
         NSMutableDictionary *j2kBlobDict=[NSMutableDictionary dictionary];
         if (!D2dict(
                    inputData,
                    parsedAttrs,
                    0,//blob min size
                    blobModeResources,
                    @"",//prefix
                    @"",//suffix
                    blobDict
                    )
             ) LOG_ERROR(@"could not parse %@",receivedFilePath);
         else
         {
#pragma mark · compress ?
            //NSLog(@"%@: %@",parsedAttrs[@"00000001_00020010-UI"][0],parsedAttrs[@"00000001_00020003-UI"][0]);
            NSString *pixelKey=nil;
            if (parsedAttrs[@"00000001_7FE00010-OB"])pixelKey=@"00000001_7FE00010-OB";
            else if (parsedAttrs[@"00000001_7FE00010-OW"])pixelKey=@"00000001_7FE00010-OW";
            
            if (   pixelKey
                && compressJ2K
                && [parsedAttrs[@"00000001_00020010-UI"][0] isEqualToString:@"1.2.840.10008.1.2.1"]
                )
            {
               NSString *nativeUrlString=parsedAttrs[pixelKey][0][@"Native"][0];
               NSData *pixelData=nil;
               if ([parsedAttrs[pixelKey][0] isKindOfClass:[NSDictionary class]])  pixelData=blobDict[parsedAttrs[pixelKey][0][@"Native"][0]];
               else pixelData=dataWithB64String(blobDict[pixelKey]);
               if (compress(
                            [nativeUrlString substringToIndex:nativeUrlString.length-3],
                            pixelData,
                            parsedAttrs,
                            j2kBlobDict,
                            j2kAttrs
                            )==success
                   )
               {
                  //remove native pixel blob and corresponding attribute
                  
                  //include j2k blobs
                  [blobDict addEntriesFromDictionary:j2kBlobDict];
                  
                  //remove native attributes
                  [parsedAttrs removeObjectForKey:pixelKey];
                  [parsedAttrs removeObjectForKey:@"00000001_00020010-UI"];
                  [parsedAttrs addEntriesFromDictionary:j2kAttrs];
               }
            }
            
            //remove group2 length
            [parsedAttrs removeObjectForKey:@"00000001_00020000-UL"];
            
            //add overriding dataset
            [parsedAttrs addEntriesFromDictionary:overridingDatasetDict];

            
#pragma mark outputData
            NSMutableData *outputData;
            
//group 2 ?
            if (parsedAttrs[@"00000001_00020003-UI"])
            {
               NSMutableDictionary *filemetainfoDict=[NSMutableDictionary dictionary];
               NSArray *keys=[parsedAttrs allKeys];
               for (NSString *key in keys)
               {
                  if ([key hasPrefix:@"00000001_0002"])
                  {
                     [filemetainfoDict setObject:parsedAttrs[key] forKey:key];
                     [parsedAttrs removeObjectForKey:key];
                  }
               }
               
               NSMutableData *filemetainfoData=[NSMutableData data];
               if (dict2D(
                          environment[@"PWD"],
                          filemetainfoDict,
                          filemetainfoData,
                          compressJ2K?dicomExplicitJ2kIdem:dicomExplicit,
                          blobDict
                          ) == failure
                   )
               {
                  LOG_ERROR(@"could not serialize group 0002. %@",filemetainfoDict.description);
                  exit(failure);
               }
               
               //create 128 empty bytes + 'DICM' + 00020000 attribute
               outputData=[NSMutableData dataWithLength:128];
               UInt32 DICM='MCID';
               [outputData appendBytes:&DICM length:4];
               UInt64 group2LengthAttr=0x44C5500000002;
               [outputData appendBytes:&group2LengthAttr length:8];
               UInt32 group2Length=(UInt32)filemetainfoData.length;
               [outputData appendBytes:&group2Length length:4];
               
               //append group2 contents
               [outputData appendData:filemetainfoData];
            }
            else outputData=[NSMutableData data];//not a part 10 dataset
//dataset
            if (dict2D(
                        environment[@"PWD"],
                        parsedAttrs,
                        outputData,
                        compressJ2K?dicomExplicitJ2kIdem:dicomExplicit,
                        blobDict
                        )==failure
                )
            {
               LOG_ERROR(@"could not serialize dataset. %@",parsedAttrs);
               exit(failure);

            }

#pragma mark · write result
            //receiverDirSet
            //coercedDirSet
            
            NSString *coercedFilePath=[args[D2DcoercedDirPath] stringByAppendingPathComponent:relativeInputPath];
            if (enclosingDirectoryWritable(fileManager, coercedDirSet, coercedFilePath)==true)
               [outputData writeToFile:coercedFilePath atomically:NO ];
            else
            {
               //not possible to write coerced into coercedDir
               //write it into receiver
               NSString *coercedIntoReceiverFilePath=[[receivedDirPath stringByAppendingPathComponent:@"COERCED"]stringByAppendingPathComponent:relativeInputPath];
               LOG_ERROR(@"coerced can not be written into %@. Try into %@",coercedFilePath,coercedIntoReceiverFilePath);
               if (enclosingDirectoryWritable(fileManager, receiverDirSet, coercedIntoReceiverFilePath)==false)
               {
                  //not possible to write it into receiver either
                  LOG_ERROR(@"can not write %@. Aborting...",coercedIntoReceiverFilePath);
                  exit(failure);
               }
               [outputData writeToFile:coercedIntoReceiverFilePath atomically:NO ];
            }
            
            //move receiver
            NSString *originalsFilePath=[[args[D2DreceiverDirPath] stringByAppendingPathComponent:@"ORIGINALS"]stringByAppendingPathComponent:relativeInputPath];
            if (   (enclosingDirectoryWritable(fileManager, receiverDirSet, originalsFilePath)==false)
                || ![fileManager moveItemAtPath:receivedFilePath toPath:originalsFilePath error:&error]
                )
            {
               LOG_ERROR(@"aborting... can not move %@ to %@: %@",receivedFilePath,originalsFilePath,error.description);
               exit(failure);
            }
         }//end parsed
         [inputData setLength:0];
      }//end loop
      return 1;
   }//end autorelease pool
   return 0;
}
