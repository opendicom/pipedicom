//  Created by jacquesfauquex@opendicom.com on 2014-07-30.
//  Copyright (c) 2014-2021 opendicom.com. All rights reserved.

#import <Foundation/Foundation.h>

#import <DCKV/dict2D.h>

#import "ODLog.h"

int main(int argc, const char * argv[])
{
 @autoreleasepool {
     
    NSError *finalError=nil;

     
#pragma mark init
     
    const UInt32 DICM='MCID';
    const UInt64 _0002000_tag_vr=0x44C5500000002;
    const UInt64 _0002001_tag_vr=0x0000424F00010002;
    const UInt32 _0002001_length=0x00000002;
    const UInt16 _0002001_value=0x0001;
 
    NSFileManager *fileManager=[NSFileManager defaultManager];

    //http://unicode.org/reports/tr35/tr35-6.html#Date_Format_Patterns
    NSDateFormatter *DAFormatter = [[NSDateFormatter alloc] init];
    [DAFormatter setDateFormat:@"yyyyMMdd"];
    NSDateFormatter *DTFormatter = [[NSDateFormatter alloc] init];
    [DTFormatter setDateFormat:@"yyyyMMddhhmmss"];

#pragma mark args
     
     NSMutableArray *args=[NSMutableArray arrayWithArray:[[NSProcessInfo processInfo] arguments]];
     //NSLog(@"%@",[args description]);
     //[0] command path
     //[1] xslt1 path
     //[2] qido base url
     //[3] audit folder
     //[4] scpaet
     
     //[1]cda2mwl.xsl path
     NSData *xslt1Data=[NSData dataWithContentsOfFile:[args[1] stringByExpandingTildeInPath]];

     //arg[2] base URL
     //ejemplo: https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE/instances?Modality=OT&SeriesDescription=solicitud&NumberOfStudyRelatedInstances=1&00080080=asseMALDONADO&StudyDate=20210128&StudyTime=1210-
     NSString *DA=[DAFormatter stringFromDate:[NSDate date]];
     
     //arg[3] audit path
     NSString *DApath=[[args[3] stringByExpandingTildeInPath] stringByAppendingPathComponent:DA];
     
     //arg[4] aet
     NSString *aetscppath=[[[args[3] stringByExpandingTildeInPath]stringByAppendingPathComponent:@"published"] stringByAppendingPathComponent:args[4]];
     if(![fileManager fileExistsAtPath:aetscppath])
     {
        if(![fileManager createDirectoryAtPath:aetscppath withIntermediateDirectories:YES attributes:nil error:&finalError])
        {
            NSLog(@"ERROR could not create folder %@. %@", aetscppath, finalError.description);
            return failure;
        }
     }

#pragma mark qido
     NSURL *qidoURL=[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",args[2],DA]];
     if (!qidoURL)
     {
        NSLog(@"ERROR no qido url");
        return (failure);
     }
     NSData *qidoResponse=[NSData dataWithContentsOfURL:qidoURL
                                                options:NSDataReadingUncached
                                                  error:nil];
     if (!qidoResponse) return (failure);//NSURLConnection finished with error - code -1002
     if (![qidoResponse length]) return (success);//no instance found




      NSArray *list = [NSJSONSerialization JSONObjectWithData:qidoResponse options:0 error:&finalError];
      if (!list)
      {
          NSLog(@"qido response to %@ not json. %@ %@",[qidoURL absoluteString],finalError.description,[[NSString alloc]initWithData:qidoResponse encoding:NSUTF8StringEncoding] );
          return (failure);
      }
     
     
      for (NSDictionary *instance in list)
      {
#pragma mark - loop StudyInstanceUIDs
          NSError *localError=nil;

          NSString *EUID=[instance[@"0020000D"][@"Value"] firstObject];
          NSString *EUIDpath=[[DApath stringByAppendingPathComponent:@"EUID"] stringByAppendingPathComponent:EUID];
          
         if([fileManager fileExistsAtPath:[[aetscppath stringByAppendingPathComponent:EUID] stringByAppendingPathExtension:@"wl"]]) continue;// published/aet/EUID.wl already created

          if(![fileManager fileExistsAtPath:EUIDpath] && ![fileManager createDirectoryAtPath:EUIDpath withIntermediateDirectories:YES attributes:nil error:&localError])
          {
              NSLog(@"ERROR could not create folder %@. %@", EUIDpath, localError.description);
              continue;
          }
          else
          {
#pragma mark AccessionNumber
              //        /AccessionNumber[^[localIssuer][^universalIssuer]]
              //                /symlink StudyInstanceUID -> StudyInstanceUID
              
              NSString *ANIsuffix=nil;
             NSString *ANL=[instance[@"00080051.00400031"][@"Value"] firstObject];
             NSString *ANU=[instance[@"00080051.00400032"][@"Value"] firstObject];
              if (ANL && ANU) ANIsuffix=[NSString stringWithFormat:@"^%@^%@",ANL,ANU];
              else if (ANL)   ANIsuffix=[NSString stringWithFormat:@"^%@",ANL];
              else if (ANU)   ANIsuffix=[NSString stringWithFormat:@"^%@",ANU];
              else            ANIsuffix=@"";
             NSString *AN=[[instance[@"00080050"][@"Value"] firstObject] stringByAppendingString:ANIsuffix];
             NSString *ANpath=[[DApath stringByAppendingPathComponent:@"AN"] stringByAppendingPathComponent:AN];
             if(![fileManager fileExistsAtPath:ANpath])
             {
                 if(![fileManager createDirectoryAtPath:ANpath withIntermediateDirectories:YES attributes:nil error:&localError])
                 {
                     NSLog(@"ERROR could not create folder %@. %@", ANpath, localError.description);
                     continue;
                 }
             }
             if (![fileManager fileExistsAtPath:[ANpath stringByAppendingPathComponent:EUID]])
             {
                if (![fileManager createSymbolicLinkAtPath:[ANpath stringByAppendingPathComponent:EUID] withDestinationPath:EUIDpath error:&localError])
                {
                    NSLog(@"ERROR could not create AccessionNumber symlink %@ to %@. %@",AN, EUIDpath, localError.description);
                }
             }

#pragma mark PatientID
              //        /PatientID[^issuer]
              //                /symlink StudyInstanceUID -> StudyInstanceUID

              NSString *PIDIsuffix=nil;
             NSString *PIDI=[instance[@"00100021"][@"Value"] firstObject];
             if (PIDI) PIDIsuffix=[NSString stringWithFormat:@"^%@",PIDI];
             else      PIDIsuffix=@"";
             NSString *PID=[[instance[@"00100020"][@"Value"] firstObject] stringByAppendingString:PIDIsuffix];
             NSString *PIDpath=[[DApath stringByAppendingPathComponent:@"PID"]stringByAppendingPathComponent:PID];
             if(![fileManager fileExistsAtPath:PIDpath])
             {
                 if(![fileManager createDirectoryAtPath:PIDpath withIntermediateDirectories:YES attributes:nil error:nil])
                 {
                     NSLog(@"ERROR could not create folder %@", PIDpath);
                     continue;
                 }
             }
            if (![fileManager fileExistsAtPath:[PIDpath stringByAppendingPathComponent:EUID]])
            {
                if (![fileManager createSymbolicLinkAtPath:[PIDpath stringByAppendingPathComponent:EUID] withDestinationPath:EUIDpath error:&localError])
                {
                    NSLog(@"ERROR could not create PatientID symlink %@ to %@. %@",PID, EUIDpath, localError.description);
                }
            }
         }

#pragma mark download details
         NSString *RetrieveString=[instance[@"00081190"][@"Value"] firstObject];
         if (RetrieveString && RetrieveString.length)
         {
            
            /*
             transform
             http://serviciosridi.asse.uy/dcm4chee-arc/wado/DCM4CHEE/studies/2.16.858.2.10001442.67430.20220906075913.5029238.8/series/2.16.858.2.10001442.67430.20220906075913.5029238.8.1/instances/2.16.858.2.10001442.67430.20220906075913.5029238.8.1.1
             into "https://serviciosridi.asse.uy/dcm4chee-arc/wado/DCM4CHEE?requestType=WADO&studyUID=2.16.858.2.10001442.67430.20220906134444.5048465.8&seriesUID=2.16.858.2.10001442.67430.20220906134444.5048465.8.1&objectUID=2.16.858.2.10001442.67430.20220906134444.5048465.8.1.1&contentType=text/xml"
             */
            NSArray *a=[RetrieveString componentsSeparatedByString:@"/"];

            NSString *wadoString;
            if ([args[2] hasPrefix:@"https"])
                wadoString=
                [NSString stringWithFormat:
                 @"https://%@/%@/%@/%@?requestType=WADO&studyUID=%@&seriesUID=%@&objectUID=%@&contentType=text/xml",
                 a[2],
                 a[3],
                 a[4],
                 a[5],
                 a[7],
                 a[9],
                 a[11]
                 ];
            else //http
                wadoString=
                [NSString stringWithFormat:
                 @"http://%@/%@/%@/%@?requestType=WADO&studyUID=%@&seriesUID=%@&objectUID=%@&contentType=text/xml",
                 a[2],
                 a[3],
                 a[4],
                 a[5],
                 a[7],
                 a[9],
                 a[11]
                 ];

             NSURL *RetrieveURL=[NSURL URLWithString:wadoString];
             if (!RetrieveURL)
             {
                NSLog(@"ERROR could not create URL from %@",RetrieveString);
                continue;
             }
             NSData *downloaded=[NSData dataWithContentsOfURL:RetrieveURL options:NSDataReadingUncached error:&localError];
             if (!downloaded)
             {
                NSLog(@"ERROR response to %@: %@",RetrieveString,localError.description);
                continue;
             }
            NSUInteger dl=downloaded.length;
             if ( dl == 0)
             {
                 NSLog(@"empty response to %@",RetrieveString);
                 continue;
             }
            NSXMLDocument *xmlDocument = nil;
            uint16 last2Bytes=0;
            [downloaded getBytes:&last2Bytes range:NSMakeRange(dl-2, 2)];
            if (last2Bytes==0x000A)
                xmlDocument = [[NSXMLDocument alloc]initWithData:[downloaded subdataWithRange:NSMakeRange(0,dl-2)] options:0 error:&localError];
            else xmlDocument = [[NSXMLDocument alloc]initWithData:downloaded options:0 error:&localError];
            if (!xmlDocument)
            {
                  LOG_WARNING(@"00420011 NOT xml %@\r%@",RetrieveString,localError.description);
                  continue;
            }
#pragma mark write cda.xml
            NSString *cdapath=[EUIDpath stringByAppendingPathComponent:@"cda.xml"];
            [[xmlDocument XMLData] writeToFile:cdapath atomically:NO];
              
#pragma mark write wl.json
            //transform CDA 2 WorkItem (wl) json contextualkey-values
            id wl = [xmlDocument objectByApplyingXSLT:xslt1Data arguments:nil error:&localError];
            if (!wl)
            {
                  NSLog(@"could not transform %@ to wl.json\r%@",cdapath,[localError description]);
                  continue;
            }
              
            if (![wl isKindOfClass:[NSData class]])
            {
                  NSLog(@"xslt1 on %@ did not output data file",cdapath);
                  continue;
            }

            NSString *wlpath=[EUIDpath stringByAppendingPathComponent:@"wl.json"];
            [wl writeToFile:wlpath atomically:NO];

#pragma mark serialize wl json data to dicom
            NSDictionary *json=[NSJSONSerialization JSONObjectWithData:wl options:0 error:&localError];
            if (!json)
            {
                  LOG_WARNING(@"ERROR reading %@: %@",wlpath,[localError description]);
                  continue;
            }

            NSMutableData *outputData=[NSMutableData dataWithLength:128];
            [outputData appendBytes:&DICM length:4];
 //fileMetadata
            NSMutableData *outputFileMetadata=[NSMutableData data];
            if (dict2D(@"",json[@"metadata"],outputFileMetadata,0,@{})==failure)
            {
                NSLog(@"could not serialize group 0002");
                continue;
            }
            [outputData appendBytes:&_0002000_tag_vr length:8];
            UInt32 fileMetadataLength=(UInt32)outputFileMetadata.length+14;
            [outputData appendBytes:&fileMetadataLength length:4];
            [outputData appendBytes:&_0002001_tag_vr length:8];
            [outputData appendBytes:&_0002001_length length:4];
            [outputData appendBytes:&_0002001_value length:2];
            [outputData appendData:outputFileMetadata];
 // dataset
            if (dict2D(@"",json[@"dataset"],outputData,0,@{})==failure)
            {
                NSLog(@"could not serialize dataset");
                continue;
            }
            [outputData writeToFile:[NSString stringWithFormat:@"%@/%@.wl",aetscppath,EUID] atomically:NO];
         }//end retrieveString
     }
  }
   return 0;
}
