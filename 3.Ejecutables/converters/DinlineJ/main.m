//
//  main.m
//  DinlineJ
//
//  Created by jacquesfauquex on 2021-06-10.
//

#import <Foundation/Foundation.h>
#import <DCKV/DCKV.h>




int main(int argc, const char * argv[]) {
   @autoreleasepool {
      
      NSMutableData *inputData=[NSMutableData data];
      NSFileHandle *readingFileHandle=[NSFileHandle fileHandleWithStandardInput];
      NSData *moreData;
      while ((moreData=[readingFileHandle availableData]) && moreData.length) [inputData appendData:moreData];
      
      ODLogLevel=4;//ERROR (default)
      freopen([@"/Users/Shared/DInlineJ.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
         
#pragma mark · parse
      NSMutableDictionary *attrDict=[NSMutableDictionary dictionary];
      NSMutableDictionary *blobDict=[NSMutableDictionary dictionary];
      if (!D2dict(
                 inputData,
                 attrDict,
                 LLONG_MAX,
                 blobModeInline,
                 @"",
                 @"",
                 blobDict
                 )
          ) return 1;

#pragma mark · jsondata
      NSMutableString *JSONstring=json4attrDict(attrDict);
      NSData *JSONdata=[JSONstring dataUsingEncoding:NSUTF8StringEncoding];
      if (!JSONdata)
      {
         LOG_ERROR(@"could not transform to JSON: %@",[attrDict description]);
         return 1;
      }
      [JSONdata writeToFile:@"/dev/stdout" atomically:NO];
   }//end autorelease pool
   return 0;
}
