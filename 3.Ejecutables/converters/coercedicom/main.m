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

static NSMutableSet *seriesTODO=nil;//for detached series processes monitoring
static NSMutableSet *seriesDONE=nil;//for detached series processes monitoring
static NSData *dotData=nil;
static NSData *headData=nil;
void series_callback(void *context){
   NSDictionary *thisContext = (NSDictionary*) context;
   /*
app:
    spoolDir
    spoolDirLogPath
    
    originalsDir
    failureDir

    successDir
    
    coercePrefix

cfg:
    Siuid
    regex
    scu
    coerceBlobs
    coerceFileMetainfo
    replaceInFileMetainfo
    supplementToFileMetainfo
    removeFromFileMetainfo
    
    coerceDataset
    replaceInDataset
    supplementToDataset
    removeFromDataset
    
    */
   
   NSFileManager *fileManager=[NSFileManager defaultManager];
   NSError *error=nil;
   NSArray *iuid_times=[fileManager contentsOfDirectoryAtPath:thisContext[@"spoolDir"] error:&error];
   NSUInteger iuidCount=iuid_times.count;
if (
          (iuidCount==0)
       ||((iuidCount==1) && [iuid_times[0] hasPrefix:@"."])
       )
{
       if (![fileManager removeItemAtPath:thisContext[@"spoolDir"] error:&error]) NSLog(@"%@",error.description);
}
else
{
    

   BOOL isDirectory=false;
   NSMutableData *inputData=[NSMutableData data];

   //logHandle (always new because of date suffix)
   if (![fileManager fileExistsAtPath:thisContext[@"spoolDirLogPath"]])
       [fileManager createFileAtPath:thisContext[@"spoolDirLogPath"] contents:nil attributes:nil];
   NSFileHandle *logHandle=nil;
      
   @try {

   logHandle=[NSFileHandle fileHandleForWritingAtPath:thisContext[@"spoolDirLogPath"]];
   if (!logHandle)
   {
      NSLog(@"can not create: %@",thisContext[@"spoolDirLogPath"]);
      logHandle=[NSFileHandle fileHandleWithStandardError];
   }
   else [logHandle seekToEndOfFile];

   //doneSet is used to avoid processing again instances already found in originals, that is already processed
   NSMutableSet *doneSet=[NSMutableSet set];
   //This is why OriginalsDir needs to exist
   NSString *originalsDir=thisContext[@"originalsDir"];
   if (![fileManager fileExistsAtPath:originalsDir])
   {
      if(![fileManager createDirectoryAtPath:originalsDir withIntermediateDirectories:YES attributes:nil error:&error])
      {
         [logHandle writeData:[[NSString stringWithFormat:@"can not create: %@: %@",originalsDir, error.description]dataUsingEncoding:NSUTF8StringEncoding]];
          return;// !!! unfinished business
      }
      [doneSet setSet:[NSSet setWithArray:[fileManager contentsOfDirectoryAtPath:originalsDir error:&error]]];
   }

   BOOL successDirExists=[fileManager fileExistsAtPath:thisContext[@"successDir"]];
   
#pragma mark loop
   for (NSString *iuid_time in iuid_times)
   {
       @autoreleasepool {
           
          if ([iuid_time hasPrefix:@"."]) continue;
          NSString *iuid_timePath=[thisContext[@"spoolDir"] stringByAppendingPathComponent:iuid_time];

          
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
                                  thisContext[@"originalsDir"],                            //dstePath
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
                //move iuid_timePath (or its contents) to thisContext[@"failureDir"]
                NSString *returnMsg=moveVersionedInstance(
                                     fileManager,
                                     iuid_timePath,                                         //srciPath
                                     thisContext[@"failureDir"],                            //dstePath
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
                //move iuid_timePath (or its contents) to thisContext[@"failureDir"]
                NSString *returnMsg=moveVersionedInstance(
                                     fileManager,
                                     iuid_timePath,                                         //srciPath
                                     thisContext[@"failureDir"],                                //dstePath
                                     iuid                                                   //iName
                                     );
                if (returnMsg.length) [logHandle writeData:[returnMsg dataUsingEncoding:NSUTF8StringEncoding]];
                continue;
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
                //move iuid_timePath (or its contents) to thisContext[@"failureDir"]
                NSString *returnMsg=moveVersionedInstance(
                                     fileManager,
                                     iuid_timePath,                                         //srciPath
                                     thisContext[@"failureDir"],                                //dstePath
                                     iuid                                                   //iName
                                     );
                if (returnMsg.length) [logHandle writeData:[returnMsg dataUsingEncoding:NSUTF8StringEncoding]];
                continue;
             }
             else
             {
    #pragma mark ·· parsed
                
    #pragma mark ··· compress ?
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
#pragma mark TODO move to failed
                      continue;
                   }
                }

    #pragma mark ··· coerce
                
    #pragma mark ···· fileMetainfo
                if (thisContext[@"coerceFileMetainfo"]) [fileMetainfoAttrs addEntriesFromDictionary:thisContext[@"coerceFileMetainfo"]];

    #pragma mark ···· blobs
                if (thisContext[@"coerceBlobs"]) [blobDict addEntriesFromDictionary:thisContext[@"coerceBlobs"]];

    #pragma mark ···· coerceFileMetainfo

    #pragma mark ···· replaceInFileMetainfo

    #pragma mark ···· supplementToFileMetainfo

    #pragma mark ···· removeFromFileMetainfo

                
                NSArray *datasetKeys=[parsedAttrs allKeys];
                
    #pragma mark ···· coerceDataset
                NSArray *coerceKeys=[thisContext[@"coerceDataset"] allKeys];
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
                   [parsedAttrs setObject:thisContext[@"coerceDataset"][coerceKey] forKey:coerceKey];
                }

    #pragma mark ···· replaceInDataset
                NSArray *replaceKeys=[thisContext[@"replaceInDataset"] allKeys];
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
                      [parsedAttrs setObject:thisContext[@"replaceInDataset"][replaceKey] forKey:replaceKey];
                   }
                }

    #pragma mark ···· supplementToDataset
                NSArray *supplementKeys=[thisContext[@"supplementToDataset"] allKeys];
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
                      [parsedAttrs setObject:thisContext[@"supplementToDataset"][supplementKey] forKey:supplementKey];
                   }
                }

                
    #pragma mark ···· removeFromDataset

                for (NSString *removeKey in thisContext[@"removeFromDataset"])
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
                      [parsedAttrs removeObjectForKey:keyFound];
                   }
                }

                
                
    #pragma mark ·· outputData init
                NSMutableData *outputData;
    //prefix
                if (!thisContext[@"coercePrefix"]) outputData=[NSMutableData dataWithLength:128];
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
                   [logHandle writeData:[[NSString stringWithFormat:@"could not serialize group 0002. %@",fileMetainfoAttrs.description]dataUsingEncoding:NSUTF8StringEncoding]];
