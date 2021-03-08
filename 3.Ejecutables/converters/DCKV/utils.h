#import <Foundation/Foundation.h>


#pragma mark - terminal execution

void DCKVkeysindexing(uint32 **bufTag, uint32 **bufIdx, NSRange **datasetRanges, NSArray *DCKVkeys, BOOL alreadySorted);

void DCKVkeyindex(uint32 **bufTag, uint32 **bufIdx, uint32 **datasetOffsets, NSString *DICOMwebKey);

#pragma mark - string functions

void trimLeadingSpaces(NSMutableString *mutableString);
void trimTrailingSpaces(NSMutableString *mutableString);
void trimLeadingAndTrailingSpaces(NSMutableString *mutableString);
