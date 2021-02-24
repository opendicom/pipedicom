//  Created by pcs on 29/1/21.
//  Copyright © 2021 opendicom.com. All rights reserved.

/*
 TODO
 
 If group 2 start with preamble
 
 urls
 at root level : base url
 in binary attributes:
 - empty map refers to the path "tag"
 */



#import <Foundation/Foundation.h>

static uint8 paddingspace=' ';
static uint8 paddingzero=0;
static uint16 vl0=0;
static uint16 vl4=4;
static uint16 vl8=8;
static uint32 vll0=0xFFFFFFFF;
static uint32 undefinedlength=0xFFFFFFFF;
static uint64 itemstart=0xffffffffe000fffe;
static uint64 itemend=0xe00dfffe;
static uint64 SQend=0xe0ddfffe;
static uint8 hexa[]={
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,
   0,0xA,0xB,0xC,0xD,0xE,0xF
};

uint32 shortshortFromFourByteHexaString(NSString *string)
{
   return
       (hexa[[string characterAtIndex:0]]*0x1000)
      +(hexa[[string characterAtIndex:1]]*0x100)
   
      +(hexa[[string characterAtIndex:2]]*0x10)
      +(hexa[[string characterAtIndex:3]]*0x1)
   
   
      +(hexa[[string characterAtIndex:4]]*0x10000000)
      +(hexa[[string characterAtIndex:5]]*0x1000000)
   
      +(hexa[[string characterAtIndex:6]]*0x100000)
      +(hexa[[string characterAtIndex:7]]*0x10000)
   ;
}

#pragma mark TODO: encodings


