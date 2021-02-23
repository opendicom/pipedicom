#import <Foundation/Foundation.h>
#import "ODLog.h"
#import "D2xml.h"

//D2M
//stdin binary dicom
//stdout mapxmldicom xml (DICOM_contextualizedKey-values)
//https://raw.githubusercontent.com/jacquesfauquex/DICOM_contextualizedKey-values/master/mapxmldicom/mapxmldicom.xsd


int main(int argc, const char * argv[]) {
   @autoreleasepool {

      NSProcessInfo *processInfo=[NSProcessInfo processInfo];
      
#pragma marks environment

      NSDictionary *environment=processInfo.environment;
      
      if (environment[@"D2MlogLevel"])
      {
         NSUInteger logLevel=[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:environment[@"D2MlogLevel"]];
         if (logLevel!=NSNotFound) ODLogLevel=(ODLogLevelEnum)logLevel;
         else ODLogLevel=4;//ERROR (default)
      }
      else ODLogLevel=4;//ERROR (default)
      
      
      //H2XlogPath
      NSString *logPath=environment[@"D2MlogPath"];
      if (logPath && ([logPath hasPrefix:@"/Users/Shared"] || [logPath hasPrefix:@"/Volumes/LOG"]))
      {
         if ([logPath hasSuffix:@".log"])
            freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
         else freopen([[logPath stringByAppendingPathExtension:@".log"] cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      }
      else freopen([@"/Users/Shared/D2M.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      
      //D2Moutput
      NSString *D2Moutput=environment[@"D2Moutput"];
      if (!D2Moutput) D2Moutput=@"/dev/stdout";

      //D2MtestPath
      NSData *data=nil;
      NSString *testPath=environment[@"D2MtestPath"];
      if (testPath) data=[NSData dataWithContentsOfFile:testPath];
      else data = [[NSFileHandle fileHandleWithStandardInput] availableData];
      
      LOG_DEBUG(@"environment:\r%@",[environment description]);
      
#pragma mark in out
      NSXMLElement *root=[NSXMLElement elementWithName:@"map"];
      [root addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://www.w3.org/2005/xpath-functions"]];
      NSXMLElement *map=[NSXMLElement elementWithName:@"map"];
      [root addChild:map];
      [map addAttribute:[NSXMLNode attributeWithName:@"key"stringValue:@"dataset"]];

      if (D2xml(data,map))
      {

         NSXMLDocument *xmlDocument=[[NSXMLDocument alloc] initWithRootElement:root];
         [xmlDocument setCharacterEncoding:@"UTF-8"];
         [xmlDocument setVersion:@"1.0"];

#pragma marks args
         
         NSArray *args=processInfo.arguments;
         NSUInteger argscount=args.count;
         NSArray *xslt1Paths=nil;
         if (argscount>1)
            xslt1Paths =[args subarrayWithRange:NSMakeRange(1, argscount-1)];
         else xslt1Paths=[NSArray array];//empty array
       
         id result=xmlDocument;
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
         if ([result isMemberOfClass:[NSXMLDocument class]])
            [[result XMLData] writeToFile:D2Moutput atomically:NO];
         else [result writeToFile:D2Moutput atomically:NO];
      }
   }//end autorelease pool
   return 0;
}
