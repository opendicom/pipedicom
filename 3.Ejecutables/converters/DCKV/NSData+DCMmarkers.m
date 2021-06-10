//
//  NSData+DCMmarkers.m
//  D2M
//
//  Created by jacquesfauquex on 2021-02-24.
//

#import "NSData+DCMmarkers.h"

@implementation NSData (DCMmarkers)

const unsigned char zero=0x0;
static NSData *zeroData=nil;
+(NSData*)zero
{
   if (!zeroData) zeroData=[NSData dataWithBytes:&zero length:1];
   return zeroData;
}

const unsigned char backslash='\\';
static NSData *backslashData=nil;
+(NSData*)backslash
{
   if (!backslashData) backslashData=[NSData dataWithBytes:&backslash length:1];
   return backslashData;
}

const unsigned char equal='=';
static NSData *equalData=nil;
+(NSData*)equal
{
   if (!equalData) equalData=[NSData dataWithBytes:&equal length:1];
   return equalData;
}

//start fragment E07F1000 4F420000 FFFFFFFF FEFF00E0 00000000 FEFF00E0 18D8


// end fragment FEFFDDE0 00000000
@end
