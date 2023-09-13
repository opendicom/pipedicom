//
//  main.m
//  coercedicom
//
//  Created by jacquesfauquex on 2021-07-08.
//
#import <os/log.h>
/*
 //for 10.11 up
 
 https://developer.apple.com/documentation/os/logging/generating_log_messages_from_your_code?language=objc
 
 The 3 levels are registered and compressed. Older logs are destructed automatically.
 os_log(OS_LOG_DEFAULT, "blanco");//Notice.
 os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "amarillo");
 os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_FAULT, "rojo");
*/

#import <Foundation/Foundation.h>
#import <DCKV/DCKV.h>
#import "fileManager.h"

const UInt32 DICM='MCID';
const UInt64 _0002000_tag_vr=0x44C5500000002;
const UInt64 _0002001_tag_vr=0x0000424F00010002;
const UInt32 _0002001_length=0x00000002;
const UInt16 _0002001_value=0x0001;

int task(NSString *launchPath, NSArray *launchArgs, NSMutableData *readData)
{
    NSTask *task=[[NSTask alloc]init];
    [task setLaunchPath:launchPath];
    [task setArguments:launchArgs];

    NSPipe* readPipe = [NSPipe pipe];
    NSFileHandle *readingFileHandle=[readPipe fileHandleForReading];
    [task setStandardOutput:readPipe];
    [task setStandardError:readPipe];
    
    [task launch];
    
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
    if (terminationStatus!=0) LOG_INFO(@"ERROR task terminationStatus: %d",terminationStatus);
    return terminationStatus;
}

NSString *removeInstanceFromSpool(
                        NSFileManager *fileManager,
                        NSString *iSrcPath,
                        NSString *sDstPath,
                        BOOL sDstPathVerify,
                        NSString *sDstAltPath
                        )
{
   /*
    s = series
    i = instance
    paths are absolute paths
    
    sDstPath contains only the first version of the instance
    sDstAltPath contains the other version with secondsFrom2000.dcm suffix
    
    returns @"" if OK
    else errMsg
    */

   NSError *error=nil;
   BOOL isDir=false;
   
   if (sDstPathVerify==true)
   {
       if (![fileManager fileExistsAtPath:sDstPath isDirectory:&isDir])
       {
           if (![fileManager createDirectoryAtPath:sDstPath
                        withIntermediateDirectories:YES
                        attributes:nil
                        error:&error]
           )
           {
               return [NSString stringWithFormat:@"cannot create series dir %@:\r\n%@",
                 sDstPath,
                 error.description];
           }
       }
       else if (isDir==false)
       {
           return [NSString stringWithFormat:@"series dir is not a dir !!! %@", sDstPath];
       }
   }

    
   NSString *iName=[iSrcPath lastPathComponent];
   NSString *iDstPath=[sDstPath stringByAppendingPathComponent:iName];
   if (![fileManager fileExistsAtPath:iDstPath])
   {
# pragma mark ·· mv iSrcPath to iOriginalPath
       if (![fileManager moveItemAtPath:iSrcPath toPath:iDstPath error:&error])
           return [NSString stringWithFormat:@"cannot move %@ to  %@:\r\n%@",iSrcPath,iDstPath,error.description];
       else return  @"";
   }
   else //iOriginalPath already exists
   {
# pragma mark ·· else to sDstAltPath ?
       
       if (![fileManager fileExistsAtPath:sDstAltPath isDirectory:&isDir])
       {
           if (![fileManager createDirectoryAtPath:sDstAltPath
                   withIntermediateDirectories:YES
                                    attributes:nil
                                          error:&error])
               return [NSString stringWithFormat:@"cannot create dst alt series dir %@:\r\n%@",sDstAltPath,error.description];
       }
       else if (isDir==false)
           return [NSString stringWithFormat:@"dst alt series dir is not dir !!! %@:\r\n%@",sDstAltPath,error.description];

       
       NSString *iDstAltPath;
       if ([iName hasSuffix:@"dcm"])
           iDstAltPath=[NSString stringWithFormat:@"%@/%@_%f.dcm",
                     sDstAltPath,
                     [iName stringByDeletingPathExtension],
                     [[NSDate date] timeIntervalSinceReferenceDate]
                     ];
       else
           iDstAltPath=[NSString stringWithFormat:@"%@/%@_%f",
                     sDstAltPath,
                     iName,
                     [[NSDate date] timeIntervalSinceReferenceDate]
                     ];

       
       if (![fileManager moveItemAtPath:iSrcPath toPath:iDstAltPath error:&error])
           return [NSString stringWithFormat:@"cannot move instance %@ to alt dst %@:\r\n%@",iSrcPath,iDstAltPath,error.description];
   }
   return @"";
}



static NSMutableSet *seriesTODO=nil;
static NSMutableSet *seriesDONE=nil;
static NSMutableSet *seriesFAILED=nil;
static NSMutableSet *seriesDUPLICATE=nil;
static NSMutableSet *seriesINPACS=nil;

static NSData *headData=nil;


