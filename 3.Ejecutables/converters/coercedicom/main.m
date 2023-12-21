//
//  main.m
//  coercedicom
//
//  Created by jacquesfauquex on 2021-07-08.
//

//required 10.11+
#import <os/log.h>
/*
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

static NSMutableArray *whiteList=nil;
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

static NSArray *CDargs=nil;
enum CDargName{
   CDargCmd=0,
   
   CDargClassified,           //1 spool in
   CDargSuccess,              //2 coercion success
   CDargFailure,              //3 original of failed coercion
   CDargOriginal,             //4 original of success coecion
   CDargSeriesPostscript,          //5 dcmsnd -fileref scripts
   CDargNoRegex,              //6 no regex match

   CDargCdamwlMismatch,       //7 (NOT USED) destination where to move originals of cdawl mismatch
   CDargPacsMismatch,         //8 (NOT USED) destination where to move originals of pacs mismatch,

   CDargCoercedicomFile,      //9 json
   CDargCdamwlDir,            //10 registry where to verify objects against cdawl
   CDargPacsSearchUrl,        //11 DICOMweb url for pacs verifications
   
   CDargTimeout,              //12 max time in seconds before ending the execution
   CDargMaxSeries,            //13 max series (negative is monothread)
   CDargSinceLastSeriesModif     //14 min time in seconds without modification in series dir before
                              // processing (may be because of receiving or previous processing)
};
static NSRegularExpression *UIRegex=nil;
static NSData *headData=nil;
static NSFileManager *fs=nil;
static NSString *_yyMMddhhmm=nil;
static NSString *sinceLastSeriesModif;
static NSDate *timeoutDate;

static NSMutableSet *seriesFAILED=nil;
static NSMutableSet *seriesPostscript=nil;
static NSMutableSet *seriesDONE=nil;

int task(NSString *launchPath, NSArray *launchArgs, NSMutableData *readData, NSString *currentDirectoryPath)
{
    NSTask *task=[[NSTask alloc]init];
    [task setLaunchPath:launchPath];
    [task setArguments:launchArgs];
    if (currentDirectoryPath) [task setCurrentDirectoryPath:currentDirectoryPath];

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
    [task waitUntilExit];
    int terminationStatus = [task terminationStatus];
    if (terminationStatus!=0) LOG_INFO(@"ERROR task terminationStatus: %d",terminationStatus);
    return terminationStatus;
}

int moveCLASSIFIEDobject(NSString *fullPath,int destContainerInt)
{
   if ((destContainerInt < 2)||(destContainerInt > 8))
   {
      os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "bad moveCLASSIFIEDobject dest %d",destContainerInt);
      exit(3);
   }
   NSArray *beforeAfter=[fullPath componentsSeparatedByString:@"/CLASSIFIED/"];
   if (beforeAfter.count != 2)
   {
      os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "moveCLASSIFIEDobject src not within CLASSIFIED %@",fullPath);
      exit(4);
   }
   
   //prepare destSubdir
   NSString *destSubdir=[CDargs[destContainerInt] stringByAppendingPathComponent:[beforeAfter[1] stringByDeletingLastPathComponent]];
   BOOL isDir;
   if (![fs fileExistsAtPath:destSubdir isDirectory:&isDir])
   {
      //create destSubdir
      NSError *createDirError;
      if (![fs createDirectoryAtPath:destSubdir withIntermediateDirectories:YES attributes:nil error:&createDirError])
      {
         os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "could not create %@: %@",destSubdir,createDirError.description);
         return 5;
      }
   }
   else if (!isDir)
   {
      os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "could not create:%@ %@",destSubdir);
      return 6;
   }

   //move object
   NSString *destObject=[CDargs[destContainerInt] stringByAppendingPathComponent:beforeAfter[1]];
   NSError *moveError;
   if (![fs fileExistsAtPath:destObject])
   {
      if (![fs moveItemAtPath:fullPath toPath:destObject error:&moveError])
      {
         os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "%@",moveError.description);
         return 7;
      }
      return 0;
   }
   if (![fs moveItemAtPath:fullPath toPath:[destObject stringByAppendingString:_yyMMddhhmm] error:&moveError])
   {
      os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "%@",moveError.description);
      return 8;
   }
   return 0;
}



void series_callback(void *context){
   NSDictionary *thisContext = (NSDictionary*) context;
   NSString *DESdir=thisContext[@"DESdir"];
   int matchInt=[thisContext[@"matchNumber"] intValue];
   BOOL cesiB64=[whiteList[matchInt][@"storeMode"] isEqualToString:@"cesiB64"];
   int j2kLayers;
   if (whiteList[matchInt][@"j2kLayers"]) j2kLayers=[whiteList[matchInt][@"j2kLayers"] intValue];
   else j2kLayers=1;
   //can be inferred from j2kLayres(0=nati 1=j2kr 4=bfhi) but not used yet
   BOOL toJ2KR=true;
   BOOL toBFHI=false;


   /*
    j2kLayers
    "sourceAET":"IRP-PROV",
    "sendingAET":"tomografo",
    "receivingAET":"IRP",
    "receivingIP":"172.16.0.3",
    "receivingPort":"11112",
    "storeMode":"cesiB64",
    suffix
   
    coercePreamble
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
   
#pragma mark array of instances
   NSMutableData *DESIdata=[NSMutableData data];
   NSMutableArray *DESIarray=[NSMutableArray array];
   //NSLog(@"225");
   if (0!=task(
        @"/usr/bin/find",
        @[
           DESdir,
           @"-type",
           @"f",
           @"-depth",
           @"1",
           @"!",
           @"-name",
           @".*"
           
        ],
       DESIdata,
       nil
     ))
   {
     os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "could not list CLASSIFIED series: %@", [[NSString alloc]initWithData:DESIdata encoding:NSUTF8StringEncoding]);
     if (0!=moveCLASSIFIEDobject(DESdir,CDargFailure))
        os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "could not move to FAILURE CLASSIFIED series: %@",DESdir);
     return;
   }

   [DESIarray addObjectsFromArray:[[[NSString alloc]initWithData:DESIdata encoding:NSUTF8StringEncoding] componentsSeparatedByString:@"\n"]];
   [DESIarray removeLastObject];
   if (DESIarray.count == 0)
   {
      NSMutableData *rmdirData=[NSMutableData data];
      //NSLog(@"254");
      if (0!=task(@"/bin/rmdir",@[DESdir],rmdirData,nil))
         os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "%@",[[NSString alloc]initWithData:rmdirData encoding:NSUTF8StringEncoding]);
      return;
   }

   NSMutableString *SfullPath=[NSMutableString string];
   NSMutableArray *Ipaths=[NSMutableArray array];
   @try
   {
#pragma mark metadata de nivel serie
      
      NSMutableDictionary *fmiAttrs=[NSMutableDictionary dictionary];
      NSMutableDictionary *datAttrs=[NSMutableDictionary dictionary];
      NSMutableDictionary *natAttrs=[NSMutableDictionary dictionary];
      NSMutableDictionary *j2kAttrs=[NSMutableDictionary dictionary];
      NSMutableDictionary *blobDict=[NSMutableDictionary dictionary];
      NSMutableDictionary *j2kBlobDict=[NSMutableDictionary dictionary];
      
      long long blobMinSize=0;
      int blobMode=blobModeResources;
      NSString *blobRefPrefix=@"";
      NSString *blobRefSuffix=@"";
      NSError *writeError=nil;
      
      for (NSString *DESIfullpath in DESIarray)
      { @autoreleasepool {
            
         NSMutableData *data=[NSMutableData dataWithData:[NSData dataWithContentsOfFile:DESIfullpath]];
         if (parse(data,fmiAttrs,datAttrs,natAttrs,j2kAttrs,blobDict,j2kBlobDict,blobMinSize,blobMode,blobRefPrefix, blobRefSuffix,toJ2KR,toBFHI)==failure)
         {
            os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "failed parsing %@",DESIfullpath);
            [seriesFAILED addObject:DESdir];
            moveCLASSIFIEDobject(DESIfullpath, CDargFailure);
            return;
         }

 #pragma mark coerce

 #pragma mark · fileMetainfo
         switch ([whiteList[matchInt][@"j2kLayers"] intValue]) {
            case 0://exe
               [fmiAttrs setObject:@[@"1.2.840.10008.1.2.1"] forKey:@"00000001_00020010-UI"];
               break;
            case 1://j2kr
               [fmiAttrs setObject:@[@"1.2.840.10008.1.2.4.90"] forKey:@"00000001_00020010-UI"];
               break;
            case 4://bfhi
               [fmiAttrs setObject:@[@"1.2.840.10008.1.2.4.91"] forKey:@"00000001_00020010-UI"];
               break;
         }
         
         [fmiAttrs setObject:@[@"1.3.6.1.4.1.23650.99.111.101.114.99.101.100.105.99.111.109"] forKey:@"00000001_00020012-UI"];
         [fmiAttrs setObject:@[@"COERCEDICOM-1.0"] forKey:@"00000001_00020013-SH"];

         //sourceAET (branch aet)
         //sendingAET (device aet)
         //receivingAET (pacs aet)
         if (whiteList[matchInt][@"sourceAET"])[fmiAttrs setObject:@[whiteList[matchInt][@"sourceAET"]] forKey:@"00000001_00020016-AE"];
         if (whiteList[matchInt][@"sendingAET"])[fmiAttrs setObject:@[whiteList[matchInt][@"sendingAET"]] forKey:@"00000001_00020017-AE"];
         if (whiteList[matchInt][@"receivingAET"])[fmiAttrs setObject:@[whiteList[matchInt][@"receivingAET"]] forKey:@"00000001_00020018-AE"];

         if (whiteList[matchInt][@"coerceFileMetainfo"]) [fmiAttrs addEntriesFromDictionary:whiteList[matchInt][@"coerceFileMetainfo"]];
         
#pragma mark · blobs
         if (whiteList[matchInt][@"coerceBlobs"]) [blobDict addEntriesFromDictionary:whiteList[matchInt][@"coerceBlobs"]];

#pragma mark · coerceFileMetainfo

#pragma mark · replaceInFileMetainfo

#pragma mark · supplementToFileMetainfo

#pragma mark · removeFromFileMetainfo

 
                
#pragma mark · coerceDataset
         if (whiteList[matchInt][@"coerceDataset"]) [datAttrs addEntriesFromDictionary:whiteList[matchInt][@"coerceDataset"]];

                
#pragma mark · replaceInDataset
         NSArray *replaceKeys=[whiteList[matchInt][@"replaceInDataset"] allKeys];
                for (NSString *replaceKey in replaceKeys)
                {
                   if (datAttrs[replaceKey])
                      [datAttrs setObject:whiteList[matchInt][@"replaceInDataset"][replaceKey] forKey:replaceKey];
                }

    #pragma mark ···· supplementToDataset
                NSArray *supplementKeys=[whiteList[matchInt][@"supplementToDataset"] allKeys];
                for (NSString *supplementKey in supplementKeys)
                {
                   if (!datAttrs[supplementKey])
                      [datAttrs setObject:whiteList[matchInt][@"supplementToDataset"][supplementKey] forKey:supplementKey];
                }

                
    #pragma mark ···· removeFromDataset
                for (NSString *removeKey in whiteList[matchInt][@"removeFromDataset"])
                {
                   if (datAttrs[removeKey])
                      [datAttrs removeObjectForKey:removeKey];
                }

                
   #pragma mark ···· removeFromEUIDprefixedDataset
                if (whiteList[matchInt][@"removeFromEUIDprefixedDataset"])
                {
                   NSString *EUID=datAttrs[@"00000001_0020000D-UI"][0];
                   NSArray *EUIDprefixes=[whiteList[matchInt][@"removeFromEUIDprefixedDataset"] allKeys];
                   for (NSString *EUIDprefix in EUIDprefixes)
                   {
                      if ([EUID hasPrefix:EUIDprefix])
                      {
                         for (NSString *removeKey in whiteList[matchInt][@"removeFromEUIDprefixedDataset"][EUIDprefix])
                         {
                            if (datAttrs[removeKey])
                               [datAttrs removeObjectForKey:removeKey];
                         }

                      }
                   }
                }

                
    #pragma mark ·· outputData init
                NSMutableData *outputData;
    //preamble
                if (!whiteList[matchInt][@"coercePreamble"])
                {
                   outputData=[NSMutableData dataWithLength:128];
                   [outputData appendBytes:&DICM length:4];
                }
                else outputData=[[NSMutableData alloc] initWithBase64EncodedString:whiteList[matchInt][@"coercePreamble"] options:0] ;

                
    //fileMetainfo
                NSMutableData *outputFileMetainfo=[NSMutableData data];
                if (dict2D(
                            @"",
                            fmiAttrs,
                            outputFileMetainfo,
                            j2kr, //j2kr   !!! error with 4 j2kh
                            blobDict
                            ) == failure
                    )
                {
                   os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "error outputFileMetainfo %@: %@",DESIfullpath,fmiAttrs.description);
                   [seriesFAILED addObject:DESdir];
                   moveCLASSIFIEDobject(DESIfullpath, CDargFailure);
                   return;
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
                            datAttrs,
                            outputData,
                            j2kr,
                            blobDict
                            )==failure
                    )
    #pragma mark ··· failure
                {
                   os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "could not serialize dataset %@: %@",DESIfullpath,datAttrs.description);
                   [seriesFAILED addObject:DESdir];
                   moveCLASSIFIEDobject(DESIfullpath, CDargFailure);
                   return;
                }
                else
                {
#pragma mark ··· + j2k or native attrs
                   
                   /*
                   - (undf) undefined: defaults to j2k, or native or what is into dataset in this order depending of the existence of the sets.
                   - (natv) native: explicit little endian without compression
                   - (j2kb) j2kBase: the quality of a miniature.
                   - (j2kf) j2kFast: compressión con pérdida, pero muy rápido, compuesta de 2 capas
                   - (j2kh) j2kHres: compressión con pérdida invisible, compuesta de 3 capas
                   - (j2ki) j2kIdem: compresión sin perdida, compuesta de 4 capas
                   - (j2kr) j2kr: compresión sin perdida, compuesta de una capa
                   - (j2k) j2k: j2kIdem o j2kr
                    */

                   if (toJ2KR || toBFHI)
                   {
                      if (dict2D(
                                  @"",
                                  j2kAttrs,
                                  outputData,
                                  j2kr,
                                  blobDict
                                  )==failure
                          )
          #pragma mark ··· failure
                      {
                         os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "could not serialize j2kAttrs %@: %@",DESIfullpath,j2kAttrs.description);
                         [seriesFAILED addObject:DESdir];
                         moveCLASSIFIEDobject(DESIfullpath, CDargFailure);
                         return;
                      }
                   }
                   else if (natAttrs.count > 0)
                   {
                      if (dict2D(
                                  @"",
                                  natAttrs,
                                  outputData,
                                  natv,
                                  blobDict
                                  )==failure
                          )
          #pragma mark ··· failure
                      {
                         os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "could not serialize native attrs %@: %@",DESIfullpath,natAttrs.description);
                         [seriesFAILED addObject:DESdir];
                         moveCLASSIFIEDobject(DESIfullpath, CDargFailure);
                         return;
                      }

                   }
                   
                   
