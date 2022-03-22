//
//  NSData+DCMmarkers.h
//  D2M
//
//  Created by jacquesfauquex on 2021-02-24.

#import <Foundation/Foundation.h>

@interface NSData (DCMmarkers)

@property (class, nonatomic, assign, readonly) NSData* zero;
@property (class, nonatomic, assign, readonly) NSData* backslash;
@property (class, nonatomic, assign, readonly) NSData* equal;

//j2k
@property (class, nonatomic, assign, readonly) NSData* SOC;
@property (class, nonatomic, assign, readonly) NSData* SOT;
@property (class, nonatomic, assign, readonly) NSData* EOC;

@end
