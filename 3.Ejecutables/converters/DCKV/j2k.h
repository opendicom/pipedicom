//
//  j2k.h
//  DCKV
//
//  Created by jacquesfauquex on 2021-06-15.

#import <Foundation/Foundation.h>


enum {
   undf=0,
   natv,
   j2kb,
   j2kf,
   j2kh,
   j2ki,
   j2kr,
   j2ks
};
// j2kb, j2kf, j2kh, j2ki require FrameBFHI JSON codification


int compressJ2KR(
             NSString *pixelUrl,
             NSData *pixelData,
             NSMutableDictionary *parsedAttrs,
             NSMutableDictionary *j2kBlobDict,
             NSMutableDictionary *j2kAttrs,
             NSMutableString *message
             );

int compressBFHI(
             NSString *pixelUrl,
             NSData *pixelData,
             NSMutableDictionary *parsedAttrs,
             NSMutableDictionary *j2kBlobDict,
             NSMutableDictionary *j2kAttrs,
             NSMutableString *message
             );


@interface j2k : NSObject
@end