#pragma mark ··· success
                  NSString *Iname;
                  if (cesiB64)
                  {
                     if (SfullPath.length==0)
                     {
                        [SfullPath setString:[NSString stringWithFormat:@"%@/%@/%@/%@/%@",
                                           CDargs[CDargSuccess],
                                           whiteList[matchInt][@"sourceAET"],
                                           b64ui([datAttrs[@"00000001_00080020-DA"][0] substringToIndex:6]),
                                           b64ui(datAttrs[@"00000001_0020000D-UI"][0]),
                                           b64ui(datAttrs[@"00000001_0020000E-UI"][0])
                                           ]
                         ];
                        BOOL isDir;
                        if (![fs fileExistsAtPath:SfullPath isDirectory:&isDir])
                        {
                           //create destSubdir
                           NSError *createDirError;
                           if (![fs createDirectoryAtPath:SfullPath withIntermediateDirectories:YES attributes:nil error:&createDirError])
                           {
                              os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "could not create %@: %@",SfullPath,createDirError.description);
                              return;
                           }
                        }
                     }
                     
                     Iname=b64ui(datAttrs[@"00000001_00080018-UI"][0]);
                     if (![outputData writeToFile:[SfullPath stringByAppendingPathComponent:Iname]
                          options:0
                          error:&writeError
                         ])
                     {
                        os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "could not write dataset %@: %@",DESIfullpath,writeError.description);
                        [seriesFAILED addObject:DESdir];
                        moveCLASSIFIEDobject(DESIfullpath, CDargFailure);
                        return;
                     }
                     [Ipaths addObject:[SfullPath stringByAppendingPathComponent:Iname]];
                  }
                  else //!cesiB64
                  {
                     if (SfullPath.length==0)
                     {
                        //sourceAET (branch aet)
                        //sendingAET (device aet)
                        //receivingAET (pacs aet)
                        [SfullPath setString:[NSString stringWithFormat:@"%@/STORE/%@/%@/SEND/%@/%02d^%@/%@/%@",
                                              CDargs[CDargSuccess],
                                              whiteList[matchInt][@"storeMode"],
                                              whiteList[matchInt][@"receivingAET"],
                                              whiteList[matchInt][@"sourceAET"],
                                              matchInt,
                                              whiteList[matchInt][@"sendingAET"],
                                              datAttrs[@"00000001_0020000D-UI"][0],
                                              datAttrs[@"00000001_0020000E-UI"][0]
                                              ]
                         ];
                         BOOL isDir;
                         if (![fs fileExistsAtPath:SfullPath isDirectory:&isDir])
                         {
                            //create destSubdir
                            NSError *createDirError;
                            if (![fs createDirectoryAtPath:SfullPath withIntermediateDirectories:YES attributes:nil error:&createDirError])
                            {
                               os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "could not create %@: %@",SfullPath,createDirError.description);
                               return;
                            }
                         }
                     }
                     
                     if ([whiteList[matchInt][@"suffix"] length] > 0)
                        Iname=[datAttrs[@"00000001_00080018-UI"][0] stringByAppendingPathExtension:whiteList[matchInt][@"suffix"]];
                     else
                        Iname=datAttrs[@"00000001_00080018-UI"][0];
                     
                     if (![outputData writeToFile:[SfullPath stringByAppendingPathComponent:Iname]
                          options:0
                          error:&writeError
                         ])
                     {
                        os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "could not write dataset %@: %@",DESIfullpath,writeError.description);
                        [seriesFAILED addObject:DESdir];
                        moveCLASSIFIEDobject(DESIfullpath, CDargFailure);
                        return;
                     }
                     [seriesDONE addObject:DESdir];

                  }

