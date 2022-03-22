#import <Foundation/Foundation.h>
#import <DCKV/DCKV.h>
#import "fileManager.h"


int main(int argc, const char * argv[]) {
   @autoreleasepool {
      NSProcessInfo *processInfo=[NSProcessInfo processInfo];
      NSArray *args=[processInfo arguments];
      if (args.count==1)//stdin
      {
         NSLog(@"no file to process");
         exit(1);
      }

      NSError *error=nil;
      NSFileManager *fileManager=[NSFileManager defaultManager];
      if (  ![fileManager fileExistsAtPath:@"stdout.j2k"]
          &&![fileManager createSymbolicLinkAtPath:@"stdout.j2k" withDestinationPath:@"/dev/stdout" error:&error]
          ) NSLog(@"could not create symlink stdout.j2k: %@",[error description]);
      if (  ![fileManager fileExistsAtPath:@"stdin.rawl"]
          &&![fileManager createSymbolicLinkAtPath:@"stdin.rawl" withDestinationPath:@"/dev/stdin" error:&error]
          ) NSLog(@"could not create symlink stdin.rawl: %@",[error description]);

      
      NSMutableArray *inputPaths=[NSMutableArray array];
      if (!visibleFiles(fileManager, [args subarrayWithRange:NSMakeRange(1,args.count -1)] , inputPaths)) exit(failure);

      
#pragma mark - environment

      NSDictionary *environment=processInfo.environment;
      
      
#pragma mark D2JlogLevel
      if (environment[@"D2JlogLevel"])
      {
         NSUInteger logLevel=[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:environment[@"D2JlogLevel"]];
         if (logLevel!=NSNotFound) ODLogLevel=(ODLogLevelEnum)logLevel;
         else ODLogLevel=4;//ERROR (default)
      }
      else ODLogLevel=4;//ERROR (default)
      


#pragma mark D2JrelativePathComponents
      NSUInteger relativePathComponents=0;// -> new UUID name
      NSString *relativePathComponentsString=environment[@"D2JrelativePathComponents"];
      if (relativePathComponentsString)
      {
         relativePathComponents=relativePathComponentsString.intValue;
         if ((relativePathComponents==INT_MIN) || (relativePathComponents==INT_MAX)) relativePathComponents=0; //not found
      }

      
#pragma mark D2JblobMode and D2JblobMinSize
      int blobMode=blobModeResources;
      long long blobMinSize=LONG_LONG_MAX;
      NSString *blobMinSizeString=environment[@"D2JblobMinSize"];
      if (blobMinSizeString)
      {
         blobMinSize=blobMinSizeString.longLongValue;
         if ((blobMinSize==0) || (blobMinSize==LONG_LONG_MIN)) blobMinSize=LONG_LONG_MAX;
      }

      
#pragma mark D2JblobRefPrefix
      NSMutableString *blobRefPrefix=[NSMutableString string];
      if (
             (blobMode==blobModeInline)
          && environment[@"D2JblobRefPrefix"]
          ) [blobRefPrefix setString:environment[@"D2JblobRefPrefix"]];

#pragma mark D2JblobRefSuffix
      NSString *blobRefSuffix=environment[@"D2JblobRefSuffix"];


#pragma mark D2Jpixel
      //this information is equivalent to the one found in coercedicom.json
      NSString *pixelString=environment[@"D2Jpixel"];
      BOOL toJ2KR=false;
      BOOL toBFHI=false;
      if (pixelString)
      {
         toJ2KR=[pixelString isEqualToString:@"j2kr"];
         toBFHI=[pixelString isEqualToString:@"j2ki"];
      }


#pragma mark D2JoutputDir
      NSString *outputDir=environment[@"D2JoutputDir"];
      
      
      LOG_DEBUG(@"environment:\r%@",[environment description]);

      
      
      

#pragma mark - processing loop

      NSMutableData *inputData=[NSMutableData data];
      for (NSString *inputPath in inputPaths)
      {
#pragma mark · parse
         if ([inputPath hasSuffix:@".dcm"])
            [blobRefPrefix setString:[ [[inputPath lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:@".bulkdata/"]];
         else
            [blobRefPrefix setString:[ [inputPath lastPathComponent] stringByAppendingString:@".bulkdata/"]];

         //inputData is empty
            [inputData appendData:[NSData dataWithContentsOfFile:inputPath]];

//json components
         NSMutableDictionary *filemetainfoAttrs=[NSMutableDictionary dictionary];
         NSMutableDictionary *datasetAttrs=[NSMutableDictionary dictionary];
         NSMutableDictionary *nativeAttrs=[NSMutableDictionary dictionary];
         NSMutableDictionary *j2kAttrs=[NSMutableDictionary dictionary];// compressing, either j2kr or bfhi
         NSMutableDictionary *blobDict=[NSMutableDictionary dictionary];
         NSMutableDictionary *j2kBlobDict=[NSMutableDictionary dictionary];

         if ( parse(
                    inputData,
                    filemetainfoAttrs,
                    datasetAttrs,
                    nativeAttrs,
                    j2kAttrs,
                    blobDict,
                    j2kBlobDict,
                    blobMinSize,
                    blobMode,
                    blobRefPrefix,
                    blobRefSuffix,
                    toJ2KR,
                    toBFHI
                    )==failure)
         {
            [inputData setLength:0];
            LOG_ERROR(@"%@",inputPath);
            continue;
         }


#pragma mark · jsondata

         NSMutableString *JSONstring=[NSMutableString stringWithString:@"{ "];
         
         if (filemetainfoAttrs.count)
         {
            [JSONstring appendFormat:@"\"filemetainfo\" :%@",jsonObject4attrs(filemetainfoAttrs)];
         }
         if (datasetAttrs.count)
         {
            if (JSONstring.length > 2) [JSONstring appendString:@", "];
            [JSONstring appendFormat:@"\"dataset\" :%@",jsonObject4attrs(datasetAttrs)];
         }
         if (nativeAttrs.count)
         {
            if (JSONstring.length > 2) [JSONstring appendString:@", "];
            [JSONstring appendFormat:@"\"native\" :%@",jsonObject4attrs(nativeAttrs)];
         }
         if (j2kAttrs.count)
         {
            if (JSONstring.length > 2) [JSONstring appendString:@", "];
            [JSONstring appendFormat:@"\"%@\" :%@",toJ2KR?@"j2kr":@"bfhi",jsonObject4attrs(j2kAttrs)];
         }
         [JSONstring appendString:@" }"];
         
         NSData *JSONdata=[JSONstring dataUsingEncoding:NSUTF8StringEncoding];
         if (!JSONdata)
         {
            LOG_ERROR(@"could not transform to JSON: %@",[datasetAttrs description]);
         }
         else
#pragma mark · outputDir
         {
            NSMutableArray *inputPathComponents=[NSMutableArray arrayWithArray:[inputPath pathComponents]];

            if (![inputPathComponents[0] length]) [inputPathComponents removeObjectAtIndex:0];//case of absolute paths
            while (relativePathComponents < inputPathComponents.count)
            {
               [inputPathComponents removeObjectAtIndex:0];
            }
            NSString *outputPath=[[[outputDir stringByAppendingPathComponent:[inputPathComponents componentsJoinedByString:@"/"]]stringByDeletingPathExtension]stringByAppendingPathExtension:@"json"];
            NSString *outputDir=[outputPath stringByDeletingLastPathComponent];
            if (![fileManager fileExistsAtPath:outputDir] && ![fileManager createDirectoryAtPath:outputDir withIntermediateDirectories:YES attributes:0 error:&error] )
            {
               LOG_ERROR(@"could not create directory %@",outputDir);
               return 1;
            }
            [JSONdata writeToFile:outputPath atomically:NO];
            if (blobDict.count)
            {
               NSString *bulkdataDir=[[outputPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"bulkdata"];
               [fileManager createDirectoryAtPath:bulkdataDir withIntermediateDirectories:YES attributes:nil error:&error];
               for (NSString *bulkdataKey in blobDict)
               {
                  [blobDict[bulkdataKey] writeToFile:[bulkdataDir stringByAppendingPathComponent:[bulkdataKey lastPathComponent]] atomically:NO];
               }
            }
         }//end parsed
         [inputData setLength:0];
      }//end loop
   }//end autorelease pool
   return 0;
}
