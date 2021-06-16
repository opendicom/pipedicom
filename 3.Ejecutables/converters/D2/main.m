#import <Foundation/Foundation.h>
#import <DCKV/DCKV.h>
//#import <DCKV/NSData+DCMmarkers.h>

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


int execTask(NSDictionary *environment, NSString *launchPath, NSArray *launchArgs, NSData *writeData, NSMutableData *readData)
{
   NSTask *task=[[NSTask alloc]init];
   
   task.environment=environment;
   
   [task setLaunchPath:launchPath];
   [task setArguments:launchArgs];
   NSPipe *writePipe = [NSPipe pipe];
   NSFileHandle *writeHandle = [writePipe fileHandleForWriting];
   [task setStandardInput:writePipe];
   
   NSPipe* readPipe = [NSPipe pipe];
   NSFileHandle *readingFileHandle=[readPipe fileHandleForReading];
   [task setStandardOutput:readPipe];
   //[task setStandardError:readPipe];
   
   [task launch];
   [writeHandle writeData:writeData];
   [writeHandle closeFile];
   
   NSData *dataPiped = nil;
   while((dataPiped = [readingFileHandle availableData]) && [dataPiped length])
   {
      [readData appendData:dataPiped];
   }
   //while( [task isRunning]) [NSThread sleepForTimeInterval: 0.1];
   //[task waitUntilExit];      // <- This is VERY DANGEROUS : the main runloop is continuing...
   //[aTask interrupt];
   
   [task waitUntilExit];
   int terminationStatus = [task terminationStatus];
   if (terminationStatus!=0) NSLog(@"ERROR task terminationStatus: %d",terminationStatus);//warning
   return terminationStatus;
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
         [inputData appendData:[NSData dataWithContentsOfFile:inputPath]];
         NSMutableDictionary *attrDict=[NSMutableDictionary dictionary];
         NSMutableDictionary *blobDict=[NSMutableDictionary dictionary];
         if (!D2dict(
                    inputData,
                    attrDict,
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
            NSLog(@"%@: %@",attrDict[@"00000001_00020010-UI"][0],attrDict[@"00000001_00020003-UI"][0]);
            NSString *pixelKey=nil;
            if (attrDict[@"00000001_7FE00010-OB"])pixelKey=@"00000001_7FE00010-OB";
            else if (attrDict[@"00000001_7FE00010-OW"])pixelKey=@"00000001_7FE00010-OW";
            if (   pixelKey
                && compressJ2K
                && [attrDict[@"00000001_00020010-UI"][0] isEqualToString:@"1.2.840.10008.1.2.1"]
                )
            {
               NSData *pixelData=nil;
               if ([attrDict[pixelKey][0] isKindOfClass:[NSDictionary class]])  pixelData=blobDict[attrDict[pixelKey][0][@"Native"][0]];
               else pixelData=blobDict[pixelKey];
               NSMutableData *j2kData=[NSMutableData data];
               int result=execTask(
                        nil,
                        @"opj_compress",
                        @[
                           @"-F",
                           [NSString stringWithFormat:@"%u,%d,%d,%d,u",
                            [attrDict[@"00000001_00280011-US"][0] unsignedShortValue],//columns
                            [attrDict[@"00000001_00280010-US"][0] unsignedShortValue],//rows
                            [attrDict[@"00000001_00280002-US"][0] unsignedShortValue],//samples
                            [attrDict[@"00000001_00280101-US"][0] unsignedShortValue] //bits
                            ],
                           @"-i",
                           @"stdin.rawl",
                           @"-o",
                           @"stdout.j2k",
                           @"-n",
                           @"6",
                           @"-r",
                           @"50,40,30,20,10,1", //6 quality layers
                           @"-p",
                           @"RLCP",//B.11.1.2 Resolution-layer-component-position
                           @"-TP",
                           @"R"//Tile-parts
                        ],
                        pixelData,
                        j2kData
                        );
               
               if (result !=0)
               {
                  NSString *errorString=[[NSString alloc]initWithData:j2kData encoding:NSUTF8StringEncoding];
                  LOG_ERROR(@"compression J2K: %@",errorString);
               }
               else
               {
#pragma mark ·· modify attrs
                  [attrDict setObject:@[@"1.2.840.10008.1.2.4.90"] forKey:@"00000001_00020010-UI"];
                  

                  
                  [attrDict setObject:@[[NSString stringWithFormat:@"Lossless compression J2K codec openjpeg 2.5, compression ratio %05f (pixel data size:%lu md5:%@)",1.0*pixelData.length/j2kData.length,(unsigned long)pixelData.length,[pixelData MD5String]]] forKey:@"00000001_00082111-ST"];

                  [attrDict setObject:@[@"J2K sin pérdida. 1 tile. 6 tile-part quality layer (50,40,30,20,10,1)"] forKey:@"00000001_00204000-2006LT"];

                  
                 NSString *nativeUrlString=attrDict[pixelKey][0][@"Native"][0];
                 NSString *encapsulatedUrlBaseString=[nativeUrlString stringByReplacingOccurrencesOfString:pixelKey withString:@"00000001_7FE00010"];
                 [attrDict removeObjectForKey:pixelKey];
           
                  
#pragma mark ·· subdivide j2kData
                  
                  NSUInteger fragmentOffset=0;
                  int fragmentCounter=1;
                  
                  NSUInteger j2kLength=j2kData.length;
                  NSRange j2kRange=NSMakeRange(fragmentOffset,j2kLength);
                  
                  //first SOC
                  NSRange nextSOCRange=[j2kData rangeOfData:NSData.SOT
                                                    options:0
                                                      range:j2kRange];
                  
                  //second SOC
                  j2kRange.location=nextSOCRange.location + nextSOCRange.length;
                  j2kRange.length=j2kLength-j2kRange.location;
                  nextSOCRange=[j2kData rangeOfData:NSData.SOT
                                                    options:0
                                                      range:j2kRange];
                  
                  NSMutableArray *pixelAttrArray=[NSMutableArray array];
                  NSMutableString *fragmentCounterString=[NSMutableString string];
                  while (nextSOCRange.location != NSNotFound)
                  {
                     NSString *fragmentName=[NSString stringWithFormat:@"%@#00000001:1.j2k%@",encapsulatedUrlBaseString,fragmentCounterString]
                     ;
                     [pixelAttrArray addObject:fragmentName];
                     [blobDict setObject:[j2kData subdataWithRange:NSMakeRange(fragmentOffset, nextSOCRange.location - fragmentOffset)] forKey:fragmentName];

                     fragmentOffset=nextSOCRange.location;

                     j2kRange.location=nextSOCRange.location + nextSOCRange.length;
                     j2kRange.length=j2kLength-j2kRange.location;
                     nextSOCRange=[j2kData rangeOfData:NSData.SOT
                                                       options:0
                                                         range:j2kRange];
                     [fragmentCounterString setString:[NSString stringWithFormat:@"%d",fragmentCounter]];
                     fragmentCounter++;
                  }
                  //last tile-part (ended with EOC)
                  //[j2kData writeToFile:@"/Users/Shared/6.j2k" atomically:NO];
                  nextSOCRange=[j2kData rangeOfData:NSData.EOC
                                                    options:0
                                                      range:j2kRange];
                  NSString *fragmentName=[NSString stringWithFormat:@"%@#00000001:1.j2kr",encapsulatedUrlBaseString]
                  ;
                  [pixelAttrArray addObject:fragmentName];
                  [blobDict setObject:[j2kData subdataWithRange:NSMakeRange(fragmentOffset, nextSOCRange.location-fragmentOffset)] forKey:fragmentName];

                  NSDictionary *frame1Dict=[NSDictionary dictionaryWithObject:pixelAttrArray forKey:@"Frame#00000001"];
                  [attrDict setObject: [NSArray arrayWithObject:frame1Dict]
                  forKey:@"00000001_7FE00010-OB"];
                  [blobDict removeObjectForKey:nativeUrlString];
               }
            }
         

#pragma mark · jsondata
            NSMutableString *JSONstring=json4attrDict(attrDict);
            NSData *JSONdata=[JSONstring dataUsingEncoding:NSUTF8StringEncoding];
            if (!JSONdata)
            {
               LOG_ERROR(@"could not transform to JSON: %@",[attrDict description]);
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