#pragma mark ·original to originalDir
                  moveCLASSIFIEDobject(DESIfullpath, CDargOriginal);
                }
                  
         }//end parsed
         
#pragma mark timeout?
         if (timeoutDate < [NSDate date]) break;
      }//end autorelease end loop

#pragma mark fileref
      if (cesiB64 && (Ipaths.count > 0))
      {
         NSString *PACS=[NSString stringWithFormat:@"%@@%@:%@",
                      whiteList[matchInt][@"receivingAET"],
                      whiteList[matchInt][@"receivingIP"],
                      whiteList[matchInt][@"receivingPort"]
                      ];
         NSMutableData *logData=[NSMutableData data];
      
         
         
         
         
         
         NSMutableArray *args=[NSMutableArray arrayWithArray:@[@"-fileref",@"-L",whiteList[matchInt][@"sourceAET"],PACS]];
         [args addObjectsFromArray:Ipaths];
         //NSLog(@"589");
         if (0==task(@"/Users/Shared/dcm4che-2.0.29/bin/dcmsnd",args,logData,nil))
            [seriesDONE addObject:SfullPath];
         else
         {
            LOG_ERROR(@"%@",[[NSString alloc]initWithData:logData encoding:NSUTF8StringEncoding]);
            [seriesPostscript addObject:SfullPath];

            //create script
            NSError *shError=nil;
            NSMutableString *sh=[NSMutableString stringWithFormat:@"#!sh\r/Users/Shared/dcm4che-2.0.29/bin/dcmsnd -fileref -L %@ %@ ",whiteList[matchInt][@"sourceAET"],PACS];
            [sh appendString:[Ipaths componentsJoinedByString:@" "]];

            //write script into seriesPostscript subDir
            NSArray *beforeAfter=[SfullPath componentsSeparatedByString:[NSString stringWithFormat:@"/%@/",CDargs[CDargSuccess]]];
            NSString *shSubdir=[CDargs[CDargSeriesPostscript] stringByAppendingPathComponent:beforeAfter[1]];

            
            BOOL isDir;
            if (![fs fileExistsAtPath:shSubdir isDirectory:&isDir])
            {
               //create destSubdir
               if (![fs createDirectoryAtPath:shSubdir withIntermediateDirectories:YES attributes:nil error:&shError])
               {
                  os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "could not create %@: %@",shSubdir,shError.description);
                  os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "TODO: %@",sh);
                  return;
               }
               else if (!isDir)
               {
                  os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "not dir %@",shSubdir);
                  os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "TODO: %@",sh);
                  return;
               }

               NSString *shPath=[shSubdir stringByAppendingPathComponent:_yyMMddhhmm];
               if (0!=[sh writeToFile:shPath atomically:NO encoding:NSUTF8StringEncoding error:&shError])
               {
                  os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "could not write %@: %@",shPath,shError.description);
                  os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "TODO: %@",sh);
                  return;
               }
               return;
            }

            [seriesDONE addObject:DESdir];
         }
      }

      return;

   }@catch (NSException *exception) {
     os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_FAULT, "%@", exception.reason);
  }
  @finally {}
}






