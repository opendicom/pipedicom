#import <Foundation/Foundation.h>
#import <DCKV/DCKV.h>

//D2J [$originalPath | test $testName]
//stdin binary dicom
//stdout DCKV JSON (DICOM_contextualizedKey-values)
//https://raw.githubusercontent.com/jacquesfauquex/DICOM_contextualizedKey-values/master/mapxmldicom/mapxmldicom.xsd


int main(int argc, const char * argv[]) {
   @autoreleasepool {

      NSFileManager *fileManager=[NSFileManager defaultManager];
      NSProcessInfo *processInfo=[NSProcessInfo processInfo];
      
#pragma mark - args
      NSString *originalPath;
      NSData *inputData;
      NSArray *args=[processInfo arguments];
      switch (args.count) {
         case 1://stdin
         {
            NSMutableData *concatenateData=[NSMutableData data];
            NSFileHandle *readingFileHandle=[NSFileHandle fileHandleWithStandardInput];
            NSData *moreData;
            while ((moreData=[readingFileHandle availableData]) && moreData.length) [concatenateData appendData:moreData];
            inputData=[NSData dataWithData:concatenateData];
            break;
         }
              
          case 2://file path
          {
            originalPath=[[args[1] stringByResolvingSymlinksInPath]stringByExpandingTildeInPath];
            inputData=[NSData dataWithContentsOfFile:args[1]];
            break;
          }
              
          case 3://test name
          {
              if ([args[1] isEqualToString:@"test"])
              {
                  NSString *testPath;
                  if ([fileManager fileExistsAtPath:[@"~/Library/Frameworks/DCKV.framework"stringByExpandingTildeInPath]]) testPath=[[@"~/Library/Frameworks/DCKV.framework/Resources/"stringByExpandingTildeInPath]stringByAppendingPathComponent:args[2]];
                  else testPath=[@"/Library/Frameworks/DCKV.framework/Resources/"stringByAppendingPathComponent:args[2]];
                  if ([fileManager fileExistsAtPath:testPath])
                  {
                     inputData=[NSData dataWithContentsOfFile:testPath];
                     originalPath=testPath;
                  }
              }
              break;
          }


         default:
            NSLog(@"syntaxis: D2J [$originalPath | test $testName]");
            return 1;
      }

#pragma mark - environment

      NSDictionary *environment=processInfo.environment;
      
#pragma mark D2JlogLevel
      if (environment[@"D2JlogLevel"])
      {
         NSUInteger logLevel=[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:environment[@"D2JlogLevel"]];
         if (logLevel!=NSNotFound) ODLogLevel=(ODLogLevelEnum)logLevel;
         else ODLogLevel=4;//ERROR (default)
      }
      else ODLogLevel=4;//ERROR (default)
      
      
#pragma mark D2JlogPath (only in /Volumes/LOG)
      NSString *logPath=environment[@"D2JlogPath"];
       
      if (logPath && [logPath hasPrefix:@"/Volumes/LOG"])
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
      int blobMode=0;//defaults to blob_inline
      NSString *blobModeString=environment[@"D2JblobMode"];
      NSMutableDictionary *blobDict=nil;

      if (blobModeString)
      {
         if ([blobModeString isEqualToString:@"blob_sourcePointer"]) blobMode=1;
         else if ([blobModeString isEqualToString:@"blob_dict"])
         {
            blobMode=2;
            blobDict=[NSMutableDictionary dictionary];
         }
      }

#pragma mark D2JblobRefPrefix
      NSString *blobRefPrefix;
      switch (blobMode) {
         case blob_inline:
            blobRefPrefix=environment[@"D2JblobRefPrefix"];
            break;
         case blob_sourcePointer:
            blobRefPrefix=originalPath;
            break;
         case blob_dict:
            if (originalPath) blobRefPrefix=[[originalPath lastPathComponent]stringByAppendingPathExtension:@"bulkdata"];
            break;
      }

#pragma mark D2JblobRefSuffix
      NSString *blobRefSuffix=environment[@"D2JblobRefSuffix"];


      LOG_DEBUG(@"environment:\r%@",[environment description]);


#pragma mark - processing
      NSMutableDictionary *attrDict=[NSMutableDictionary dictionary];
      if (D2dict(
                 inputData,
                 attrDict,
                 blobMinSize,
                 blobMode,
                 blobRefPrefix,
                 blobRefSuffix,
                 blobDict
                 )
          )
      {
         NSError *error;
#pragma mark - JSON serializing
         //NSData *JSONdata=[NSJSONSerialization dataWithJSONObject:@{@"dataset":dict} options:NSJSONWritingSortedKeys error:&error];//10.15 || NSJSONWritingWithoutEscapingSlashes

         NSMutableString *JSONstring=[NSMutableString stringWithString:@"{ \"dataset\": { "];
         NSArray *keys=[[attrDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
         
         
#pragma mark loop on ordered keys
         for (NSString *key in keys)
         {
            LOG_DEBUG(@"%@",key);
            [JSONstring appendFormat:@"\"%@\": ",key];
            
            switch ([key characterAtIndex:key.length-2]+([key characterAtIndex:key.length-1]*0x100))
            {
               
#pragma mark · string based attributes
//AS DA AE DT TM CS LO LT PN SH ST PN UC UT UR UI OB OD OF OL OV OW UN AT
               case 0x5341://AS
               case 0x4144://DA
               case 0x4541://AE
               case 0x5444://DT
               case 0x4d54://TM
               case 0x5343://CS
               case 0x4f4c://LO
               case 0x544c://LT
               case 0x4853://SH
               case 0x5453://ST
               case 0x4e50://PN
               case 0x4355://UC
               case 0x5455://UT
               case 0x5255://UR
               case 0x4955://UI
               case 0x5441://AT
               {
                  switch ([attrDict[key] count]) {
                     case 0:
                     {
                        [JSONstring appendString:@"[], "];
                        break;
                     }

                     case 1:
                     {
                        [JSONstring appendFormat:@"[ \"%@\" ], ",
                         (attrDict[key])[0]];
                        break;
                     }

                     default:
                     {
                        [JSONstring appendString:@"[ "];
                        for (NSString *string in attrDict[key])
                        {
                           [JSONstring appendFormat:@"\"%@\", ",
                            string];
                        }
                        [JSONstring deleteCharactersInRange:NSMakeRange(JSONstring.length-2,2)];
                        [JSONstring appendString:@"], "];

                        break;
                     }
                  }
                  
                  break;
               }
                  
                  
#pragma mark · string or map based
               case 0x424F://OB
               case 0x444F://OD
               case 0x464F://OF
               case 0x4C4F://OL
               case 0x564F://OV
               case 0x574F://OW
               case 0x4E55://UN
               {
                  switch ([attrDict[key] count]) {
                     case 0:
                     {
                        [JSONstring appendString:@"[], "];
                        break;
                     }

                     case 1:
                     {
                        id obj=(attrDict[key])[0];
                        if ([obj isKindOfClass:[NSString class]])
                        {
                           [JSONstring appendFormat:@"[ \"%@\" ], ",
                         obj];
                        }
                        else //@[@{ @"BulkData":urlString}]
                        {
                           NSString *subKey=([obj allKeys])[0];
                           [JSONstring appendFormat:@"[ { \"%@\": \"%@\" } ], ",subKey, obj[subKey]];
                        }
                        break;
                     }

                     default://more than one value
                     {
                        [JSONstring appendString:@"[ "];
                        id obj=(attrDict[key])[0];
                        if ([obj isKindOfClass:[NSString class]])
                        {
                           for (NSString *string in attrDict[key])
                           {
                              [JSONstring appendFormat:@"\"%@\", ",
                               string];
                           }
                           [JSONstring deleteCharactersInRange:NSMakeRange(JSONstring.length-2,2)];
                           [JSONstring appendString:@" ], "];
                        }
                        else //@[@{ @"BulkData":urlString}]
                        {
                           for (NSDictionary *d in attrDict[key])
                           {
                              NSString *subKey=([d allKeys])[0];
                              [JSONstring appendFormat:@"{ \"%@\": \"%@\" }, ",subKey, d[subKey]];
                           }
                           [JSONstring deleteCharactersInRange:NSMakeRange(JSONstring.length-2,2)];
                           [JSONstring appendString:@"], "];
                        }
                        break;
                     }
                  }
                  break;
               }
                  
                  
#pragma mark · null based
//SQ IQ IZ SZ
               case 0x5153://SQ
               case 0x5149://IQ
               case 0x5A49://IZ
               case 0x5A53://SZ
               {
                  [JSONstring appendString:@"null, "];
                  break;
               }

                  
#pragma mark · number based attributes
//IS DS SL UL SS US SV UV FL FD
               case 0x5349://IS
               case 0x5344://DS
               case 0x4C53://SL
               case 0x4C55://UL
               case 0x5353://SS
               case 0x5355://US
               case 0x5653://SV
               case 0x5655://UV
               case 0x4C46://FL
               case 0x4446://FD
               {
                  switch ([attrDict[key] count]) {
                     case 0:
                     {
                        [JSONstring appendString:@"[], "];
                        break;
                     }

                     case 1:
                     {
                        [JSONstring appendFormat:@"[ %@ ], ",
                         (attrDict[key])[0]];
                        break;
                     }

                     default:
                     {
                        [JSONstring appendString:@"[ "];
                        for (NSString *string in attrDict[key])
                        {
                           [JSONstring appendFormat:@"%@, ",
                            string];
                        }
                        [JSONstring deleteCharactersInRange:NSMakeRange(JSONstring.length-2,2)];
                        [JSONstring appendString:@"], "];

                        break;
                     }
                  }
                  break;
               }
            }
         }
         [JSONstring deleteCharactersInRange:NSMakeRange(JSONstring.length-2,2)];
         [JSONstring appendString:@" } }"];

         NSData *JSONdata=[JSONstring dataUsingEncoding:NSUTF8StringEncoding];
         
         
         NSString *D2JoutputDir=environment[@"D2JoutputDir"];
         if (!JSONdata)
         {
            LOG_ERROR(@"could not transform to JSON: %@",[attrDict description]);
         }
         else if (!D2JoutputDir)
         {
            [JSONdata writeToFile:@"/dev/stdout" atomically:NO];
#pragma mark TODO transformar json y blob dict a zip
         }
         else if (!originalPath || !relativePathComponents)
         {
            NSString *UUIDString=[[NSUUID UUID]UUIDString];
            [JSONdata writeToFile:[[D2JoutputDir stringByAppendingPathComponent:UUIDString]stringByAppendingPathExtension:@"json"] atomically:NO];
            if (blobDict.count)
            {
               NSString *bulkdataDir=[[D2JoutputDir stringByAppendingPathComponent:UUIDString]stringByAppendingPathExtension:@"bulkdata"];
               [fileManager createDirectoryAtPath:bulkdataDir withIntermediateDirectories:YES attributes:nil error:&error];
               for (NSString *bulkdataKey in blobDict)
               {
                  [blobDict[bulkdataKey] writeToFile:[bulkdataDir stringByAppendingPathComponent:bulkdataKey] atomically:NO];
               }
            }
         }
         else
         {
            NSMutableArray *originalPathComponents=[NSMutableArray arrayWithArray:[originalPath pathComponents]];

            if (![originalPathComponents[0] length])[originalPathComponents removeObjectAtIndex:0];//case of absolute paths
            while (relativePathComponents < originalPathComponents.count)
            {
               [originalPathComponents removeObjectAtIndex:0];
            }
            NSString *outputPath=[[[D2JoutputDir stringByAppendingPathComponent:[originalPathComponents componentsJoinedByString:@"/"]]stringByDeletingPathExtension]stringByAppendingPathExtension:@"json"];
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
                  [blobDict[bulkdataKey] writeToFile:[bulkdataDir stringByAppendingPathComponent:bulkdataKey] atomically:NO];
               }
            }

         }
         
         
      }
   }//end autorelease pool
   return 0;
}
