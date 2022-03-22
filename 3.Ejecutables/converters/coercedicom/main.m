//
//  main.m
//  coercedicom
//
//  Created by jacquesfauquex on 2021-07-08.
//

#import <Foundation/Foundation.h>
#import <DCKV/DCKV.h>
#import "fileManager.h"

const UInt32 DICM='MCID';
const UInt64 _0002000_tag_vr=0x44C5500000002;
const UInt64 _0002001_tag_vr=0x0000424F00010002;
const UInt32 _0002001_length=0x00000002;
const UInt16 _0002001_value=0x0001;


void async_f_study_callback(void *context){
   NSDictionary *current = (NSDictionary*) context;
   NSFileManager *fileManager=[NSFileManager defaultManager];
   NSError *error=nil;

   
   //this folder is always required to remove files from classified
   NSString *originalsDir=current[@"originalsDir"];
   if (![fileManager fileExistsAtPath:originalsDir])
   {
      if(![fileManager createDirectoryAtPath:originalsDir withIntermediateDirectories:YES attributes:nil error:&error])
      {
          NSLog(@"can not create: %@: %@",originalsDir, error.description);
          return;
      }
   }

   
   //log file
   [[NSFileManager defaultManager] createFileAtPath:current[@"spoolDirLogPath"] contents:nil attributes:nil];
   NSFileHandle *logHandle=[NSFileHandle fileHandleForWritingAtPath:current[@"spoolDirLogPath"]];
   if (!logHandle)
   {
      NSLog(@"can not create: %@",current[@"spoolDirLogPath"]);
      return;
   }

   
   //variable init
   BOOL isDirectory=false;
    NSData *dotData=[@"." dataUsingEncoding:NSASCIIStringEncoding];
   NSData *headData=[@"\r\n--myboundary\r\nContent-Type: application/dicom\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
   NSMutableData *inputData=[NSMutableData data];
   long long storeBucketSize=[current[@"storeBucketSize"] longLongValue];
   NSMutableString *bucketName=[NSMutableString string];
   long long bucketSpaceLeft=0;

   
   //we want to create this folder, if necesary, and once only
   BOOL successDirExists=([fileManager fileExistsAtPath:current[@"successDir"]]);
   
   
   //doneSet is used to avoid processing again instances already found in originals, that is already processed
   NSMutableSet *doneSet=[NSMutableSet setWithArray:[fileManager contentsOfDirectoryAtPath:originalsDir error:&error]];


   
#pragma mark loop
   
   NSArray *iuid_times=[fileManager contentsOfDirectoryAtPath:current[@"spoolDirPath"] error:&error];
   NSInteger maxBatchCount=[current[@"maxIperE"] integerValue];
   for (NSString *iuid_time in iuid_times)
   {
       if (maxBatchCount==0) break;
       maxBatchCount--;
       @autoreleasepool {
           
          if ([iuid_time hasPrefix:@"#"]) continue;//log file
          if ([iuid_time hasPrefix:@"."]) continue;
          NSString *iuid_timePath=[current[@"spoolDirPath"] stringByAppendingPathComponent:iuid_time];

          
          //is this a directory containing versions?
          //select the first one found as versionSuffix
          NSString *versionSuffix=nil;
          if ([fileManager fileExistsAtPath:iuid_timePath isDirectory:&isDirectory] && isDirectory )
          {
             //reverse order... to look at latest first
             NSArray *versions=[[[fileManager contentsOfDirectoryAtPath:iuid_timePath error:&error]reverseObjectEnumerator] allObjects];
             for (NSString *version in versions)
             {
                if ([version hasSuffix:@"dcm"]) versionSuffix=[@"/" stringByAppendingString:version];
                break;
             }
          }
          if (!versionSuffix) versionSuffix=@"";

          
          //remove timestamp from name and obtain iuid.dcm, (dst name format)
          NSString *iuid=nil;
          if ([iuid_time containsString:@"_"])
             iuid=[[iuid_time componentsSeparatedByString:@"_"][0] stringByAppendingPathExtension:@"dcm"];
          else iuid=iuid_time;
          if ([doneSet containsObject:iuid])
          {
    #pragma mark · move duplicate to originals

             NSString *returnMsg=moveVersionedInstance(
                                  fileManager,
                                  iuid_timePath,                                           //srciPath
                                  current[@"originalsDir"],                                //dstePath
                                  iuid                                                     //iName
                                  );
             if (returnMsg.length) [logHandle writeData:[returnMsg dataUsingEncoding:NSUTF8StringEncoding]];
             continue;
          }
          else
          {
    #pragma mark · parse

             [inputData appendData:[NSData dataWithContentsOfFile:[iuid_timePath stringByAppendingString:versionSuffix]]];
             
             uint32 inputFileMetainfoLength=0;
             if (inputData.length > 144) [inputData getBytes:&inputFileMetainfoLength range:NSMakeRange(140,4)];
             
             NSData *inputFileMetainfo=nil;
             if (   ( inputFileMetainfoLength > 100 )
                 && ( inputData.length >= 144 + inputFileMetainfoLength )
                 )
                inputFileMetainfo=[inputData subdataWithRange:NSMakeRange(158,inputFileMetainfoLength-14)];
             else
             {
    #pragma mark ·· failed
                //move iuid_timePath (or its contents) to current[@"failureDir"]
                NSString *returnMsg=moveVersionedInstance(
                                     fileManager,
                                     iuid_timePath,                                         //srciPath
                                     current[@"failureDir"],                                //dstePath
                                     iuid                                                   //iName
                                     );
                if (returnMsg.length) [logHandle writeData:[returnMsg dataUsingEncoding:NSUTF8StringEncoding]];
                continue;
             }
             
             
             NSMutableDictionary *parsedAttrs=[NSMutableDictionary dictionary];
             NSMutableDictionary *blobDict=[NSMutableDictionary dictionary];
             NSMutableDictionary *j2kAttrs=[NSMutableDictionary dictionary];
             NSMutableDictionary *j2kBlobDict=[NSMutableDictionary dictionary];
             
             NSMutableDictionary *fileMetainfoAttrs=[NSMutableDictionary dictionary];
             if (!D2dict(
                        inputFileMetainfo,
                        fileMetainfoAttrs,
                        0,//blob min size
                        blobModeResources,
                        @"",//prefix
                        @"",//suffix
                        blobDict
                        )
                 )
             {
                [logHandle writeData:[[NSString stringWithFormat:@"could not parse fileMetainfo %@%@\r\n",iuid_timePath,versionSuffix] dataUsingEncoding:NSUTF8StringEncoding]];

                break;
             }


             if (!D2dict(
                         [inputData subdataWithRange:NSMakeRange(144+inputFileMetainfoLength,inputData.length-144-inputFileMetainfoLength)],
                        parsedAttrs,
                        0,//blob min size
                        blobModeResources,
                        @"",//prefix
                        @"",//suffix
                        blobDict
                        )
                 )
             {
                [logHandle writeData:[[NSString stringWithFormat:@"could not parse %@%@\r\n",iuid_timePath,versionSuffix] dataUsingEncoding:NSUTF8StringEncoding]];
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
                    && ([parsedAttrs[@"00000001_00280100-US"][0] intValue] != 1)
                    && [fileMetainfoAttrs[@"00000001_00020010-UI"][0] isEqualToString:@"1.2.840.10008.1.2.1"]
                    )
                {
                   NSString *nativeUrlString=parsedAttrs[pixelKey][0][@"Native"][0];
                   NSData *pixelData=nil;
                   if ([parsedAttrs[pixelKey][0] isKindOfClass:[NSDictionary class]])  pixelData=blobDict[parsedAttrs[pixelKey][0][@"Native"][0]];
                   else pixelData=dataWithB64String(blobDict[pixelKey]);
                   NSMutableString *response=[NSMutableString string];
                   if (compressJ2KR(
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

                      [fileMetainfoAttrs setObject:@[@"1.2.840.10008.1.2.4.90"] forKey:@"00000001_00020010-UI"];
                   }
                   else
                   {
                      [logHandle writeData:[[NSString stringWithFormat:@"could not compress %@%@\r\n",iuid_timePath,versionSuffix] dataUsingEncoding:NSUTF8StringEncoding]];
                      break;
                   }
                }

    #pragma mark · coerce
                
    #pragma mark ·· fileMetainfo
                if (current[@"coerceFileMetainfo"]) [fileMetainfoAttrs addEntriesFromDictionary:current[@"coerceFileMetainfo"]];

    #pragma mark ·· blobs
                if (current[@"coerceBlobs"]) [blobDict addEntriesFromDictionary:current[@"coerceBlobs"]];

    #pragma mark ·· coerceFileMetainfo

    #pragma mark ·· replaceInFileMetainfo

    #pragma mark ·· supplementToFileMetainfo

    #pragma mark ·· removeFromFileMetainfo

                
                NSArray *datasetKeys=[parsedAttrs allKeys];
                
    #pragma mark ·· coerceDataset
                NSArray *coerceKeys=[current[@"coerceDataset"] allKeys];
                for (NSString *coerceKey in coerceKeys)
                {
                   NSString *keyNoSuffix=[coerceKey componentsSeparatedByString:@"-"][0];
                   NSString *keyFound=nil;
                   for (NSString *datasetKey in datasetKeys)
                   {
                      if ([datasetKey hasPrefix:keyNoSuffix])
                      {
                         keyFound=datasetKey;
                         break;
                      }
                   }
                   if (keyFound)
                   {
                      [parsedAttrs removeObjectForKey:keyFound];
                   }
                   //coerce
                   [parsedAttrs setObject:current[@"coerceDataset"][coerceKey] forKey:coerceKey];
                }

    #pragma mark ·· replaceInDataset
                NSArray *replaceKeys=[current[@"replaceInDataset"] allKeys];
                for (NSString *replaceKey in replaceKeys)
                {
                   NSString *keyNoSuffix=[replaceKey componentsSeparatedByString:@"-"][0];
                   NSString *keyFound=nil;
                   for (NSString *datasetKey in datasetKeys)
                   {
                      if ([datasetKey hasPrefix:keyNoSuffix])
                      {
                         keyFound=datasetKey;
                         break;
                      }
                   }
                   if (keyFound)
                   {
                      //replace
                      [parsedAttrs removeObjectForKey:keyFound];
                      [parsedAttrs setObject:current[@"replaceInDataset"][replaceKey] forKey:replaceKey];
                   }
                }

    #pragma mark ·· supplementToDataset
                NSArray *supplementKeys=[current[@"supplementToDataset"] allKeys];
                for (NSString *supplementKey in supplementKeys)
                {
                   NSString *keyNoSuffix=[supplementKey componentsSeparatedByString:@"-"][0];
                   NSString *keyFound=nil;
                   for (NSString *datasetKey in datasetKeys)
                   {
                      if ([datasetKey hasPrefix:keyNoSuffix])
                      {
                         keyFound=datasetKey;
                         break;
                      }
                   }
                   if (!keyFound)
                   {
                      //supplement
                      [parsedAttrs setObject:current[@"supplementToDataset"][supplementKey] forKey:supplementKey];
                   }
                }

                
    #pragma mark ·· removeFromDataset

                for (NSString *removeKey in current[@"removeFromDataset"])
                {
                   NSString *keyNoSuffix=[removeKey componentsSeparatedByString:@"-"][0];
                   NSString *keyFound=nil;
                   for (NSString *datasetKey in datasetKeys)
                   {
                      if ([datasetKey hasPrefix:keyNoSuffix])
                      {
                         keyFound=datasetKey;
                         break;
                      }
                   }
                   if (keyFound)
                   {
                      //remove
                      [parsedAttrs removeObjectForKey:removeKey];
                   }
                }

                
                
    #pragma mark ·· outputData init
                NSMutableData *outputData;
    //prefix
                if (!current[@"coercePrefix"]) outputData=[NSMutableData dataWithLength:128];
                else outputData=[NSMutableData dataWithLength:128];
                [outputData appendBytes:&DICM length:4];
    //fileMetainfo
                NSMutableData *outputFileMetainfo=[NSMutableData data];
                if (dict2D(
                            @"",
                            fileMetainfoAttrs,
                            outputFileMetainfo,
                            4, //dicomExplicitJ2kIdem
                            blobDict
                            ) == failure
                    )
                {
                   NSLog(@"could not serialize group 0002. %@",fileMetainfoAttrs.description);
                   exit(failure);
                }
                
                [outputData appendBytes:&_0002000_tag_vr length:8];
                UInt32 fileMetainfoLength=(UInt32)outputFileMetainfo.length+14;//00020001
                [outputData appendBytes:&fileMetainfoLength length:4];
                [outputData appendBytes:&_0002001_tag_vr length:8];
                [outputData appendBytes:&_0002001_length length:4];
                [outputData appendBytes:&_0002001_value length:2];
                [outputData appendData:outputFileMetainfo];


    // dataset
                if (dict2D(
                            @"",
                            parsedAttrs,
                            outputData,
                            4, //dicomExplicitJ2kIdem
                            blobDict
                            )==failure
                    )
    #pragma mark ··· failure
                {
                   NSLog(@"could not serialize dataset. %@",parsedAttrs);
                   //move iuid_timePath (or its contents) to current[@"failureDir"]
                   NSString *returnMsg=moveVersionedInstance(
                                        fileManager,
                                        iuid_timePath,           //srciPath
                                        current[@"failureDir"],  //dstePath
                                        iuid                     //iName
                                        );
                   if (returnMsg.length) [logHandle writeData:[returnMsg dataUsingEncoding:NSUTF8StringEncoding]];
                   continue;
                }
                else
                {
    #pragma mark ··· success
                   
                   if (storeBucketSize == 0)
    #pragma mark ···· directly into EIUID
                   {
                      if (!successDirExists)
                      {
                         if (![fileManager createDirectoryAtPath:current[@"successDir"] withIntermediateDirectories:YES attributes:nil error:&error])
                         {
                            [logHandle writeData:[[NSString stringWithFormat:@"can not create %@\r\n",current[@"successDir"]] dataUsingEncoding:NSUTF8StringEncoding]];
                            break;
                         }
                         successDirExists=true;
                      }
                      
                      [outputData writeToFile:[current[@"successDir"] stringByAppendingPathComponent:iuid] atomically:NO];
                   }
                   else
    #pragma mark ···· into store buckets
                   {
                      //67 = mime head 51 + space + space + mime tail 16
                      if (outputData.length > [current[@"storeBucketSize"] longLongValue]-67)
                      {
                         [logHandle writeData:[[NSString stringWithFormat:@"%@ dataset (%lu + mime) larger than bucket (%lld). Increase bucket size\r\n",iuid,(unsigned long)outputData.length,[current[@"storeBucketSize"] longLongValue] ] dataUsingEncoding:NSUTF8StringEncoding]];
                         break;
                      }
                      
                      bucketSpaceLeft-=outputData.length;
                      if (bucketSpaceLeft < 69)
                      {
                         //69 for mime tail?
                         //replaced by cat * tail i storedicom
                         //new bucket
                         [bucketName setString:[[NSUUID UUID]UUIDString]];
                         bucketSpaceLeft=[current[@"storeBucketSize"] longLongValue]-outputData.length;
                         successDirExists=false;
                      }

                      NSString *bucketDir=[current[@"successDir"]
                                           stringByAppendingPathComponent:bucketName];
                      if (!successDirExists)
                      {
                         if (![fileManager createDirectoryAtPath:bucketDir withIntermediateDirectories:YES attributes:nil error:&error])
                         {
                            [logHandle writeData:[[NSString stringWithFormat:@"can not create %@\r\n",bucketDir] dataUsingEncoding:NSUTF8StringEncoding]];
                            break;
                         }
                         successDirExists=true;
                      }
                      
                      [outputData replaceBytesInRange:NSMakeRange(0,0) withBytes:headData.bytes length:51 ];
                      [outputData writeToFile:[bucketDir stringByAppendingPathComponent:[iuid stringByAppendingPathExtension:@"part"]] atomically:NO];
                   }
                   
                   
    #pragma mark ···· original to originalsDir

                   //move iuid_timePath (or its contents) to current[@"originalsDir"] iuid
                   NSString *returnMsg=moveVersionedInstance(
                                        fileManager,
                                        iuid_timePath,            //srciPath
                                        current[@"originalsDir"], //dstePath
                                        iuid                      //iName
                                        );
                   if (returnMsg.length) [logHandle writeData:[returnMsg dataUsingEncoding:NSUTF8StringEncoding]];

                   
                   [doneSet addObject:[current[@"originalsDir"] stringByAppendingPathComponent:iuid]];
                }//end parsed
                [inputData setLength:0];
             }
          }
       }
       [logHandle writeData:dotData];
   }//end loop
   
   [logHandle closeFile];
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
   int returnInt=0;
   @autoreleasepool {

    NSFileManager *fileManager=[NSFileManager defaultManager];
    NSError *error=nil;
    BOOL isDirectory=false;

    NSProcessInfo *processInfo=[NSProcessInfo processInfo];
    NSArray *args=[processInfo arguments];
    unsigned int waitSeconds=0;//no GDCasync
    NSInteger maxIperE=NSNotFound;
    NSString *argAsync = args[CDargAsyncMonitorLoopsWait];
    if (argAsync)
    {
       NSArray *argAsyncxs=[argAsync componentsSeparatedByString:@"x"];
       if (argAsyncxs.count==2)
       {
          maxIperE=[argAsyncxs[0] integerValue];
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

    
    
#pragma mark coercedicom json directives
    
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
 
  coercePrefix:base64
  coerceBlobs:{}
  coerceFileMetainfo:{}
  replaceInMetainfo:{}
  supplementToMetainfo:{}
  removeFromMetainfo:[]
  coerceDataset:{}
  replaceInDataset:{}
  supplementToDataset:{}
  removeFromDataset:[]
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
                 || (Eiuids.count==0)
                 ||(
                       (Eiuids.count==1)
                    && [Eiuids[0] hasPrefix:@"."]
                    )
                 )
             {
                 //empty source
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
      
#pragma mark sourceMismatch To Be discarded
      for (NSString *sourceName in sourcesBeforeMapping)
      {
         NSString *errMsg=mergeDir(fileManager, [args[CDargSpool] stringByAppendingPathComponent:sourceName], [args[CDargSourceMismatch] stringByAppendingPathComponent:sourceName]);
         if (errMsg && errMsg.length)
         {
            NSLog(@"%@",errMsg);
            return 1;
         }
      }
        
#pragma mark sourcesToBeProcessed
    NSMutableArray *studyTasks=[NSMutableArray array];
    if (sourcesToBeProcessed.count)
    {
       NSDate *now=[NSDate date];
       static NSISO8601DateFormatter *ISO8601yyyyMMdd;
       ISO8601yyyyMMdd=[[NSISO8601DateFormatter alloc]init];
       ISO8601yyyyMMdd.formatOptions=NSISO8601DateFormatWithFullDate;
       NSString *todayDCMString=[ISO8601yyyyMMdd stringFromDate:now];
       NSDateFormatter *DICMDT = [[NSDateFormatter alloc]init];
       [DICMDT setDateFormat:@"yyyyMMddhhmmss"];
       NSString *timeDCMString=[DICMDT stringFromDate:now];

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


#pragma mark - source loop
       for (NSDictionary *sourceDict in sourcesToBeProcessed)
       {
            NSString *sourceDir=[args[CDargSpool] stringByAppendingPathComponent:sourceDict[@"scu"]];
            NSArray *Eiuids=[fileManager contentsOfDirectoryAtPath:sourceDir error:nil];

          
#pragma mark · StudyUIDs loop
         for (NSString *Eiuid in Eiuids)
         {
            
            // starting with dot ?
            NSString *studyPath=[sourceDir stringByAppendingPathComponent:Eiuid];
            if ([Eiuid hasPrefix:@"."])
            {
                if (![fileManager removeItemAtPath:studyPath error:&error]) NSLog(@"can not remove %@. %@",studyPath,error.description);
                continue;
             }

            //empty?
            NSArray *StudyContents=[fileManager contentsOfDirectoryAtPath:studyPath error:nil];
            NSUInteger StudyCount=StudyContents.count;
            for (NSString *iName in StudyContents)
            {
                if ([iName hasPrefix:@"."]) StudyCount--;
                if ([iName hasPrefix:@"#"]) StudyCount--;
            }
            if (StudyCount==0) continue;

            
            NSMutableDictionary *studyTaskDict=[NSMutableDictionary dictionaryWithDictionary:sourceDict];
             
             [studyTaskDict setObject:[NSNumber numberWithInteger:maxIperE] forKey:@"maxIperE"];
            
            [studyTaskDict setObject:studyPath forKey:@"spoolDirPath"];
            [studyTaskDict setObject:[studyPath stringByAppendingFormat:@"/#%@.txt",timeDCMString] forKey:@"spoolDirLogPath"];


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

            if (waitSeconds!=0) //multithread
            {
            dispatch_async_f(
               studyQueue,
               [NSDictionary dictionaryWithDictionary:studyTaskDict],
               async_f_study_callback
               );//(__bridge void * _Nullable)(studyTaskDict),
            }
            else
            {
               async_f_study_callback([NSDictionary dictionaryWithDictionary:studyTaskDict]);//run sequentially on one thread
            }
         } //NSLog(@"end of study loop");
       } //NSLog(@"end of source loop");
    } //NSLog(@"end of sources to be processed");
      
      
#pragma mark execution time for dispatch_asyncf before exiting
   if (waitSeconds!=0)
       [NSThread sleepForTimeInterval:(float)waitSeconds];
   returnInt=(int)studyTasks.count;
}//end autoreleaspool
  return returnInt;//returns the number studuies processed
}






