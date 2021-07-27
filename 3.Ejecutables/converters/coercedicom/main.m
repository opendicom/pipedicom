//
//  main.m
//  coercedicom
//
//  Created by jacquesfauquex on 2021-07-08.
//

#import <Foundation/Foundation.h>
#import <DCKV/DCKV.h>

const UInt32 DICM='MCID';
const UInt64 _0002000_tag_vr=0x44C5500000002;
const UInt64 _0002001_tag_vr=0x0000424F00010002;
const UInt32 _0002001_length=0x00000002;
const UInt16 _0002001_value=0x0001;

NSString *noUnderscoreSuffixBeforeDcmExt(NSString *name)
{
   if ([name containsString:@"_"])
      return [[name componentsSeparatedByString:@"_"][0] stringByAppendingPathExtension:@"dcm"];
   else return name;
}

NSString *moveDup(NSFileManager *fileManager, NSString *srcFile,NSString *dstFile)
{
   BOOL isDir;
   NSError *error;
   
   if ([fileManager fileExistsAtPath:dstFile isDirectory:&isDir])
   {
      if (isDir)
      {
         //directory already existing
         NSUInteger sameFileCount=[[fileManager contentsOfDirectoryAtPath:dstFile error:&error]count];
         if (![fileManager moveItemAtPath:srcFile toPath:[dstFile stringByAppendingPathComponent:[NSString stringWithFormat:@"%lu.dcm",sameFileCount + 1]] error:&error]) return error.description;
         return nil;
      }
      else
      {
         NSString *tmpFile=[[dstFile stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"1"];
         if (![fileManager moveItemAtPath:dstFile toPath:tmpFile error:&error]) return error.description;
         if (![fileManager createDirectoryAtPath:dstFile withIntermediateDirectories:true attributes:nil error:&error]) return error.description;
         if (![fileManager moveItemAtPath:tmpFile toPath:[dstFile stringByAppendingPathComponent:@"1.dcm"] error:&error]) return error.description;
         if (![fileManager moveItemAtPath:srcFile toPath:[dstFile stringByAppendingPathComponent:@"2.dcm"] error:&error]) return error.description;
         return nil;
      }
   }
   else if (![fileManager moveItemAtPath:srcFile toPath:dstFile error:&error]) return error.description;
   else return nil;
}

NSString *mergeDir(NSFileManager *fileManager, NSString *srcDir, NSString *dstDir)
{
   //returns:
   //  nil   srcDir moved
   //  @""   srcDir can be removed
   //  errorMessage
   NSError *err=nil;
   BOOL isDir=false;
   
   if (![fileManager fileExistsAtPath:dstDir])
   {
      if (![fileManager moveItemAtPath:srcDir toPath:dstDir error:&err])
         return [err description];
     return nil;
   }

   NSArray *children=[fileManager contentsOfDirectoryAtPath:srcDir error:nil];
   for (NSString *childName in children)
   {
      if ([childName hasPrefix:@"."]) continue;
      
      NSString *childDstPath=[dstDir stringByAppendingPathComponent:childName];
      NSString *childSrcPath=[srcDir stringByAppendingPathComponent:childName];
      [fileManager fileExistsAtPath:childSrcPath isDirectory:&isDir];
      if (isDir==false)
      {
         moveDup(fileManager,childSrcPath,childDstPath);
      }
      else //recursive
      {
         NSString *errMsg=mergeDir(fileManager,childSrcPath,childDstPath);
         if (errMsg && (errMsg.length)) return errMsg;
      }
   }
   if (![fileManager removeItemAtPath:srcDir error:&err]) return err.description;
   return nil;
}

void async_f_study_callback(void *context){
   NSMutableDictionary *current = (NSMutableDictionary*) context;
   NSFileManager *fileManager=[NSFileManager defaultManager];
   NSError *error=nil;
   NSData *headData=[@"\r\n--myboundary\r\nContent-Type: application/dicom\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
   NSData *tailData=[@"\r\n--myboundary--"
                      dataUsingEncoding:NSASCIIStringEncoding];
   NSMutableString *response=[NSMutableString string];

   NSMutableArray *srcNames=[NSMutableArray array];
   if (!visibleRelativeFiles(fileManager, current[@"spoolDirPath"], [fileManager contentsOfDirectoryAtPath:current[@"spoolDirPath"] error:&error] , srcNames))
   {
      [response appendFormat:@"error reading directory %@\r\n",current[@"spoolDirPath"]];
      [current setObject:response forKey:@"response"];
      return;
   }

   //we want to create these folder, if necesary, once only
   
   BOOL successDirExists=([fileManager fileExistsAtPath:current[@"successDir"]]);
   BOOL failureDirExists=([fileManager fileExistsAtPath:current[@"failureDir"]]);

   NSString *originalsDir=current[@"originalsDir"];
   if (![fileManager fileExistsAtPath:originalsDir])
   {
      if (![fileManager createDirectoryAtPath:originalsDir withIntermediateDirectories:YES attributes:nil error:&error])
      {
         [response appendFormat:@"can not create %@\r\n",originalsDir];
         [current setObject:response forKey:@"response"];
         return;
      }
   }
   
   //to find duplicate tasks and move them to ORIGINALS
   NSMutableSet *doneSet=[NSMutableSet setWithArray:[fileManager contentsOfDirectoryAtPath:originalsDir error:&error]];

#pragma mark loop
   NSMutableData *inputData=[NSMutableData data];
   long long storeBucketSize=[current[@"storeBucketSize"] longLongValue];
   long long bucketNumber=0;
   long long bucketSpaceLeft=0;
   for (NSString *srcName in srcNames)
   {
      if ([srcName hasPrefix:@"."]) continue;
      NSString *srcFile=[current[@"spoolDirPath"] stringByAppendingPathComponent:srcName];
      //already in originals?
      NSString *dstName=noUnderscoreSuffixBeforeDcmExt(srcName);
      if ([doneSet containsObject:dstName])
      {
         NSString *errMsg=moveDup(
                                  fileManager,
                                  srcFile,
                                  [originalsDir stringByAppendingPathComponent:dstName]);
         if (errMsg) [response appendString:errMsg];
      }
      else
      {

#pragma mark · parse
         [inputData appendData:[NSData dataWithContentsOfFile:srcFile]];
         
         uint32 inputFileMetadataLength=0;
         if (inputData.length > 144) [inputData getBytes:&inputFileMetadataLength range:NSMakeRange(140,4)];
         
         NSData *inputFileMetadata=nil;
         if (   ( inputFileMetadataLength > 100 )
             && ( inputData.length >= 144 + inputFileMetadataLength )
             )
            inputFileMetadata=[inputData subdataWithRange:NSMakeRange(158,inputFileMetadataLength-14)];
         else
         {
            //move srcFile to FAILURE
            if (!failureDirExists)
            {
               if (![fileManager createDirectoryAtPath:current[@"failureDir"] withIntermediateDirectories:YES attributes:nil error:&error])
               {
                  [response appendFormat:@"failed to create %@\r\n",current[@"failureDir"]];
                  break;
               }
            }

            NSString *errMsg=moveDup(
                                     fileManager,
                                     srcFile,
                                     [current[@"failureDir"] stringByAppendingPathComponent:dstName]
                                     );
            if (errMsg) [response appendString:errMsg];
            continue;
         }
         
         
         NSMutableDictionary *parsedAttrs=[NSMutableDictionary dictionary];
         NSMutableDictionary *blobDict=[NSMutableDictionary dictionary];
         NSMutableDictionary *j2kAttrs=[NSMutableDictionary dictionary];
         NSMutableDictionary *j2kBlobDict=[NSMutableDictionary dictionary];
         
         NSMutableDictionary *fileMetadataAttrs=[NSMutableDictionary dictionary];
         if (!D2dict(
                    inputFileMetadata,
                    fileMetadataAttrs,
                    0,//blob min size
                    blobModeResources,
                    @"",//prefix
                    @"",//suffix
                    blobDict
                    )
             )
         {
            [response appendFormat:@"could not parse fileMetadata %@\r\n",srcFile];
            break;
         }


         if (!D2dict(
                     [inputData subdataWithRange:NSMakeRange(144+inputFileMetadataLength,inputData.length-144-inputFileMetadataLength)],
                    parsedAttrs,
                    0,//blob min size
                    blobModeResources,
                    @"",//prefix
                    @"",//suffix
                    blobDict
                    )
             )
         {
            [response appendFormat:@"could not parse %@\r\n",srcFile];
            break;
         }
         else
         {
#pragma mark · compress ?
            //NSLog(@"%@: %@",parsedAttrs[@"00000001_00020010-UI"][0],parsedAttrs[@"00000001_00020003-UI"][0]);
            NSString *pixelKey=nil;
            if (parsedAttrs[@"00000001_7FE00010-OB"])pixelKey=@"00000001_7FE00010-OB";
            else if (parsedAttrs[@"00000001_7FE00010-OW"])pixelKey=@"00000001_7FE00010-OW";
            
            if (   pixelKey
                && [fileMetadataAttrs[@"00000001_00020010-UI"][0] isEqualToString:@"1.2.840.10008.1.2.1"]
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
                            j2kAttrs,
                            response
                            )==success
                   )
               {
                  //remove native pixel blob and corresponding attribute
                  
                  //include j2k blobs
                  [blobDict addEntriesFromDictionary:j2kBlobDict];
                  
                  //remove native attributes
                  [parsedAttrs removeObjectForKey:pixelKey];
                  [parsedAttrs addEntriesFromDictionary:j2kAttrs];

                  [fileMetadataAttrs setObject:@[@"1.2.840.10008.1.2.4.90"] forKey:@"00000001_00020010-UI"];
               }
               else
               {
                  [response appendFormat:@"could not compress %@\r\n",srcFile];
                  break;
               }
            }
            
            
#pragma mark coerce and outputData init
            if (current[@"coerceDataset"]) [parsedAttrs addEntriesFromDictionary:current[@"coerceDataset"]];
            
            if (current[@"coerceFileMetadata"]) [fileMetadataAttrs addEntriesFromDictionary:current[@"coerceFileMetadata"]];
            
            if (current[@"coerceBlobs"]) [blobDict addEntriesFromDictionary:current[@"coerceBlobs"]];

            NSMutableData *outputData;
//prefix
            if (!current[@"coercePrefix"]) outputData=[NSMutableData dataWithLength:128];
            else outputData=[NSMutableData dataWithLength:128];
            [outputData appendBytes:&DICM length:4];
//fileMetadata
            NSMutableData *outputFileMetadata=[NSMutableData data];
            if (dict2D(
                        @"",
                        fileMetadataAttrs,
                        outputFileMetadata,
                        4, //dicomExplicitJ2kIdem
                        blobDict
                        ) == failure
                )
            {
               NSLog(@"could not serialize group 0002. %@",fileMetadataAttrs.description);
               exit(failure);
            }
            
            [outputData appendBytes:&_0002000_tag_vr length:8];
            UInt32 fileMetadataLength=(UInt32)outputFileMetadata.length+14;//00020001
            [outputData appendBytes:&fileMetadataLength length:4];
            [outputData appendBytes:&_0002001_tag_vr length:8];
            [outputData appendBytes:&_0002001_length length:4];
            [outputData appendBytes:&_0002001_value length:2];
            [outputData appendData:outputFileMetadata];


// dataset
            if (dict2D(
                        @"",
                        parsedAttrs,
                        outputData,
                        4, //dicomExplicitJ2kIdem
                        blobDict
                        )==failure
                )
#pragma mark · failure
            {
               NSLog(@"could not serialize dataset. %@",parsedAttrs);
               if (!failureDirExists)
               {
                  if (![fileManager createDirectoryAtPath:current[@"failureDir"] withIntermediateDirectories:YES attributes:nil error:&error])
                  {
                     [response appendFormat:@"failed to create %@\r\n",current[@"failureDir"]];
                     break;
                  }
               }

               NSString *errMsg=moveDup(
                                        fileManager,
                                        srcFile,
                                        [current[@"failureDir"] stringByAppendingPathComponent:noUnderscoreSuffixBeforeDcmExt(srcName)]);
               if (errMsg) [response appendString:errMsg];
               break;
            }
            else
            {
#pragma mark · success
               
               if (storeBucketSize == 0)
#pragma mark ·· directly into EIUID
               {
                  if (!successDirExists)
                  {
                     if (![fileManager createDirectoryAtPath:current[@"successDir"] withIntermediateDirectories:YES attributes:nil error:&error])
                     {
                        [response appendFormat:@"can not create %@\r\n",current[@"successDir"]];
                        break;
                     }
                     successDirExists=true;
                  }
                  
                  [outputData writeToFile:[current[@"successDir"] stringByAppendingPathComponent:srcName] atomically:NO];
               }
               else
#pragma mark ·· into store buckets
               {
                  //67 = mime head 51 + space + space + mime tail 16
                  if (outputData.length > [current[@"storeBucketSize"] longLongValue]-67)
                  {
                     [response appendFormat:@"%@ dataset (%lu + mime) larger than bucket (%lld). Increase bucket size\r\n",srcName,(unsigned long)outputData.length,[current[@"storeBucketSize"] longLongValue] ];
                     break;
                  }
                  
                  bucketSpaceLeft-=outputData.length;
                  if (bucketSpaceLeft < 69)
                  {
                     //copy mime tail?
                     NSString *tailFile=[[current[@"successDir"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%lld",bucketNumber]] stringByAppendingPathComponent:@"multipart.tail"];
                     if (![fileManager fileExistsAtPath:tailFile]) [tailData writeToFile:tailFile atomically:NO];
                     
                     //new bucket
                     bucketNumber++;
                     bucketSpaceLeft=[current[@"storeBucketSize"] longLongValue]-outputData.length;
                     successDirExists=false;
                  }

                  NSString *bucketDir=[current[@"successDir"]
                                       stringByAppendingPathComponent:[NSString stringWithFormat:@"%lld",bucketNumber]
                                       ];
                  if (!successDirExists)
                  {
                     if (![fileManager createDirectoryAtPath:bucketDir withIntermediateDirectories:YES attributes:nil error:&error])
                     {
                        [response appendFormat:@"can not create %@\r\n",bucketDir];
                        break;
                     }
                     successDirExists=true;
                  }
                  
                  [outputData replaceBytesInRange:NSMakeRange(0,0) withBytes:headData.bytes length:51 ];
                  [outputData writeToFile:[bucketDir stringByAppendingPathComponent:[srcName stringByAppendingPathExtension:@"part"]] atomically:NO];
               }
               
   //move to doneFilePath
               NSString *errMsg=moveDup(
                                        fileManager,
                                        srcFile,
                                        [originalsDir stringByAppendingPathComponent:noUnderscoreSuffixBeforeDcmExt(srcName)]);
               if (errMsg) [response appendString:errMsg];
               [doneSet addObject:dstName];
            }//end parsed
            [inputData setLength:0];
         }
      }
   }//end loop
   
   
   if (bucketNumber > 0)
   {
      //last tail?
      NSString *tailFile=[[current[@"successDir"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%lld",bucketNumber]] stringByAppendingPathComponent:@"multipart.tail"];
      if (![fileManager fileExistsAtPath:tailFile]) [tailData writeToFile:tailFile atomically:NO];
   }
   
   [current setObject:response forKey:@"response"];
   return;
}




enum CDargName{
   CDargCmd=0,
   
   CDargSpool,
   CDargSuccess,
   CDargFailure,
   CDargOriginals,
   
   CDargSourceMismatch,
   CDargCdawlMismatch,
   CDargPacsMismatch,
   
   CDargCoercedicomFile,
   CDargCdamwlDir,
   CDargPacsSearchUrl,
   
   CDargAsyncMonitorLoopsWait
};


int main(int argc, const char * argv[]){
   int returnInt;
   @autoreleasepool {

   NSFileManager *fileManager=[NSFileManager defaultManager];
    NSError *error=nil;
    BOOL isDirectory=false;

    NSProcessInfo *processInfo=[NSProcessInfo processInfo];
    NSArray *args=[processInfo arguments];
    unsigned int waitSeconds=0;//no GDCasync
    NSInteger waitLoops=NSNotFound;
    NSString *argAsync = args[CDargAsyncMonitorLoopsWait];
    if (argAsync)
    {
       NSArray *argAsyncxs=[argAsync componentsSeparatedByString:@"x"];
       if (argAsyncxs.count==2)
       {
          waitLoops=[argAsyncxs[0] integerValue];
          waitSeconds=(unsigned int)[[argAsyncxs[1] substringToIndex:[argAsyncxs[1] length] -1 ] integerValue];
       }
    }
    
    if (![fileManager fileExistsAtPath:args[CDargSpool] isDirectory:&isDirectory] || !isDirectory)
    {
         NSLog(@"CLASSIFIED directory not found: %@",args[CDargSpool]);
         exit(1);
    };
    
    NSArray *CLASSIFIEDarray=[fileManager contentsOfDirectoryAtPath:args[CDargSpool] error:&error];
    if (!CLASSIFIEDarray)
    {
        NSLog(@"Can not open CLASSIFIED directory: %@. %@",args[CDargSpool], error.description);
         exit(1);
    };

    if (!CLASSIFIEDarray.count) exit(0);
    NSMutableArray *sourcesBeforeMapping=[NSMutableArray arrayWithArray:CLASSIFIEDarray];
    if ([sourcesBeforeMapping[0] hasPrefix:@"."])
    {
       if([fileManager removeItemAtPath:[args[CDargSpool] stringByAppendingPathComponent:sourcesBeforeMapping[0]] error:&error])
       {
          [sourcesBeforeMapping removeObjectAtIndex:0];
          if (!sourcesBeforeMapping.count) exit(0);

       }
       else NSLog(@"can not remove %@. %@",[args[CDargSpool] stringByAppendingPathComponent:sourcesBeforeMapping[0]],error.description);
    }

    
    
#pragma mark coercedicom
    
    NSData *jsonData=[NSData dataWithContentsOfFile:args[CDargCoercedicomFile]];
    if (!jsonData)
    {
        NSLog(@"no coercedicom json file at: %@",args[CDargCoercedicomFile]);
         exit(1);
    };
    
    NSMutableArray *whiteList=[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    if (!whiteList)
    {
        NSLog(@"bad coercedicom json file:%@ %@",args[CDargCoercedicomFile],[error description]);
        exit(1);
    }
    NSMutableArray *sourcesToBeProcessed=[NSMutableArray array];
/*
format:
[
{
  org:string (pacs aet)
 
  regex:string (scu pattern)
  scu:string (scu matching)
 
  coerceDataset:{}
  coerceFileMetadata
  coerceBlobs
  coercePrefix
  ...
 
  successDir
  failureDir
  originalsDir
  storeBucketSize (subdir max size for storedicom operation)
}
...
]

The root is an array where items are clasified by priority of execution
(normally CR, US, DX come before large CT)

"spool": is added dynamically in source
 
"success", "failure", "done" added for each study
*/

    for (NSDictionary *matchDict in whiteList)
    {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:matchDict[@"regex"] options:0 error:&error];
        if (!regex)
        {
            NSLog(@"bad coercedicom json file:%@ item:%@ %@",args[CDargCoercedicomFile],matchDict.description,[error description]);
        }
       
       //loop sourcesBeforeMapping for matching regex filter
       for ( long i=sourcesBeforeMapping.count-1; i>=0; i--)
       {
          if ([regex numberOfMatchesInString:sourcesBeforeMapping[i] options:0 range:NSMakeRange(0,[sourcesBeforeMapping[i] length])])
          {
             NSArray *Eiuids=[fileManager contentsOfDirectoryAtPath:[args[CDargSpool] stringByAppendingPathComponent:sourcesBeforeMapping[i]] error:&error];
             if (  !Eiuids
                 ||(
                       (Eiuids.count==1)
                    && [Eiuids[0] hasPrefix:@"."]
                    )
                 )
             {
                if(![fileManager removeItemAtPath:[args[CDargSpool] stringByAppendingPathComponent:sourcesBeforeMapping[0]] error:&error]) NSLog(@"can not remove %@. %@",[args[CDargSpool] stringByAppendingPathComponent:sourcesBeforeMapping[i]],error.description);
             }
             else
             {
                [sourcesToBeProcessed addObject:[NSMutableDictionary dictionaryWithDictionary:matchDict]];
                [sourcesToBeProcessed.lastObject setObject:sourcesBeforeMapping[i] forKey:@"scu"];
             }
             [sourcesBeforeMapping removeObjectAtIndex:i];
          }
       }
    }
      
#pragma mark - sourceMismatch To Be discarded
      for (NSString *sourceName in sourcesBeforeMapping)
      {
         NSString *errMsg=mergeDir(fileManager, [args[CDargSpool] stringByAppendingPathComponent:sourceName], [args[CDargSourceMismatch] stringByAppendingPathComponent:sourceName]);
         if (errMsg && errMsg.length)
         {
            NSLog(@"%@",errMsg);
            return 1;
         }
      }
        
#pragma mark - sourcesToBeProcessed
    NSMutableArray *studyTasks=[NSMutableArray array];
    if (sourcesToBeProcessed.count)
    {
       static NSISO8601DateFormatter *ISO8601yyyyMMdd;
       ISO8601yyyyMMdd=[[NSISO8601DateFormatter alloc]init];
       ISO8601yyyyMMdd.formatOptions=NSISO8601DateFormatWithFullDate;
       NSString *todayDCMString=[ISO8601yyyyMMdd stringFromDate:[NSDate date]];

#pragma mark cdawldicom init
       NSString *wltodayFolder=nil;
       NSString *wltodayEUIDFolder=nil;
       NSString *wltodayANFolder=nil;
       NSString *wltodayPIDFolder=nil;
       NSArray  *wltodayEUIDkeys=nil;
       NSArray  *wltodayANkeys=nil;
       NSArray  *wltodayPIDkeys=nil;
       NSString *wlpublished=nil;
       NSString *wlcompleted=nil;
       NSString *wlcancelled=nil;
       if ([args[CDargCdamwlDir] length])
       {
          wltodayFolder=[args[CDargCdamwlDir] stringByAppendingPathComponent:todayDCMString
             ];
          if ([fileManager fileExistsAtPath:wltodayFolder])
          {
              wlpublished=[args[CDargCdamwlDir] stringByAppendingPathComponent:@"published"];
              wlcompleted=[args[CDargCdamwlDir] stringByAppendingPathComponent:@"completed"];
              wlcancelled=[args[CDargCdamwlDir] stringByAppendingPathComponent:@"cancelled"];

              wltodayEUIDFolder=[wltodayFolder stringByAppendingPathComponent:@"EUID"];
              wltodayEUIDkeys=[fileManager contentsOfDirectoryAtPath:wltodayEUIDFolder error:nil];
          }
           
        }
       
       dispatch_queue_attr_t attr=dispatch_queue_attr_make_with_autorelease_frequency(DISPATCH_QUEUE_CONCURRENT,DISPATCH_AUTORELEASE_FREQUENCY_WORK_ITEM);


       dispatch_queue_t studyQueue = dispatch_queue_create("com.opendicom.coercedicom.studyqueue", attr);


#pragma mark source loop
       for (NSDictionary *sourceDict in sourcesToBeProcessed)
       {
            NSString *sourceDir=[args[CDargSpool] stringByAppendingPathComponent:sourceDict[@"scu"]];
            NSArray *Eiuids=[fileManager contentsOfDirectoryAtPath:sourceDir error:nil];

          
#pragma mark - StudyUIDs loop
         for (NSString *Eiuid in Eiuids)
         {
            
#pragma mark empty ?
            NSString *studyPath=[sourceDir stringByAppendingPathComponent:Eiuid];
            if ([Eiuid hasPrefix:@"."])
            {
                if (![fileManager removeItemAtPath:studyPath error:&error]) NSLog(@"can not remove %@. %@",studyPath,error.description);
                continue;
             }
            NSArray *StudyContents=[fileManager contentsOfDirectoryAtPath:studyPath error:nil];
            if (  ![StudyContents count]
                || (
                      ([StudyContents count]==1)
                    &&[StudyContents[0] hasPrefix:@"."]
                   )
                )
            {
               //remove folder
               if (![fileManager removeItemAtPath:studyPath error:&error]) NSLog(@"could not remove empty folder %@ %@",studyPath,[error description]);
               continue;
            }

            NSMutableDictionary *studyTaskDict=[NSMutableDictionary dictionaryWithDictionary:sourceDict];
            
            [studyTaskDict setObject:studyPath forKey:@"spoolDirPath"];

            [studyTaskDict setObject:
             [[[args[CDargSuccess]
               stringByAppendingPathComponent:sourceDict[@"coerceDataset"][@"00000001_00080080-LO"][0]]
               stringByAppendingPathComponent:sourceDict[@"scu"]]
              stringByAppendingPathComponent:Eiuid
              ] forKey:@"successDir"];
            [studyTaskDict setObject:
             [[args[CDargFailure]
               stringByAppendingPathComponent:sourceDict[@"scu"]]
              stringByAppendingPathComponent:Eiuid
              ] forKey:@"failureDir"];
            [studyTaskDict setObject:
             [[args[CDargOriginals]
               stringByAppendingPathComponent:sourceDict[@"scu"]]
              stringByAppendingPathComponent:Eiuid
              ] forKey:@"originalsDir"];

#pragma mark (2) check with cdawldicom
/*
            //add eventual additional coercion in correspondinng "coerceDataset" mutable dictionary of the study
            if (wltodayEUIDkeys)
            {
                //depending on the results of cdawldicom, pacsTesting will be executed, or not
                //EUIDindex, ANindex and PIDindex indicate cdawldicom contains the usefull metadata
               //When ANindex is found, EUIDindex is found by symlink
               //When PIDindex is found, EUIDindex is found by symlink
               NSString *EUIDpath=nil;
               NSUInteger ANindex=NSNotFound;
               NSUInteger PIDindex=NSNotFound;
#pragma mark (2.1) StudyInstanceUID match
               NSUInteger EUIDindex=[wltodayEUIDkeys indexOfObject:Eiuid];
               if (EUIDindex!=NSNotFound)
               {
                  EUIDpath=[wltodayEUIDFolder stringByAppendingPathComponent:wltodayEUIDkeys[EUIDindex] ];
               }
               else
               {
                  //no definitive StudyInstanceUID matching
#pragma mark dependent on an instance metadata

                  //read last instance (to avoid the case of reading a .DS_store file ... which is first)
                  //we already knwo there is one or more of them
                  NSString *sopPath=[studyPath stringByAppendingPathComponent:StudyContents.lastObject];
                  NSMutableDictionary *sopDict=[NSMutableDictionary dictionary];
                  if (!D2dict(
                             [NSData  dataWithContentsOfFile:sopPath],
                             sopDict,
                             sopPath,
                             1000
                             )
                      )
                  {
                     NSLog(@"SOP not parsed %@",sopPath);
                     break;
                  }
                  
                  //Charset
                  char eidx=0;//default encoding
                  NSString *CS=sopDict[@"00000001_00080005-CS"];
                  if (CS) eidx=encodingCSindex(CS);
                  else LOG_VERBOSE(@"default encoding used");
                  if (eidx==encodingTotal)
                  {
                     NSLog(@"unnknown encodinng '%@'. Default encoding used",CS);
                     eidx=0;
                  }

#pragma mark (2.2) AccessionNumber match
                  if (!wltodayANFolder) wltodayANFolder=[wltodayFolder stringByAppendingPathComponent:@"AN"];
                  wltodayANkeys=[fileManager contentsOfDirectoryAtPath:wltodayANFolder error:nil];
                  
                  NSString *AN;
                  NSArray *ANa=sopDict[[NSString stringWithFormat:@"00000001_00080050-%@SH",evr[eidx]]];
                  if (ANa && ANa.count) AN=ANa[0];
                  
#pragma mark TODO AccessionNumber issuer
                  
                  
                  ANindex=[wltodayANkeys indexOfObject:AN];
                  if (ANindex!=NSNotFound)
                  {
                     [fileManager destinationOfSymbolicLinkAtPath:[wltodayANFolder stringByAppendingPathComponent:wltodayANkeys[ANindex]] error:&error];
                  }
                  else
                  {
                     
                   //no definitive Accssion Number matching

                   //read wldict
                   NSDictionary *wldict=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[wltodayEUIDFolder stringByAppendingPathComponent:Eiuid]stringByAppendingPathComponent:@"wl.json"] options:0 error:&error] options:0 error:&error];
                   
                   
                 
#pragma mark (2.3) PatientID match
                      if (!wltodayPIDFolder) wltodayPIDFolder=[wltodayFolder stringByAppendingPathComponent:@"PID"];
                      wltodayPIDkeys=[fileManager contentsOfDirectoryAtPath:wltodayPIDFolder error:nil];

                  }


             }
#pragma mark (3) PacsSearch

             if (args[argPacsSearch] && [args[argPacsSearch] length])
             {
                 NSString *pacsURIString=[NSString stringWithFormat:args[argcoercedicom],institutionName];
                 
                 

             }

             //pacs already containing all the items of the study?
             NSMutableData *sqlResponseData=[NSMutableData data];
             if ([args count]>5)
                execTask(
                     environment,
                     @"/bin/bash",
                     @[@"-s"],
                     [
                         [args[argPacsSearch] stringByAppendingFormat:args[argcoercedicom],
                          Eiuid]
                         dataUsingEncoding:NSUTF8StringEncoding
                     ],
                     sqlResponseData
                     );
                
             if (sqlResponseData.length)
             {
                 //(studyUID already exists in PACS?)
                 //same institution name?
                 [sqlResponseData
                  getBytes:&lastByte
                  range:NSMakeRange([sqlResponseData length]-1,1)
                  ];
                 NSString *sqlResponseString=nil;//remove eventual last space
                 if (lastByte==0x20) sqlResponseString=
                    [
                     [NSString alloc]
                     initWithData:sqlResponseData
                     encoding:NSUTF8StringEncoding
                     ];
                 else sqlResponseString=
                    [
                     [NSString alloc]
                     initWithData:[sqlResponseData subdataWithRange:NSMakeRange(0,[sqlResponseData length]-1)]
                     encoding:NSUTF8StringEncoding
                     ];
                
                 if (![sqlResponseString isEqualToString:institutionName])
                 {
                     LOG_WARNING(@"%@ discarded. Comes from %@. Was already registered for %@)",Eiuid,institutionName,sqlResponseString);
                 
                     [fileManager
                      moveItemAtPath:studyPath
                      toPath:[NSString stringWithFormat:@"%@/%@@%f",args[argDiscarded],CLASSIFIEDname,[[NSDate date]timeIntervalSinceReferenceDate
                      ]]
                      error:&error];
                     continue;
                 }
             }
                
             NSURL *pacsURI=[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",pacsURIString,Eiuid]];
             NSString *qidoRequest=[NSString stringWithFormat:@"%@?StudyInstanceUID=%@",pacsURIString,Eiuid];
             NSURL *qidoRequestURL=[NSURL URLWithString:qidoRequest];
                
             NSDictionary *q=[NSDictionary studyAttributesForQidoURL:qidoRequestURL];
             if (q[@"00100020"] && [q[@"00100020"] length])
             {
//JF                   LOG_INFO(@"%@ %@ (%@/%@) for patient %@ in PACS before STOW",
//JF                      Eiuid,
//JF                      q[@"00080061"],
//JF                      q[@"00201206"],
//JF                      q[@"00201208"],
//JF                      q[@"00100020"]
//JF                      );
             }
             else if (q[@"name"] && [q[@"name"] length])
             {
//JF                   LOG_WARNING(@"study %@ discarded. %@: %@",Eiuid,q[@"name"],q[@"reason"]);
                NSString *DISCARDEDpath=[NSString stringWithFormat:@"%@/%@/%@@%f",DISCARDED,CLASSIFIEDname,Eiuid,[[NSDate date]timeIntervalSinceReferenceDate
                ]];
                [fileManager createDirectoryAtPath:[DISCARDED stringByAppendingPathComponent:CLASSIFIEDname] withIntermediateDirectories:YES attributes:nil error:&error];
                [fileManager moveItemAtPath:studyPath
                                     toPath:DISCARDEDpath
                                      error:&error
                 ];
                continue;
             }


            }
*/
            
            
            [studyTasks addObject:studyTaskDict];
            //dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0 ),

            if (waitSeconds!=0)
            dispatch_async_f(
               studyQueue,
               studyTaskDict,
               async_f_study_callback
               );//(__bridge void * _Nullable)(studyTaskDict),
            else async_f_study_callback(studyTaskDict);//run sequentially on one thread
            
         } //NSLog(@"end of study loop");
       } //NSLog(@"end of source loop");
    } //NSLog(@"end of sources to be processed");
      
      
#pragma mark monitor studyTask completion
      
   while (studyTasks.count && (waitLoops > 0))
   {
      waitLoops--;
      sleep(waitSeconds);
      for (NSUInteger i=0; i < studyTasks.count; i++)
      {
         if (studyTasks[i][@"response"])
         {
            NSLog(@"%@",studyTasks[i][@"response"]);
            [studyTasks removeObjectAtIndex:i];
         }
      }
   }
   returnInt=(int)studyTasks.count;
}//end autoreleaspool
  return returnInt;
}

