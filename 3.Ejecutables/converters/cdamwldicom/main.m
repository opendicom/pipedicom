//  Created by jacquesfauquex@opendicom.com on 2014-07-30.
//  Copyright (c) 2014-2021 opendicom.com. All rights reserved.

#import <Foundation/Foundation.h>
#import "ZZArchiveEntry.h"
#import "ZZArchive.h"
#import "ZZConstants.h"
#import "ZZChannel.h"
#import "ZZError.h"

#import <DCKV/dict2D.h>

#import "ODLog.h"

int main(int argc, const char * argv[])
{
 @autoreleasepool {
     
     
#pragma mark init
     
    NSError *error=nil;
    const uint64 tag00420011=0x0000424F00110042;//encapsulatedCDA tag + vr + padding (used in order to find the offset)
    NSFileManager *fileManager=[NSFileManager defaultManager];

    //http://unicode.org/reports/tr35/tr35-6.html#Date_Format_Patterns
    NSDateFormatter *DAFormatter = [[NSDateFormatter alloc] init];
    [DAFormatter setDateFormat:@"yyyyMMdd"];

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
     
     //NSString *DA=@"20161018";
     NSString *DA=[DAFormatter stringFromDate:[NSDate date]];
     NSDictionary *DAargdict = [NSDictionary dictionaryWithObject:DA forKey:@"now"];

     //arg[2] base URL
     //ejemplo: https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE/instances?Modality=OT&SeriesDescription=solicitud&NumberOfStudyRelatedInstances=1&00080080=asseMALDONADO&StudyDate=20210128&StudyTime=1210-
     NSURL *qidoURL=[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",args[2],DA]];
     
     //arg[3] audit path
     NSString *DApath=[[args[3] stringByExpandingTildeInPath] stringByAppendingPathComponent:DA];
     
     //arg[4] aet
     NSString *aetscppath=[[[args[3] stringByExpandingTildeInPath]stringByAppendingPathComponent:@"published"] stringByAppendingPathComponent:args[4]];
     
#pragma mark qido
     NSData *qidoResponse=[NSData dataWithContentsOfURL:qidoURL
                                                options:NSDataReadingUncached
                                                  error:&error];
     if (error)
     {
        LOG_ERROR(@"%@",[error description]);
         exit(0);
     }
     if (!qidoResponse)
     {
        LOG_WARNING(@"no answer to qido");
         exit(0);
     }
     if (![qidoResponse length]) exit(0);


      NSArray *list = [NSJSONSerialization JSONObjectWithData:qidoResponse options:0 error:&error];
      if (!list)
      {
          LOG_ERROR(@"qido response not json. %@ %@",[error description],[[NSString alloc]initWithData:qidoResponse encoding:NSUTF8StringEncoding] );
          exit(1);
      }
     
     
      for (NSDictionary *instance in list)
      {
#pragma mark - loop StudyInstanceUIDs
          
          NSString *EUID=[[[instance objectForKey:@"0020000D"]objectForKey:@"Value"]firstObject];
          NSString *EUIDpath=[[DApath stringByAppendingPathComponent:@"EUID"] stringByAppendingPathComponent:EUID];
          
          if([fileManager fileExistsAtPath:[EUIDpath stringByAppendingPathComponent:@"wl.xml"]]) continue;//WorkItem (wl.xml) already downloaded
          
          if(![fileManager fileExistsAtPath:EUIDpath] && ![fileManager createDirectoryAtPath:EUIDpath withIntermediateDirectories:YES attributes:nil error:nil])
          {
              LOG_ERROR(@"could not create folder %@", EUIDpath);
              continue;
          }
          else
          {
#pragma mark AccessionNumber
              //        /AccessionNumber[^[localIssuer][^universalIssuer]]
              //                /symlink StudyInstanceUID -> StudyInstanceUID
              
              NSString *ANIsuffix=nil;
              NSString *ANL=[[[instance objectForKey:@"00080051.00400031"]objectForKey:@"Value"]firstObject];
              NSString *ANU=[[[instance objectForKey:@"00080051.00400032"]objectForKey:@"Value"]firstObject];
              if (ANL && ANU) ANIsuffix=[NSString stringWithFormat:@"^%@^%@",ANL,ANU];
              else if (ANL)   ANIsuffix=[NSString stringWithFormat:@"^%@",ANL];
              else if (ANU)   ANIsuffix=[NSString stringWithFormat:@"^%@",ANU];
              else            ANIsuffix=@"";
              NSString *AN=[[[[instance objectForKey:@"00080050"]objectForKey:@"Value"]firstObject]stringByAppendingString:ANIsuffix];
              NSString *ANpath=[[DApath stringByAppendingPathComponent:@"AN"] stringByAppendingPathComponent:AN];
              if(![fileManager fileExistsAtPath:ANpath])
              {
                  if(![fileManager createDirectoryAtPath:ANpath withIntermediateDirectories:YES attributes:nil error:nil])
                  {
                      LOG_ERROR(@"could not create folder %@", ANpath);
                      continue;
                  }
              }
              if (![fileManager createSymbolicLinkAtPath:[ANpath stringByAppendingPathComponent:EUID] withDestinationPath:EUIDpath error:&error])
              {
                  LOG_ERROR(@"could not create AccessionNumber symlink %@ to %@. %@",AN, EUIDpath, [error description]);
                  continue;
              }

#pragma mark PatientID
              //        /PatientID[^issuer]
              //                /symlink StudyInstanceUID -> StudyInstanceUID

              NSString *PIDIsuffix=nil;
              NSString *PIDI=[[[instance objectForKey:@"00100021"]objectForKey:@"Value"]firstObject];
              if (PIDI) PIDIsuffix=[NSString stringWithFormat:@"^%@",PIDI];
              else      PIDIsuffix=@"";
              NSString *PID=[[[[instance objectForKey:@"00100020"]objectForKey:@"Value"]firstObject]stringByAppendingString:PIDIsuffix];
              NSString *PIDpath=[[DApath stringByAppendingPathComponent:@"PID"]stringByAppendingPathComponent:PID];
              if(![fileManager fileExistsAtPath:PIDpath])
              {
                  if(![fileManager createDirectoryAtPath:PIDpath withIntermediateDirectories:YES attributes:nil error:nil])
                  {
                      LOG_ERROR(@"could not create folder %@", PIDpath);
                      continue;
                  }
              }
              if (![fileManager createSymbolicLinkAtPath:[PIDpath stringByAppendingPathComponent:EUID] withDestinationPath:EUIDpath error:&error])
              {
                  LOG_ERROR(@"could not create PatientID symlink %@ to %@. %@",PID, EUIDpath, [error description]);
                  continue;
              }
          }
         
#pragma mark download details
          NSString *RetrieveString=[[[instance objectForKey:@"00081190"]objectForKey:@"Value"]firstObject];
          if (RetrieveString)
          {
              NSData *downloaded=[NSData dataWithContentsOfURL:[NSURL URLWithString:RetrieveString]];
              if (!downloaded || ![qidoResponse length])
              {
                  LOG_WARNING(@"NO response to %@",RetrieveString);
                  continue;
              }
              
              //unzip
              NSError *error=nil;
              ZZArchive *archive = [ZZArchive archiveWithData:downloaded];
              ZZArchiveEntry *firstEntry = archive.entries[0];
              NSData *unzipped = [firstEntry newDataWithError:&error];
              if (error!=nil)
              {
                  LOG_WARNING(@"could NOT unzip %@",RetrieveString);
                  continue;
              }
              
              //get CDA: 00420011
              NSRange range00420011=[unzipped rangeOfData:[NSData dataWithBytes:(void*)&tag00420011 length:8]
                                                  options:0
                                                    range:NSMakeRange(0,[unzipped length])];
              if (range00420011.location==NSNotFound)
              {
                  LOG_WARNING(@"NO contiene attr 00420011: %@",RetrieveString);
                  continue;
              }
              //get CDA: 00420011.length
              uint32 capsuleLength=0x00000000;
              [unzipped getBytes:&capsuleLength range:NSMakeRange(range00420011.location+8,4)];
              
              unsigned char padded=0xFF;
              [unzipped getBytes:&padded range:NSMakeRange(range00420011.location+12+capsuleLength-1,1)];
              NSData *encapsulatedData=[[NSData alloc]initWithData:[unzipped subdataWithRange:NSMakeRange(range00420011.location+12,capsuleLength-(padded==0))]];
              
              if (!encapsulatedData)
              {
                  LOG_WARNING(@"attr 00420011 empty: %@",RetrieveString);
                  continue;
              }
              
              NSXMLDocument *xmlDocument = [[NSXMLDocument alloc]initWithData:encapsulatedData options:0 error:&error];
              if (!xmlDocument)
              {
                  LOG_WARNING(@"00420011 NOT xml %@\r%@",RetrieveString,[error description]);
                  continue;
              }
#pragma mark write cda.xml
              NSString *cdapath=[EUIDpath stringByAppendingPathComponent:@"cda.xml"];
              [[xmlDocument XMLData] writeToFile:cdapath atomically:NO];
              
#pragma mark write wl.json
              //transform CDA 2 WorkItem (wl) json contextualkey-values
              id wl = [xmlDocument objectByApplyingXSLT:xslt1Data
                                                       arguments:DAargdict
                                                           error:&error];
              if (!wl)
              {
                  LOG_WARNING(@"could not transform %@ to wl.json\r%@",cdapath,[error description]);
                  continue;
              }
              
              if (![wl isKindOfClass:[NSData class]])
              {
                  LOG_WARNING(@"xslt1 on %@ did not output data file",cdapath);
                  continue;
              }

              NSString *wlpath=[EUIDpath stringByAppendingPathComponent:@"wl.json"];
              [wl writeToFile:wlpath atomically:NO];

#pragma mark serialize wl json data to dicom
              NSDictionary *json=[NSJSONSerialization JSONObjectWithData:wl options:0 error:&error];
              if (!json)
              {
                  LOG_WARNING(@"ERROR reading %@: %@",wlpath,[error description]);
                  continue;
              }

              NSMutableData *dicomData=[NSMutableData data];
              int result=dict2D(@"", json, dicomData, 0, @{});
              
              [dicomData writeToFile:[NSString stringWithFormat:@"%@/%@.wl",aetscppath,EUID] atomically:NO];

          }
     }
  }
  return 0;
}
