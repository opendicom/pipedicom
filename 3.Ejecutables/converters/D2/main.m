#import <Foundation/Foundation.h>
#import <DCKV/DCKV.h>


//https://raw.githubusercontent.com/jacquesfauquex/DICOM_contextualizedKey-values/master/mapxmldicom/mapxmldicom.xsd

int visibleFiles(NSFileManager *fileManager, NSArray *mountPoints, NSMutableArray *paths)
{
   BOOL isDirectory=false;
   for (NSString *mountPoint in mountPoints)
   {
      if ([mountPoint hasPrefix:@"."]) continue;
      
      NSString *noSymlink=[[mountPoint stringByExpandingTildeInPath] stringByResolvingSymlinksInPath];

      if ([fileManager fileExistsAtPath:noSymlink isDirectory:&isDirectory])
      {
         if (isDirectory)
         {
            NSError *error;
            NSArray *contents=[fileManager contentsOfDirectoryAtPath:noSymlink error:&error];
            
#pragma mark TODO agregar base URL prefix to each of the file names.
            
            if (error)
            {
               LOG_WARNING(@"bad directory path %@",noSymlink);
               return failure;
            }
            
            NSMutableArray *contentsPaths=[NSMutableArray array];
            for (NSString *name in contents)
            {
               [contentsPaths addObject:[mountPoint stringByAppendingPathComponent:name]];
            }
            
            if (visibleFiles(fileManager,contentsPaths, paths) != success) return failure;
         }
         else [paths addObject:noSymlink];
      }
   }
   return success;
}



