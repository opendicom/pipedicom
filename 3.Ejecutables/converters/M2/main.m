#import <Foundation/Foundation.h>
#import "ODLog.h"

//M2
//stdin
//stdout depends on the xslt1
//special cases include :
// xslt1 B.xslt (further serializes in bson)
// xslt1 D.xslt (further serializes in binary dicom)



int main(int argc, const char * argv[]) {
   @autoreleasepool {
      
      NSProcessInfo *processInfo=[NSProcessInfo processInfo];
      
#pragma marks environment

      NSDictionary *environment=processInfo.environment;
      
      //M2logLevel
      if (environment[@"M2logLevel"])
      {
         NSUInteger logLevel=[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:environment[@"M2logLevel"]];
         if (logLevel!=NSNotFound) ODLogLevel=(ODLogLevelEnum)logLevel;
         else ODLogLevel=4;//ERROR (default)
      }
      else ODLogLevel=4;//ERROR (default)
      
      
      //M2logPath
      NSString *logPath=environment[@"M2logPath"];
      if (logPath && ([logPath hasPrefix:@"/Users/Shared"] || [logPath hasPrefix:@"/Volumes/LOG"]))
      {
         if ([logPath hasSuffix:@".log"])
            freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
         else freopen([[logPath stringByAppendingPathExtension:@".log"] cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      }
      else freopen([@"/Users/Shared/M2.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      
      //M2output
      NSString *M2output=environment[@"M2output"];
      if (!M2output) M2output=@"/dev/stdout";

      //M2testPath
      NSData *data=nil;
      NSString *testPath=environment[@"M2testPath"];
      if (testPath) data=[NSData dataWithContentsOfFile:testPath];
      else data = [[NSFileHandle fileHandleWithStandardInput] availableData];
      
      LOG_DEBUG(@"%@",[environment description]);
      
      id result=data;
      if (data.length > 134)
      {
         //minimal xml:
         /* <map xmlns="http://www.w3.org/2005/xpath-functions"><map key="dataset"><array key="00000001-00020000_UL"></number></array></map></map>*/
#pragma marks args
         
         NSArray *args=processInfo.arguments;
         NSUInteger argscount=args.count;
         NSArray *xslt1Paths=nil;
         NSXMLDocument *xmlDocument=nil;
         NSError *error=nil;
         if (argscount>1)
         {
            xmlDocument=[[NSXMLDocument alloc] initWithData:data options:0 error:&error];
            if (error)
            {
               LOG_ERROR(@"Error 1 reading M xml document");
               exit(1);
            }
            xslt1Paths =[args subarrayWithRange:NSMakeRange(1, argscount-1)];
         }
         else xslt1Paths=[NSArray array];//empty array

         for (NSString *xslt1Path in xslt1Paths)
         {
            NSData *xsl1data=[NSData dataWithContentsOfFile:xslt1Path];
            if (!xsl1data)
            {
               LOG_ERROR(@"arg XSL1TransformationPath %@ not available",args[1]);
               exit(2);
            }

            NSMutableDictionary *xslparams=environment[[xslt1Path lastPathComponent]];
            LOG_DEBUG(@"xsl1t %@ with params : %@",args[1],[xslparams description]);
            
            NSError *error=nil;
            id result=[xmlDocument objectByApplyingXSLT:xsl1data arguments:xslparams error:&error];
            if (!result)
            {
               LOG_WARNING(@"Error 5 with xsl %@",[args description]);
               [[NSData data] writeToFile:@"/dev/stdout" atomically:NO];
               exit(5);
            }
            [xmlDocument setRootElement:[result rootElement]];
         }
      }
      if ([result isMemberOfClass:[NSXMLDocument class]])
         [[result XMLData] writeToFile:M2output atomically:NO];
      else [result writeToFile:M2output atomically:NO];
   }//end autorelease pool
   return 0;
}