int main(int argc, const char * argv[]){
   NSError *error=nil;
   NSProcessInfo *processInfo=[NSProcessInfo processInfo];
   CDargs=[processInfo arguments];
   if (CDargs.count != 15)
   {
      os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_FAULT, "bad args count: %@",[CDargs description]);
      exit(1);
   };


#pragma mark global static
   fs=[NSFileManager defaultManager];
   headData=[@"\r\n--myboundary\r\nContent-Type: application/dicom\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
   UIRegex = [NSRegularExpression regularExpressionWithPattern:@"[1-9](\\d)*(\\.0|\\.[1-9](\\d)*)*" options:0 error:NULL];
   int maxSeries=abs([CDargs[CDargMaxSeries] intValue]);

   //whitelist
   NSData *jsonData=[NSData dataWithContentsOfFile:CDargs[CDargCoercedicomFile]];
   if (!jsonData)
   {
      os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "no coercedicom json file at: %@",CDargs[CDargCoercedicomFile]);
      exit(1);
   };
   whiteList=[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
   if (!whiteList)
   {
      os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "bad coercedicom json file:%@ %@",CDargs[CDargCoercedicomFile],[error description]);
      exit(1);
   }
   
   sinceLastSeriesModif=[NSString stringWithFormat:@"-%@s",CDargs[CDargSinceLastSeriesModif]];
   NSDateFormatter *_yyMMddhhmmFormatter = [[NSDateFormatter alloc]init];
   [_yyMMddhhmmFormatter setDateFormat:@"_yyMMddhhmm"];
   _yyMMddhhmm=[_yyMMddhhmmFormatter stringFromDate:[NSDate date]];
   int timeout=[CDargs[CDargTimeout] intValue];
   timeoutDate=[NSDate dateWithTimeIntervalSinceNow:timeout];
   @autoreleasepool {
#pragma mark CLASSIFIED
   BOOL isDirectory=false;
   NSMutableData *rmdirData=[NSMutableData data];
      //NSLog(@"690");
      if (0!=task(
           @"/usr/bin/find",
           @[
              CDargs[CDargClassified],
              @"-type",
              @"f",
              @"-name",
              @".DS_Store",
              @"-delete"
           ],
           rmdirData,
           nil
        ))
      {
        os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "could not list CLASSIFIED studies: %@", [[NSString alloc]initWithData:rmdirData encoding:NSUTF8StringEncoding]);
        exit(2);
      }

    