#pragma mark move to failed
                   continue;
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
                   [logHandle writeData:[[NSString stringWithFormat:@"could not serialize dataset. %@",parsedAttrs]dataUsingEncoding:NSUTF8StringEncoding]];

                   //move iuid_timePath (or its contents) to thisContext[@"failureDir"]
                   NSString *returnMsg=moveVersionedInstance(
                                        fileManager,
                                        iuid_timePath,               //srciPath
                                        thisContext[@"failureDir"],  //dstePath
                                        iuid                         //iName
                                        );
                   
                   if (returnMsg.length) [logHandle writeData:[returnMsg dataUsingEncoding:NSUTF8StringEncoding]];
                   continue;
                }
                else
                {
    #pragma mark ··· success
                   
                  if (!successDirExists)
                  {
                     if (![fileManager createDirectoryAtPath:thisContext[@"successDir"] withIntermediateDirectories:YES attributes:nil error:&error])
                     {
                         [logHandle writeData:[[NSString stringWithFormat:@"can not create %@\r\n",thisContext[@"successDir"]] dataUsingEncoding:NSUTF8StringEncoding]];
                         break;
                     }
                     successDirExists=true;
                  }
                      
                  [outputData replaceBytesInRange:NSMakeRange(0,0) withBytes:headData.bytes length:51 ];
                  [outputData writeToFile:[thisContext[@"successDir"] stringByAppendingPathComponent:[iuid stringByAppendingPathExtension:@"part"]] atomically:NO];
                   
                   
                   
    #pragma mark ···· original to originalsDir

                  //move iuid_timePath (or its contents) to thisContext[@"originalsDir"] iuid
                  NSString *returnMsg=moveVersionedInstance(
                                        fileManager,
                                        iuid_timePath,            //srciPath
                                        thisContext[@"originalsDir"], //dstePath
                                        iuid                      //iName
                                        );
                  if (returnMsg.length) [logHandle writeData:[returnMsg dataUsingEncoding:NSUTF8StringEncoding]];

                   
                  [doneSet addObject:[thisContext[@"originalsDir"] stringByAppendingPathComponent:iuid]];
                }//end parsed
                [inputData setLength:0];
             }
          }
       }
       [logHandle writeData:dotData];
   }//end loop

   [seriesDONE addObject:thisContext[@"Siuid"]];
  }@catch (NSException *exception) {
      NSLog(@"%@", exception.reason);
  }
  @finally {
   [logHandle closeFile];
  }
 }
 [seriesTODO removeObject:thisContext[@"Siuid"]];
}




