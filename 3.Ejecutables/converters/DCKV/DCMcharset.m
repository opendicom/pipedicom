#import "DCMcharset.h"
#import "ODLog.h"

static NSDictionary *CSNS=nil;
NSUInteger stringEncoding(NSString *CS00080005)
{
   if (!CS00080005)
   {
      return 0;
   }
   if (!CSNS)
      CSNS=@{
         @"ISO_IR 100":[NSNumber numberWithUnsignedInteger:NSISOLatin1StringEncoding],
         //@"ISO_IR 101":[NSNumber numberWithUnsignedInteger:NSISOLatin2StringEncoding],
         //@"ISO_IR 144":[NSNumber numberWithUnsignedInteger:NSWindowsCP1251StringEncoding],
         //@"ISO_IR 126":[NSNumber numberWithUnsignedInteger:NSWindowsCP1253StringEncoding],
         //@"ISO_IR 13":[NSNumber numberWithUnsignedInteger:NSISO2022JPStringEncoding],
         @"ISO 2022 IR 6":[NSNumber numberWithUnsignedInteger:NSASCIIStringEncoding],
         @"ISO 2022 IR 100":[NSNumber numberWithUnsignedInteger:NSISOLatin1StringEncoding],
         //@"ISO 2022 IR 101":[NSNumber numberWithUnsignedInteger:NSISOLatin2StringEncoding],
         //@"ISO 2022 IR 144":[NSNumber numberWithUnsignedInteger:NSWindowsCP1251StringEncoding],
         //@"ISO 2022 IR 126":[NSNumber numberWithUnsignedInteger:NSWindowsCP1253StringEncoding],
         //@"ISO 2022 IR 13":[NSNumber numberWithUnsignedInteger:NSISO2022JPStringEncoding],
         @"ISO_IR 192":[NSNumber numberWithUnsignedInteger:NSUTF8StringEncoding]
      };
   NSNumber *stringEncodingNumber=CSNS[CS00080005];
   if (!stringEncodingNumber) return NSUIntegerMax;
   return stringEncodingNumber.unsignedIntegerValue;
};

const NSUInteger ISO_IR13=NSISO2022JPStringEncoding;//japanese
const NSUInteger ISO_IR100=NSISOLatin1StringEncoding;//latin 1
const NSUInteger ISO_IR101=NSISOLatin2StringEncoding;//latin 2
const NSUInteger ISO_IR109=0;//latin 3
const NSUInteger ISO_IR110=0;//latin 4
const NSUInteger ISO_IR126=NSWindowsCP1253StringEncoding;//greek
const NSUInteger ISO_IR127=0;//arabic
const NSUInteger ISO_IR138=0;//hebrew
const NSUInteger ISO_IR144=NSWindowsCP1251StringEncoding;//cyrilic
const NSUInteger ISO_IR148=0;//latin 5
const NSUInteger ISO_IR166=0;//thai
const NSUInteger ISO_IR192=NSUTF8StringEncoding;

const NSUInteger ISO2022IR6=NSASCIIStringEncoding;//default
const NSUInteger ISO2022IR13=NSISO2022JPStringEncoding;//japanese
const NSUInteger ISO2022IR58=0;//simplified chinese
const NSUInteger ISO2022IR87=0;//japanese
const NSUInteger ISO2022IR100=NSISOLatin1StringEncoding;//latin 1
const NSUInteger ISO2022IR101=NSISOLatin2StringEncoding;//latin 2
const NSUInteger ISO2022IR109=0;//latin 3
const NSUInteger ISO2022IR110=0;//latin 4
const NSUInteger ISO2022IR126=NSWindowsCP1253StringEncoding;//greek
const NSUInteger ISO2022IR127=0;//arabic
const NSUInteger ISO2022IR138=0;//hebrew
const NSUInteger ISO2022IR144=NSWindowsCP1251StringEncoding;//cyrilic
const NSUInteger ISO2022IR148=0;//latin 5
const NSUInteger ISO2022IR149=0;//korean
const NSUInteger ISO2022IR159=0;//japanese
const NSUInteger ISO2022IR166=0;//thai

const NSUInteger GB18030=0;//
const NSUInteger GBK=0;