#pragma mark · DEa (a=any)
    
    if (![fs fileExistsAtPath:CDargs[CDargClassified] isDirectory:&isDirectory] || !isDirectory)
    {
       os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "no valid CLASSIFIED dir");
       exit(1);
    }
    //Set of any dir study
    NSMutableData *DEadirData=[NSMutableData data];
    NSMutableSet *DEadirSet=nil;
    //NSLog(@"720");
    if (0!=task(
         @"/usr/bin/find",
         @[
            CDargs[CDargClassified],
            @"-type",
            @"d",
            @"-depth",
            @"2"
         ],
         DEadirData,
         nil
      ))
    {
      os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "could not list CLASSIFIED studies: %@", [[NSString alloc]initWithData:DEadirData encoding:NSUTF8StringEncoding]);
      exit(2);
    }
    else
    {
      DEadirSet=[NSMutableSet setWithArray:[[[NSString alloc]initWithData:DEadirData encoding:NSUTF8StringEncoding] componentsSeparatedByString:@"\n"]];
      [DEadirSet removeObject:@""];
    }
    if (!DEadirSet.count)
    {
       os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "no studies dir found in classified");
       exit(0);
    }

      
#pragma mark CLASSIFIED DEf (f=full->contains dir(s))
      NSMutableData *DEfdirData=[NSMutableData data];
      NSMutableSet *DEfdirSet=nil;
      //NSLog(@"752");
      if (0!=task(
           @"/usr/bin/find",
           @[
              CDargs[CDargClassified],
              @"-type",
              @"d",
              @"-depth",
              @"3",
              @"-exec",
              @"dirname",
              @"{}",
              @";"
           ],
           DEfdirData,
           nil
        ))
      {
         os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "could not list CLASSIFIED studies: %@", [[NSString alloc]initWithData:DEfdirData encoding:NSUTF8StringEncoding]);
         exit(2);
      }
      DEfdirSet=[NSMutableSet setWithArray:[[[NSString alloc]initWithData:DEfdirData encoding:NSUTF8StringEncoding] componentsSeparatedByString:@"\n"]];
      [DEfdirSet removeObject:@""];
      