void J2D(NSDictionary *J, NSMutableData *D)
{
    NSMutableDictionary *A=[NSMutableDictionary dictionary];//Attributes
    for (NSString *key in J)
    {
        if ([J[key] isKindOfClass:[NSDictionary class]]) [A addEntriesFromDictionary:J[key]];
    }
    NSArray *K=nil;
    if (A.count)
    {
        K=[[A allKeys] sortedArrayUsingSelector:@selector(compare:)];
    }

#pragma mark TODO Preambule?
   
   
    uint32 tag;
    uint16 vr;
    uint16 vl;
    uint32 vll;
    
    for (NSString *key in K)
    {
        vr=[key characterAtIndex:key.length-2]+([key characterAtIndex:key.length-1]*0x100);
        tag=shortshortFromFourByteHexaString([key substringWithRange:NSMakeRange(((key.length/18 -1)*18)+9, 8)]);
        switch (vr) {
            
#pragma mark AE CS DT LO PN SH TM
            case 0x4541://AE
            case 0x5343://CS
            case 0x5444://DT
            case 0x4f4c://LO
            case 0x4e50://PN
            case 0x4853://SH
            case 0x4d54://TM
            {
                [D appendBytes:&tag length:4];
                [D appendBytes:&vr length:2];
                if ([A[key] count])
                {
                   NSString *string=[A[key] componentsJoinedByString:@"\\"];
                   BOOL odd=string.length % 2;
                   vl=string.length + odd;
                   [D appendBytes:&vl length:2];
                   [D appendData:[string dataUsingEncoding:NSISOLatin1StringEncoding]];
                   if (odd) [D appendBytes:&paddingspace length:1];
                }
                else [D appendBytes:&vl0 length:2];
                break;
            }
            
#pragma mark LT ST
           case 0x544c://LT
           case 0x5453://ST
           {
               [D appendBytes:&tag length:4];
               [D appendBytes:&vr length:2];
               if ([A[key] count])
               {
                 BOOL odd=[(A[key])[0] length] % 2;
                 vl=[(A[key])[0] length] + odd;
                 [D appendBytes:&vl length:2];
                 [D appendData:[(A[key])[0] dataUsingEncoding:NSISOLatin1StringEncoding]];
                 if (odd) [D appendBytes:&paddingspace length:1];
               }
               else [D appendBytes:&vl0 length:2];
               break;
           }

#pragma mark AS
            case 0x5341://AS 4 chars (one value only)
            {
                [D appendBytes:&tag length:4];
                [D appendBytes:&vr length:2];
                [D appendBytes:&vl4 length:2];
                [D appendData:[(A[key])[0] dataUsingEncoding:NSASCIIStringEncoding]];
                break;
            }
            
            
#pragma mark DA
            case 0x4144://DA 8 chars (one value only)
            {
                [D appendBytes:&tag length:4];
                [D appendBytes:&vr length:2];
                [D appendBytes:&vl8 length:2];
                [D appendData:[(A[key])[0] dataUsingEncoding:NSASCIIStringEncoding]];
                break;
            }

#pragma mark UC UR UT
            case 0x4355://UC
            /*
             Unlimited Characters
             */
            case 0x5255://UR
            /*
             Universal Resource Identifier or Universal Resource Locator (URI/URL)
             */
            case 0x5455://UT
            /*
             A character string that may contain one or more paragraphs. It may contain the Graphic Character set and the Control Characters, CR, LF, FF, and ESC. It may be padded with trailing spaces, which may be ignored, but leading spaces are considered to be significant. Data Elements with this VR shall not be multi-valued and therefore character code 5CH (the BACKSLASH "\" in ISO-IR 6) may be used.
             */
            {
                [D appendBytes:&tag length:4];
                [D appendBytes:&vr length:2];
                [D appendBytes:&vl0 length:2];
                
                NSData *data=[(A[key])[0] dataUsingEncoding:NSISOLatin1StringEncoding];
                BOOL odd=data.length % 2;
                vll=(uint32)data.length + odd;
                [D appendBytes:&vll length:4];
                [D appendData:data];
                if (odd) [D appendBytes:&paddingspace length:1];

                break;
            }
            
#pragma mark UI
            case 0x4955:
            {
               [D appendBytes:&tag length:4];
               [D appendBytes:&vr length:2];
               NSString *string=[A[key] componentsJoinedByString:@"\\"];
               BOOL odd=string.length % 2;
               vl=string.length + odd;
               [D appendBytes:&vl length:2];
               [D appendData:[string dataUsingEncoding:NSASCIIStringEncoding]];
               if (odd) [D appendBytes:&paddingzero length:1];
                break;
            }
            
#pragma mark SQ
            case 0x5153:
            {
               [D appendBytes:&tag length:4];
               [D appendBytes:&vr length:2];
               [D appendBytes:&vl0 length:2];
               [D appendBytes:&undefinedlength length:4];
                break;
            }
            
#pragma mark IQ
            case 0x5149:
            {
               [D appendBytes:&itemstart length:8];
                break;
            }
            
#pragma mark IZ
            case 0x5A49:
            {
               [D appendBytes:&itemend length:8];
                break;
            }
            
#pragma mark SZ
            case 0x5A53:
            {
               [D appendBytes:&SQend length:8];
                break;
            }
            
#pragma mark IS DS
            case 0x5344://DS
            case 0x5349://IS
            {
               [D appendBytes:&tag length:4];
               [D appendBytes:&vr length:2];
               switch ([A[key] count]) {
                     
                  case 0:
                     [D appendBytes:&vl0 length:2];
                     break;
                     
                  case 1: {
                     NSString *string=[(A[key])[0] stringValue];
                     BOOL odd=string.length % 2;
                     vl=string.length + odd;
                     [D appendBytes:&vl length:2];
                     [D appendData:[string dataUsingEncoding:NSISOLatin1StringEncoding]];
                     if (odd) [D appendBytes:&paddingspace length:1];
                  }
                     break;
                     
                  default: {
                     NSMutableString *mutableString=[NSMutableString string];
                     [mutableString appendString:[(A[key])[0] stringValue]];
                     for (NSNumber *number in [A[key] subarrayWithRange:NSMakeRange(1,[A[key] count]-1)])
                     {
                        [mutableString appendString:@"\\"];
                        [mutableString appendString:[number
                                                     stringValue]];
                     }
                     BOOL odd=mutableString.length % 2;
                     vl=mutableString.length + odd;
                     [D appendBytes:&vl length:2];
                     [D appendData:[mutableString dataUsingEncoding:NSISOLatin1StringEncoding]];
                     if (odd) [D appendBytes:&paddingspace length:1];
                  }
                  break;
               }
               break;
            }
            
            
#pragma mark SL
            case 0x4C53:
            {
                //Signed Long
               [D appendBytes:&tag length:4];
               [D appendBytes:&vr length:2];
               vl=[A[key] count]*4;
               [D appendBytes:&vl length:2];
               sint32 sl;
               for (NSNumber *number in A[key])
               {
                  sl=[number intValue];
                  [D appendBytes:&sl length:4];
               }
                break;
            }
            
#pragma mark UL
            case 0x4C55:
            {
                //Unsigned Long
               [D appendBytes:&tag length:4];
               [D appendBytes:&vr length:2];
               vl=[A[key] count]*4;
               [D appendBytes:&vl length:2];
               uint32 ul;
               for (NSNumber *number in A[key])
               {
                  ul=[number unsignedIntValue];
                  [D appendBytes:&ul length:4];
               }
                break;
            }
            
            
#pragma mark SS
            case 0x5353:
            {
                //Signed Short
               [D appendBytes:&tag length:4];
               [D appendBytes:&vr length:2];
               vl=[A[key] count]*2;
               [D appendBytes:&vl length:2];
               sint16 ss;
               for (NSNumber *number in A[key])
               {
                  ss=[number shortValue];
                  [D appendBytes:&ss length:2];
               }
                break;
            }
            
#pragma mark US
            case 0x5355:
            {
                //Unsigned Short
               [D appendBytes:&tag length:4];
               [D appendBytes:&vr length:2];
               vl=[A[key] count]*2;
               [D appendBytes:&vl length:2];
               uint16 us;
               for (NSNumber *number in A[key])
               {
                  us=[number unsignedShortValue];
                  [D appendBytes:&us length:2];
               }
                break;
            }
            
#pragma mark SV
            case 0x5653:
            {
                //Signed 64-bit Very Long
               //Signed Long
              [D appendBytes:&tag length:4];
              [D appendBytes:&vr length:2];
              [D appendBytes:&vl0 length:2];
              vll=(uint32)[A[key] count]*8;
              [D appendBytes:&vll length:4];
              sint64 sv;
              for (NSNumber *number in A[key])
              {
                 sv=[number longLongValue];
                 [D appendBytes:&sv length:8];
              }
               break;
            }
            
#pragma mark UV
            case 0x5655:
            {
                //Unsigned 64-bit Very Long
               [D appendBytes:&tag length:4];
               [D appendBytes:&vr length:2];
               [D appendBytes:&vl0 length:2];
               vll=(uint32)[A[key] count]*8;
               [D appendBytes:&vll length:4];
               uint64 uv;
               for (NSNumber *number in A[key])
               {
                  uv=[number unsignedLongLongValue];
                  [D appendBytes:&uv length:8];
               }
                break;
            }
            
#pragma mark FL
            case 0x4C46:
            {
                //Unsigned Long
               [D appendBytes:&tag length:4];
               [D appendBytes:&vr length:2];
               vl=[A[key] count]*4;
               [D appendBytes:&vl length:2];
               float fl;
               for (NSNumber *number in A[key])
               {
                  fl=[number floatValue];
                  [D appendBytes:&fl length:4];
               }
                break;
            }
            
#pragma mark FD
            case 0x4446:
            {
               /* 8 byte*/
              [D appendBytes:&tag length:4];
               [D appendBytes:&vr length:2];
               vl=[A[key] count]*8;
               [D appendBytes:&vl length:2];
               float fd;
               for (NSNumber *number in A[key])
               {
                  fd=[number doubleValue];
                  [D appendBytes:&fd length:8];
               }
                break;
            }
            
#pragma mark OB
            case 0x424F:
            /*
             An octet-stream where the encoding of the contents is specified by the negotiated Transfer Syntax. OB is a VR that is insensitive to byte ordering (see Section 7.3). The octet-stream shall be padded with a single trailing NULL byte value (00H) when necessary to achieve even length.
             */
           {
              [D appendBytes:&tag length:4];
              [D appendBytes:&vr length:2];
              [D appendBytes:&vl0 length:2];
              if ([A[key] count])
              {
                 NSData *data=[[NSData alloc]initWithBase64EncodedData:[(A[key])[0] dataUsingEncoding:NSASCIIStringEncoding ] options:0];
                 BOOL odd=data.length % 2;
                 vll=(uint32)data.length + odd;
                 [D appendBytes:&vll length:4];
                 [D appendData:data];
                 if (odd) [D appendBytes:&paddingzero length:1];
              }
              else [D appendBytes:&vll0 length:4];
              break;
           }
              
#pragma mark OD OF OL OV OW UN
              
            case 0x444F://OD
            /*
             A stream of 64-bit IEEE 754:1985 floating point words. OD is a VR that requires byte swapping within each 64-bit word when changing byte ordering (see Section 7.3).
             */
            case 0x464F://OF
            /*
             A stream of 32-bit IEEE 754:1985 floating point words. OF is a VR that requires byte swapping within each 32-bit word when changing byte ordering (see Section 7.3).
             */
            case 0x4C4F://OL
            /*
             A stream of 32-bit words where the encoding of the contents is specified by the negotiated Transfer Syntax. OL is a VR that requires byte swapping within each word when changing byte ordering (see Section 7.3).
             */
            case 0x564F://OV
            /*
             A stream of 64-bit words where the encoding of the contents is specified by the negotiated Transfer Syntax. OV is a VR that requires byte swapping within each word when changing byte ordering (see Section 7.3).
             */
            case 0x574F://OW
            /*
             A stream of 16-bit words where the encoding of the contents is specified by the negotiated Transfer Syntax. OW is a VR that requires byte swapping within each word when changing byte ordering (see Section 7.3).
             */
            case 0x4E55://UN
            {
               [D appendBytes:&tag length:4];
               [D appendBytes:&vr length:2];
               [D appendBytes:&vl0 length:2];
               if ([A[key] count])
               {
                  NSData *data=[[NSData alloc]initWithBase64EncodedData:[(A[key])[0] dataUsingEncoding:NSASCIIStringEncoding ] options:0];
                  vll=(uint32)data.length;
                  [D appendBytes:&vll length:4];
                  [D appendData:data];
               }
               else [D appendBytes:&vll0 length:4];
               break;
            }
            
            
#pragma mark AT
            case 0x5441:
            {
               /*
                Ordered pair of 16-bit unsigned integers that is the value of a Data Element Tag.
                In mapxmldicom it is encoded as one or more string(s)
                */
               [D appendBytes:&tag length:4];
               [D appendBytes:&vr length:2];
               vl=[A[key] count]*4;
               [D appendBytes:&vl length:2];
               uint32 AT;
               for (NSString *string in A[key])
               {
                  AT=shortshortFromFourByteHexaString(string);
                  [D appendBytes:&AT length:4];
               }
                break;
            }
            
            
            default://ERROR unknow VR
            {
#pragma mark ERROR4: unknown VR
                NSLog(@"vr: %d", vr);
                NSLog(@"ERROR4: unknown VR");
                exit(4);
                break;
            }
        }
    }
}
