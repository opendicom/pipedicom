#import <Foundation/Foundation.h>

UInt16 uint16FromCuartetBuffer( unsigned char* buffer, NSUInteger index);
UInt32 uint32FromCuartetBuffer( unsigned char* buffer, NSUInteger index);
uint32 uint32visual(uint32 tag);
UInt8 octetFromCuartetBuffer( unsigned char* buffer, NSUInteger index);
void setMutabledataFromCuartetBuffer( unsigned char* buffer, NSUInteger startindex, NSUInteger afterindex, NSMutableData *md);