#pragma mark rm empty dir (up to 100)
      [DEadirSet minusSet:DEfdirSet];
      if (DEadirSet.count > 0)
      {
         if (DEadirSet.count < 101)
         {
            //NSLog(@"793");

            if (0!=task(@"/bin/rmdir",[DEadirSet allObjects],rmdirData,nil))
               os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "%@",[[NSString alloc]initWithData:rmdirData encoding:NSUTF8StringEncoding]);
         }
         else
         {
            NSMutableArray *rmDirs=[NSMutableArray arrayWithArray:[DEadirSet allObjects]];
            [rmDirs removeObjectsInRange:NSMakeRange(100,rmDirs.count-100)];
            //NSLog(@"791");

            if (0!=task(@"/bin/rmdir",rmDirs,nil,nil))
               os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "rmdir %@",rmDirs.description);
         }
      }

      
#pragma mark loop white list
    
    NSMutableDictionary *DESdirDict=[NSMutableDictionary dictionary];//DESdirKey:matchIndex
    NSMutableSet *DEfdirSetCurrent=[NSMutableSet set];
    //move valid devices from array Ds to array devicesToBeProcessed
    for (int matchIndex=0; matchIndex<whiteList.count; matchIndex++)
    {
       if (DESdirDict.count < maxSeries)
       {
           NSNumber *matchNumber=[NSNumber numberWithInt:matchIndex];
           //key regex should be presente
           NSDictionary *matchDict=whiteList[matchIndex];
           NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:matchDict[@"regex"] options:0 error:&error];
           if (!regex)
           {
              os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "bad coercedicom json file:%@ item:%@ %@",CDargs[CDargCoercedicomFile],matchDict.description,[error description]);
               exit(1);
           }
          
