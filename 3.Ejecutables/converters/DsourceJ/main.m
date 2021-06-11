//
//  main.m
//  DsourceJ
//
//  Created by jacquesfauquex on 2021-06-10.
//

#import <Foundation/Foundation.h>
#import <DCKV/DCKV.h>




int main(int argc, const char * argv[]) {
   @autoreleasepool {
      NSString *path=[[NSProcessInfo processInfo] arguments][1];
      NSMutableData *inputData=[NSMutableData dataWithContentsOfFile:path];

      
      ODLogLevel=4;//ERROR (default)
      FILE *fp;
      fp=freopen([@"/Users/Shared/DinlineJ.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
         
#pragma mark · parse
      NSMutableDictionary *attrDict=[NSMutableDictionary dictionary];
      NSMutableDictionary *blobDict=[NSMutableDictionary dictionary];
      if (!D2dict(
                 inputData,
                 attrDict,
                 LLONG_MAX,
                 blobModeSource,
                 path,
                 @"",
                 blobDict
                 )
          )
      {
         LOG_ERROR(@"could not parse DICOM");
         fclose(fp);
         return 1;
      }

#pragma mark · jsondata
      NSMutableString *JSONstring=json4attrDict(attrDict);
      NSData *JSONdata=[JSONstring dataUsingEncoding:NSUTF8StringEncoding];
      if (!JSONdata)
      {
         LOG_ERROR(@"could not transform to JSON: %@",[attrDict description]);
         fclose(fp);
         return 1;
      }
      [JSONdata writeToFile:@"/dev/stdout" atomically:NO];
      fclose(fp);
   }//end autorelease pool

   return 0;
}
