#import <Foundation/Foundation.h>
#import "DCKV.h"

#pragma mark - terminal execution

void DCKVkeysindexing(uint32 **bufTag, uint32 **bufIdx, NSRange **datasetRanges, NSArray *DCKVkeys, BOOL alreadySorted);

void DCKVkeyindex(uint32 **bufTag, uint32 **bufIdx, uint32 **datasetOffsets, NSString *DICOMwebKey);

#pragma mark - string functions

void trimLeadingSpaces(NSMutableString *mutableString);
void trimTrailingSpaces(NSMutableString *mutableString);
void trimLeadingAndTrailingSpaces(NSMutableString *mutableString);

#pragma mark - filesystem functions

int visibleFiles(NSFileManager *fileManager, NSArray *mountPoints, NSMutableArray *paths);

int moveFile(NSFileManager *fileManager, NSString *src, NSString *dst, NSUInteger rpc);//relative path components

int writeData(NSFileManager *fileManager, NSData *data, NSString *src, NSString *dst, NSUInteger rpc, NSString *ext);//relative path components

int writeBulkData(NSFileManager *fileManager, NSData *srcData, struct dckRangeVecs bulkdatas, NSString *src, NSString *dst, NSUInteger rpc);//relative path components