#pragma mark loop DEfdirSet for matching device study level regex filter
          [DEfdirSetCurrent setSet:DEfdirSet];
          
          for ( NSString *DEdirKey in DEfdirSetCurrent)
          {
             if ([regex numberOfMatchesInString:DEdirKey options:0 range:NSMakeRange(0,DEdirKey.length)])
             {
                //study already managed. Remove from pool
                [DEfdirSet removeObject:DEdirKey];
                //find series
                NSMutableData *DESdirData=[NSMutableData data];
                //NSLog(@"830");

                if (0!=task(
                     @"/usr/bin/find",
                     @[
                        DEdirKey,
                        @"-type",
                        @"d",
                        @"-depth",
                        @"1"
                     ],
                     DESdirData,
                     nil
                  ))
                {
                  os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "could not list series of study %@: %@",DEdirKey, [[NSString alloc]initWithData:DEfdirData encoding:NSUTF8StringEncoding]);
                  moveCLASSIFIEDobject(DEdirKey, CDargFailure);
                }
                else
                {
                  //register series to be processed
                  NSArray *DESdirArray=[[[NSString alloc]initWithData:DESdirData encoding:NSUTF8StringEncoding] componentsSeparatedByString:@"\n"];
                  for (int i=0; i<(DESdirArray.count-1); i++)
                  {
                     [DESdirDict setObject:matchNumber forKey:DESdirArray[i]];
                  }
                }
             }
          }
       }
    }
    
        
