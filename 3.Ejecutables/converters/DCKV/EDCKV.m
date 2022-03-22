#import "EDCKV.h"
#import "ODLog.h"
#import "dict2D.h"

NSString* EDCKVcompile(
   NSDictionary *EDCKV,
   int pixelMode,
   NSMutableDictionary *filemetainfo,
   NSMutableDictionary *dataset
)
{
   if (!EDCKV) return @"no EDCKV";

   
#pragma mark dict set
   NSArray *keys=[EDCKV allKeys];
   NSMutableSet *sets=[NSMutableSet set];
   for (NSString *key in keys)
   {
      if ([EDCKV[key] isKindOfClass:[NSDictionary class]])
         [sets addObject:key];
   }

   
#pragma mark ·dataset
   if (![sets containsObject:@"dataset"]) return @"no dataset";
   [dataset addEntriesFromDictionary:EDCKV[@"dataset"]];
   [sets removeObject:@"dataset"];

   
#pragma mark ·filemetainfo
   
   //from dataset
   if (dataset[@"00000001_00020003-UI"])
   {
      NSArray *keys=[dataset allKeys];
      for (NSString *key in keys)
      {
         if ([key hasPrefix:@"00000001_0002"])
         {
            [filemetainfo setObject:dataset[key] forKey:key];
            [dataset removeObjectForKey:key];
         }
      }
   }
   //from filemetainfo set
   if ([sets containsObject:@"filemetainfo"])
   {
      [sets removeObject:@"filemetainfo"];
      [filemetainfo addEntriesFromDictionary:EDCKV[@"filemetainfo"]];
   }

#pragma mark - pixel mode

#pragma mark · undf
   if (pixelMode==undf)
   {
      if ([sets containsObject:@"j2ki"]) pixelMode=j2ki;
      else if ([sets containsObject:@"j2kr"]) pixelMode=j2kr;
      else pixelMode=natv;
   }

#pragma mark · j2k
   if (pixelMode==j2ks)
   {
      if ([sets containsObject:@"j2kr"]) pixelMode=j2kr;
      else pixelMode=j2ki;
   }

#pragma mark other cases
   
   switch (pixelMode) {
         
#pragma mark · natv
      case natv:
      {
         if ([sets containsObject:@"natv"])
         {
            [dataset addEntriesFromDictionary:EDCKV[@"natv"]];
            [sets removeObject:@"natv"];
            if ([sets containsObject:@"j2ki"]) [sets removeObject:@"j2ki"];
            if ([sets containsObject:@"j2kr"]) [sets removeObject:@"j2kr"];
         }
         else if ([sets containsObject:@"j2ki"])
         {
            //uncompress
            [sets removeObject:@"j2ki"];
return @"j2ki decompression not implemented yet";
         }
         else if ([sets containsObject:@"j2kr"])
         {
            //uncompress
            [sets removeObject:@"j2kr"];
return @"j2kr decompression not implemented yet";
         }
         //no changes in relation to dataset
      }
         break;
         
#pragma mark · j2kb
      case j2kb:
      {
         if ([sets containsObject:@"j2ki"])
         {
            [filemetainfo setObject:@[@"1.2.840.10008.1.2.4.91"] forKey:@"00000001_00020010-UI"];
            
            [dataset
             setObject:@[[EDCKV[@"j2ki"][@"00000001_00082111-ST"][0] substringFromIndex:9]]
             forKey:@"00000001_00082111-ST"
             ];//remove "lossless"
            
            [dataset
             setObject:
              EDCKV[@"j2ki"][@"00000001_7FE00010-OB"]
             forKey:@"00000001_7FE00010-OB"
             ];
            
            [dataset setObject:@[@"j2kb; first quality layer (compression factor 50)"] forKey:@"00000001_00204000-2006LT"];

            NSMutableArray *frames=[NSMutableArray array];
            NSArray *frameDictArray=EDCKV[@"j2ki"][@"00000001_7FE00010-OB"];
            for (NSDictionary *frameDict in frameDictArray)
            {
               NSMutableArray *urls=[NSMutableArray array];
               NSString *frameName=[frameDict allKeys][0];
               for (NSString *urlString in frameDict[frameName])
               {
                  if ([urlString hasSuffix:@"j2kb"]) [urls addObject:urlString];
               }
               [frames addObject:@{ frameName : urls }];
            }
            [dataset setObject:frames forKey:@"00000001_7FE00010-OB"];
                        
            [sets removeObject:@"j2ki"];
            if ([sets containsObject:@"natv"])
               [sets removeObject:@"natv"];
            if ([sets containsObject:@"j2kr"])
               [sets removeObject:@"j2kr"];
         }
         else if ([sets containsObject:@"natv"])
         {
#pragma mark TODO compress
            [sets removeObject:@"natv"];
            return @"j2ki compression not implemented yet";
         }
         else if ([sets containsObject:@"j2kr"])
         {
#pragma mark TODO j2kr -> j2ki
            [sets removeObject:@"j2kr"];
            return @"j2kr -> j2ki not implemented yet";
         }
         else return @"j2ki not found for j2kb";
      }
         break;
         
#pragma mark · j2kf
      case j2kf:
      {
         if ([sets containsObject:@"j2ki"])
         {
            [filemetainfo setObject:@[@"1.2.840.10008.1.2.4.91"] forKey:@"00000001_00020010-UI"];
            
            [dataset
             setObject:@[[EDCKV[@"j2ki"][@"00000001_00082111-ST"][0] substringFromIndex:9]]
             forKey:@"00000001_00082111-ST"
             ];//remove "lossless"
            
            [dataset
             setObject:
              EDCKV[@"j2ki"][@"00000001_7FE00010-OB"]
             forKey:@"00000001_7FE00010-OB"
             ];
            
            [dataset setObject:@[@"j2kf; first two quality layers (compression factor 20)"] forKey:@"00000001_00204000-2006LT"];


            NSMutableArray *frames=[NSMutableArray array];
            NSArray *frameDictArray=EDCKV[@"j2ki"][@"00000001_7FE00010-OB"];
            for (NSDictionary *frameDict in frameDictArray)
            {
               NSMutableArray *urls=[NSMutableArray array];
               NSString *frameName=[frameDict allKeys][0];
               for (NSString *urlString in frameDict[frameName])
               {
                  if ([urlString hasSuffix:@"j2kb"]) [urls addObject:urlString];
                  if ([urlString hasSuffix:@"j2kf"]) [urls addObject:urlString];
               }
               [frames addObject:@{ frameName : urls }];
            }
            [dataset setObject:frames forKey:@"00000001_7FE00010-OB"];
            
            [sets removeObject:@"j2ki"];
            if ([sets containsObject:@"natv"])
               [sets removeObject:@"natv"];
            if ([sets containsObject:@"j2kr"])
               [sets removeObject:@"j2kr"];
         }
         else if ([sets containsObject:@"natv"])
         {
#pragma mark TODO compress
            [sets removeObject:@"natv"];
            return @"j2ki compression not implemented yet";
         }
         else if ([sets containsObject:@"j2kr"])
         {
#pragma mark TODO j2kr -> j2ki
            [sets removeObject:@"j2kr"];
            return @"j2kr -> j2ki not implemented yet";
         }
         else return @"j2ki not found for j2kFast";
      }
         break;
         
#pragma mark · j2kh
      case j2kh:
      {
         if ([sets containsObject:@"j2ki"])
         {
            [filemetainfo setObject:@[@"1.2.840.10008.1.2.4.91"] forKey:@"00000001_00020010-UI"];
            
            [dataset
             setObject:@[[EDCKV[@"j2ki"][@"00000001_00082111-ST"][0] substringFromIndex:9]]
             forKey:@"00000001_00082111-ST"
             ];//remove "lossless"
            
            [dataset
             setObject:
              EDCKV[@"j2ki"][@"00000001_7FE00010-OB"]
             forKey:@"00000001_7FE00010-OB"
             ];
            
            [dataset setObject:@[@"j2kh; first three quality layer (compression factor 10)"] forKey:@"00000001_00204000-2006LT"];

            NSMutableArray *frames=[NSMutableArray array];
            NSArray *frameDictArray=EDCKV[@"j2ki"][@"00000001_7FE00010-OB"];
            for (NSDictionary *frameDict in frameDictArray)
            {
               NSMutableArray *urls=[NSMutableArray array];
               NSString *frameName=[frameDict allKeys][0];
               for (NSString *urlString in frameDict[frameName])
               {
                  if ([urlString hasSuffix:@"j2kb"]) [urls addObject:urlString];
                  if ([urlString hasSuffix:@"j2kf"]) [urls addObject:urlString];
                  if ([urlString hasSuffix:@"j2kh"]) [urls addObject:urlString];
               }
               [frames addObject:@{ frameName : urls }];
            }
            [dataset setObject:frames forKey:@"00000001_7FE00010-OB"];
            
            [sets removeObject:@"j2ki"];
            if ([sets containsObject:@"natv"])
               [sets removeObject:@"natv"];
            if ([sets containsObject:@"j2kr"])
               [sets removeObject:@"j2kr"];
         }
         else if ([sets containsObject:@"natv"])
         {
#pragma mark TODO compress
            [sets removeObject:@"natv"];
            return @"j2ki compression not implemented yet";
         }
         else if ([sets containsObject:@"j2kr"])
         {
#pragma mark TODO j2kr -> j2ki
            [sets removeObject:@"j2kr"];
            return @"j2kr -> j2ki not implemented yet";
         }
         else return @"j2ki not found for j2kHres";
      }
         break;
         
#pragma mark · j2ki
      case j2ki:
      {
         if ([sets containsObject:@"j2ki"])
         {
            [dataset addEntriesFromDictionary:EDCKV[@"j2ki"]];
            [sets removeObject:@"j2ki"];
            if ([sets containsObject:@"natv"])
               [sets removeObject:@"natv"];
            if ([sets containsObject:@"j2kr"])
               [sets removeObject:@"j2kr"];
         }
         else if ([sets containsObject:@"natv"])
         {
#pragma mark TODO compress
            [sets removeObject:@"natv"];
            return @"j2ki compression not implemented yet";
         }
         else if ([sets containsObject:@"j2kr"])
         {
#pragma mark TODO j2kr -> j2ki
            [sets removeObject:@"j2kr"];
            return @"j2kr -> j2ki not implemented yet";
         }
         else return @"j2ki not found";
      }
         break;
         
#pragma mark · j2kr
      case j2kr:
      {
         if ([sets containsObject:@"j2kr"])
         {
            [dataset addEntriesFromDictionary:EDCKV[@"j2kr"]];
            [sets removeObject:@"j2kr"];
            if ([sets containsObject:@"natv"])
               [sets removeObject:@"natv"];
            if ([sets containsObject:@"j2ki"])
               [sets removeObject:@"j2ki"];
         }
         else if ([sets containsObject:@"j2ki"])
         {
#pragma mark TODO j2ki -> j2kr
            [sets removeObject:@"j2ki"];
            return @"j2ki -> j2kr not implemented yet";
         }
         else if ([sets containsObject:@"natv"])
         {
#pragma mark TODO compress
            [sets removeObject:@"natv"];
            return @"j2kr compression not implemented yet";
         }
         else return @"j2kr not found";
      }
         break;
   }

   
#pragma mark other sets into dataset
   if ([sets containsObject:@"remove"])
      [sets removeObject:@"remove"];
   
   for (NSString *set in sets)
   {
      [dataset addEntriesFromDictionary:EDCKV[set]];
   }
   
#pragma mark remove
   if (EDCKV[@"remove"])
   {
      NSArray *datasetKeys=[dataset allKeys];
      NSArray *removeKeys=[EDCKV[@"remove"] allKeys];
      for (NSString *removeKey in removeKeys)
      {
         NSString *noSuffix=[removeKey componentsSeparatedByString:@"-"][0];
         for (NSString *datasetKey in datasetKeys)
         {
            if ([datasetKey hasPrefix:noSuffix])
               [dataset removeObjectForKey:datasetKey];
         }
      }
   }
   return nil;
}
