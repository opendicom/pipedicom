#import <Foundation/Foundation.h>
#import "ODLog.h"
#import "dict2D.h"

//J2D
//stdin mapxmldicom JSON (DICOM_contextualizedKey-values)
//stdout binary dicom
//https://raw.githubusercontent.com/jacquesfauquex/DICOM_contextualizedKey-values/master/mapxmldicom/mapxmldicom.xsd


int main(int argc, const char * argv[]) {
   @autoreleasepool {

      NSFileManager *fileManager=[NSFileManager defaultManager];
      NSProcessInfo *processInfo=[NSProcessInfo processInfo];

#pragma mark - args
      NSString *originalPath=nil;
      NSString *bulkdataPath=nil;
      NSData *inputData=nil;
      NSArray *args=[processInfo arguments];
      switch (args.count) {
         case 1:
            {
               NSMutableData *concatenateData=[NSMutableData data];
               NSFileHandle *readingFileHandle=[NSFileHandle fileHandleWithStandardInput];
               NSData *moreData;
               while ((moreData=[readingFileHandle availableData]) && moreData.length) [concatenateData appendData:moreData];
               inputData=[NSData dataWithData:concatenateData];
               bulkdataPath=[fileManager currentDirectoryPath];
               break;
            }
            
         case 2:
            {
               originalPath=[[args[1] stringByResolvingSymlinksInPath]stringByExpandingTildeInPath];
               inputData=[NSData dataWithContentsOfFile:args[1]];
               bulkdataPath=[[originalPath stringByDeletingPathExtension]stringByAppendingPathExtension:@"bulkdata"];
               break;
            }
              
          case 3://test name
          {
              if ([args[1] isEqualToString:@"test"])
              {
                 originalPath=[[@"~/Library/Frameworks/DCKV.framework/Resources/"stringByExpandingTildeInPath]stringByAppendingPathComponent:args[2]];
                  if ([fileManager fileExistsAtPath:originalPath]) inputData=[NSData dataWithContentsOfFile:originalPath];
                 bulkdataPath=[[originalPath stringByDeletingPathExtension]stringByAppendingPathExtension:@"bulkdata"];
              }
              break;
          }

         default:
            NSLog(@"bad syntaxis. Look at README.md");
            return 1;
      }

#pragma mark environment

      NSDictionary *environment=processInfo.environment;
      
#pragma mark J2DlogLevel
      if (environment[@"J2DlogLevel"])
      {
         NSUInteger logLevel=[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:environment[@"J2DlogLevel"]];
         if (logLevel!=NSNotFound) ODLogLevel=(ODLogLevelEnum)logLevel;
         else ODLogLevel=4;//ERROR (default)
      }
      else ODLogLevel=4;//ERROR (default)
      
      
#pragma mark J2DlogPath (only in /Volumes/LOG)
      NSString *logPath=environment[@"J2DlogPath"];
      if (logPath && [logPath hasPrefix:@"/Volumes/LOG"])
      {
         if ([logPath hasSuffix:@".log"])
            freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
         else freopen([[logPath stringByAppendingPathExtension:@".log"] cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      }
      else if ([[NSFileManager defaultManager]fileExistsAtPath:@"/Volumes/LOG"]) freopen([@"/Volumes/LOG/J2D.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      else freopen([@"/Users/Shared/J2D.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);

      
#pragma mark - processing
      NSError *error=nil;
      NSDictionary *inputDict=[NSJSONSerialization JSONObjectWithData:inputData options:0 error:&error];
      if (!inputDict)
      {
         LOG_WARNING(@"no JSON object received %@",[error description]);
         return 1;
      }
 
      
#pragma mark concatenate datasets
      NSMutableDictionary *datasets=[NSMutableDictionary dictionary];
      for (id obj in [inputDict allValues])
      {
         if ([obj isKindOfClass:[NSDictionary class]]) [datasets addEntriesFromDictionary:obj];
      }


#pragma mark initiate outputDdata (with or without group 2)
      NSMutableData *outputData;
      
      NSArray *tsArray=datasets[@"00000001_00020010-UI"];
      BOOL native=(!tsArray || [tsArray[0] isEqualToString:@"1.2.840.10008.1.2.1"]);
      //group 2 ?
      if (datasets[@"00000001_00020003-UI"])
      {
         [datasets removeObjectForKey:@"00000001_00020000-UL"];//group length will be recalculated later
         
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
         if (!dict2D(filemetainfoDict,filemetainfoData,true,bulkdataPath))
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
      if (dict2D(datasets,outputData,native,bulkdataPath)) [outputData writeToFile:@"/dev/stdout" atomically:NO];
   }//end autorelease pool
   return 0;
}
