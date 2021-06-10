#import "NSData+MD5.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSData (MD5)

- (NSString *)MD5String
{
   unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
   CC_MD5(self.bytes, (unsigned int)self.length, md5Buffer);
   NSMutableString* string = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
   for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
       [string appendFormat:@"%02x", md5Buffer[i]];
   return string;
}

@end
