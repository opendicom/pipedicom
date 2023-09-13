#import <Foundation/Foundation.h>

extern char const  base64EncodingTable[65];
extern char const  base64DecodingTable[128];

//-----------------------------------------
#pragma mark String

NSMutableString* B64JSONstringWithData(NSData *binData);

NSData* B64dataWithData(NSData *binData);
NSData* dataWithB64String(NSString *base64NSString);

//-----------------------------------------
#pragma mark - UID

NSString* b64ui(NSString* uidString);
