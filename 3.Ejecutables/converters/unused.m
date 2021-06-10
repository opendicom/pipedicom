//
//  unused.m
//  converters
//
//  Created by jacquesfauquex on 2021-06-10.
//

#import "unused.h"


NSString *tagChainFromDCKVkey(NSString *DCKVkey)
{
   if (DCKVkey.length < 21) return [DCKVkey substringWithRange:NSMakeRange(9,8)];
   if (DCKVkey.length < 41) return
      [
       [DCKVkey substringWithRange:NSMakeRange(9,8)]
       stringByAppendingString:
       [DCKVkey substringWithRange:NSMakeRange(29,8)]
       ];
   if (DCKVkey.length < 61) return
      [
        [DCKVkey substringWithRange:NSMakeRange(9,8)]
        stringByAppendingString:
        [
         [DCKVkey substringWithRange:NSMakeRange(29,8)]
          stringByAppendingString:
           [DCKVkey substringWithRange:NSMakeRange(49,8)]
        ]
      ];
   if (DCKVkey.length < 81) return
      [
        [DCKVkey substringWithRange:NSMakeRange(9,8)]
        stringByAppendingString:
        [
         [DCKVkey substringWithRange:NSMakeRange(29,8)]
          stringByAppendingString:
         [
           [DCKVkey substringWithRange:NSMakeRange(49,8)]
           stringByAppendingString:
            [DCKVkey substringWithRange:NSMakeRange(69,8)]
         ]
      ]
   ];

   return @"deeperThanFour";
}



/*
void logger(NSString *format, ... )
{
   //https://azizuysal.wordpress.com/2011/01/02/redirecting-nslog-output-to-a-file-on-demand-for-iphone-debugging/
   //writes to stderr which was defined as first arg of the function
   NSString *string=nil;
   
   va_list args;
   va_start(args, format);
   string=[[NSString alloc] initWithFormat:format arguments:args];
   va_end(args);
   
   NSFileHandle *e=[NSFileHandle fileHandleForUpdatingAtPath:@"/dev/stderr"];
   if (e)
   {
      [e seekToEndOfFile];
      [e writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
   }
}
*/



int moveFile(NSFileManager *fileManager, NSString *src, NSString *dst, NSUInteger rpc)
{
   NSArray *srcComponents=[src componentsSeparatedByString:@"/"];
   NSString *relativePart;
   if (srcComponents.count > rpc)
      relativePart=[[srcComponents subarrayWithRange:NSMakeRange(srcComponents.count - rpc - 1,rpc)]componentsJoinedByString:@"/"];
   else relativePart=src;
   
   NSString *destFile=[dst stringByAppendingPathComponent:relativePart];
   NSString *destFolder=[destFile stringByDeletingLastPathComponent];
   
   NSError *error;
   BOOL isDirectory;
   if (![fileManager fileExistsAtPath:destFolder isDirectory:&isDirectory] && [fileManager createDirectoryAtPath:destFolder withIntermediateDirectories:YES attributes:nil error:&error])
   {
      LOG_WARNING(@"could not create dest directory '%@'",destFolder);
      return failure;
   }
   
   if (!isDirectory)
   {
      LOG_WARNING(@"dest '%@' is not a directory",destFolder);
      return failure;
   }

   if ([fileManager fileExistsAtPath:destFile])
   {
      LOG_WARNING(@"dest file '%@' already exists",destFile);
      return failure;
   }
   
   if ([fileManager moveItemAtPath:src toPath:destFile error:&error]) return success;
   LOG_WARNING(@"could not move '%@' to '%@': %@",src,destFile,error.description);
   return failure;
}


int writeData(NSFileManager *fileManager, NSData *data, NSString *src, NSString *dst, NSUInteger rpc, NSString *ext)
{
   NSArray *srcComponents=[src componentsSeparatedByString:@"/"];
   NSString *relativePart;
   if (srcComponents.count > rpc)
      relativePart=[[srcComponents subarrayWithRange:NSMakeRange(srcComponents.count - rpc - 1,rpc)]componentsJoinedByString:@"/"];
   else relativePart=src;
   
   NSString *destFile=nil;
   if (ext && ext.length) destFile=[[dst stringByAppendingPathComponent:relativePart]stringByDeletingPathExtension];
   else destFile=[dst stringByAppendingPathComponent:relativePart];
   
   NSString *destFolder=[destFile stringByDeletingLastPathComponent];
   
   NSError *error;
   BOOL isDirectory;
   if (![fileManager fileExistsAtPath:destFolder isDirectory:&isDirectory] && [fileManager createDirectoryAtPath:destFolder withIntermediateDirectories:YES attributes:nil error:&error])
   {
      LOG_WARNING(@"could not create dest directory '%@'",destFolder);
      return failure;
   }
   
   if (!isDirectory)
   {
      LOG_WARNING(@"dest '%@' is not a directory",destFolder);
      return failure;
   }

   if ([fileManager fileExistsAtPath:destFile])
   {
      LOG_WARNING(@"dest file '%@' already exists",destFile);
      return failure;
   }
   
   if ([data writeToFile:destFile options:0 error:&error]) return success;
   LOG_WARNING(@"could not write data parsed from '%@' to '%@': %@",src,destFile,error.description);
   return failure;
}


int writeBulkData(NSFileManager *fileManager, NSData *srcData, struct dckRangeVecs bulkdatas, NSString *src, NSString *dst, NSUInteger rpc)
{
   if (bulkdatas.curTop==NSNotFound) return success;//nothing to do
   
   NSArray *srcComponents=[src componentsSeparatedByString:@"/"];
   NSString *relativePart;
   if (srcComponents.count > rpc)
      relativePart=
      [
       [
        [srcComponents subarrayWithRange:NSMakeRange(srcComponents.count - rpc - 1,rpc)
         ]
        componentsJoinedByString:@"/"
        ]
       stringByAppendingPathExtension:@"bulkdata"
       ];
   else
      relativePart=
      [src stringByAppendingPathExtension:@"bulkdata"];
   

   NSString *destFolder=[dst stringByAppendingPathComponent:relativePart];
   NSError *error;
   BOOL isDirectory;
   if (![fileManager fileExistsAtPath:destFolder isDirectory:&isDirectory] && [fileManager createDirectoryAtPath:destFolder withIntermediateDirectories:YES attributes:nil error:&error])
   {
      LOG_WARNING(@"could not create dest directory '%@'",destFolder);
      return failure;
   }
   if (!isDirectory)
   {
      LOG_WARNING(@"dest '%@' is not a directory",destFolder);
      return failure;
   }
   
   struct dckRange bulkdata=popDckRange(bulkdatas);
   while (bulkdata.dck)
   {
      if (![[srcData subdataWithRange:NSMakeRange(bulkdata.loc,bulkdata.len)]writeToFile:[destFolder stringByAppendingPathComponent:bulkdata.dck] options:0 error:&error])
      {
         LOG_WARNING(@"could not write %@. %@",[destFolder stringByAppendingPathComponent:bulkdata.dck],error.debugDescription);
         return failure;
      }
      bulkdata=popDckRange(bulkdatas);
   }
   return success;
}

@implementation unused

@end