void series_callback(void *context){
   NSDictionary *thisContext = (NSDictionary*) context;
   /*
    Siuid
    deviceAET
    ReceivingAET
    j2kLayers
    spoolDir
    failureDir
    originalDir
    alternatesDir
    coercePreamble
    sendDir
    
    TransferSyntaxSuffix
    suffix

    

cfg:
    Siuid
    regex
    sendingAET
    coerceBlobs
    coerceFileMetainfo
    replaceInFileMetainfo
    supplementToFileMetainfo
    removeFromFileMetainfo
    
    coerceDataset
    replaceInDataset
    supplementToDataset
    removeFromDataset
NEW
    j2kLayers
    storeMode
    */
   
   NSFileManager *fileManager=[NSFileManager defaultManager];
   NSError *error=nil;
   NSArray *iuids=[fileManager contentsOfDirectoryAtPath:thisContext[@"spoolDir"] error:&error];
   NSUInteger iuidCount=iuids.count;
if (
          (iuidCount==0)
       ||((iuidCount==1) && [iuids[0] hasPrefix:@"."])
   )
{
       if (![fileManager removeItemAtPath:thisContext[@"spoolDir"] error:&error])
       {
          if (@available(macOS 10.11, *))
             os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "%@",error.description);
          NSLog(@"%@",error.description);
       }
}
else
{
   NSString *originalDir=thisContext[@"originalDir"];
   BOOL originalsIsDir=false;
   if (![fileManager fileExistsAtPath:originalDir isDirectory:&originalsIsDir])
   {
       if (![fileManager createDirectoryAtPath:originalDir
                        withIntermediateDirectories:YES
                        attributes:nil
                        error:&error]
           )
       {
          if (@available(macOS 10.11, *))
             os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_FAULT, "cannot create ORIGINAL series dir %@: %@", originalDir, error.description);
          else NSLog(@"cannot create ORIGINAL series dir %@: %@", originalDir, error.description);

           [seriesTODO removeObject:thisContext[@"Siuid"]];
           [seriesFAILED addObject:thisContext[@"Siuid"]];
           return;
       }
    }
   else if (originalsIsDir==false)
   {
      if (@available(macOS 10.11, *))
      os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_FAULT, "ORIGINAL series dir is not a dir !!! %@", originalDir);
      else NSLog(@"ORIGINAL series dir is not a dir !!! %@", originalDir);
      [seriesTODO removeObject:thisContext[@"Siuid"]];
      [seriesFAILED addObject:thisContext[@"Siuid"]];
      return;
   }

//spool -> originals is possible
//start processing
   @try
   {
       
   NSMutableData *inputData=[NSMutableData data];

   //doneSet is used to avoid processing again instances already found in original, that is already processed
   NSMutableSet *doneSet=[NSMutableSet setWithArray:[fileManager contentsOfDirectoryAtPath:originalDir error:&error]];

   BOOL sendDirExists=[fileManager fileExistsAtPath:thisContext[@"sendDir"]];

   BOOL cesiB64=[thisContext[@"storeMode"] isEqualToString:@"cesiB64"];
   BOOL dcmsnd=false;
   //iuidsWritten nil means the whole sendDir shall be sent by dcmsnd in case of cesiB64 storeMode
   //else it means that destination folder already exists (with files in it) so in case of cesiB64 storeMode, dcmsnd shall be performed only for iuidsWritten
   NSMutableArray *iuidsWritten;
   if (sendDirExists) iuidsWritten=[NSMutableArray array];

   int j2kLayers;
   if (thisContext[@"j2kLayers"]) j2kLayers=[thisContext[@"j2kLayers"] intValue];
   else j2kLayers=1;
      

#pragma mark loop
   for (NSString *iuid in iuids)
   { @autoreleasepool {
           
          if ([iuid hasPrefix:@"."]) continue;
          NSString *iuidPath=[thisContext[@"spoolDir"] stringByAppendingPathComponent:iuid];
          if ([doneSet containsObject:iuid])
          {
#pragma mark · remove duplicate
              if ([fileManager contentsEqualAtPath:iuidPath andPath:[originalDir stringByAppendingPathComponent:iuid]])
              {
                  [seriesDUPLICATE addObject:thisContext[@"Siuid"]];
                  if (![fileManager removeItemAtPath:iuidPath error:nil])
                  {
                     if (@available(macOS 10.11, *))
                     os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "could not remove duplicate %@", iuidPath);
                     else NSLog(@"could not remove duplicate %@", iuidPath);
                     [seriesFAILED addObject:thisContext[@"Siuid"]];
                  }
                  continue;
               }
           }

               
#pragma mark · parse

          [inputData appendData:[NSData dataWithContentsOfFile:iuidPath ]];
          
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
             [seriesFAILED addObject:thisContext[@"Siuid"]];
             NSString *returnMsg=removeInstanceFromSpool(
                                  fileManager,
                                  iuidPath,
                                  thisContext[@"failureDir"],
                                  true,
                                  thisContext[@"failureDir"]
                                  );
             if (returnMsg.length)
             {
                if (@available(macOS 10.11, *))
                os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "%@", returnMsg);
                else NSLog(@"%@", returnMsg);
             }

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
             if (@available(macOS 10.11, *))
             os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "could not parse fileMetainfo %@\r\n",iuidPath);
             else NSLog(@"could not parse fileMetainfo %@\r\n",iuidPath);

              [seriesFAILED addObject:thisContext[@"Siuid"]];
              NSString *returnMsg=removeInstanceFromSpool(
                                   fileManager,
                                   iuidPath,
                                   thisContext[@"failureDir"],
                                   true,
                                   thisContext[@"failureDir"]
                                   );

             if (returnMsg.length)
             {
                if (@available(macOS 10.11, *))
                os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "%@",returnMsg);
                else NSLog(@"%@",returnMsg);

             }
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
              [seriesFAILED addObject:thisContext[@"Siuid"]];
              NSString *returnMsg=removeInstanceFromSpool(
                                   fileManager,
                                   iuidPath,
                                   thisContext[@"failureDir"],
                                   true,
                                   thisContext[@"failureDir"]
                                   );

              if (returnMsg.length)
              {
                 if (@available(macOS 10.11, *))
                 os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "%@",returnMsg);
                 else NSLog(@"%@",returnMsg);

              }
             continue;
          }
          else
          {
 #pragma mark ·· parsed
             
 #pragma mark ··· compress ?
        
             switch (j2kLayers) {
                case 1://J2KR
                {
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
                    [seriesFAILED addObject:thisContext[@"Siuid"]];
                    NSString *returnMsg=removeInstanceFromSpool(
                                         fileManager,
                                         iuidPath,
                                         thisContext[@"failureDir"],
                                         true,
                                         thisContext[@"failureDir"]
                                         );

                    if (returnMsg.length)
                   {
                      if (@available(macOS 10.11, *))
                      os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "%@",returnMsg);
                      else NSLog(@"%@",returnMsg);
                   }
                   continue;
                }
                }
                   }
                   break;
                      
