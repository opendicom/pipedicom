//
//  unused.h
//  converters
//
//  Created by jacquesfauquex on 2021-06-10.
//

#import <Foundation/Foundation.h>

NSString *tagChainFromDCKVkey(NSString *DCKVkey);


int moveFile(NSFileManager *fileManager, NSString *src, NSString *dst, NSUInteger rpc);//relative path components

int writeData(NSFileManager *fileManager, NSData *data, NSString *src, NSString *dst, NSUInteger rpc, NSString *ext);//relative path components

int writeBulkData(NSFileManager *fileManager, NSData *srcData, struct dckRangeVecs bulkdatas, NSString *src, NSString *dst, NSUInteger rpc);//relative path components

NS_ASSUME_NONNULL_BEGIN

@interface unused : NSObject

@end

NS_ASSUME_NONNULL_END
