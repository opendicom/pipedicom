//
//  main.m
//  coercedicom
//
//  Created by jacquesfauquex on 2021-07-08.
//

#import <Foundation/Foundation.h>
#import <DCKV/DCKV.h>

void async_f_study_callback(void *context){
   NSMutableDictionary *current = (NSMutableDictionary*) context;
   NSFileManager *fileManager=[NSFileManager defaultManager];
   NSError *error=nil;
   BOOL isDirectory=false;
   NSMutableString *response=[NSMutableString string];

   NSMutableArray *inputPaths=[NSMutableArray array];
   if (!visibleRelativeFiles(fileManager, current[@"spoolDirPath"], [fileManager contentsOfDirectoryAtPath:current[@"spoolDirPath"] error:&error] , inputPaths))
   {
      [response appendFormat:@"error reading directory %@\r\n",current[@"spoolDirPath"]];
      [current setObject:response forKey:@"response"];
      return;
   }

   //we want to create these folder, if necesary, once only
   
   BOOL successDirExists=([fileManager fileExistsAtPath:current[@"successDirPath"]]);
   BOOL failureDirExists=([fileManager fileExistsAtPath:current[@"failureDirPath"]]);

   NSString *doneDirPath=current[@"doneDirPath"];
   if (![fileManager fileExistsAtPath:doneDirPath])
   {
      if (![fileManager createDirectoryAtPath:doneDirPath withIntermediateDirectories:YES attributes:nil error:&error])
      {
         [response appendFormat:@"can not create %@\r\n",doneDirPath];
         [current setObject:response forKey:@"response"];
         return;
      }
   }
   
   //to find duplicate tasks and move them to ORIGINALS
   NSSet *DoneInitialSet=[NSSet setWithArray:[fileManager contentsOfDirectoryAtPath:doneDirPath error:&error]];

#pragma mark loop
   NSMutableData *inputData=[NSMutableData data];
   for (NSString *relativeInputPath in inputPaths)
   {
      if ([relativeInputPath hasPrefix:@"."]) continue;
      NSString *spoolFilePath=[current[@"spoolDirPath"] stringByAppendingPathComponent:relativeInputPath];
      //already in originals?
      NSString *relativeInputUidPath;
      if ([relativeInputPath containsString:@"_"])
         relativeInputUidPath=[[relativeInputPath componentsSeparatedByString:@"_"][0] stringByAppendingPathExtension:@"dcm"];
      else relativeInputUidPath=relativeInputPath;
      if ([DoneInitialSet containsObject:relativeInputUidPath])
      {
         NSLog(@"%@ already existing",relativeInputPath);
         NSString *sopDonePath=[doneDirPath stringByAppendingPathComponent:relativeInputUidPath];
         if ([fileManager fileExistsAtPath:sopDonePath isDirectory:&isDirectory])
         {
            if (isDirectory==true)
            {
               //directory already existing
               NSUInteger sameSopCount=[[fileManager contentsOfDirectoryAtPath:sopDonePath error:nil]count];
               [fileManager moveItemAtPath:spoolFilePath toPath:[sopDonePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%lu.dcm",sameSopCount + 1]] error:&error];
            }
            else
            {
               NSString *one=[current[@"doneDirPath"] stringByAppendingPathComponent:@"1"];
               //rename sop to "1"
               [fileManager moveItemAtPath:sopDonePath toPath:one error:&error];
               //create dir
               [fileManager createDirectoryAtPath:sopDonePath withIntermediateDirectories:false attributes:nil error:&error];
               //move 1 to dir
               [fileManager moveItemAtPath:one toPath:[sopDonePath stringByAppendingPathComponent:@"1.dcm"] error:&error];
               [fileManager moveItemAtPath:spoolFilePath toPath:[sopDonePath stringByAppendingPathComponent:@"2.dcm"] error:&error];
            }
         }
      }
      else
      {

#pragma mark · parse
         [inputData appendData:[NSData dataWithContentsOfFile:spoolFilePath]];
         
         NSMutableDictionary *parsedAttrs=[NSMutableDictionary dictionary];
         NSMutableDictionary *blobDict=[NSMutableDictionary dictionary];
         NSMutableDictionary *j2kAttrs=[NSMutableDictionary dictionary];
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
             )
         {
            [response appendFormat:@"could not parse %@\r\n",spoolFilePath];
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
                  [parsedAttrs removeObjectForKey:@"00000001_00020010-UI"];
                  [parsedAttrs addEntriesFromDictionary:j2kAttrs];
               }
               else
               {
                  [response appendFormat:@"could not compress %@\r\n",spoolFilePath];
                  break;
               }
            }
            
            //remove group2 length
            [parsedAttrs removeObjectForKey:@"00000001_00020000-UL"];
            
            //add overriding dataset
            [parsedAttrs addEntriesFromDictionary:current[@"coerce"]];

            
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
                          @"",
                          filemetainfoDict,
                          filemetainfoData,
                          4, //dicomExplicitJ2kIdem
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


#pragma mark finalize dataset
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
               NSString *failureFilePath=[current[@"failureDirPath"] stringByAppendingPathComponent:relativeInputPath];
               if (!failureDirExists)
               {
                  if (![fileManager createDirectoryAtPath:current[@"failureDirPath"] withIntermediateDirectories:YES attributes:nil error:&error])
                  {
                     [response appendFormat:@"failed to create %@\r\n",current[@"failureDirPath"]];
                     break;
                  }
               }
               [outputData writeToFile:failureFilePath atomically:NO ];
               [response appendFormat:@"failed to write %@\r\n",failureFilePath];
               break;
            }

#pragma mark · write result
            NSString *successFilePath=[current[@"successDirPath"] stringByAppendingPathComponent:relativeInputPath];
            if (!successDirExists)
            {
               if (![fileManager createDirectoryAtPath:current[@"successDirPath"] withIntermediateDirectories:YES attributes:nil error:&error])
               {
                  [response appendFormat:@"can not write %@\r\n",successFilePath];
                  break;
               }
            }
            [outputData writeToFile:successFilePath atomically:NO ];

            
//move to doneFilePath
            NSString *doneFilePath=[doneDirPath stringByAppendingPathComponent:relativeInputUidPath];
            if (![fileManager moveItemAtPath:spoolFilePath toPath:doneFilePath error:&error])
            {
               [response appendFormat:@"can not move %@ to %@: %@\r\n",spoolFilePath,doneFilePath,error.description];
               break;
            }
         }//end parsed
         [inputData setLength:0];
      }
   }//end loop
   
   [current setObject:response forKey:@"response"];
   return;
}




