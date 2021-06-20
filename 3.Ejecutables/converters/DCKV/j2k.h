//
//  j2k.h
//  DCKV
//
//  Created by jacquesfauquex on 2021-06-15.
//

#import <Foundation/Foundation.h>

int compress(
             NSString *pixelUrl,
             NSData *pixelData,
             NSMutableDictionary *parsedAttrs,
             NSMutableDictionary *j2kBlobDict,
             NSMutableDictionary *j2kAttrs
             );

NS_ASSUME_NONNULL_BEGIN

@interface j2k : NSObject

@end

NS_ASSUME_NONNULL_END
