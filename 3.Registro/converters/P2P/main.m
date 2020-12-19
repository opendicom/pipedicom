#import <Foundation/Foundation.h>
#import "utils.h"
#import "ODLog.h"

//P2P
//stdin and stdout data based plist with 4 arrays (headstrings,bodystrings,headdatas,bodydatas)

//Specific Transformation performed on objects
//In the future: transformation by xslt script or by javascript

int main(int argc, const char * argv[]) {
   @autoreleasepool {

      NSError *error=nil;
      NSData *transformerdata=nil;

#pragma marks args
      //P2P [ transformer [logfile [loglevel]]]
      //1 transformer script file path
      //2 logfile default: /Volumes/LOG/H2P.log
      //3 loglevel [ DEBUG | VERBOSE | INFO | WARNING | ERROR | EXCEPTION] default: ERROR

      
      NSArray *args=[[NSProcessInfo processInfo] arguments];
      switch (args.count) {
         case 4:
#pragma mark loglevel
            ODLogLevel=(ODLogLevelEnum)[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:args[3]];
            
         case 3:
#pragma mark logfile
            if (
                   ![args[2] hasPrefix:@"/Users/Shared"]
                && ![args[2] hasPrefix:@"/Volumes/LOG"]
                )
            {
               NSLog(@"usage : P2P [transformer [logfile [loglevel]]]. Logfile should be in /Users/Shared or /Volumes/LOG");
               exit(0);
            }
            if ([args[2] hasSuffix:@".log"])
               freopen([args[2] cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
            else freopen([[args[2] stringByAppendingPathExtension:@".log"] cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
            break;


         case 2:
            transformerdata=[NSData dataWithContentsOfFile:args[1]];

         case 1:
#pragma mark defaults
            //no arguments
            ODLogLevel=4;//ERROR
            freopen([@"/Users/Shared/P2P.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
            break;
            
         default:
            NSLog(@"usage : P2P [transformer [logfile [loglevel]]]");
            exit(0);
            break;
      }

      LOG_DEBUG(@"%@",[args description]);

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