enum CDargName{
   CDargCmd=0,
   CDargSpool,
   CDargSuccess,
   CDargDiscarded,
   CDargFailure,
   CDargDone,
   CDargInstitutionmapping,
   CDargCdamwlDir,
   CDargPacsquery,
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
    NSString *arg8 = args[CDargAsyncMonitorLoopsWait];
    if (arg8)
    {
       NSArray *arg8xs=[arg8 componentsSeparatedByString:@"x"];
       if (arg8xs.count==2)
       {
          waitLoops=[arg8xs[0] integerValue];
          waitSeconds=(unsigned int)[[arg8xs[1] substringToIndex:[arg8xs[1] length] -1 ] integerValue];
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

    
    
#pragma mark institutionMapping
    
    NSData *jsonData=[NSData dataWithContentsOfFile:args[CDargInstitutionmapping]];
    if (!jsonData)
    {
        NSLog(@"no institutionMapping json file at: %@",args[CDargInstitutionmapping]);
         exit(1);
    };
    
    NSMutableArray *whiteList=[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    if (!whiteList)
    {
        NSLog(@"bad institutionMapping json file:%@ %@",args[CDargInstitutionmapping],[error description]);
        exit(1);
    }
    NSMutableArray *sourcesToBeProcessed=[NSMutableArray array];
/*
format:
[
{
  org:string,
  regex:string
  coerce:{}
  ...
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
            NSLog(@"bad institutionMapping json file:%@ item:%@ %@",args[CDargInstitutionmapping],matchDict.description,[error description]);
        }
       
       //loop sourcesBeforeMapping for matching regex filter
       for ( long i=sourcesBeforeMapping.count-1; i>=0; i--)
       {
          if ([regex numberOfMatchesInString:sourcesBeforeMapping[i] options:0 range:NSMakeRange(0,[sourcesBeforeMapping[i] length])])
          {
             NSArray *StudyInstanceUIDs=[fileManager contentsOfDirectoryAtPath:[args[CDargSpool] stringByAppendingPathComponent:sourcesBeforeMapping[i]] error:&error];
             if (  !StudyInstanceUIDs
                 ||(
                       (StudyInstanceUIDs.count==1)
                    && [StudyInstanceUIDs[0] hasPrefix:@"."]
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
      
#pragma mark - sources To Be discarded
      for (NSString *source in sourcesBeforeMapping)
      {
         NSString *discardedSourceDirPath=[args[CDargDiscarded] stringByAppendingPathComponent:source];
         if ([fileManager fileExistsAtPath:discardedSourceDirPath])
         {
            //move contents there
            NSString *sourceDirPath=[args[CDargSpool] stringByAppendingPathComponent:source];

            NSArray *StudyInstanceUIDs=[fileManager contentsOfDirectoryAtPath:sourceDirPath error:&error];
            for (NSString *StudyInstanceUID in StudyInstanceUIDs)
            {
               if ([StudyInstanceUID hasPrefix:@"."]) continue;
               [fileManager moveItemAtPath:[sourceDirPath stringByAppendingPathComponent:StudyInstanceUID] toPath:[discardedSourceDirPath stringByAppendingPathComponent:StudyInstanceUID] error:&error];
            }
            [fileManager removeItemAtPath:sourceDirPath error:&error];
         }
         else //new discarded source
         {
            //move source there
            [fileManager moveItemAtPath:[args[CDargSpool] stringByAppendingPathComponent:source] toPath:discardedSourceDirPath error:&error];
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
       for (NSDictionary *source in sourcesToBeProcessed)
       {
            NSString *sourcePath=[args[CDargSpool] stringByAppendingPathComponent:source[@"scu"]];
            NSArray *StudyInstanceUIDs=[fileManager contentsOfDirectoryAtPath:sourcePath error:nil];

          
#pragma mark - StudyUIDs loop
         for (NSString *StudyInstanceUID in StudyInstanceUIDs)
         {
            
#pragma mark empty ?
            NSString *studyPath=[sourcePath stringByAppendingPathComponent:StudyInstanceUID];
            if ([StudyInstanceUID hasPrefix:@"."])
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

            NSMutableDictionary *studyTaskDict=[NSMutableDictionary dictionaryWithObject:source[@"coerce"] forKey:@"coerce"];
            
            [studyTaskDict setObject:studyPath forKey:@"spoolDirPath"];

            [studyTaskDict setObject:
             [[[args[CDargSuccess]
               stringByAppendingPathComponent:source[@"coerce"][@"00000001_00080080-LO"][0]]
               stringByAppendingPathComponent:source[@"scu"]]
              stringByAppendingPathComponent:StudyInstanceUID
              ] forKey:@"successDirPath"];
            [studyTaskDict setObject:
             [[args[CDargFailure]
               stringByAppendingPathComponent:source[@"scu"]]
              stringByAppendingPathComponent:StudyInstanceUID
              ] forKey:@"failureDirPath"];
            [studyTaskDict setObject:
             [[args[CDargDone]
               stringByAppendingPathComponent:source[@"scu"]]
              stringByAppendingPathComponent:StudyInstanceUID
              ] forKey:@"doneDirPath"];

#pragma mark (2) check with cdawldicom
/*
            //add eventual additional coercion in correspondinng "coerce" mutable dictionary of the study
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
               NSUInteger EUIDindex=[wltodayEUIDkeys indexOfObject:StudyInstanceUID];
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
                   NSDictionary *wldict=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[wltodayEUIDFolder stringByAppendingPathComponent:StudyInstanceUID]stringByAppendingPathComponent:@"wl.json"] options:0 error:&error] options:0 error:&error];
                   
                   
                 
#pragma mark (2.3) PatientID match
                      if (!wltodayPIDFolder) wltodayPIDFolder=[wltodayFolder stringByAppendingPathComponent:@"PID"];
                      wltodayPIDkeys=[fileManager contentsOfDirectoryAtPath:wltodayPIDFolder error:nil];

                  }


             }
#pragma mark (3) Pacsquery

             if (args[argPacsquery] && [args[argPacsquery] length])
             {
                 NSString *pacsURIString=[NSString stringWithFormat:args[argInstitutionmapping],institutionName];
                 
                 

             }

             //pacs already containing all the items of the study?
             NSMutableData *sqlResponseData=[NSMutableData data];
             if ([args count]>5)
                execTask(
                     environment,
                     @"/bin/bash",
                     @[@"-s"],
                     [
                         [args[argPacsquery] stringByAppendingFormat:args[argInstitutionmapping],
                          StudyInstanceUID]
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
                     LOG_WARNING(@"%@ discarded. Comes from %@. Was already registered for %@)",StudyInstanceUID,institutionName,sqlResponseString);
                 
                     [fileManager
                      moveItemAtPath:studyPath
                      toPath:[NSString stringWithFormat:@"%@/%@@%f",args[argDiscarded],CLASSIFIEDname,[[NSDate date]timeIntervalSinceReferenceDate
                      ]]
                      error:&error];
                     continue;
                 }
             }
                
             NSURL *pacsURI=[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",pacsURIString,StudyInstanceUID]];
             NSString *qidoRequest=[NSString stringWithFormat:@"%@?StudyInstanceUID=%@",pacsURIString,StudyInstanceUID];
             NSURL *qidoRequestURL=[NSURL URLWithString:qidoRequest];
                
             NSDictionary *q=[NSDictionary studyAttributesForQidoURL:qidoRequestURL];
             if (q[@"00100020"] && [q[@"00100020"] length])
             {
//JF                   LOG_INFO(@"%@ %@ (%@/%@) for patient %@ in PACS before STOW",
//JF                      StudyInstanceUID,
//JF                      q[@"00080061"],
//JF                      q[@"00201206"],
//JF                      q[@"00201208"],
//JF                      q[@"00100020"]
//JF                      );
             }
             else if (q[@"name"] && [q[@"name"] length])
             {
//JF                   LOG_WARNING(@"study %@ discarded. %@: %@",StudyInstanceUID,q[@"name"],q[@"reason"]);
                NSString *DISCARDEDpath=[NSString stringWithFormat:@"%@/%@/%@@%f",DISCARDED,CLASSIFIEDname,StudyInstanceUID,[[NSDate date]timeIntervalSinceReferenceDate
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

