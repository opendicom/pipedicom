#import <Foundation/Foundation.h>
#import "ODLog.h"
#import "D2dict.h"

//D2J
//stdin binary dicom
//stdout mapxmldicom JSON (DICOM_contextualizedKey-values)
//https://raw.githubusercontent.com/jacquesfauquex/DICOM_contextualizedKey-values/master/mapxmldicom/mapxmldicom.xsd


int main(int argc, const char * argv[]) {
   @autoreleasepool {

      NSProcessInfo *processInfo=[NSProcessInfo processInfo];
      
#pragma marks environment

      NSDictionary *environment=processInfo.environment;
      
      if (environment[@"D2JlogLevel"])
      {
         NSUInteger logLevel=[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:environment[@"D2JlogLevel"]];
         if (logLevel!=NSNotFound) ODLogLevel=(ODLogLevelEnum)logLevel;
         else ODLogLevel=4;//ERROR (default)
      }
      else ODLogLevel=4;//ERROR (default)
      
      
      //H2XlogPath
      NSString *logPath=environment[@"D2JlogPath"];
      if (logPath && ([logPath hasPrefix:@"/Users/Shared"] || [logPath hasPrefix:@"/Volumes/LOG"]))
      {
         if ([logPath hasSuffix:@".log"])
            freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
         else freopen([[logPath stringByAppendingPathExtension:@".log"] cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      }
      else freopen([@"/Users/Shared/D2J.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      
      //D2Moutput
      NSString *D2Joutput=environment[@"D2Joutput"];
      if (!D2Joutput) D2Joutput=@"/dev/stdout";

      //D2MtestPath
      NSData *data=nil;
      NSString *testPath=environment[@"D2JtestPath"];
      if (testPath) data=[NSData dataWithContentsOfFile:testPath];
      else data = [[NSFileHandle fileHandleWithStandardInput] availableData];
      
      LOG_DEBUG(@"environment:\r%@",[environment description]);
      
      NSMutableDictionary *dict=[NSMutableDictionary dictionary];
      if (D2dict(data, dict))
      {
         NSError *error;
         NSData *JSONdata=[NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingSortedKeys error:&error];//10.15 || NSJSONWritingWithoutEscapingSlashes
         if (!JSONdata)
         {
            LOG_ERROR(@"could not transform to JSON: %@",[dict description]);
         }
         else [JSONdata writeToFile:D2Joutput atomically:NO];
      }
   }//end autorelease pool
   return 0;
}