//TODO case 4 BFMI
                  
                   default://no compression
                      break;
                }

                
    #pragma mark ··· coerce

    #pragma mark ···· fileMetainfo
                
                //sourceAET (branch aet)
                //sendingAET (device aet)
                //receivingAET (pacs aet)
                if (thisContext[@"sourceAET"])[fileMetainfoAttrs setObject:@[thisContext[@"sourceAET"]] forKey:@"00000001_00020016-AE"];
                if (thisContext[@"sendingAET"])[fileMetainfoAttrs setObject:@[thisContext[@"sendingAET"]] forKey:@"00000001_00020017-AE"];
                if (thisContext[@"receivingAET"])[fileMetainfoAttrs setObject:@[thisContext[@"receivingAET"]] forKey:@"00000001_00020018-AE"];

                if (thisContext[@"coerceFileMetainfo"]) [fileMetainfoAttrs addEntriesFromDictionary:thisContext[@"coerceFileMetainfo"]];

    #pragma mark ···· blobs
                if (thisContext[@"coerceBlobs"]) [blobDict addEntriesFromDictionary:thisContext[@"coerceBlobs"]];

    #pragma mark ···· coerceFileMetainfo

    #pragma mark ···· replaceInFileMetainfo

    #pragma mark ···· supplementToFileMetainfo

    #pragma mark ···· removeFromFileMetainfo

 
                
    #pragma mark ···· coerceDataset
                if (thisContext[@"coerceDataset"])
                   [parsedAttrs addEntriesFromDictionary:thisContext[@"coerceDataset"]];

                
    #pragma mark ···· replaceInDataset
                NSArray *replaceKeys=[thisContext[@"replaceInDataset"] allKeys];
                for (NSString *replaceKey in replaceKeys)
                {
                   if (parsedAttrs[replaceKey])
                      [parsedAttrs setObject:thisContext[@"replaceInDataset"][replaceKey] forKey:replaceKey];
                }

    #pragma mark ···· supplementToDataset
                NSArray *supplementKeys=[thisContext[@"supplementToDataset"] allKeys];
                for (NSString *supplementKey in supplementKeys)
                {
                   if (!parsedAttrs[supplementKey])
                      [parsedAttrs setObject:thisContext[@"supplementToDataset"][supplementKey] forKey:supplementKey];
                }

                
    #pragma mark ···· removeFromDataset
                for (NSString *removeKey in thisContext[@"removeFromDataset"])
                {
                   if (parsedAttrs[removeKey])
                      [parsedAttrs removeObjectForKey:removeKey];
                }

                
   #pragma mark ···· removeFromEUIDprefixedDataset
                if (thisContext[@"removeFromEUIDprefixedDataset"])
                {
                   NSString *EUID=parsedAttrs[@"00000001_0020000D-UI"][0];
                   NSArray *EUIDprefixes=[thisContext[@"removeFromEUIDprefixedDataset"] allKeys];
                   for (NSString *EUIDprefix in EUIDprefixes)
                   {
                      if ([EUID hasPrefix:EUIDprefix])
                      {
                         for (NSString *removeKey in thisContext[@"removeFromEUIDprefixedDataset"][EUIDprefix])
                         {
                            if (parsedAttrs[removeKey])
                               [parsedAttrs removeObjectForKey:removeKey];
                         }

                      }
                   }
                }

                
    #pragma mark ·· outputData init
                NSMutableData *outputData;
    //preamble
                if (!thisContext[@"coercePreamble"])
                {
                   outputData=[NSMutableData dataWithLength:128];
                   [outputData appendBytes:&DICM length:4];
                }
                else outputData=[[NSMutableData alloc] initWithBase64EncodedString:thisContext[@"coercePreamble"] options:0] ;

                
    //fileMetainfo
                NSMutableData *outputFileMetainfo=[NSMutableData data];
                if (dict2D(
                            @"",
                            fileMetainfoAttrs,
                            outputFileMetainfo,
                            6, //j2kr   !!! error with 4 j2kh
                            blobDict
                            ) == failure
                    )
                {
                   if (@available(macOS 10.11, *))
                   os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "error outputFileMetainfo: %@",fileMetainfoAttrs.description);
                   else NSLog(@"error outputFileMetainfo: %@",fileMetainfoAttrs.description);

                   [seriesFAILED addObject:thisContext[@"Siuid"]];
                  NSString *returnMsg=removeInstanceFromSpool(
                                         fileManager,
                                         iuidPath,
                                         thisContext[@"failureDir"],
                                         true,
                                         thisContext[@"failureDir"]
                                         );
                    if (returnMsg.length)
                    {
                       if (@available(macOS 10.11, *))
                       os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "%@",returnMsg);
                       else NSLog(@"%@",returnMsg);
                    }
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
                   if (@available(macOS 10.11, *))
                   os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "could not serialize dataset. %@",parsedAttrs);
                   else NSLog(@"could not serialize dataset. %@",parsedAttrs);

                   [seriesFAILED addObject:thisContext[@"Siuid"]];
                   NSString *returnMsg=removeInstanceFromSpool(
                                         fileManager,
                                         iuidPath,
                                         thisContext[@"failureDir"],
                                         true,
                                         thisContext[@"failureDir"]
                                         );

                   
                    if (returnMsg.length)
                    {
                       if (@available(macOS 10.11, *))
                       os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "%@",returnMsg);
                       else NSLog(@"%@",returnMsg);

                    }
                    continue;
                }
                else
                {
    #pragma mark ··· success
                   
                  if (!sendDirExists)
                  {
                     if (![fileManager createDirectoryAtPath:thisContext[@"sendDir"] withIntermediateDirectories:YES attributes:nil error:&error])
                     {
                        if (@available(macOS 10.11, *))
                        os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "can not create  %@",thisContext[@"sendDir"]);
                        else NSLog(@"can not create  %@",thisContext[@"sendDir"]);
                        break;
                     }
                     sendDirExists=true;
                  }

                  BOOL written;

                  if (cesiB64)
                  {
                     //write without cesi without extension
                     unsigned short ext0=[[iuid pathExtension] characterAtIndex:0];
                     
                     NSString *iuidPath;
                     if ( (ext0 > 47) && (ext0 < 58)) iuidPath=[thisContext[@"sendDir"] stringByAppendingPathComponent:b64ui(iuid)];
                     else iuidPath=[thisContext[@"sendDir"] stringByAppendingPathComponent:b64ui([iuid stringByDeletingPathExtension])];
                     written=[outputData writeToFile:iuidPath atomically:NO];

                     if (iuidsWritten && written) [iuidsWritten addObject:iuidPath];
                  }
                  else
                  {
                     written=[outputData writeToFile:[thisContext[@"sendDir"] stringByAppendingPathComponent:iuid] atomically:YES];
                  }
                   
                  if (written)
                  {
                    dcmsnd=true;
    #pragma mark ···· original to originalDir (or alternatesDir)
                    NSString *returnMsg=removeInstanceFromSpool(
                                         fileManager,
                                         iuidPath,
                                         thisContext[@"originalDir"],
                                         false,
                                         thisContext[@"alternatesDir"]
                                         );
                     if (returnMsg.length)
                     {
                        if (@available(macOS 10.11, *))
                        os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "%@",returnMsg);
                        else NSLog(@"%@",returnMsg);
                     }
                     [doneSet addObject:iuid];
                  }
                  
                }//end parsed
                [inputData setLength:0];
             }
          
       }}//end autorelease end loop

   if (cesiB64 && dcmsnd)
   {
      NSString *PACS=[NSString stringWithFormat:@"%@@%@:%@",thisContext[@"receivingAET"],thisContext[@"receivingIP"],thisContext[@"receivingPort"]];
      NSMutableData *logData=[NSMutableData data];
      
      if (iuidsWritten)
      {
         NSMutableArray *args=[NSMutableArray arrayWithArray:@[@"-fileref",@"-L",thisContext[@"sourceAET"],PACS]];
         for (NSString *iuidWritten in iuidsWritten)
         {
            [args addObject:[thisContext[@"sendDir"] stringByAppendingPathComponent:iuidWritten]];
         }
         if (task(@"/Users/Shared/dcm4che-2.0.29/bin/dcmsnd",args,logData))
            LOG_ERROR(@"%@",[[NSString alloc]initWithData:logData encoding:NSUTF8StringEncoding]);
      }
      else //complete series
      {
         if (task(@"/Users/Shared/dcm4che-2.0.29/bin/dcmsnd",@[@"-fileref",@"-L",thisContext[@"sourceAET"],PACS,thisContext[@"sendDir"]],logData))
            LOG_ERROR(@"%@",[[NSString alloc]initWithData:logData encoding:NSUTF8StringEncoding]);
      }
   }
      
   if (   ![seriesFAILED    containsObject:thisContext[@"Siuid"]]
       && ![seriesDUPLICATE containsObject:thisContext[@"Siuid"]]
       && ![seriesINPACS    containsObject:thisContext[@"Siuid"]]
      )
      [seriesDONE addObject:thisContext[@"Siuid"]];
  }@catch (NSException *exception) {
     if (@available(macOS 10.11, *))
      os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_FAULT, "%@", exception.reason);
     else NSLog(@"%@", exception.reason);
  }
  @finally {
  }
 }
 [seriesTODO removeObject:thisContext[@"Siuid"]];
}




