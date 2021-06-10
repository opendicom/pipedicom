//
//  main.m
//  DinlineJ
//
//  Created by jacquesfauquex on 2021-06-10.
//

#import <Foundation/Foundation.h>
#import <DCKV/DCKV.h>


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
   [task setStandardError:readPipe];
   
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
      NSError *error=nil;
      NSFileManager *fileManager=[NSFileManager defaultManager];
      if (  ![fileManager fileExistsAtPath:@"stdout.j2k"]
          &&![fileManager createSymbolicLinkAtPath:@"stdout.j2k" withDestinationPath:@"/dev/stdout" error:&error]
          ) NSLog(@"could not create symlink stdout.j2k: %@",[error description]);
      NSProcessInfo *processInfo=[NSProcessInfo processInfo];
      
#pragma mark args
      NSMutableArray *inputPaths=[NSMutableArray array];
      NSMutableData *inputData=[NSMutableData data];
      NSArray *args=[processInfo arguments];
      if (args.count==1)//stdin
      {
         NSFileHandle *readingFileHandle=[NSFileHandle fileHandleWithStandardInput];
         NSData *moreData;
         while ((moreData=[readingFileHandle availableData]) && moreData.length) [inputData appendData:moreData];
         [inputPaths addObject:@"stdin"];
      }
      else if (!visibleFiles(fileManager, [args subarrayWithRange:NSMakeRange(1,args.count -1)] , inputPaths)) exit(failure);

      
#pragma mark environment

      NSDictionary *environment=processInfo.environment;
      
#pragma mark D2JlogLevel
      if (environment[@"D2JlogLevel"])
      {
         NSUInteger logLevel=[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:environment[@"D2JlogLevel"]];
         if (logLevel!=NSNotFound) ODLogLevel=(ODLogLevelEnum)logLevel;
         else ODLogLevel=4;//ERROR (default)
      }
      else ODLogLevel=4;//ERROR (default)
      
      
