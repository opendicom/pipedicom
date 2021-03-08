#import "utils.h"

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



