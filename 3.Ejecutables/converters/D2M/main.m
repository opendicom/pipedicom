#import <Foundation/Foundation.h>
#import "ODLog.h"
#import "D2xml.h"
#import "dckRangeVecs.h"
#import "utils.h"

//D2M
//stdin binary dicom
//stdout DCKV xml (DICOM_contextualizedKey-values)
//https://raw.githubusercontent.com/jacquesfauquex/DICOM_contextualizedKey-values/master/mapxmldicom/mapxmldicom.xsd

static NSString *bulkdataStdin=@"offset=%lu&amp;length=%d";
static NSString *bulkdataSource=@"file:%@?offset=%lu&amp;length=%d";
static NSString *bulkdataCopied=@"%@.bulkdata/%@";//fileName,dckv
static NSString *bulkdataZipped=@"zipped";

id process(
    NSData *inputData,
    uint32 datasetIndex,
    NSArray *xslt1Names,
    NSArray *xslt1Datas,
    NSArray *xslt1ParamStrings,
    NSMutableData *outputData,
    long long bulkdataMinSize,
    NSString *bulkdataUrlTemplate,
    struct dckRangeVecs bulkdataVecs
    )
{
   /*
    if bulkdataMinSize -> not inlined
    
    if bulkdataUrlTemplate -> byReference to pointer in data
    else copied to bulkdatas with key dckv
    */
   
   if (inputData.length <10)
   {
      LOG_WARNING(@"dicom binary data too small");
      return nil;
   }

   id result=nil;
   
#pragma mark - xml map, root, document
   NSXMLElement *xmlMap=[NSXMLElement elementWithName:@"map"];
   [xmlMap addAttribute:[NSXMLNode attributeWithName:@"key"stringValue:@"dataset"]];


   if (D2xml(inputData,xmlMap,bulkdataMinSize,bulkdataUrlTemplate,bulkdataVecs))
   {
      //root node
      NSXMLElement *root=[NSXMLElement elementWithName:@"map"];
      [root addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://www.w3.org/2005/xpath-functions"]];
      [root addChild:xmlMap];

      //document
      NSXMLDocument *xmlDocument=[[NSXMLDocument alloc] initWithRootElement:root];
      [xmlDocument setCharacterEncoding:@"UTF-8"];
      [xmlDocument setVersion:@"1.0"];
      
      //apply xslt1
      result=xmlDocument;
      for (NSUInteger idx=0;idx<xslt1Datas.count;idx++)
      {
         NSError *error=nil;
         id result=[xmlDocument objectByApplyingXSLT:xslt1Datas[idx] arguments:xslt1ParamStrings[idx] error:&error];
         if (!result)
         {
            LOG_WARNING(@"Error 5 with xsl %@",xslt1Names[idx]);
            return nil;
         }
         [xmlDocument setRootElement:[result rootElement]];
      }
   }
   return result;
}

int main(int argc, const char * argv[]) {
   @autoreleasepool {

      NSFileManager *fileManager=[NSFileManager defaultManager];
      NSProcessInfo *processInfo=[NSProcessInfo processInfo];
      NSDictionary *environment=processInfo.environment;
      NSArray *args=processInfo.arguments;
      BOOL isDirectory=false;

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
         if ([fileManager fileExistsAtPath:[logPath stringByDeletingLastPathComponent] isDirectory:&isDirectory] && isDirectory)
         {
            if ([logPath hasSuffix:@".log"]) freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
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


      
#pragma mark D2MforceZip
      BOOL D2MforceZip=environment[@"D2MforceZip"] && [environment[@"D2MforceZip"] isEqualToString:@"true"];

      
#pragma mark D2MoutputDir
      NSString *D2MoutputDir=nil;
      if (environment[@"D2MoutputDir"])
      {
         NSString *absolutePath=[environment[@"D2MoutputDir"] stringByExpandingTildeInPath];
         if (![fileManager fileExistsAtPath:absolutePath isDirectory:&isDirectory])
         {
            LOG_ERROR(@"D2MoutputDir '%@' does not exist",absolutePath);
            return 1;
         }
         if (!isDirectory)
         {
            LOG_ERROR(@"2: D2MoutputDir '%@' is not a directory",absolutePath);
            return 2;
         }
         D2MoutputDir=[NSString stringWithString:absolutePath];
      }
      
#pragma mark D2MerrorDir
      NSString *D2MerrorDir=nil;
      if (environment[@"D2MerrorDir"])
      {
         NSString *absolutePath=[environment[@"D2MerrorDir"] stringByExpandingTildeInPath];
         if (![fileManager fileExistsAtPath:absolutePath isDirectory:&isDirectory])
         {
            LOG_ERROR(@"D2MerrorDir '%@' does not exist",absolutePath);
            return 1;
         }
         if (!isDirectory)
         {
            LOG_ERROR(@"2: D2MerrorDir '%@' is not a directory",absolutePath);
            return 2;
         }
         D2MerrorDir=[NSString stringWithString:absolutePath];
      }

      
#pragma mark D2MdoneDir
      NSString *D2MdoneDir=nil;
      if (environment[@"D2MdoneDir"])
      {
         NSString *absolutePath=[environment[@"D2MdoneDir"] stringByExpandingTildeInPath];
         if (![fileManager fileExistsAtPath:absolutePath isDirectory:&isDirectory])
         {
            LOG_ERROR(@"D2MdoneDir '%@' does not exist",absolutePath);
            return 1;
         }
         if (!isDirectory)
         {
            LOG_ERROR(@"2: D2MdoneDir '%@' is not a directory",absolutePath);
            return 2;
         }
         D2MdoneDir=[NSString stringWithString:absolutePath];
      }


#pragma mark D2MrelativePathComponents
      NSUInteger D2Mrpc=0;// -> new UUID name
      NSString *D2MrpcString=environment[@"D2MD2MrelativePathComponents"];
      if (D2MrpcString)
      {
          D2Mrpc=D2MrpcString.intValue;
          if ((D2Mrpc==INT_MIN) || (D2Mrpc==INT_MAX)) D2Mrpc=0;//not found
      }
      
#pragma mark D2Mext
      NSString *D2Mext=nil;
      NSString *ext=environment[@"D2Mext"];
      if (ext && ([@[@"html",@"xhtml",@"cda",@"txt"] indexOfObject:ext]!=NSNotFound)) D2Mext=ext;
      
      
#pragma mark D2MBulkdataMinSize, D2MBulkdataUrlTemplate
      long long bulkdataMinSize=LONG_LONG_MAX;
      NSString *bulkdataUrlTemplate=nil;
      NSString *bulkdataMinSizeString=environment[@"D2MBulkdataMinSize"];
      if (bulkdataMinSize)
      {
         bulkdataMinSize=bulkdataMinSizeString.longLongValue;
          if ((bulkdataMinSize==0) || (bulkdataMinSize==LONG_LONG_MIN)) bulkdataMinSize=LONG_LONG_MAX;

         /*
          "source"
          "copied" (into a folder named as the original with a ".bulkdata" extension)
          "zipped" (indexed dckv)
          */
         NSString *D2MBulkdataUrlTemplate=environment[@"D2MBulkdataUrlTemplate"];
         if (D2MBulkdataUrlTemplate)
         {
            if([D2MBulkdataUrlTemplate isEqualToString:@"source"]) bulkdataUrlTemplate=bulkdataSource;
            else if ([D2MBulkdataUrlTemplate isEqualToString:@"copied"]) bulkdataUrlTemplate=bulkdataCopied;
            else if ([D2MBulkdataUrlTemplate isEqualToString:@"zipped"]) bulkdataUrlTemplate=bulkdataZipped;
         }
         else bulkdataUrlTemplate=bulkdataStdin;
      }
      
      
#pragma mark D2Mxslt1
      NSMutableArray *xslt1Names=nil;
      NSMutableArray *xslt1Datas=nil;
      NSMutableArray *xslt1ParamStrings=nil;
      NSString *D2Mxslt1=environment[@"D2Mxslt1"];
      if (D2Mxslt1)
      {
         xslt1Names=[NSMutableArray array];
         xslt1Datas=[NSMutableArray array];
         xslt1ParamStrings=[NSMutableArray array];
         
         for (NSString *xslt1Path in [D2Mxslt1 componentsSeparatedByString:@" "])
         {
            NSError *error;
            NSData *readXslt1Data=[NSData dataWithContentsOfFile:xslt1Path options:0 error:&error];
            if (!error && readXslt1Data)
            {
               [xslt1Datas addObject:readXslt1Data];
               [xslt1Names addObject:[[xslt1Path lastPathComponent] stringByDeletingPathExtension]];
               NSString *paramString=environment[xslt1Names.lastObject];
               if (!paramString) paramString=@"";
               [xslt1ParamStrings addObject:paramString];
            }
         }
      }
      
      LOG_DEBUG(@"environment:\r%@",[environment description]);

      
#pragma mark - args
      NSMutableArray *inputPaths=[NSMutableArray array];
      NSData *inputData;
      
      if (args.count ==1)//stdin
      {
         NSMutableData *concatenateData=[NSMutableData data];
         NSFileHandle *readingFileHandle=[NSFileHandle fileHandleWithStandardInput];
         NSData *moreData;
         while ((moreData=[readingFileHandle availableData]) && moreData.length) [concatenateData appendData:moreData];
            inputData=[NSData dataWithData:concatenateData];
         [inputPaths addObject:@""];//stdin
      }
      else
      {
         if ([args[1] isEqualToString:@"test"])
         {
            for (NSUInteger i=2; i< args.count; i++)
            {
               NSString *testPath;
               if ([fileManager fileExistsAtPath:[@"~/Library/Frameworks/DCKV.framework"stringByExpandingTildeInPath]]) testPath=[[@"~/Library/Frameworks/DCKV.framework/Resources/"stringByExpandingTildeInPath]stringByAppendingPathComponent:args[i]];
               else testPath=[@"/Library/Frameworks/DCKV.framework/Resources/"stringByAppendingPathComponent:args[i]];
               if (testPath) [inputPaths addObject:testPath];
            }
         }
         else //file path
         {
            if (!visibleFiles(fileManager, [args  subarrayWithRange:NSMakeRange(2, args.count)] , inputPaths)) exit(failure);
         }
      }

      
#pragma mark - process inputData or inputPaths
      
/*
 D2MforceZip | D2MoutputDir |    args    | stdout
 ------------|--------------|------------|----------
 true        |          true|            |zip outputDir UUID name
 false       |true          |            |err number (0=OK)
 true        |false         |            |zipped
 false       |false         |0-1         |xml or xslt1 result
 false       |false         |test + 1    |xml or xslt1 result
 false       |false         |>1          | zipped
 */
      NSMutableData *outputData=[NSMutableData data];

      if (!D2MforceZip)
      {
         if (!D2MoutputDir)
         {
            if (inputPaths.count > 1)
#pragma mark TODO many sop -> stdout wado-rs zipped
            {
            }
            else
#pragma mark one sop -> stdout
            {
               if (!inputData)
               {
                  NSError *error;
                  inputData=[NSData dataWithContentsOfFile:inputPaths[0] options:0 error:&error];
                  if (!inputData)
                  {
                     LOG_WARNING(@"reading file %@: %@",inputPaths[0],error.description);
                     exit(failure);
                  }
                  if (!inputData.length)
                  {
                     LOG_WARNING(@"empty file %@",inputPaths[0]);
                     exit(failure);
                  }
               }
               //inputData -> stdout
               [outputData setLength:0];
               id result=process(
                       inputData,
                       0x00000001,
                       xslt1Names,
                       xslt1Datas,
                       xslt1ParamStrings,
                       outputData,
                       bulkdataMinSize,
                       bulkdataUrlTemplate,
                       newDckRangeVecs(args.count * 10)
                                 );
               if ([result isMemberOfClass:[NSXMLDocument class]])
                  [[result XMLData] writeToFile:@"/dev/stdout" atomically:NO];
               else [result writeToFile:@"/dev/stdout" atomically:NO];
            }
         }
         else //D2MoutputDir
         {
#pragma mark -> outputDir
            
            for (NSString *inputPath in inputPaths)
            {
               NSError *error;
               if (inputPath.length)
               {
                  inputData=[NSData dataWithContentsOfFile:inputPaths[0] options:0 error:&error];
                  
                  if (!inputData)
                  {
                     LOG_WARNING(@"unread file %@: %@",inputPath,error.description);
                     moveFile(fileManager, inputPath, [D2MerrorDir stringByAppendingPathComponent:@"unread"], D2Mrpc)
                     break;
                  }
               }//length=0 -> data has been streamed
               
               if (!inputData.length)
               {
                  LOG_WARNING(@"empty file %@",inputPath);
                  moveFile(fileManager, inputPath, [D2MerrorDir stringByAppendingPathComponent:@"empty"], D2Mrpc)
                  break;
               }

               [outputData setLength:0];
               struct dckRangeVecs bulkdatas=newDckRangeVecs(args.count * 10);
               id result=process(
                    inputData,
                    0x00000001,
                    xslt1Names,
                    xslt1Datas,
                    xslt1ParamStrings,
                    outputData,
                    bulkdataMinSize,
                    bulkdataUrlTemplate,
                    bulkdatas
                              );
               
               if (!result)
               {
                  LOG_WARNING(@"unprocessed file %@",inputPath);
                  moveFile(fileManager, inputPath, [D2MerrorDir stringByAppendingPathComponent:@"unprocessed"], D2Mrpc);
               }
               else if ([result isMemberOfClass:[NSXMLDocument class]])
               {
                  if (writeData(fileManager, [result XMLData], inputPath, D2MoutputDir, D2Mrpc, D2Mext))
                  {
                     if (writeBulkdata(fileManager, bulkdatas, inputPath, D2MoutputDir, D2Mrpc))
                     {
                        LOG_VERBOSE(@"processed file %@",inputPath);
                        moveFile(fileManager, inputPath, D2MdoneDir, D2Mrpc);
                     }
                     else
                     {
                        LOG_WARNING(@"bulkdata problem for %@",inputPath);
                        moveFile(fileManager, inputPath, [D2MerrorDir stringByAppendingPathComponent:@"bulkdata"], D2Mrpc);
                     }
                  }
                  else moveFile(fileManager, inputPath, [D2MerrorDir stringByAppendingPathComponent:@"xmlWriting"], D2Mrpc);
               }
               else
               {
                  [result writeToFile:@"/dev/stdout" atomically:NO];
               }

         }
      }
      else //D2MforceZip
      {
   
      }
       
   }//end autorelease pool
   return 0;
}

