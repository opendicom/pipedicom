#import <Foundation/Foundation.h>
#import <DCKV/DCKV.h>
#import "dict2D.h"



int main(int argc, const char * argv[]) {
@autoreleasepool {
   
NSError *error=nil;
NSProcessInfo *processInfo=[NSProcessInfo processInfo];
NSArray *args=[processInfo arguments];
NSDictionary *environment=processInfo.environment;
NSString *PWD;
   
#pragma mark env
   
if (environment[@"J2DLogLevel"])
{
   NSUInteger logLevel=[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:environment[@"J2DLogLevel"]];
   if (logLevel!=NSNotFound) ODLogLevel=(ODLogLevelEnum)logLevel;
   else ODLogLevel=4;//ERROR (default)
}
else ODLogLevel=4;//ERROR (default)

   
#pragma mark stdin
   
NSMutableData *inputData=[NSMutableData data];
if (args.count==3)//filePath es args[2]
{
   NSData *pathData=[NSData dataWithContentsOfFile:[args[2] stringByExpandingTildeInPath]];
   if (!pathData)
   {
      LOG_ERROR(@"bad path: %@",pathData);
      return 1;
   }
   [inputData appendData:pathData];
   PWD=[args[2] stringByDeletingLastPathComponent];//for file path JSON, relative resource paths are from the containing folder of file path JSON
}
else //using stdin
{
   NSFileHandle *readingFileHandle=[NSFileHandle fileHandleWithStandardInput];
   NSData *moreData;
   while ((moreData=[readingFileHandle availableData]) && moreData.length) [inputData appendData:moreData];
   [readingFileHandle closeFile];

   char firstByte=0;
   [inputData getBytes:&firstByte length:1];
   if (firstByte == '{') PWD=environment[@"PWD"];//for JSON stdin, relative resource paths are from PWD
   else
   {
      //this is not a json
      NSString *inputDataString=[[NSString alloc]initWithData:inputData encoding:NSUTF8StringEncoding];
      if (![[NSFileManager defaultManager] fileExistsAtPath:inputDataString])
      {
         LOG_WARNING(@"stdin not JSON nor path");
         return 1;
      }
      [inputData setData:[NSData dataWithContentsOfFile:inputDataString]];
      [inputData getBytes:&firstByte length:1];
      if (firstByte != '{')
      {
         LOG_WARNING(@"stdin path does not contain a JSON at byte 0");
         return 1;
      }
      PWD=[inputDataString stringByDeletingLastPathComponent];//for file path JSON, relative resource paths are from the containing folder of file path JSON
   }
}

NSDictionary *inputDict=[NSJSONSerialization JSONObjectWithData:inputData options:0 error:&error];
if (!inputDict)
{
   LOG_WARNING(@"malformed stdin JSON: %@",[error description]);
   return 1;
}


#pragma mark args
   
NSUInteger pixelMode;
switch (args.count) {
   case 1:
      pixelMode=undf;
      break;
      
   case 2:
   case 3:
   {
      pixelMode=[@[@"undf",@"natv",@"j2kb",@"j2kf",@"j2kh",@"j2ki",@"j2kr",@"j2k"] indexOfObject:args[1]];
      if (pixelMode==NSNotFound) pixelMode=4;//idem;
   }
      break;
      
   default:
      LOG_ERROR(@"syntax: J2D [ unddf | natv | j2kb | j2kf | j2kh | j2ki | j2kr | j2k ] [ path ]");
      return 1;
}
   
#pragma mark concatenate dataset
NSMutableDictionary *filemetainfo=[NSMutableDictionary dictionary];
NSMutableDictionary *dataset=[NSMutableDictionary dictionary];
NSString *EDCKVcompileErrMsg=EDCKVcompile(
   inputDict,
   pixelMode,
   filemetainfo,
   dataset
);
if (EDCKVcompileErrMsg)
{
   LOG_WARNING(@"%@",EDCKVcompileErrMsg);
   return 1;
}





NSMutableData *outputData;
//prefix
if (!current[@"coercePrefix"]) outputData=[NSMutableData dataWithLength:128];
else outputData=[NSMutableData dataWithLength:128];
[outputData appendBytes:&DICM length:4];
//fileMetadata
NSMutableData *outputFileMetadata=[NSMutableData data];
if (dict2D(
            @"",
            fileMetadataAttrs,
            outputFileMetadata,
            4, //dicomExplicitJ2kIdem
            blobDict
            ) == failure
    )
{
   NSLog(@"could not serialize group 0002. %@",fileMetadataAttrs.description);
   exit(failure);
}

[outputData appendBytes:&_0002000_tag_vr length:8];
UInt32 fileMetadataLength=(UInt32)outputFileMetadata.length+14;//00020001
[outputData appendBytes:&fileMetadataLength length:4];
[outputData appendBytes:&_0002001_tag_vr length:8];
[outputData appendBytes:&_0002001_length length:4];
[outputData appendBytes:&_0002001_value length:2];
[outputData appendData:outputFileMetadata];


// dataset
if (dict2D(
            @"",
            parsedAttrs,
            outputData,
            4, //dicomExplicitJ2kIdem
            blobDict
            )==failure
    )
#pragma mark · failure
{
   NSLog(@"could not serialize dataset. %@",parsedAttrs);
   if (!failureDirExists)
   {
      if (![fileManager createDirectoryAtPath:current[@"failureDir"] withIntermediateDirectories:YES attributes:nil error:&error])
      {
         [response appendFormat:@"failed to create %@\r\n",current[@"failureDir"]];
         break;
      }
   }

   NSString *errMsg=moveDup(
                            fileManager,
                            srcFile,
                            [current[@"failureDir"] stringByAppendingPathComponent:noUnderscoreSuffixBeforeDcmExt(srcName)]);
   if (errMsg) [response appendString:errMsg];
   break;
}
else
{
#pragma mark · success
   
   if (storeBucketSize == 0)
#pragma mark ·· directly into EIUID
   {
      if (!successDirExists)
      {
         if (![fileManager createDirectoryAtPath:current[@"successDir"] withIntermediateDirectories:YES attributes:nil error:&error])
         {
            [response appendFormat:@"can not create %@\r\n",current[@"successDir"]];
            break;
         }
         successDirExists=true;
      }
      
      [outputData writeToFile:[current[@"successDir"] stringByAppendingPathComponent:srcName] atomically:NO];
   }
   else
#pragma mark ·· into store buckets
   {
      //67 = mime head 51 + space + space + mime tail 16
      if (outputData.length > [current[@"storeBucketSize"] longLongValue]-67)
      {
         [response appendFormat:@"%@ dataset (%lu + mime) larger than bucket (%lld). Increase bucket size\r\n",srcName,(unsigned long)outputData.length,[current[@"storeBucketSize"] longLongValue] ];
         break;
      }
      
      bucketSpaceLeft-=outputData.length;
      if (bucketSpaceLeft < 69)
      {
         //copy mime tail?
         NSString *tailFile=[[current[@"successDir"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%lld",bucketNumber]] stringByAppendingPathComponent:@"zygote-mime-multipart"];
         if (![fileManager fileExistsAtPath:tailFile]) [tailData writeToFile:tailFile atomically:NO];
         
         //new bucket
         bucketNumber++;
         bucketSpaceLeft=[current[@"storeBucketSize"] longLongValue]-outputData.length;
         successDirExists=false;
      }

      NSString *bucketDir=[current[@"successDir"]
                           stringByAppendingPathComponent:[NSString stringWithFormat:@"%lld",bucketNumber]
                           ];
      if (!successDirExists)
      {
         if (![fileManager createDirectoryAtPath:bucketDir withIntermediateDirectories:YES attributes:nil error:&error])
         {
            [response appendFormat:@"can not create %@\r\n",bucketDir];
            break;
         }
         successDirExists=true;
      }
      
      [outputData replaceBytesInRange:NSMakeRange(0,0) withBytes:headData.bytes length:51 ];
      [outputData writeToFile:[bucketDir stringByAppendingPathComponent:[srcName stringByAppendingPathExtension:@"part"]] atomically:NO];
   }
   
//move to doneFilePath
   NSString *errMsg=moveDup(
                            fileManager,
                            srcFile,
                            [originalsDir stringByAppendingPathComponent:noUnderscoreSuffixBeforeDcmExt(srcName)]);
   if (errMsg) [response appendString:errMsg];
   [doneSet addObject:dstName];
}//end parsed
[inputData setLength:0];

   
}//end autorelease pool
   return 0;
}