enum CDargName{
   CDargCmd=0,
   
   CDargSpool,                //1 receive
   CDargSuccess,              //2 send
   CDargFailure,              //3 coerce error
   CDargOriginal,             //4 destination where to move originals of successfull coertion
   CDargAlternates,           //5 destination where to move diferent alternates of original

   CDargSending,              //6 destination where to move originals of sending mismatch
   CDargCdamwlMismatch,       //7 destination where to move originals of cdawl mismatch
   CDargPacsMismatch,         //8 destination where to move originals of pacs mismatch,
   CDargCoercedicomFile,      //9 json
   CDargCdamwlDir,            //10 registry where to verify objects against cdawl
   CDargPacsSearchUrl,        //11 DICOMweb url for pacs verifications
   
   CDargTimeout,              //12 max time in seconds before ending the execution
   CDargMaxSeries,            //13 max series (negative is monothread)
   CDsinceLastSeriesModif     //14 min time in seconds without modification in series dir before
                              // processing (may be because of receiving or previous processing)
};


int main(int argc, const char * argv[]){
   int returnInt=0;
   headData=[@"\r\n--myboundary\r\nContent-Type: application/dicom\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];

   @autoreleasepool {

    NSFileManager *fileManager=[NSFileManager defaultManager];
    NSError *error=nil;
    BOOL isDirectory=false;


    NSProcessInfo *processInfo=[NSProcessInfo processInfo];
    NSArray *args=[processInfo arguments];
    if (args.count != 15)
    {
       if (@available(macOS 10.11, *))
       os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_FAULT, "bad args count: %@",[args description]);
       else NSLog(@"bad args count: %@",[args description]);
       exit(1);
    };

    int sinceLastSeriesModif=[args[CDsinceLastSeriesModif] intValue] * -1;

    NSDate *refTime=[NSDate date];
    NSDateFormatter *DICMDA = [[NSDateFormatter alloc]init];
    [DICMDA setDateFormat:@"yyyyMMdd"];
    NSString *todayDCMString=[DICMDA stringFromDate:refTime];

#pragma mark classified
    if (![fileManager fileExistsAtPath:args[CDargSpool] isDirectory:&isDirectory] || !isDirectory) exit(0);

    
    NSArray *CLASSIFIEDarray=[fileManager contentsOfDirectoryAtPath:args[CDargSpool] error:&error];
    if (!CLASSIFIEDarray)
    {
       if (@available(macOS 10.11, *))
          os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_FAULT, "Can not open CLASSIFIED directory: %@. %@",args[CDargSpool], error.description);
       else NSLog(@"Can not open CLASSIFIED directory: %@. %@",args[CDargSpool], error.description);
       exit(1);
    };

    if (!CLASSIFIEDarray.count)
    {
       if (@available(macOS 10.11, *))
          os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "no classified devices");
       else NSLog(@"no classified devices");
       exit(0);
    }
    NSMutableArray *sourcesBeforeMapping=[NSMutableArray arrayWithArray:CLASSIFIEDarray];
    if ([sourcesBeforeMapping[0] hasPrefix:@"."])
    {
       if([fileManager removeItemAtPath:[args[CDargSpool] stringByAppendingPathComponent:sourcesBeforeMapping[0]] error:&error])
       {
          [sourcesBeforeMapping removeObjectAtIndex:0];
          if (!sourcesBeforeMapping.count) exit(0);

       }
       else
       {
          if (@available(macOS 10.11, *))
             os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "can not remove %@. %@",[args[CDargSpool] stringByAppendingPathComponent:sourcesBeforeMapping[0]],error.description);
          else NSLog(@"can not remove %@. %@",[args[CDargSpool] stringByAppendingPathComponent:sourcesBeforeMapping[0]],error.description);
       }
    }

    


      
