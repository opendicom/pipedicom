#import <Foundation/Foundation.h>
#import "ODLog.h"

//M2
//stdin
//stdout depends on the xslt1
//special cases include :
// xslt1 B.xslt (further serializes in bson)
// xslt1 D.xslt (further serializes in binary dicom)
//wherehttps://github.com/jacquesfauquex/DICOM_contextualizedKey-values/blob/master/xml/xmldicom.xsd


int main(int argc, const char * argv[]) {
   @autoreleasepool {
      
      NSProcessInfo *processInfo=[NSProcessInfo processInfo];
      
#pragma marks environment

      NSDictionary *environment=processInfo.environment;
      
      //X2XlogLevel
      if (environment[@"X2XlogLevel"])
      {
         NSUInteger logLevel=[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:environment[@"X2XlogLevel"]];
         if (logLevel!=NSNotFound) ODLogLevel=(ODLogLevelEnum)logLevel;
         else ODLogLevel=4;//ERROR (default)
      }
      else ODLogLevel=4;//ERROR (default)
      
      
      //X2XlogPath
      NSString *logPath=environment[@"X2XlogPath"];
      if (logPath && ([logPath hasPrefix:@"/Users/Shared"] || [logPath hasPrefix:@"/Volumes/LOG"]))
      {
         if ([logPath hasSuffix:@".log"])
            freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
         else freopen([[logPath stringByAppendingPathExtension:@".log"] cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      }
      else freopen([@"/Users/Shared/X2X.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      
      //M2output
      NSString *M2output=environment[@"M2output"];
      if (!M2output) M2output=@"/dev/stdout";

      //X2XtestPath
      NSData *linedata=nil;
      NSString *testPath=environment[@"X2XtestPath"];
      if (testPath) linedata=[NSData dataWithContentsOfFile:testPath];
      else linedata = [[NSFileHandle fileHandleWithStandardInput] availableData];
      
      
      LOG_DEBUG(@"%@",[environment description]);
      
      
#pragma marks args
      
      NSArray *args=[[NSProcessInfo processInfo] arguments];
      
      if (args.count==1) [linedata writeToFile:M2output atomically:NO]; //without args: in>out
      else //X2X [XSL1TransformationPath [params...]]
      {
         NSData *xsl1data=[NSData dataWithContentsOfFile:args[1]];
         if (!xsl1data)
         {
            LOG_ERROR(@"arg XSL1TransformationPath %@ not available",args[1]);
            exit(2);
         }

         NSMutableDictionary *xslparams=[NSMutableDictionary dictionary];
         for (NSString *string in [args subarrayWithRange:NSMakeRange(2,args.count - 2)])
         {
            NSArray *keyValue=[string componentsSeparatedByString:@"="];
            if (keyValue.count != 2)
            {
               LOG_ERROR(@"xsl1t params in %@ should be key=value",args[1]);
               exit(3);
            }
            [xslparams setValue:keyValue[1] forKey:keyValue[0]];
         }

         LOG_DEBUG(@"xsl1t %@ with params : %@",args[1],[xslparams description]);
         
   #pragma mark in out
         if (linedata.length)
         {
            NSError *error=nil;
            NSXMLDocument *xmlDocument=[[NSXMLDocument alloc]initWithData:linedata options:0 error:&error];
            //https://developer.apple.com/documentation/foundation/nsxmlnodeoptions
            if (!xmlDocument)
            {
               if (error) LOG_INFO(@"%@",[error description]);
               [[NSData data] writeToFile:M2output atomically:NO];
            }
            else
            {
               id result=[xmlDocument objectByApplyingXSLT:xsl1data arguments:xslparams error:&error];
               if (!result)
               {
                  LOG_WARNING(@"Error with xsl %@",[args description]);
               }
               else if ([result isMemberOfClass:[NSXMLDocument class]])
               {
                  LOG_VERBOSE(@"xml result");
                  [[result XMLData] writeToFile:M2output atomically:NO];
               }
               else
               {
                  LOG_VERBOSE(@"data result");
                  [result writeToFile:M2output atomically:NO];
               }
            }
         }
      }
   }//end autorelease pool
   return 0;
}
