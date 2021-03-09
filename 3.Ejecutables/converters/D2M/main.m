#import <Foundation/Foundation.h>
#import "ODLog.h"
#import "D2xml.h"

//D2M
//stdin binary dicom
//stdout DCKV xml (DICOM_contextualizedKey-values)
//https://raw.githubusercontent.com/jacquesfauquex/DICOM_contextualizedKey-values/master/mapxmldicom/mapxmldicom.xsd


int main(int argc, const char * argv[]) {
   @autoreleasepool {

      NSFileManager *fileManager=[NSFileManager defaultManager];
      NSProcessInfo *processInfo=[NSProcessInfo processInfo];
      NSDictionary *environment=processInfo.environment;
       
      NSString *originalPath;
      NSData *inputData;
      
      NSString *D2MtestName=environment[@"D2Mtest"];
       
      if (D2MtestName)
      {
         NSString *testPath;
         if ([fileManager fileExistsAtPath:[@"~/Library/Frameworks/DCKV.framework"stringByExpandingTildeInPath]]) testPath=[[@"~/Library/Frameworks/DCKV.framework/Resources/"stringByExpandingTildeInPath]stringByAppendingPathComponent:D2MtestName];
         else testPath=[@"/Library/Frameworks/DCKV.framework/Resources/"stringByAppendingPathComponent:D2MtestName];
         if ([fileManager fileExistsAtPath:testPath]) inputData=[NSData dataWithContentsOfFile:testPath];
         originalPath=[@"D2Mtest" stringByAppendingPathComponent:D2MtestName];
      }
      else
      {
         NSMutableData *concatenateData=[NSMutableData data];
         NSFileHandle *readingFileHandle=[NSFileHandle fileHandleWithStandardInput];
         NSData *moreData;
         while ((moreData=[readingFileHandle availableData]) && moreData.length) [concatenateData appendData:moreData];
         inputData=[NSData dataWithData:concatenateData];
       }

    
#pragma mark D2MlogLevel
      if (environment[@"D2MlogLevel"])
      {
         NSUInteger logLevel=[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:environment[@"D2MlogLevel"]];
         if (logLevel!=NSNotFound) ODLogLevel=(ODLogLevelEnum)logLevel;
         else ODLogLevel=4;//ERROR (default)
      }
      else ODLogLevel=4;//ERROR (default)
      
      
#pragma mark D2MlogPath (only in /Volumes/LOG)
      NSString *logPath=environment[@"D2MlogPath"];
       
       if (logPath && [logPath hasPrefix:@"/Volumes/LOG"])
       {
           BOOL isDirectory=false;
           if ([fileManager fileExistsAtPath:[logPath stringByDeletingLastPathComponent] isDirectory:&isDirectory] && isDirectory)
           {
               if ([logPath hasSuffix:@".log"])
                   freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
               else freopen([[logPath stringByAppendingPathExtension:@".log"] cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
           }
           else
           {
               LOG_ERROR(@"bad log path (dir does not exist): %@",logPath);
               exit(1);
           }
       }
       else if ([fileManager fileExistsAtPath:@"/Volumes/LOG"]) freopen([@"/Volumes/LOG/D2M.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
       else freopen([@"/Users/Shared/D2M.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);

       
#pragma mark D2MrelativePathComponents
       NSUInteger relativePathComponents=0;// -> new UUID name
       NSString *relativePathComponentsString=environment[@"D2MrelativePathComponents"];
       if (relativePathComponentsString)
       {
           relativePathComponents=relativePathComponentsString.intValue;
           if ((relativePathComponents==INT_MIN) || (relativePathComponents==INT_MAX)) relativePathComponents=0;//not found
       }
       
#pragma mark D2MbyRefToOriginalMinSize
       long long minSize=LONG_LONG_MAX;
       NSString *minSizeString=environment[@"D2MbyRefToOriginalMinSize"];
       if (minSizeString)
       {
           minSize=minSizeString.longLongValue;
           if ((minSize==0) || (minSize==LONG_LONG_MIN)) minSize=LONG_LONG_MAX;
       }
       
       LOG_DEBUG(@"environment:\r%@",[environment description]);
      
#pragma mark - xml map, root, document
      NSXMLElement *map=[NSXMLElement elementWithName:@"map"];
      [map addAttribute:[NSXMLNode attributeWithName:@"key"stringValue:@"dataset"]];

      if (D2xml(inputData,map,@"originalPath",minSize))
      {
          //root node
          NSXMLElement *root=[NSXMLElement elementWithName:@"map"];
          [root addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://www.w3.org/2005/xpath-functions"]];
          [root addChild:map];

          //document
          NSXMLDocument *xmlDocument=[[NSXMLDocument alloc] initWithRootElement:root];
          [xmlDocument setCharacterEncoding:@"UTF-8"];
          [xmlDocument setVersion:@"1.0"];

#pragma mark args xslt
         
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
            [[result XMLData] writeToFile:@"/dev/stdout" atomically:NO];
         else [result writeToFile:@"/dev/stdout" atomically:NO];
      }
   }//end autorelease pool
   return 0;
}