#pragma mark coercedicom json directives
    
    NSData *jsonData=[NSData dataWithContentsOfFile:args[CDargCoercedicomFile]];
    if (!jsonData)
    {
       if (@available(macOS 10.11, *))
          os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "no coercedicom json file at: %@",args[CDargCoercedicomFile]);
       else NSLog(@"no coercedicom json file at: %@",args[CDargCoercedicomFile]);
       exit(1);
    };
    
    NSMutableArray *whiteList=[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    if (!whiteList)
    {
       if (@available(macOS 10.11, *))
          os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "bad coercedicom json file:%@ %@",args[CDargCoercedicomFile],[error description]);
       else NSLog(@"bad coercedicom json file:%@ %@",args[CDargCoercedicomFile],[error description]);
       exit(1);
    }
      
    //array corresponding to prioridad
    NSMutableArray *devicesToBeProcessed=[NSMutableArray array];
/*
format:
[
{
from JSON
  regex:string (pattern)
  j2kLayers:int
  sourceAET:string ( 0002,0016)
  receivingAET:string (destination  0002,0018 )
  storeMode (DICMhttp11,DICMhttp2,DICMhttp3,storescu,cesiB64)

  coercePreamble:base64
 
  coerceBlobs:{}
 
  removeFromFileMetainfo:[]
  coerceFileMetainfo:{}
  replaceInFileMetainfo:{}
  supplementToFileMetainfo:{}
  removeFromEUIDprefixedFileMetainfo:{ "UIDprefix":[atributeID]}

  coerceDataset:{}
  replaceInDataset:{}
  supplementToDataset:{}
  removeFromDataset:[]
  removeFromEUIDprefixedDataset:{ "UIDprefix":[atributeID]}

ADDED
  suffix
  devicePriority:%02ld
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
           if (@available(macOS 10.11, *))
              os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "bad coercedicom json file:%@ item:%@ %@",args[CDargCoercedicomFile],matchDict.description,[error description]);
           else NSLog(@"bad coercedicom json file:%@ item:%@ %@",args[CDargCoercedicomFile],matchDict.description,[error description]);
            exit(1);
        }
       
       //loop sourcesBeforeMapping for matching regex filter
       for ( long i=sourcesBeforeMapping.count-1; i>=0; i--)
       {
          if ([regex numberOfMatchesInString:sourcesBeforeMapping[i] options:0 range:NSMakeRange(0,[sourcesBeforeMapping[i] length])])
          {
             NSArray *ePCAUs=[fileManager contentsOfDirectoryAtPath:[args[CDargSpool] stringByAppendingPathComponent:sourcesBeforeMapping[i]] error:&error];
             if (  !ePCAUs
                 || (ePCAUs.count==0)
                 ||(
                       (ePCAUs.count==1)
                    && [ePCAUs[0] hasPrefix:@"."]
                    )
                 )
             {
                 //empty source
             }
             else
             {
                [devicesToBeProcessed addObject:[NSMutableDictionary dictionaryWithDictionary:matchDict]];
                [devicesToBeProcessed.lastObject setObject:sourcesBeforeMapping[i] forKey:@"sendingAET"];
                [devicesToBeProcessed.lastObject setObject:[NSString stringWithFormat:@"%02ld^",matchIndex] forKey:@"devicePriority"];
             }
             [sourcesBeforeMapping removeObjectAtIndex:i];
          }
       }
    }
      
#pragma mark sendingMismatch To Be discarded
      for (NSString *sourceName in sourcesBeforeMapping)
      {
         NSString *errMsg=mergeDir(fileManager, [args[CDargSpool] stringByAppendingPathComponent:sourceName], [args[CDargSending] stringByAppendingPathComponent:sourceName]);
         if (errMsg && errMsg.length)
         {
            if (@available(macOS 10.11, *))
               os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "%@",errMsg);
            else NSLog(@"%@",errMsg);
            return 1;
         }
      }
        
#pragma mark - devicesToBeProcessed
    if (devicesToBeProcessed.count)
    {
       
#pragma mark cdawldicom init
       NSString *wltodayFolder=nil;
       
       NSString *wltodayEUIDFolder=nil;
       //NSString *wltodayANFolder=nil;
       //NSString *wltodayPIDFolder=nil;
       
       NSArray  *wltodayEUIDkeys=nil;
       //NSArray  *wltodayANkeys=nil;
       //NSArray  *wltodayPIDkeys=nil;
       
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
       int maxSeries=[args[CDargMaxSeries] intValue];
       if (maxSeries == 0) maxSeries=1;
       if (maxSeries < 0) maxSeries=-maxSeries;//no dispatch queue
       else
       {
          useDispatchQueue=true;
           attr=dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT, QOS_CLASS_USER_INTERACTIVE, QOS_MIN_RELATIVE_PRIORITY);
           
           //dispatch_queue_attr_make_with_autorelease_frequency(DISPATCH_QUEUE_CONCURRENT,DISPATCH_AUTORELEASE_FREQUENCY_WORK_ITEM);
          seriesqueue = dispatch_queue_create("com.opendicom.coercedicom.seriesqueue", attr);
       }


#pragma mark - source loop
       seriesTODO=[NSMutableSet set];
       seriesDONE=[NSMutableSet set];
       seriesFAILED=[NSMutableSet set];
       seriesDUPLICATE=[NSMutableSet set];
       seriesINPACS=[NSMutableSet set];
       for (NSDictionary *deviceDict in devicesToBeProcessed)
       {
         if (maxSeries >0) {
         NSString *sourceDir=[args[CDargSpool] stringByAppendingPathComponent:deviceDict[@"sendingAET"]];
         NSArray *ePCAUs=[fileManager contentsOfDirectoryAtPath:sourceDir error:nil];
#pragma mark · StudyUIDs loop
         for (NSString *ePCAU in ePCAUs)
         {
            if (maxSeries >0) {
            // starting with dot ?
            NSString *studyPath=[sourceDir stringByAppendingPathComponent:ePCAU];
            if ([ePCAU hasPrefix:@"."])
            {
                if (![fileManager removeItemAtPath:studyPath error:&error])
                {
                   if (@available(macOS 10.11, *))
                      os_log(OS_LOG_DEFAULT, "can not remove %@. %@",studyPath,error.description);
                   else NSLog(@"can not remove %@. %@",studyPath,error.description);
                }
                continue;
            }
            //does the study contain series directory?
            NSMutableSet *Siuids=[NSMutableSet setWithArray:[fileManager contentsOfDirectoryAtPath:studyPath error:nil]];
            for (NSString *Siuid in [Siuids allObjects] )
            {
                if ([Siuid hasPrefix:@"."]) [Siuids removeObject:Siuid];//case of invisible
            }
            if (Siuids.count==0)
            {
                if (![fileManager removeItemAtPath:studyPath error:&error])
                {
                   if (@available(macOS 10.11, *))
                      os_log(OS_LOG_DEFAULT, "can not remove empty %@. %@",studyPath,error.description);
                   else NSLog(@"can not remove empty %@. %@",studyPath,error.description);
               }
                continue;
            }
            for (NSString *Siuid in [Siuids allObjects] )
            {
                if ([Siuid hasSuffix:@".log"])
                    [Siuids removeObject:Siuid];
            }
            if (Siuids.count==0) continue;//does not contain series directory



#pragma mark ·· check with cdawldicom (TODO)
/*
            // add eventual additional coercion
            // in corresponding "coerceDataset" mutable dictionary of the study
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
               NSUInteger EUIDindex=[wltodayEUIDkeys indexOfObject:ePCAU];
               if (EUIDindex!=NSNotFound)
               {
                  EUIDpath=[wltodayEUIDFolder stringByAppendingPathComponent:wltodayEUIDkeys[EUIDindex] ];
               }
               else
               {
                  //no definitive StudyInstanceUID matching
#pragma mark dependent on an instance metadata

                  //read last instance of the last series (to avoid the case of reading a .DS_store file ... which is first)
                  //we already knwo there is one or more of them
                  NSString *SiuidPath=[studyPath stringByAppendingPathComponent:[Siuids anyObject]];
                  
                  NSArray *SOPuids=[fileManager contentsOfDirectoryAtPath:SiuidPath error:nil];
                  
                  NSString *SOPuidPath=[SiuidPath stringByAppendingPathComponent:[SOPuids lastObject]];


                  NSMutableDictionary *sopDict=[NSMutableDictionary dictionary];
                  NSMutableDictionary *blobDict=[NSMutableDictionary dictionary];

                  if (!D2dict(
                              [NSData dataWithContentsOfFile:SOPuidPath],
                              sopDict,
                              0,//blob min size
                              blobModeSource,
                              @"",//prefix
                              @"",//suffix
                              blobDict
                             )
                      )
                  {
                     os_log(OS_LOG_DEFAULT, "can not parse  %@",SOPuidPath);
                     continue;
                  }
                  
#pragma mark (2.2) AccessionNumber match
                  if (!wltodayANFolder) wltodayANFolder=[wltodayFolder stringByAppendingPathComponent:@"AN"];
                  wltodayANkeys=[fileManager contentsOfDirectoryAtPath:wltodayANFolder error:nil];
                  
                  NSString *AN;
                  NSArray *ANa=sopDict[@"00000001_00080050-SH"];
                  if (!ANa) ANa=sopDict[@"00000001_00080050-1100SH"];
                  if (ANa && ANa.count) AN=ANa[0];
                  
#pragma mark TODO AccessionNumber issuer
                  
                  
                  ANindex=[wltodayANkeys indexOfObject:AN];
                  if (ANindex!=NSNotFound)
                  {
                     EUIDpath=[fileManager destinationOfSymbolicLinkAtPath:[wltodayANFolder stringByAppendingPathComponent:wltodayANkeys[ANindex]] error:&error];
                  }
                  else //no definitive Accession Number matching
                  {
                 
#pragma mark (2.3) PatientID match
                      if (!wltodayPIDFolder) wltodayPIDFolder=[wltodayFolder stringByAppendingPathComponent:@"PID"];
                      wltodayPIDkeys=[fileManager contentsOfDirectoryAtPath:wltodayPIDFolder error:nil];

                  }


             }
*/
            