#pragma mark D2JlogPath
      NSString *logPath=environment[@"D2JlogPath"];
       
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
      else if ([fileManager fileExistsAtPath:@"/Volumes/LOG"]) freopen([@"/Volumes/LOG/D2J.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      else freopen([@"/Users/Shared/D2J.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);


#pragma mark D2JrelativePathComponents
      NSUInteger relativePathComponents=0;// -> new UUID name
      NSString *relativePathComponentsString=environment[@"D2JrelativePathComponents"];
      if (relativePathComponentsString)
      {
         relativePathComponents=relativePathComponentsString.intValue;
         if ((relativePathComponents==INT_MIN) || (relativePathComponents==INT_MAX)) relativePathComponents=0; //not found
      }

#pragma mark D2JblobMinSize
      long long blobMinSize=LONG_LONG_MAX;
      NSString *blobMinSizeString=environment[@"D2JblobMinSize"];
      if (blobMinSizeString)
      {
         blobMinSize=blobMinSizeString.longLongValue;
         if ((blobMinSize==0) || (blobMinSize==LONG_LONG_MIN)) blobMinSize=LONG_LONG_MAX;
      }
      
#pragma mark D2JblobMode
      int blobMode=blobModeInline;
      NSString *blobModeString=environment[@"D2JblobMode"];

      if (blobModeString)
      {
         if ([blobModeString isEqualToString:@"blobModeSource"]) blobMode=blobModeSource;
         else if ([blobModeString isEqualToString:@"blobModeResources"]) blobMode=blobModeResources;
      }

#pragma mark D2JblobRefPrefix
      NSMutableString *blobRefPrefix=[NSMutableString string];
      if (
             (blobMode==blobModeInline)
          && environment[@"D2JblobRefPrefix"]
          ) [blobRefPrefix setString:environment[@"D2JblobRefPrefix"]];

#pragma mark D2JblobRefSuffix
      NSString *blobRefSuffix=environment[@"D2JblobRefSuffix"];

#pragma mark D2JforceZip
      BOOL forceZip=environment[@"D2JforceZip"] && [environment[@"D2JforceZip"] isEqualToString:@"true"];

#pragma mark D2JcompressJ2K
      BOOL compressJ2K=environment[@"D2JcompressJ2K"] && [environment[@"D2JcompressJ2K"] isEqualToString:@"true"];

#pragma mark D2JoutputDir
      NSString *outputDir=environment[@"D2JoutputDir"];
      
      
      LOG_DEBUG(@"environment:\r%@",[environment description]);

      
      
      

      
      /*
       D2JforceZip | D2JoutputDir | args   | stdout   | stdout error
       ------------|--------------|--------|----------|---------------
       false       | true         |        | 0        | err number > 0
       false       | false        | 1      | json     | err number > 0

       false       | false        | >1     | zipped   | err number > 0
       true        | true         |        | zip name | err number > 0
       true        | false        |        | zipped   | err number > 0

       */
#pragma mark - processing
      
#pragma mark eventually prepare zip header
      if (   forceZip
          || (!outputDir && args.count > 2)
          ) //more than one path
      {
         //do something
      }

#pragma mark loop

      for (NSString *inputPath in inputPaths)
      {
         switch (blobMode) {
            case blobModeSource:
               [blobRefPrefix setString:inputPath];
               break;
            case blobModeResources:
               if (inputPath) [blobRefPrefix setString:[ [inputPath lastPathComponent] stringByAppendingString:@".bulkdata/"]];
               break;
         }
         
         if (!inputData.length) [inputData appendData:[NSData dataWithContentsOfFile:inputPath]];//stdin has data already
         
#pragma mark · parse
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
#pragma mark · compress
            if (blobMode!=blobModeSource)
            {
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
                           @"/Users/jacquesfauquex/Desktop/prueba/prueba/grk_compress",
                           @[
                              @"-F",
                              [NSString stringWithFormat:@"%u,%d,%d,%d,u",
                               [(attrDict[@"00000001_00280011-US"])[0] unsignedShortValue],//columns
                               [(attrDict[@"00000001_00280010-US"])[0] unsignedShortValue],//rows
                               [(attrDict[@"00000001_00280002-US"])[0] unsignedShortValue],//samples
                               [(attrDict[@"00000001_00280101-US"])[0] unsignedShortValue] //bits
                               ],
                              @"-InFor",
                              @"rawl",
                              @"-OutFor",
                              @"j2k",
                              @"-o",
                              @"stdout.j2k"],
                           pixelData,
                           j2kData
                           );
                  
#pragma mark TODO compression error management
                  if (result !=0)
                  {
                     NSString *errorString=[[NSString alloc]initWithData:j2kData encoding:NSUTF8StringEncoding];
                     LOG_ERROR(@"compression J2K: %@",errorString);
                     exit(0);
                  }
                  
                  [attrDict setObject:@[@"1.2.840.10008.1.2.4.90"] forKey:@"00000001_00020010-UI"];
                  

                  
                  [attrDict setObject:@[[NSString stringWithFormat:@"Lossless compression J2K codec https://github.com/GrokImageCompression/grok (v9.2,2021-05-22), compression ratio %05f (pixel data size:%lu md5:%@)",1.0*pixelData.length/j2kData.length,(unsigned long)pixelData.length,[pixelData MD5String]]] forKey:@"00000001_00082111-ST"];

                  [attrDict setObject:@[@"J2K sin pérdida"] forKey:@"00000001_00204000-2006LT"];

                  
                  if (![attrDict[pixelKey][0] isKindOfClass:[NSString class]])//blobModeResources
                  {
                     NSString *oldEncapsulatedURLString=attrDict[pixelKey][0][@"Native"][0];
                     NSString *newEncapsulatedURLString=[oldEncapsulatedURLString stringByReplacingOccurrencesOfString:pixelKey withString:@"00000001_7FE00010-OB"];
                     [attrDict removeObjectForKey:pixelKey];
                     [attrDict setObject:
                      @[
                         @{
                            @"Frame#00000001" : @[ newEncapsulatedURLString ]
                         }
                      ]
                     forKey:@"00000001_7FE00010-OB"];
                     [blobDict removeObjectForKey:oldEncapsulatedURLString];
                     [blobDict setObject:j2kData forKey:newEncapsulatedURLString];

                  }
                  else //blobModeInline
                  {
                     [attrDict removeObjectForKey:pixelKey];
                     [attrDict setObject:@[B64JSONstringWithData(j2kData)] forKey:@"00000001_7FE00010-OB"];
                  }

               }
            }

#pragma mark · jsondata
            NSMutableString *JSONstring=json4attrDict(attrDict);
            NSData *JSONdata=[JSONstring dataUsingEncoding:NSUTF8StringEncoding];
            if (!JSONdata)
            {
               LOG_ERROR(@"could not transform to JSON: %@",[attrDict description]);
            }
            else if (
               forceZip
            || (!outputDir && args.count > 2)
            )//more than one path
#pragma mark ·· zip
            {
            }
            else if (outputDir)
#pragma mark ·· outputDir
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

                  if (![inputPathComponents[0] length])[inputPathComponents removeObjectAtIndex:0];//case of absolute paths
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
            else //!outputDir
            {
#pragma mark ·· stdout
               [JSONdata writeToFile:@"/dev/stdout" atomically:NO];
            }
         }//end parsed
         [inputData setLength:0];
      }//end loop
      return 1;
   }//end autorelease pool
   return 0;
}