int main(int argc, const char * argv[]) {
   @autoreleasepool {

      NSProcessInfo *processInfo=[NSProcessInfo processInfo];
      NSArray *args=[processInfo arguments];
      if (args.count==1)//stdin
      {
         NSLog(@"no file to process");
         exit(1);
      }

      NSError *error=nil;
      NSFileManager *fileManager=[NSFileManager defaultManager];
      if (  ![fileManager fileExistsAtPath:@"stdout.j2k"]
          &&![fileManager createSymbolicLinkAtPath:@"stdout.j2k" withDestinationPath:@"/dev/stdout" error:&error]
          ) NSLog(@"could not create symlink stdout.j2k: %@",[error description]);
      if (  ![fileManager fileExistsAtPath:@"stdin.rawl"]
          &&![fileManager createSymbolicLinkAtPath:@"stdin.rawl" withDestinationPath:@"/dev/stdin" error:&error]
          ) NSLog(@"could not create symlink stdin.rawl: %@",[error description]);

      
      NSMutableArray *inputPaths=[NSMutableArray array];
      if (!visibleFiles(fileManager, [args subarrayWithRange:NSMakeRange(1,args.count -1)] , inputPaths)) exit(failure);

      
#pragma mark environment

      NSDictionary *environment=processInfo.environment;
      
#pragma mark D2logLevel
      if (environment[@"D2logLevel"])
      {
         NSUInteger logLevel=[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:environment[@"D2logLevel"]];
         if (logLevel!=NSNotFound) ODLogLevel=(ODLogLevelEnum)logLevel;
         else ODLogLevel=4;//ERROR (default)
      }
      else ODLogLevel=4;//ERROR (default)
      
      
#pragma mark D2logPath
      NSString *logPath=environment[@"D2logPath"];
       
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
      else if ([fileManager fileExistsAtPath:@"/Volumes/LOG"]) freopen([@"/Volumes/LOG/D2.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      else freopen([@"/Users/Shared/D2.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);


#pragma mark D2relativePathComponents
      NSUInteger relativePathComponents=0;// -> new UUID name
      NSString *relativePathComponentsString=environment[@"D2relativePathComponents"];
      if (relativePathComponentsString)
      {
         relativePathComponents=relativePathComponentsString.intValue;
         if ((relativePathComponents==INT_MIN) || (relativePathComponents==INT_MAX)) relativePathComponents=0; //not found
      }

#pragma mark D2blobMode and D2blobMinSize
      int blobMode=blobModeResources;
      long long blobMinSize=LONG_LONG_MAX;
      NSString *blobMinSizeString=environment[@"D2blobMinSize"];
      if (blobMinSizeString)
      {
         blobMinSize=blobMinSizeString.longLongValue;
         if ((blobMinSize==0) || (blobMinSize==LONG_LONG_MIN)) blobMinSize=LONG_LONG_MAX;
      }

#pragma mark D2blobRefPrefix
      NSMutableString *blobRefPrefix=[NSMutableString string];
      if (
             (blobMode==blobModeInline)
          && environment[@"D2blobRefPrefix"]
          ) [blobRefPrefix setString:environment[@"D2blobRefPrefix"]];

#pragma mark D2blobRefSuffix
      NSString *blobRefSuffix=environment[@"D2blobRefSuffix"];


#pragma mark D2compressJ2K
      BOOL compressJ2K=environment[@"D2compressJ2K"] && [environment[@"D2compressJ2K"] isEqualToString:@"true"];

#pragma mark D2outputDir
      NSString *outputDir=environment[@"D2outputDir"];
      
      
      LOG_DEBUG(@"environment:\r%@",[environment description]);

      
      
      

#pragma mark - processing
      
#pragma mark loop

      NSMutableData *inputData=[NSMutableData data];
      for (NSString *inputPath in inputPaths)
      {
#pragma mark · parse
         [blobRefPrefix setString:[ [inputPath lastPathComponent] stringByAppendingString:@".bulkdata/"]];
         //inputData is empty
         [inputData appendData:[NSData dataWithContentsOfFile:inputPath]];
         
         NSMutableDictionary *parsedAttrs=[NSMutableDictionary dictionary];//parsing
         NSMutableDictionary *blobDict=[NSMutableDictionary dictionary];
         NSMutableDictionary *nativeAttrs=[NSMutableDictionary dictionary];//removed from parsing
         NSMutableDictionary *j2kAttrs=[NSMutableDictionary dictionary];//added compressing
         NSMutableDictionary *j2kBlobDict=[NSMutableDictionary dictionary];
         if (!D2dict(
                    inputData,
                    parsedAttrs,
                    blobMinSize,
                    blobMode,
                    blobRefPrefix,
                    blobRefSuffix,
                    blobDict
                    )
             ) LOG_ERROR(@"could not parse %@",inputPath);
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
                  
                  //relocate native attributes
                  [nativeAttrs setObject:parsedAttrs[pixelKey] forKey:pixelKey];
                  [parsedAttrs removeObjectForKey:pixelKey];
                  [nativeAttrs setObject:parsedAttrs[@"00000001_00020010-UI"] forKey:@"00000001_00020010-UI"];
                  [parsedAttrs removeObjectForKey:@"00000001_00020010-UI"];
                  
                  

               }

               
            }
         

#pragma mark · jsondata
            
            //remove group2 length
            [parsedAttrs removeObjectForKey:@"00000001_00020000-UL"];
            // remove File Meta Information Version. (0002,0001) OB "AAE="
            [parsedAttrs removeObjectForKey:@"00000001_00020001-OB"];

            
            NSString *JSONstring=
            [NSString
             stringWithFormat:
             @"{ \"dataset\" :%@, \"+j2k\" :%@, \"-native\" :%@}",
             jsonObject4attrs(parsedAttrs),
             jsonObject4attrs(j2kAttrs),
             jsonObject4attrs(nativeAttrs)
             ];
            
            NSData *JSONdata=[JSONstring dataUsingEncoding:NSUTF8StringEncoding];
            if (!JSONdata)
            {
               LOG_ERROR(@"could not transform to JSON: %@",[parsedAttrs description]);
            }
            else
#pragma mark · outputDir
            {
               if (!inputPath || !relativePathComponents)
               {
                  NSString *UUIDString=[[NSUUID UUID]UUIDString];
                  [JSONdata writeToFile:[[outputDir stringByAppendingPathComponent:UUIDString]stringByAppendingPathExtension:@"json"] atomically:NO];
                  if (blobDict.count)
                  {
                     NSString *bulkdataDir=[[outputDir stringByAppendingPathComponent:UUIDString]stringByAppendingPathExtension:@"bulkdata"];
                     [fileManager createDirectoryAtPath:bulkdataDir withIntermediateDirectories:YES attributes:nil error:&error];
                     for (NSString *bulkdataKey in blobDict)
                     {
                        [blobDict[bulkdataKey] writeToFile:[bulkdataDir stringByAppendingPathComponent:bulkdataKey] atomically:NO];
                     }
                  }
               }
               else
               {
                  NSMutableArray *inputPathComponents=[NSMutableArray arrayWithArray:[inputPath pathComponents]];

                  if (![inputPathComponents[0] length]) [inputPathComponents removeObjectAtIndex:0];//case of absolute paths
                  while (relativePathComponents < inputPathComponents.count)
                  {
                     [inputPathComponents removeObjectAtIndex:0];
                  }
                  NSString *outputPath=[[[outputDir stringByAppendingPathComponent:[inputPathComponents componentsJoinedByString:@"/"]]stringByDeletingPathExtension]stringByAppendingPathExtension:@"json"];
                  NSString *outputDir=[outputPath stringByDeletingLastPathComponent];
                  if (![fileManager fileExistsAtPath:outputDir] && ![fileManager createDirectoryAtPath:outputDir withIntermediateDirectories:YES attributes:0 error:&error] )
                  {
                     LOG_ERROR(@"could not create directory %@",outputDir);
                     return 1;
                  }
                  [JSONdata writeToFile:outputPath atomically:NO];
                  if (blobDict.count)
                  {
                     NSString *bulkdataDir=[[outputPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"bulkdata"];
                     [fileManager createDirectoryAtPath:bulkdataDir withIntermediateDirectories:YES attributes:nil error:&error];
                     for (NSString *bulkdataKey in blobDict)
                     {
                        [blobDict[bulkdataKey] writeToFile:[bulkdataDir stringByAppendingPathComponent:[bulkdataKey lastPathComponent]] atomically:NO];
                     }
                  }
               }
            }
         }//end parsed
         [inputData setLength:0];
      }//end loop
      return 1;
   }//end autorelease pool
   return 0;
}
