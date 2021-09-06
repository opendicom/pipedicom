#import <Foundation/Foundation.h>
#import <DCKV/DCKV.h>
#import "dict2D.h"

//J2D
//https://raw.githubusercontent.com/jacquesfauquex/DICOM_contextualizedKey-values/master/mapxmldicom/mapxmldicom.xsd



int main(int argc, const char * argv[]) {
@autoreleasepool {
   
NSError *error=nil;
NSProcessInfo *processInfo=[NSProcessInfo processInfo];
NSArray *args=[processInfo arguments];
NSDictionary *environment=processInfo.environment;
NSString *PWD;
   
#pragma mark env
   
if (environment[@"J2DLogLevel"])
{
   NSUInteger logLevel=[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:environment[@"J2DLogLevel"]];
   if (logLevel!=NSNotFound) ODLogLevel=(ODLogLevelEnum)logLevel;
   else ODLogLevel=4;//ERROR (default)
}
else ODLogLevel=4;//ERROR (default)

   
#pragma mark stdin
   
NSMutableData *inputData=[NSMutableData data];
if (args.count==3)//EDCKV filePath es args[2]
{
   NSData *pathData=[NSData dataWithContentsOfFile:[args[2] stringByExpandingTildeInPath]];
   if (!pathData)
   {
      LOG_ERROR(@"bad path: %@",pathData);
      return 1;
   }
   [inputData appendData:pathData];
   PWD=[args[2] stringByDeletingLastPathComponent];//for file path JSON, relative resource paths are from the containing folder of file path JSON
}
else //using stdin
{
   NSFileHandle *readingFileHandle=[NSFileHandle fileHandleWithStandardInput];
   NSData *moreData;
   while ((moreData=[readingFileHandle availableData]) && moreData.length) [inputData appendData:moreData];
   [readingFileHandle closeFile];

   char firstByte=0;
   [inputData getBytes:&firstByte length:1];
   if (firstByte == '{') PWD=environment[@"PWD"];//for JSON stdin, relative resource paths are from PWD
   else
   {
      //this is not a json
      NSString *inputDataString=[[NSString alloc]initWithData:inputData encoding:NSUTF8StringEncoding];
      if (![[NSFileManager defaultManager] fileExistsAtPath:inputDataString])
      {
         LOG_WARNING(@"stdin not JSON nor path");
         return 1;
      }
      [inputData setData:[NSData dataWithContentsOfFile:inputDataString]];
      [inputData getBytes:&firstByte length:1];
      if (firstByte != '{')
      {
         LOG_WARNING(@"stdin path does not contain a JSON at byte 0");
         return 1;
      }
      PWD=[inputDataString stringByDeletingLastPathComponent];//for file path JSON, relative resource paths are from the containing folder of file path JSON
   }
}

NSDictionary *inputDict=[NSJSONSerialization JSONObjectWithData:inputData options:0 error:&error];
if (!inputDict)
{
   LOG_WARNING(@"malformed stdin JSON: %@",[error description]);
   return 1;
}


#pragma mark args
   
NSUInteger pixelMode;
switch (args.count) {
   case 1:
      pixelMode=4;//idem;
      break;
      
   case 2:
   case 3:
   {
      pixelMode=[@[@"native",@"j2kbase",@"j2kfast",@"j2khres",@"idem",@"jpeg50"] indexOfObject:args[1]];
      if (pixelMode==NSNotFound) pixelMode=4;//idem;
   }
      break;
      
   default:
      LOG_ERROR(@"syntax: J2D [ native | j2kbase | j2kfast | j2khres | idem | jpeg50 ] [ path ] ");
      return 1;
}
   
#pragma mark concatenate dataset
NSMutableDictionary *dataset=[NSMutableDictionary dictionaryWithDictionary:inputDict[@"dataset"]];

//incorporate non pixel mode datasets
NSArray *inputDictSets=[inputDict allKeys];
for (NSString *inputDictSet in inputDictSets)
{
   //this set is treated separately
   if ([inputDictSet isEqualToString:@"filemetainfo"]) continue;

   //we have uncompressed pixels. Do we need them?
   if ([inputDictSet isEqualToString:@"native"])
   {
      if (pixelMode!=0)//the request is not for native pixels
      {
         if (pixelMode<5)//the request is for a j2k
         {
            if (inputDict[@"j2k"]) continue;//there is a j2k source
            if (inputDict[@"filemetainfo"])
            {
               if (![inputDict[@"filemetainfo"][@"00000001_00020010-UI"][0] isEqualToString:@"1.2.840.10008.1.4.90"]) continue;
               else pixelMode=0;//idem is in fact native
            }
            else  continue;
         }
         else if (pixelMode!=0) continue;//native
      }
   }
   
   if ([inputDictSet isEqualToString:@"j2k"] && (pixelMode==0)) continue;//native
   
   
   if ([inputDict[inputDictSet] isKindOfClass:NSDictionary.class])
   {
      if ([inputDictSet isEqualToString:@"remove"])
      {
#pragma mark TODO remove
      }
      else
      {
#pragma mark TODO sequence intelligent add
         [dataset addEntriesFromDictionary:inputDict[@"native"]];
      }
   }
}
   
#pragma mark pixel mode j2k non reversible
if ((pixelMode==1)|| (pixelMode==2)|| (pixelMode==3))
{
   [dataset setObject:@[@"1.2.840.10008.1.2.4.91"] forKey:@"00000001_00020010-UI"];
   [dataset setObject:@[[inputDict[@"j2k"][@"00000001_00082111-ST"][0] substringFromIndex:9]] forKey:@"00000001_00082111-ST"];//remove "lossless"
   [dataset setObject:inputDict[@"j2k"][@"00000001_7FE00010-OB"] forKey:@"00000001_7FE00010-OB" ];

   switch (pixelMode) {
      case 1://j2kBase:
      {
         [dataset setObject:@[@"dcmj2kbase; first quality layer (compression factor 50)"] forKey:@"00000001_00204000-2006LT"];
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
         
      case 2://j2kFast:
      {
         [dataset setObject:@[@"dcmj2kfast; first two quality layers (compression factor 20)"] forKey:@"00000001_00204000-2006LT"];
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
         
      case 3://j2kHres:
      {
         [dataset setObject:@[@"dcmj2khres; first three quality layer (compression factor 10)"] forKey:@"00000001_00204000-2006LT"];
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
   
   //[dataset setObject:frames forKey:@"00000001_7FE00010-OB"];

}


#pragma mark group 2 ?
   
NSMutableDictionary *filemetainfoDict=[NSMutableDictionary dictionary];

// por separado dentro de filemetainfo
if (inputDict[@"filemetainfo"])
{
   [filemetainfoDict addEntriesFromDictionary:inputDict[@"filemetainfo"]];

   //remove filemetainfo from dataset
   NSArray *keys=[dataset allKeys];
   for (NSString *key in keys)
   {
      if ([key hasPrefix:@"00000001_0002"])
      {
         [dataset removeObjectForKey:key];
      }
   }
}
else //no separate filemetainfo
{
   if (dataset[@"00000001_00020003-UI"])
   {
      NSArray *keys=[dataset allKeys];
      for (NSString *key in keys)
      {
         if ([key hasPrefix:@"00000001_0002"])
         {
            [filemetainfoDict setObject:dataset[key] forKey:key];
            [dataset removeObjectForKey:key];
         }
      }
   }
}

#pragma mark TODO blobDict

#pragma mark outputData
NSMutableData *outputData;
if (filemetainfoDict.count)
{
   NSMutableData *filemetainfoData=[NSMutableData data];
   if (dict2D(PWD,filemetainfoDict,filemetainfoData,pixelMode,nil) == failure)
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
else //no filemetainfo
   outputData=[NSMutableData data];


//serialize and append dataset
if (dict2D(PWD,dataset,outputData,pixelMode,nil)==success)
   [outputData writeToFile:@"/Users/jacquesfauquex/Desktop/test.dcm" atomically:NO];
//         [outputData writeToFile:@"/dev/stdout" atomically:NO];
}//end autorelease pool
   return 0;
}