enum CDargName{
   CDargCmd=0,
   
   CDargSpool,                //receive
   CDargSuccess,              //send
   CDargFailure,              //coerce error
   CDargOriginals,            //destination where to move originals of successfull coertion
   
   CDargSourceMismatch,       //destination where to move originals of source mismatch
   CDargCdamwlMismatch,       //destination where to move originals of cdawl mismatch
   CDargPacsMismatch,         //destination where to move originals of pacs mismatch
   
   CDargCoercedicomFile,      //json
   CDargCdamwlDir,            //registry where to verify objects against cdawl
   CDargPacsSearchUrl,        //DICOMweb url for pacs verifications
   
   CDargUntilLastDispatch,    //max time in seconds before ending the execution
   CDargCores,                //1 is sequential on one core
   CDsinceLastSeriesModif     //min time in seconds without modification in series dir before processing
                              //may be because of receiving
                              //may be because of previous processing

};


int main(int argc, const char * argv[]){
   int returnInt=0;
   dotData=[@"." dataUsingEncoding:NSASCIIStringEncoding];
   headData=[@"\r\n--myboundary\r\nContent-Type: application/dicom\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];

   @autoreleasepool {

    NSFileManager *fileManager=[NSFileManager defaultManager];
    NSError *error=nil;
    BOOL isDirectory=false;


    NSProcessInfo *processInfo=[NSProcessInfo processInfo];
    NSArray *args=[processInfo arguments];
    if (args.count != 14)
    {
         NSLog(@"bad args count: %@",[args description]);
         exit(1);
    };

    NSDate *lastDispatchDate=[NSDate dateWithTimeIntervalSinceNow:[args[CDargUntilLastDispatch] intValue]];

    int sinceLastSeriesModif=[args[CDsinceLastSeriesModif] intValue] * -1;
      
#pragma mark classified

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
      
    //array corresponding to prioridad
    NSMutableArray *sourcesToBeProcessed=[NSMutableArray array];
/*
format:
[
{
  pacsAET:string (destination)
  branch:string
  regex:string (scu pattern)
  scu:string (scu matching)
  priority:%02ld
 
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

    for (long matchIndex=0; matchIndex<whiteList.count; matchIndex++)
    {
        NSDictionary *matchDict=whiteList[matchIndex];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:matchDict[@"regex"] options:0 error:&error];
        if (!regex)
        {
            NSLog(@"bad coercedicom json file:%@ item:%@ %@",args[CDargCoercedicomFile],matchDict.description,[error description]);
            exit(1);
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
                 [sourcesToBeProcessed.lastObject setObject:[NSString stringWithFormat:@"%02ld=",matchIndex] forKey:@"priority"];
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
    if (sourcesToBeProcessed.count)
    {
       NSDate *refTime=[NSDate date];
       static NSISO8601DateFormatter *ISO8601yyyyMMdd;
       ISO8601yyyyMMdd=[[NSISO8601DateFormatter alloc]init];
       ISO8601yyyyMMdd.formatOptions=NSISO8601DateFormatWithFullDate;
       NSString *todayDCMString=[ISO8601yyyyMMdd stringFromDate:refTime];
       //NSDateFormatter *DICMDT = [[NSDateFormatter alloc]init];
       //[DICMDT setDateFormat:@"yyyyMMddhhmmss"];
       //NSString *timeDCMString=[DICMDT stringFromDate:refTime];

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
       
#pragma mark dispatch queue init ?
       BOOL useDispatchQueue=false;
       dispatch_queue_attr_t attr;
       dispatch_queue_t seriesqueue=nil;
       int cores=[args[CDargCores] intValue];
       if ((cores < 1) || (cores > 63)) cores=1;
       if (cores > 1)
       {
          useDispatchQueue=true;
          attr=dispatch_queue_attr_make_with_autorelease_frequency(DISPATCH_QUEUE_CONCURRENT,DISPATCH_AUTORELEASE_FREQUENCY_WORK_ITEM);
          seriesqueue = dispatch_queue_create("com.opendicom.coercedicom.seriesqueue", attr);
       }


#pragma mark - source loop
       seriesTODO=[NSMutableSet set];
       seriesDONE=[NSMutableSet set];
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
            //does the study contain series directory?
            NSMutableSet *Siuids=[NSMutableSet setWithArray:[fileManager contentsOfDirectoryAtPath:studyPath error:nil]];
            for (NSString *Siuid in [Siuids allObjects] )
            {
                if ([Siuid hasPrefix:@"."]) [Siuids removeObject:Siuid];//case of invisible
                if ([Siuid hasSuffix:@".log"])
                    [Siuids removeObject:Siuid];
            }
            if (Siuids.count==0) continue;//does not contain series directory



#pragma mark ·· check with cdawldicom (TODO)
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

            
#pragma mark ·· SeriesUIDs loop the set contains series dirs only
            

            
            //time remains for a new series?
            NSDate *now=[NSDate date];
            while (Siuids.count && ([lastDispatchDate compare:now ] == NSOrderedDescending))
            {
                NSString *Siuid=[Siuids anyObject];
                [Siuids removeObject:Siuid];

                NSDate *modificationDate=[fileManager attributesOfItemAtPath:[studyPath stringByAppendingPathComponent:Siuid] error:nil][NSFileModificationDate];
                if ( [modificationDate timeIntervalSinceNow] > sinceLastSeriesModif) continue;
                //log last modified less than one minute ago
                //may be because of receiving
                //may be because of previous processing
                
                //all cores already in use?
                while (seriesTODO.count >= cores)
                {
                    [NSThread sleepForTimeInterval:1];//wait 1 second
                    NSLog(@"TODO:%lu   DONE:%lu",(unsigned long)seriesTODO.count,(unsigned long)seriesDONE.count);

                }
                                
                [seriesTODO addObject:Siuid];
               
                NSMutableDictionary *seriesTaskDict=[NSMutableDictionary dictionaryWithDictionary:sourceDict];

                [seriesTaskDict setObject:Siuid forKey:@"Siuid"];
                [seriesTaskDict setObject:
                   [studyPath stringByAppendingPathComponent:Siuid]
                   forKey:@"spoolDir"];
                [seriesTaskDict setObject:
                     [NSString stringWithFormat:@"%@/%@/SEND/%@/%@%@/%@/%@",
                      args[CDargSuccess],
                      sourceDict[@"pacsAET"],
                      sourceDict[@"branch"],
                      sourceDict[@"priority"],
                      sourceDict[@"scu"],
                      Eiuid,
                      Siuid]
                    forKey:@"successDir"];
                [seriesTaskDict setObject:
                    [NSString stringWithFormat:@"%@/%@/%@/%@",
                       args[CDargFailure],
                       sourceDict[@"scu"],
                       Eiuid,
                       Siuid]
                    forKey:@"failureDir"];
                [seriesTaskDict setObject:
                   [NSString stringWithFormat:@"%@/%@/%@/%@",
                      args[CDargOriginals],
                      sourceDict[@"scu"],
                      Eiuid,
                      Siuid]
                    forKey:@"originalsDir"];
                [seriesTaskDict setObject:
                   [studyPath stringByAppendingFormat:@"/%@.log",Siuid]
                   forKey:@"spoolDirLogPath"];

 
              
                if (useDispatchQueue) //multithread
                   dispatch_async_f( seriesqueue, [NSDictionary dictionaryWithDictionary:seriesTaskDict], series_callback );
                else //run sequentially on the main thread
                   series_callback([NSDictionary dictionaryWithDictionary:seriesTaskDict]);
                
              } //NSLog(@"end of series loop");
           } //NSLog(@"end of study loop");
        } //NSLog(@"end of source loop");
    } //NSLog(@"end of sources to be processed");
      

#pragma mark waiting for last series to complete
   while (seriesTODO.count > 0)
   {
      [NSThread sleepForTimeInterval:5];//espera 5 segundos
      NSLog(@"TODO:%lu",(unsigned long)seriesTODO.count);
   }
}//end autoreleaspool
  return returnInt;//returns the number studuies processed
}







