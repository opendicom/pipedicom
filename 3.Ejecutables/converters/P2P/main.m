#import <Foundation/Foundation.h>
#import "utils.h"
#import "ODLog.h"

//P2P
//stdin and stdout data based plist with 4 arrays (headstrings,bodystrings,headdatas,bodydatas)

//Specific Transformation performed on objects
//In the future: transformation by xslt script or by javascript

int main(int argc, const char * argv[]) {
   @autoreleasepool {

      NSProcessInfo *processInfo=[NSProcessInfo processInfo];
      
#pragma marks environment

      NSDictionary *environment=processInfo.environment;
      
      //P2PlogLevel
      if (environment[@"P2PlogLevel"])
      {
         NSUInteger logLevel=[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:environment[@"P2PlogLevel"]];
         if (logLevel!=NSNotFound) ODLogLevel=(ODLogLevelEnum)logLevel;
         else ODLogLevel=4;//ERROR (default)
      }
      else ODLogLevel=4;//ERROR (default)
      
      
      //P2PlogPath
      NSString *logPath=environment[@"P2PlogPath"];
      if (logPath && ([logPath hasPrefix:@"/Users/Shared"] || [logPath hasPrefix:@"/Volumes/LOG"]))
      {
         if ([logPath hasSuffix:@".log"])
            freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
         else freopen([[logPath stringByAppendingPathExtension:@".log"] cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      }
      else freopen([@"/Users/Shared/P2P.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      

      //P2PtestPath
      NSData *linedata=nil;
      NSString *testPath=environment[@"P2PtestPath"];
      if (testPath) linedata=[NSData dataWithContentsOfFile:testPath];
      else linedata = [[NSFileHandle fileHandleWithStandardInput] availableData];
      
      
      LOG_DEBUG(@"%@",[environment description]);

#pragma marks args
      //P2P transformer
      //1 transformer script file path
      
      NSArray *args=processInfo.arguments;
      if (args.count < 2)
      {
         LOG_ERROR(@"P2P requires a transformer parameter");
         exit(1)
      }
      LOG_DEBUG(@"%@",[args description]);
      
      
      NSData *transformerdata=[NSData dataWithContentsOfFile:args[1]];
      NSError *error=nil;


#pragma mark plistdata
      NSData *plistdata = [[NSFileHandle fileHandleWithStandardInput] availableData];
      id rootarray=
      [
       NSPropertyListSerialization
       propertyListWithData:plistdata
       options:NSPropertyListMutableContainersAndLeaves
       format:nil
       error:&error
       ];
      if (
             ![rootarray  isKindOfClass:[NSArray class]]
          || [rootarray count]!=4
          )
      {
         LOG_WARNING(@"stdin not plist [[],[],[],[]]\r\n%@", plistdata.description);
         exit(0);
      }

      NSMutableArray *headstrings=rootarray[0];
      NSMutableArray *bodystrings=rootarray[1];
      NSMutableArray *headdatas=rootarray[2];
      NSMutableArray *bodydatas=rootarray[3];

#pragma mark transform

#pragma mark TODO
      
#pragma mark stdout
      [
       [
       NSPropertyListSerialization
       dataWithPropertyList:@[
                              headstrings,
                              bodystrings,
                              headdatas,
                              bodydatas
                              ]
       format:NSPropertyListBinaryFormat_v1_0
       options:0
       error:&error
       ]
       writeToFile:@"/dev/stdout"
       atomically:NO
       ];

   }
   return 0;
}