#pragma mark ·· SeriesUIDs loop the set contains series dirs only
            
            while (Siuids.count)
            {
                NSString *Siuid=[Siuids anyObject];
                [Siuids removeObject:Siuid];

                NSDate *modificationDate=[fileManager attributesOfItemAtPath:[studyPath stringByAppendingPathComponent:Siuid] error:nil][NSFileModificationDate];
                if ( [modificationDate timeIntervalSinceNow] > sinceLastSeriesModif) continue;
                //log last modified less than one minute ago
                //may be because of receiving
                //may be because of previous processing
                                                
                [seriesTODO addObject:Siuid];
                
               
#pragma mark seriesTaskDict
                //replicates deviceDict
                NSMutableDictionary *seriesTaskDict=[NSMutableDictionary dictionaryWithDictionary:deviceDict];

                //+series iuid
                [seriesTaskDict setObject:Siuid forKey:@"Siuid"];
               
                //sourceAET is defined from the json dictionary
                //receivingAET is defined from the json dictionary

               //+transferSyntaxSuffix
               //+sendingAET (with value of sourceAET from Classified sourceAET@sourceIP^${syntax:14}^calledAET
               //${syntax:14} = transfer syntax trunkated of the initial "1.2.840.10008." (which is the DICOM arc)
                NSArray *sourceAETCircumflex=[deviceDict[@"sendingAET"] componentsSeparatedByString:@"^"];
                if (sourceAETCircumflex.count > 2) [seriesTaskDict setObject:sourceAETCircumflex[1] forKey:@"transferSyntaxSuffix"];
                NSArray *sourceAETArroba=[sourceAETCircumflex[0] componentsSeparatedByString:@"@"];
                [seriesTaskDict setObject:sourceAETArroba[0] forKey:@"sendingAET"];

                //+spoolDir (series path)
                [seriesTaskDict setObject:
                   [studyPath stringByAppendingPathComponent:Siuid]
                   forKey:@"spoolDir"];
                
                if ([deviceDict[@"storeMode"] isEqualToString:@"cesiB64"])
                {
                   
                   [seriesTaskDict setObject:
                        [NSString stringWithFormat:@"%@/%@/%@/%@",
                         args[CDargSuccess],
                         b64ui([ePCAU componentsSeparatedByString:@"@"][1]),
                         b64ui([ePCAU componentsSeparatedByString:@"@"][3]),
                         b64ui(Siuid)
                         ]
                       forKey:@"sendDir"];
                }
                else
                [seriesTaskDict setObject:
                     [NSString stringWithFormat:@"%@/STORE/%@/%@/SEND/%@/%@%@/%@/%@",
                      args[CDargSuccess],
                      deviceDict[@"storeMode"],
                      deviceDict[@"receivingAET"],
                      deviceDict[@"sendingAET"],
                      deviceDict[@"devicePriority"],
                      deviceDict[@"sendingAET"],
                      ePCAU,
                      Siuid]
                    forKey:@"sendDir"];
                                
                [seriesTaskDict setObject:
                    [NSString stringWithFormat:@"%@/%@/%@/%@",
                       args[CDargFailure],
                       deviceDict[@"sendingAET"],
                       ePCAU,
                       Siuid]
                    forKey:@"failureDir"];
                
                [seriesTaskDict setObject:
                   [NSString stringWithFormat:@"%@/%@/%@/%@",
                      args[CDargOriginal],
                      deviceDict[@"sendingAET"],
                      ePCAU,
                      Siuid]
                    forKey:@"originalDir"];
                
                [seriesTaskDict setObject:
                   [NSString stringWithFormat:@"%@/%@/%@/%@",
                      args[CDargAlternates],
                      deviceDict[@"sendingAET"],
                      ePCAU,
                      Siuid]
                    forKey:@"alternatesDir"];
                
                [seriesTaskDict setObject:
                   [studyPath stringByAppendingFormat:@"/%@.log",Siuid]
                   forKey:@"spoolDirLogPath"];

 
              
                if (useDispatchQueue) //multithread
                   dispatch_async_f( seriesqueue, [NSDictionary dictionaryWithDictionary:seriesTaskDict], series_callback );
                else //run sequentially on the main thread
                   series_callback([NSDictionary dictionaryWithDictionary:seriesTaskDict]);
                maxSeries--;
                
              } //os_log(OS_LOG_DEFAULT, "end of series loop");
           }} //os_log(OS_LOG_DEFAULT, "end of study loop");
        }} //os_log(OS_LOG_DEFAULT, "end of source loop");
    } //os_log(OS_LOG_DEFAULT, "end of sources to be processed");
      

