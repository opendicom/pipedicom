#import <Foundation/Foundation.h>
#import <DCKV/DCKV.h>

//D2D

//https://raw.githubusercontent.com/jacquesfauquex/DICOM_contextualizedKey-values/master/mapxmldicom/mapxmldicom.xsd



enum {
   D2Dcommand=0,
   D2DspoolDirPath,
   D2DsuccessDir,
   D2DfailureDir,
   D2DoriginalsDir
} D2DcommandArgs;

int main(int argc, const char * argv[]) {
   @autoreleasepool {

      NSProcessInfo *processInfo=[NSProcessInfo processInfo];
      NSArray *args=[processInfo arguments];
      if (args.count!=5)//stdin
      {
         NSLog(@"Should be: D2D spoolDirPath successDir failureDir originalsDir. Was: %@",args.description);
         exit(failure);
      }

      NSError *error=nil;
      NSFileManager *fileManager=[NSFileManager defaultManager];

      
#pragma mark  input
      NSMutableArray *inputPaths=[NSMutableArray array];
      if (!visibleRelativeFiles(fileManager, args[D2DspoolDirPath], [fileManager contentsOfDirectoryAtPath:args[D2DspoolDirPath] error:&error] , inputPaths))
      {
         NSLog(@"error reading directory %@",args[D2DspoolDirPath]);
         exit(failure);
      }

      
#pragma mark environment

      NSDictionary *environment=processInfo.environment;


#pragma mark D2DcompressJ2KR
      BOOL compressJ2KR=environment[@"D2DcompressJ2KR"] && [environment[@"D2DcompressJ2KR"] isEqualToString:@"true"];
      BOOL compressBFHI=environment[@"D2DcompressBFHI"] && [environment[@"D2DcompressBFHI"] isEqualToString:@"true"];

      
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
      NSMutableSet *successDirSet=[NSMutableSet set];
      NSMutableSet *failureDirSet=[NSMutableSet set];
      NSMutableSet *originalsDirSet=[NSMutableSet set];
#pragma mark loop

      NSMutableData *inputData=[NSMutableData data];
      for (NSString *relativeInputPath in inputPaths)
      {
         NSString *spoolFilePath=[args[D2DspoolDirPath] stringByAppendingPathComponent:relativeInputPath];
#pragma mark · parse
         [inputData appendData:[NSData dataWithContentsOfFile:spoolFilePath]];
         
         NSMutableDictionary *parsedAttrs=[NSMutableDictionary dictionary];//parsing
         NSMutableDictionary *blobDict=[NSMutableDictionary dictionary];
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
             ) NSLog(@"could not parse %@",spoolFilePath);
         else
         {
#pragma mark · compress ?
            //NSLog(@"%@: %@",parsedAttrs[@"00000001_00020010-UI"][0],parsedAttrs[@"00000001_00020003-UI"][0]);
            NSString *pixelKey=nil;
            if (parsedAttrs[@"00000001_7FE00010-OB"])pixelKey=@"00000001_7FE00010-OB";
            else if (parsedAttrs[@"00000001_7FE00010-OW"])pixelKey=@"00000001_7FE00010-OW";
            
            if (   pixelKey
                && (compressJ2KR || compressBFHI)
                && [parsedAttrs[@"00000001_00020010-UI"][0] isEqualToString:@"1.2.840.10008.1.2.1"]
                )
            {
               NSString *nativeUrlString=parsedAttrs[pixelKey][0][@"Native"][0];
               NSData *pixelData=nil;
               if ([parsedAttrs[pixelKey][0] isKindOfClass:[NSDictionary class]])  pixelData=blobDict[parsedAttrs[pixelKey][0][@"Native"][0]];
               else pixelData=dataWithB64String(blobDict[pixelKey]);
               
               NSMutableString *message=[NSMutableString string];
               NSString *errString=nil;
               if (compressJ2KR) errString=compressJ2KR(
                  [nativeUrlString substringToIndex:nativeUrlString.length-3],
                  pixelData,
                  parsedAttrs,
                  j2kBlobDict,
                  j2kAttrs
                  );
               else errString=compressBFHI(
                  [nativeUrlString substringToIndex:nativeUrlString.length-3],
                  pixelData,
                  parsedAttrs,
                  j2kBlobDict,
                  j2kAttrs
                  );
               if (errString)
               {
                  NSLog(@"%@",errString);
                  return 1;
               }
#pragma mark TODO groups j2kr o bfhi
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
                  NSLog(@"could not serialize group 0002. %@",filemetainfoDict.description);
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
               NSLog(@"could not serialize dataset. %@",parsedAttrs);
               NSString *failureFilePath=[args[D2DfailureDir] stringByAppendingPathComponent:relativeInputPath];
               if (enclosingDirectoryWritable(fileManager, failureDirSet, failureFilePath)==true)
                  [outputData writeToFile:failureFilePath atomically:NO ];
               else
               {
                  NSLog(@"can not write %@. Aborting...",failureFilePath);
                  exit(failure);
               }
            }

#pragma mark · write result
            NSString *successFilePath=[args[D2DsuccessDir] stringByAppendingPathComponent:relativeInputPath];
            if (enclosingDirectoryWritable(fileManager, successDirSet, successFilePath)==true)
            {
               [outputData writeToFile:successFilePath atomically:NO ];
               //NSLog(@"OK %@",successFilePath);
            }
            else
            {
               NSLog(@"can not write %@. Aborting...",successFilePath);
               exit(failure);
            }
            
            //move receiver
            NSString *doneFilePath=[args[D2DoriginalsDir]stringByAppendingPathComponent:relativeInputPath];
            if (   (enclosingDirectoryWritable(fileManager, originalsDirSet, doneFilePath)==false)
                || ![fileManager moveItemAtPath:spoolFilePath toPath:doneFilePath error:&error]
                )
            {
               NSLog(@"aborting... can not move %@ to %@: %@",spoolFilePath,doneFilePath,error.description);
               exit(failure);
            }
         }//end parsed
         [inputData setLength:0];
      }//end loop
      return 1;
   }//end autorelease pool
   return 0;
}