#pragma mark mv studies with no regex match to CDargNoRegex
   if (DESdirDict.count < maxSeries)
   {
      for ( NSString *DEdirKey in DEfdirSet) //remaing studies matching no regex
      {
         moveCLASSIFIEDobject(DEdirKey, CDargNoRegex);
      }
   }

       
#pragma mark dispatch queue init ?
   seriesPostscript=[NSMutableSet set];
   seriesDONE=[NSMutableSet set];
   seriesFAILED=[NSMutableSet set];

   if  ([CDargs[CDargMaxSeries] intValue] > 0)
   {
      dispatch_queue_attr_t attr=dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT, QOS_CLASS_USER_INTERACTIVE, QOS_MIN_RELATIVE_PRIORITY);
      //dispatch_queue_attr_make_with_autorelease_frequency(DISPATCH_QUEUE_CONCURRENT,DISPATCH_AUTORELEASE_FREQUENCY_WORK_ITEM);
      dispatch_queue_t seriesqueue = dispatch_queue_create("com.opendicom.coercedicom.seriesqueue", attr);
      for (NSString *DESdir in DESdirDict )
      {
         dispatch_async_f( seriesqueue, [NSDictionary dictionaryWithObjectsAndKeys:DESdir,@"DESdir",DESdirDict[DESdir],@"matchNumber", nil], series_callback );
      }
      while (timeout > -5)
      {
         timeout-=5;
         [NSThread sleepForTimeInterval:5];//wait 5 segundos
      }

   }
   else
   {
      //run sequentially on the main thread
      for (NSString *DESdir in DESdirDict )
      {
         series_callback([NSDictionary dictionaryWithObjectsAndKeys:DESdir,@"DESdir",DESdirDict[DESdir],@"matchNumber", nil]);
         if ([NSDate date] < timeoutDate) break;
      }
                                
   }


   if (seriesFAILED.count > 0)
      os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "FAILED series\r\n%@",seriesFAILED.description);
   if (seriesPostscript.count > 0)
      os_log(OS_LOG_DEFAULT, "%lu NOT REGISTERED series",(unsigned long)seriesPostscript.count);
   if (seriesDONE.count > 0)
      os_log(OS_LOG_DEFAULT, "%lu OK series",(unsigned long)seriesDONE.count);
}//end autoreleaspool
  return 0;//returns the number studuies processed
}