#pragma mark waiting for last series to complete
   int timeout=[args[CDargTimeout] intValue];
   while ((seriesTODO.count > 0) && (timeout > 0))
   {
      timeout-=5;
      [NSThread sleepForTimeInterval:5];//wait 5 segundos
   }
   /*
    if ((timeout==[args[CDargTimeout] intValue])&&(seriesTODO.count==0))
    {
      if (@available(macOS 10.11, *))
         os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "NO JOB");
      else NSLog(@"NO JOB");
    }
    */
   if (timeout<1)
   {
      if (@available(macOS 10.11, *))
      os_log(OS_LOG_DEFAULT, "ended after %d timeout seconds. Remaining series:\r\n%@",[args[CDargTimeout] intValue],[seriesTODO description]);
   }
   if (seriesDONE.count > 0)
   {
      if (@available(macOS 10.11, *))
      os_log(OS_LOG_DEFAULT, "COERCED %lu series",(unsigned long)seriesDONE.count);
   }
   if (seriesDUPLICATE.count > 0)
   {
      if (@available(macOS 10.11, *))
      os_log(OS_LOG_DEFAULT, "DUPLICATE %lu series",(unsigned long)seriesDUPLICATE.count);
   }
   if (seriesFAILED.count > 0)
   {
      if (@available(macOS 10.11, *))
         os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "FAILED series\r\n%@",seriesFAILED.description);
      else NSLog(@"FAILED series\r\n%@",seriesFAILED.description);
   }
   if (seriesINPACS.count > 0)
   {
      if (@available(macOS 10.11, *))
         os_log(OS_LOG_DEFAULT, "INPACS series\r\n%@",seriesINPACS.description);
      else NSLog(@"INPACS series\r\n%@",seriesINPACS.description);
   }

}//end autoreleaspool
  return returnInt;//returns the number studuies processed
}
