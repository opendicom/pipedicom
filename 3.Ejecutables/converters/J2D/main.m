#import <Foundation/Foundation.h>
#import "ODLog.h"
#import <DCKV/DCKV.h>

//J2D
//https://raw.githubusercontent.com/jacquesfauquex/DICOM_contextualizedKey-values/master/mapxmldicom/mapxmldicom.xsd



int main(int argc, const char * argv[]) {
   @autoreleasepool {
      
      NSProcessInfo *processInfo=[NSProcessInfo processInfo];
      
//logs
      NSDictionary *environment=processInfo.environment;
      if (environment[@"J2DlogLevel"])
      {
         NSUInteger logLevel=[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:environment[@"J2DlogLevel"]];
         if (logLevel!=NSNotFound) ODLogLevel=(ODLogLevelEnum)logLevel;
         else ODLogLevel=4;//ERROR (default)
      }
      else ODLogLevel=4;//ERROR (default)

      FILE *fp;
      fp=freopen([@"/Users/Shared/DinlineJ.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);

      NSMutableData *inputData=[NSMutableData data];


      /*//stdin
      NSFileHandle *readingFileHandle=[NSFileHandle fileHandleWithStandardInput];
     NSData *moreData;
      while ((moreData=[readingFileHandle availableData]) && moreData.length) [inputData appendData:moreData];
      */
      [inputData appendData:[NSData dataWithContentsOfFile:@"/Users/Shared/D/CT1.ele.json"]];
      
      NSError *error=nil;
      NSDictionary *inputDict=[NSJSONSerialization JSONObjectWithData:inputData options:0 error:&error];
      if (!inputDict)
      {
         LOG_WARNING(@"no JSON object received %@",[error description]);
         fclose(fp);
         return 1;
      }

      
//args
      NSArray *args=[processInfo arguments];
      NSUInteger pixelMode;//dicomExplicitPixelMode
      if (args.count == 1)
      {
         if (inputDict[@"j2k"]) pixelMode=dicomExplicitJ2kIdem;
         else pixelMode=dicomExplicit;
      }
      else //args.count > 1
      {
         if (inputDict[@"j2k"]) pixelMode=[@[@"dcmexplicit",@"dcmj2kbase",@"dcmj2kfast",@"dcmj2khres",@"dcmj2kidem"] indexOfObject:args[1]];
         else pixelMode=dicomExplicit;
      }
 
      
#pragma mark concatenate datasets
      NSMutableDictionary *datasets=[NSMutableDictionary dictionaryWithDictionary:inputDict[@"dataset"]];

      if (pixelMode==dicomExplicit)
      {
         if (inputDict[@"native"]) [datasets addEntriesFromDictionary:inputDict[@"native"]];
      }
      else if (pixelMode==dicomExplicitJ2kIdem)
      {
         if (inputDict[@"j2k"]) [datasets addEntriesFromDictionary:inputDict[@"j2k"]];
      }
      else
      {
         [datasets setObject:@[@"1.2.840.10008.1.2.4.91"] forKey:@"00000001_00020010-UI"];
         [datasets setObject:@[[inputDict[@"j2k"][@"00000001_00082111-ST"][0] substringFromIndex:9]] forKey:@"00000001_00082111-ST"];//remove "lossless"
         [datasets setObject:inputDict[@"j2k"][@"00000001_7FE00010-OB"] forKey:@"00000001_7FE00010-OB" ];

         NSMutableArray *frames=[NSMutableArray array];
         switch (pixelMode) {
            case dicomExplicitJ2kBase:
            {
               [datasets setObject:@[@"dcmj2kbase; first quality layer (compression factor 50)"] forKey:@"00000001_00204000-2006LT"];
               /*
               for (NSDictionary *frameDict in inputDict[@"j2k"][@"00000001_7FE00010-OB"])
               {
                  NSMutableArray *urls=[NSMutableArray array];
                  NSString *frameName=[frameDict allKeys][0];
                  for (NSString *urlString in frameDict[frameName])
                  {
                     if ([urlString hasSuffix:@"j2kbase"]) [urls addObject:urlString];
                  }
                  [frames addObject:@{ frameName : urls }];
               }
                */

            }
               break;
               
            case dicomExplicitJ2kFast:
            {
               [datasets setObject:@[@"dcmj2kfast; first two quality layers (compression factor 20)"] forKey:@"00000001_00204000-2006LT"];
               /*
               for (NSDictionary *frameDict in inputDict[@"j2k"][@"00000001_7FE00010-OB"])
               {
                  NSMutableArray *urls=[NSMutableArray array];
                  NSString *frameName=[frameDict allKeys][0];
                  for (NSString *urlString in frameDict[frameName])
                  {
                     if ([urlString hasSuffix:@"j2kbase"]) [urls addObject:urlString];
                     if ([urlString hasSuffix:@"j2kfast"]) [urls addObject:urlString];
                  }
                  [frames addObject:@{ frameName : urls }];
               }
                */
            }
               break;
               
            case dicomExplicitJ2kHres:
            {
               [datasets setObject:@[@"dcmj2khres; first three quality layer (compression factor 10)"] forKey:@"00000001_00204000-2006LT"];
               /*
               for (NSDictionary *frameDict in inputDict[@"j2k"][@"00000001_7FE00010-OB"])
               {
                  NSMutableArray *urls=[NSMutableArray array];
                  NSString *frameName=[frameDict allKeys][0];
                  for (NSString *urlString in frameDict[frameName])
                  {
                     if ([urlString hasSuffix:@"j2kbase"]) [urls addObject:urlString];
                     if ([urlString hasSuffix:@"j2kfast"]) [urls addObject:urlString];
                     if ([urlString hasSuffix:@"j2khres"]) [urls addObject:urlString];
                  }
                  [frames addObject:@{ frameName : urls }];
               }
                */
            }
               break;
         }
         
         //[datasets setObject:frames forKey:@"00000001_7FE00010-OB"];

      }


#pragma mark initiate outputDdata (with or without group 2)
      NSMutableData *outputData;
      
      //group 2 ?
      if (datasets[@"00000001_00020003-UI"])
      {
         NSMutableDictionary *filemetainfoDict=[NSMutableDictionary dictionary];
         NSArray *keys=[datasets allKeys];
         for (NSString *key in keys)
         {
            if ([key hasPrefix:@"00000001_0002"])
            {
               [filemetainfoDict setObject:datasets[key] forKey:key];
               [datasets removeObjectForKey:key];
            }
         }
         
         NSMutableData *filemetainfoData=[NSMutableData data];
         if (dict2D(environment[@"PWD"],filemetainfoDict,filemetainfoData,pixelMode,nil) == failure)
         {
            LOG_ERROR(@"could not serialize group 0002. %@",filemetainfoDict);
            return 0;//failed
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

      
      //serialize and append datasets
      if (dict2D(environment[@"PWD"],datasets,outputData,pixelMode,nil)==success)
         [outputData writeToFile:@"/Users/Shared/j2k.dcm" atomically:NO];
//         [outputData writeToFile:@"/dev/stdout" atomically:NO];
   }//end autorelease pool
   return 0;
}
