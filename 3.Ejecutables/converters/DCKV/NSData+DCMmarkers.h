//
//  NSData+DCMmarkers.h
//  D2M
//
//  Created by jacquesfauquex on 2021-02-24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (DCMmarkers)

@property (class, nonatomic, assign, readonly) NSData* zero;
@property (class, nonatomic, assign, readonly) NSData* backslash;
@property (class, nonatomic, assign, readonly) NSData* equal;

@end

NS_ASSUME_NONNULL_END
