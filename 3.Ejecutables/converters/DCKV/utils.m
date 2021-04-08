#import "utils.h"
#import "ODLog.h"

#pragma mark - terminal execution
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
NSMutableData* decodedData = [NSMutableData dataWithLength:10];
uint32 *decodedChars = (uint32*)decodedData.mutableBytes;

uint32 bufLength=sopDict.count * 4;
NSMutableData *bufTagData=[NSMutableData dataWithLength:bufLength];
uint32 *bufTag=(uint32*)bufTagData.mutableBytes;

NSMutableData *bufIdxData=[NSMutableData dataWithLength:bufLength];
uint32 *bufIdx=(uint32*)bufIdxData.mutableBytes;

NSRange *datasetRanges[sopDict.count / 10];


void nextKey(
             uint32 **bufTag,
             uint32 **bufIdx,
             NSRange **datasetRanges,
             uint32 datasetIdx,
             NSString *previousTagChain,
             NSArray *DCKVkeys,
             uint32 keyIdx
             )
{
   if (keyIdx < DCKVkeys.count)
   {
      //get TagChain
      NSString *newTagChain=tagChainFromDCKVkey(DCKVkeys[keyIdx]);
      
      if (previousTagChain.length == newTagChain.length)
      {
         //same level
         if ([DCKVkeys[keyIdx] hasSuffix:@"SQ"])
         {
            
         }
         else if ([DCKVkeys[keyIdx] hasSuffix:@"IZ"])
         {
            //end of an item
         }
         else
         {
            //just another attribute of the item
            
            // datasetIdx does not change (we are in the same item)
            NSRange thisDatasetRange=*datasetRanges[datasetIdx];
            // -> bufTag and bufIdx
            *bufTag[thisDatasetRange.length]=(uint32)[[newTagChain substringWithRange:NSMakeRange(newTagChain.length - 8,8)] longLongValue];
            *bufIdx[thisDatasetRange.length]=keyIdx;
            
            thisDatasetRange.length++;
            keyIdx++;
         }
      }
      else //always higher level (see algorithm below for lower level)
      {
         
      }
   }
}

void DCKVkeysindexing(
   uint32 **bufTag,
   uint32 **bufIdx,
   NSRange **datasetRanges,
   NSArray *DCKVkeys,
   BOOL alreadySorted
)
{
   NSLog(@"DCKVkeysindexing");
   //fills up buf and datasetOffsets
   
   //buf size is DCKVkeys.count
   //contains lists of
   //datasetOffsets is larger than necesary (for istancde DCKVkeys.count / 10)
   
   NSArray *array;
   if (alreadySorted) array=DCKVkeys;
   else array=[DCKVkeys sortedArrayUsingSelector:@selector(compare:)];
   
   *datasetRanges[0]=NSMakeRange(0,0);
   nextKey(
           bufTag,
           bufIdx,
           datasetRanges,
           0,
           @"00000000-00",
           DCKVkeys,
           0
           );


}

void DCKVkeyindex(uint32 **bufTag, uint32 **bufIdx, uint32 **datasetOffsets, NSString *DICOMwebKey)
{
   NSLog(@"DCKVkeyindex");
}

*/

#pragma mark - string functions

void trimLeadingSpaces(NSMutableString *mutableString)
{
   while ([mutableString hasPrefix:@" "])
   {
      [mutableString deleteCharactersInRange:NSMakeRange(0,1)];
   }
}

void trimTrailingSpaces(NSMutableString *mutableString)
{
   while ([mutableString hasSuffix:@" "])
   {
      [mutableString deleteCharactersInRange:NSMakeRange(mutableString.length-1,1)];
   }
}

void trimLeadingAndTrailingSpaces(NSMutableString *mutableString)
{
   trimLeadingSpaces(mutableString);
   trimTrailingSpaces(mutableString);
}

int visibleFiles(NSFileManager *fileManager, NSArray *mountPoints, NSMutableArray *paths)
{
   BOOL isDirectory=false;
   for (NSString *mountPoint in mountPoints)
   {
      if ([mountPoint hasPrefix:@"."]) continue;
      
      NSString *noSymlink=[[mountPoint stringByExpandingTildeInPath] stringByResolvingSymlinksInPath];

      if ([fileManager fileExistsAtPath:noSymlink isDirectory:&isDirectory])
      {
         if (isDirectory)
         {
            NSError *error;
            NSArray *contents=[fileManager contentsOfDirectoryAtPath:noSymlink error:&error];
            if (error)
            {
               LOG_WARNING(@"bad directory path %@",noSymlink);
               return failure;
            }
            
            if (visibleFiles(fileManager,contents, paths) != success) return failure;
         }
         else [paths addObject:noSymlink];
      }
   }
   return success;
}

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
