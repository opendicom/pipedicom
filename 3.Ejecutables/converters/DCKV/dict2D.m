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
#import "dict2D.h"
#import "ODLog.h"
#import "DCMcharset.h"
#import "NSData+DCMmarkers.h"
#import "B64.h"

static uint8 paddingspace=' ';
static uint8 paddingzero=0;
static uint16 vl0=0;
static uint16 vl4=4;
static uint16 vl8=8;
static uint32 vll0=0x00000000;
static uint32 undefinedlength=0xFFFFFFFF;
static uint32 itemstart=0xe000fffe;
static uint64 itemstartundefined=0xffffffffe000fffe;
static uint64 itemempty=0xe000fffe;
static uint64 itemend=0xe00dfffe;
static uint64 SQend=0xe0ddfffe;
static uint8 hexa[]={
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,
   0,0xA,0xB,0xC,0xD,0xE,0xF
};

void appendFrame(NSMutableData *data, NSString *baseURLString, NSString *urlString, BOOL appendEOC, NSDictionary *blobDict)
{
   NSData *fragmentData;
   if (blobDict)
   {
      fragmentData=blobDict[urlString];
   }
   else
   {
      NSString *fragmentPath;
      if ([urlString hasPrefix:@"/"]) fragmentPath=urlString;
      else fragmentPath=[baseURLString stringByAppendingPathComponent:urlString];
      fragmentData=[NSData dataWithContentsOfFile:fragmentPath];
   }
   
   [data appendBytes:&itemstart length:4];
   uint32 l;
   if (appendEOC)
   {
      l=(uint32)fragmentData.length + 2;
      [data appendBytes:&l length:4];
      [data appendData:fragmentData];
      [data appendData:NSData.EOC];
   }
   else
   {
      l=(uint32)fragmentData.length;
      [data appendBytes:&l length:4];
      [data appendData:fragmentData];
   }
}

int charsetIndex4key(NSString *key)
{
   if (key.length % 9 < 3) return 1;
   int i=0;//ascii
   NSString *afterDash=[key componentsSeparatedByString:@"-"][1];
   NSString *ep=[afterDash substringToIndex:afterDash.length-2];//encoding prefix
   i=0;
   while (![evr[i] isEqualToString:ep] && (i < encodingTotal)) i++;
   if (i== encodingTotal)
   {
      LOG_ERROR(@"bad key encoding prefix '%@' in  %@",ep,key);
   }
   return i % encodingTotal;
}

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


int dict2D(
           NSString *baseURLString,
           NSDictionary *attrs,
           NSMutableData *data,
           NSUInteger pixelMode,
           NSDictionary *blobDict
           )
{
    if (attrs && attrs.count)
    {
       NSArray *keys=[[attrs allKeys] sortedArrayUsingSelector:@selector(compare:)];
      
       uint32 tag;
       uint16 vr;
       uint16 vl;
       uint32 vll;
       
       for (NSString *key in keys)
       {
           vr=[key characterAtIndex:key.length-2]+([key characterAtIndex:key.length-1]*0x100);
           tag=shortshortFromFourByteHexaString([key substringWithRange:NSMakeRange(((key.length/18 -1)*18)+9, 8)]);
          
          LOG_DEBUG(@"%08X-%c%c",tag,vr & 0xff,
                    vr >> 8);
          
           switch (vr) {

#pragma mark AS
            case 0x5341://AS 4 chars (one value only)
            {
                [data appendBytes:&tag length:4];
                [data appendBytes:&vr length:2];
                if ([attrs[key] count])
                {
                   [data appendBytes:&vl4 length:2];
                   [data appendData:[(attrs[key])[0] dataUsingEncoding:NSASCIIStringEncoding]];
                }
                else [data appendBytes:&vl0 length:2];
                break;
            }
            
            
#pragma mark DA
            case 0x4144://DA 8 chars (one value only)
            {
                [data appendBytes:&tag length:4];
                [data appendBytes:&vr length:2];
                if ([attrs[key] count])
                {
                   [data appendBytes:&vl8 length:2];
                   [data appendData:[(attrs[key])[0] dataUsingEncoding:NSASCIIStringEncoding]];
                }
                else [data appendBytes:&vl0 length:2];
                break;
            }

#pragma mark AE CS DT TM
            case 0x4541://AE
            case 0x5343://CS
            case 0x5444://DT
            case 0x4d54://TM
            {
               [data appendBytes:&tag length:4];
               [data appendBytes:&vr length:2];
               if ([attrs[key] count])
               {
                  NSData *stringData=[[attrs[key] componentsJoinedByString:@"\\"] dataUsingEncoding:NSISOLatin1StringEncoding];
                  BOOL odd=stringData.length % 2;
                  vl=stringData.length + odd;
                  [data appendBytes:&vl length:2];
                  [data appendData:stringData];
                  if (odd) [data appendBytes:&paddingspace length:1];
               }
               else [data appendBytes:&vl0 length:2];
               break;
            }
                 
#pragma mark LO SH
            case 0x4f4c://LO
            case 0x4853://SH
            {
               [data appendBytes:&tag length:4];
               [data appendBytes:&vr length:2];
               if (![attrs[key] count]) [data appendBytes:&vl0 length:2];
               else
                {
                   NSData *stringData=[[attrs[key] componentsJoinedByString:@"\\"] dataUsingEncoding:encodingNS[charsetIndex4key(key)]];
                
                   BOOL odd=stringData.length % 2;
                   vl=stringData.length + odd;
                   [data appendBytes:&vl length:2];
                   [data appendData:stringData];
                   if (odd) [data appendBytes:&paddingspace length:1];
                }
                break;
            }
               
#pragma mark LT ST
           case 0x544c://LT
           case 0x5453://ST
           {
              //not multivalued
               [data appendBytes:&tag length:4];
               [data appendBytes:&vr length:2];
               if (![attrs[key] count]) [data appendBytes:&vl0 length:2];
               else
               {
                  NSData *stringData=[(attrs[key])[0]  dataUsingEncoding:encodingNS[charsetIndex4key(key)]];
                  BOOL odd=stringData.length % 2;
                  vl=stringData.length + odd;
                  [data appendBytes:&vl length:2];
                  [data appendData:stringData];
                  if (odd) [data appendBytes:&paddingspace length:1];
               }
               break;
           }

#pragma mark UC
            case 0x4355://UC
            /*
             Unlimited Characters
             May be multivalued
             */
           {
               [data appendBytes:&tag length:4];
               [data appendBytes:&vr length:2];
               [data appendBytes:&vl0 length:2];//vll aligned on 4 bytes
              
              if (![attrs[key] count])
              {
                 [data appendBytes:&vl0 length:2];
                 [data appendBytes:&vl0 length:2];
              }
              else
              {
                 NSData *stringData=[[attrs[key] componentsJoinedByString:@"\\"] dataUsingEncoding:encodingNS[charsetIndex4key(key)]];
              
                 BOOL odd=stringData.length % 2;
                 vll=(uint32)(stringData.length + odd);
                 [data appendBytes:&vll length:4];
                 [data appendData:stringData];
                 if (odd) [data appendBytes:&paddingspace length:1];
              }
              break;
           }
              
#pragma mark UT
            case 0x5455://UT
            /*
             A character string that may contain one or more paragraphs. It may contain the Graphic Character set and the Control Characters, CR, LF, FF, and ESC. It may be padded with trailing spaces, which may be ignored, but leading spaces are considered to be significant. Data Elements with this VR shall not be multi-valued and therefore character code 5CH (the BACKSLASH "\" in ISO-IR 6) may be used.
             */
            {
                [data appendBytes:&tag length:4];
                [data appendBytes:&vr length:2];
                [data appendBytes:&vl0 length:2];//vll aligned on 4 bytes
               
               if (![attrs[key] count])
               {
                  [data appendBytes:&vl0 length:2];
                  [data appendBytes:&vl0 length:2];
               }
               else
               {
                  NSData *stringData=[(attrs[key])[0] dataUsingEncoding:encodingNS[charsetIndex4key(key)]];
               
                  BOOL odd=stringData.length % 2;
                  vll=(uint32)(stringData.length + odd);
                  [data appendBytes:&vll length:4];
                  [data appendData:stringData];
                  if (odd) [data appendBytes:&paddingspace length:1];
               }
               break;
            }

#pragma mark UR
            case 0x5255://UR
            /*
             Universal Resource Identifier or Universal Resource Locator (URI/URL)
             authorized characters : IETF RFC3986 Section 2
             we keep it as UTF8
             shall not be multi-valued
             */
            {
                [data appendBytes:&tag length:4];
                [data appendBytes:&vr length:2];
                [data appendBytes:&vl0 length:2];//vll aligned on 4 bytes
               
               if (![attrs[key] count])
               {
                  [data appendBytes:&vl0 length:2];
                  [data appendBytes:&vl0 length:2];
               }
               else
               {
                  NSData *stringData=
                  [
                   [(attrs[key])[0]  stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]
                   ]
                   dataUsingEncoding:encodingNS[charsetIndex4key(key)]
                   ];
               
                  BOOL odd=stringData.length % 2;
                  vll=(uint32)(stringData.length + odd);
                  [data appendBytes:&vll length:4];
                  [data appendData:stringData];
                  if (odd) [data appendBytes:&paddingspace length:1];
               }
               break;
            }

                 
#pragma mark PN
            case 0x4e50://PN
            {
               NSArray *strings=attrs[key];
               [data appendBytes:&tag length:4];
               [data appendBytes:&vr length:2];
               if (!strings.count)[data appendBytes:&vl0 length:2];
               else
               {
                  NSUInteger encodingIndexes[]={0,0,0};
                  
#pragma mark TODO does not work for vr without prefix
                  /*

                  NSString *eps=[[key componentsSeparatedByString:@"-"] lastObject ];//encoding prefixes
                  for (int j=0; j < eps.length / 4; j++)
                  {
                     NSString *ep=[eps substringWithRange:NSMakeRange(j*4,4)];
                     while (![evr[encodingIndexes[j]] isEqualToString:ep] && (encodingIndexes[j] < encodingTotal)) encodingIndexes[j]++;
                     if (encodingIndexes[j] == encodingTotal)
                     {
                        LOG_ERROR(@"bad key encoding prefix '%@' in  %@",ep,key);
                        return failure;
                     }
                  }
                  */
                  NSMutableData *PNdata=[NSMutableData data];
                  for (NSUInteger l=0; l<strings.count; l++)
                  {
                     if (l) [PNdata appendData:NSData.backslash];
                     NSArray *PNreps=[strings[l] componentsSeparatedByString:@"="];
                     for (NSUInteger k=0; k < PNreps.count; k++ )
                     {
                        if (k) [PNdata appendData:NSData.equal];
                        [PNdata appendData:[PNreps[k] dataUsingEncoding:encodingNS[encodingIndexes[k]]]];
                     }
                  }
                  
                  BOOL odd=PNdata.length % 2;
                  vl=PNdata.length + odd;
                  [data appendBytes:&vl length:2];
                  [data appendData:PNdata];
                  if (odd) [data appendBytes:&paddingspace length:1];

               }
               break;
            }


#pragma mark UI
               case 0x4955:
               {
                  [data appendBytes:&tag length:4];
                  [data appendBytes:&vr length:2];
                  NSString *string=[attrs[key] componentsJoinedByString:@"\\"];
                  BOOL odd=string.length % 2;
                  vl=string.length + odd;
                  [data appendBytes:&vl length:2];
                  [data appendData:[string dataUsingEncoding:NSASCIIStringEncoding]];
                  if (odd) [data appendBytes:&paddingzero length:1];
                   break;
               }
               
   #pragma mark SQ
               case 0x5153:
               {
                  [data appendBytes:&tag length:4];
                  [data appendBytes:&vr length:2];
                  [data appendBytes:&vl0 length:2];
                  [data appendBytes:&undefinedlength length:4];
                   break;
               }
               
   #pragma mark IQ
               case 0x5149:
               {
                  [data appendBytes:&itemstartundefined length:8];
                   break;
               }
               
   #pragma mark IZ
               case 0x5A49:
               {
                  [data appendBytes:&itemend length:8];
                   break;
               }
               
   #pragma mark SZ
               case 0x5A53:
               {
                  [data appendBytes:&SQend length:8];
                   break;
               }
               
   #pragma mark IS DS
               case 0x5344://DS
               case 0x5349://IS
               {
                  [data appendBytes:&tag length:4];
                  [data appendBytes:&vr length:2];
                  switch ([attrs[key] count]) {
                        
                     case 0:
                        [data appendBytes:&vl0 length:2];
                        break;
                        
                     case 1: {
                        NSString *string=[(attrs[key])[0] stringValue];
                        BOOL odd=string.length % 2;
                        vl=string.length + odd;
                        [data appendBytes:&vl length:2];
                        [data appendData:[string dataUsingEncoding:NSISOLatin1StringEncoding]];
                        if (odd) [data appendBytes:&paddingspace length:1];
                     }
                        break;
                        
                     default: {
                        NSMutableString *mutableString=[NSMutableString string];
                        [mutableString appendString:[(attrs[key])[0] stringValue]];
                        for (NSNumber *number in [attrs[key] subarrayWithRange:NSMakeRange(1,[attrs[key] count]-1)])
                        {
                           [mutableString appendString:@"\\"];
                           [mutableString appendString:[number
                                                        stringValue]];
                        }
                        BOOL odd=mutableString.length % 2;
                        vl=mutableString.length + odd;
                        [data appendBytes:&vl length:2];
                        [data appendData:[mutableString dataUsingEncoding:NSISOLatin1StringEncoding]];
                        if (odd) [data appendBytes:&paddingspace length:1];
                     }
                     break;
                  }
                  break;
               }
               
               
   #pragma mark SL
               case 0x4C53:
               {
                   //Signed Long
                  [data appendBytes:&tag length:4];
                  [data appendBytes:&vr length:2];
                  vl=[attrs[key] count]*4;
                  [data appendBytes:&vl length:2];
                  sint32 sl;
                  for (NSNumber *number in attrs[key])
                  {
                     sl=[number intValue];
                     [data appendBytes:&sl length:4];
                  }
                   break;
               }
               
   #pragma mark UL
               case 0x4C55:
               {
                   //Unsigned Long
                  [data appendBytes:&tag length:4];
                  [data appendBytes:&vr length:2];
                  vl=[attrs[key] count]*4;
                  [data appendBytes:&vl length:2];
                  uint32 ul;
                  for (NSNumber *number in attrs[key])
                  {
                     ul=[number unsignedIntValue];
                     [data appendBytes:&ul length:4];
                  }
                   break;
               }
               
               
   #pragma mark SS
               case 0x5353:
               {
                   //Signed Short
                  [data appendBytes:&tag length:4];
                  [data appendBytes:&vr length:2];
                  vl=[attrs[key] count]*2;
                  [data appendBytes:&vl length:2];
                  sint16 ss;
                  for (NSNumber *number in attrs[key])
                  {
                     ss=[number shortValue];
                     [data appendBytes:&ss length:2];
                  }
                   break;
               }
               
   #pragma mark US
               case 0x5355:
               {
                   //Unsigned Short
                  [data appendBytes:&tag length:4];
                  [data appendBytes:&vr length:2];
                  vl=[attrs[key] count]*2;
                  [data appendBytes:&vl length:2];
                  uint16 us;
                  for (NSNumber *number in attrs[key])
                  {
                     us=[number unsignedShortValue];
                     [data appendBytes:&us length:2];
                  }
                   break;
               }
               
   #pragma mark SV
               case 0x5653:
               {
                   //Signed 64-bit Very Long
                  //Signed Long
                 [data appendBytes:&tag length:4];
                 [data appendBytes:&vr length:2];
                 [data appendBytes:&vl0 length:2];
                 vll=(uint32)[attrs[key] count]*8;
                 [data appendBytes:&vll length:4];
                 sint64 sv;
                 for (NSNumber *number in attrs[key])
                 {
                    sv=[number longLongValue];
                    [data appendBytes:&sv length:8];
                 }
                  break;
               }
               
   #pragma mark UV
               case 0x5655:
               {
                   //Unsigned 64-bit Very Long
                  [data appendBytes:&tag length:4];
                  [data appendBytes:&vr length:2];
                  [data appendBytes:&vl0 length:2];
                  vll=(uint32)[attrs[key] count]*8;
                  [data appendBytes:&vll length:4];
                  uint64 uv;
                  for (NSNumber *number in attrs[key])
                  {
                     uv=[number unsignedLongLongValue];
                     [data appendBytes:&uv length:8];
                  }
                   break;
               }
               
   #pragma mark FL
               case 0x4C46:
               {
                   //Unsigned Long
                  [data appendBytes:&tag length:4];
                  [data appendBytes:&vr length:2];
                  vl=[attrs[key] count]*4;
                  [data appendBytes:&vl length:2];
                  float fl;
                  for (NSNumber *number in attrs[key])
                  {
                     fl=[number floatValue];
                     [data appendBytes:&fl length:4];
                  }
                   break;
               }
               
   #pragma mark FD
               case 0x4446:
               {
                  /* 8 byte*/
                  [data appendBytes:&tag length:4];
                  [data appendBytes:&vr length:2];
                  vl=[attrs[key] count]*8;
                  [data appendBytes:&vl length:2];
                  float fd;
                  for (NSNumber *number in attrs[key])
                  {
                     fd=[number doubleValue];
                     [data appendBytes:&fd length:8];
                  }
                   break;
               }
               
   #pragma mark OB OD OF OL OV OW UN
               case 0x424F://OB
               /*
                An octet-stream where the encoding of the contents is specified by the negotiated Transfer Syntax. OB is a VR that is insensitive to byte ordering (see Section 7.3). The octet-stream shall be padded with a single trailing NULL byte value (00H) when necessary to achieve even length.
                */
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
                  [data appendBytes:&tag length:4];
                  [data appendBytes:&vr length:2];
                  [data appendBytes:&vl0 length:2];
                  
                  if ((tag==0x107fe0) && (pixelMode != natv))
                  {
#pragma mark .fragments
                     [data appendBytes:&undefinedlength length:4];
                     //first empty fragment
                     [data appendBytes:&itemempty length:8];
                     
                     for (NSDictionary *frameDict in attrs[key])
                     {
                        NSString *frameName=frameDict.allKeys[0];
                        NSArray *urls=frameDict[frameName];
                        if ([frameName hasPrefix:@"FrameBFHI"])
                        {
                           switch (pixelMode) {
                              case j2kb:
                              {
                                 appendFrame(data, baseURLString, urls[0], true, blobDict);
                              }
                                 break;

                              case j2kf:
                              {
                                 appendFrame(data, baseURLString, urls[0], false,blobDict);
                                 appendFrame(data, baseURLString, urls[1], true,blobDict);
                              }
                                 break;

                              case j2kh:
                              {
                                 appendFrame(data, baseURLString, urls[0], false,blobDict);
                                 appendFrame(data, baseURLString, urls[1], false,blobDict);
                                 appendFrame(data, baseURLString, urls[2], true,blobDict);
                              }
                                 break;

                              default://idem
                              {
                                 appendFrame(data, baseURLString, urls[0], false,blobDict);
                                 appendFrame(data, baseURLString, urls[1], false,blobDict);
                                 appendFrame(data, baseURLString, urls[2], false,blobDict);
                                 appendFrame(data, baseURLString, urls[3], true,blobDict);
                              }
                                 break;
                           }
                        }
                        else //not compressed FrameBFHI
                        {
                           int penultimo= (int)urls.count - 2 ;
                           int i;
                           for (i=0; i<penultimo; i++)
                           {
                              appendFrame(data, baseURLString, urls[i], false,blobDict);
                           }
                           appendFrame(data, baseURLString, urls[i], true,blobDict);
                        }
                     }
                     [data appendBytes:&SQend length:8];
                     break;
                  }
                  
#pragma mark .native
                  
                  if ([attrs[key] count])
                  {
                     id obj=(attrs[key])[0];
                     NSData *firstValueData;
                     if ([obj isKindOfClass:[NSDictionary class]])
                     {
                        NSString *obj0StringValue=[obj allValues][0][0];
                        if (blobDict) firstValueData=blobDict[obj0StringValue];
                        else firstValueData=[NSData dataWithContentsOfURL:[NSURL URLWithString:obj0StringValue]];
                     }
                     else
                     {
                        firstValueData=[[NSData alloc]initWithBase64EncodedData:[obj dataUsingEncoding:NSASCIIStringEncoding ] options:0];
                     }
                     BOOL odd=firstValueData.length % 2;
                     vll=(uint32)firstValueData.length + odd;
                     [data appendBytes:&vll length:4];
                     [data appendData:firstValueData];
                  }
                  else [data appendBytes:&vll0 length:4];
                  break;
               }
               
               
   #pragma mark AT
               case 0x5441:
               {
                  /*
                   Ordered pair of 16-bit unsigned integers that is the value of a Data Element Tag.
                   In mapxmldicom it is encoded as one or more string(s)
                   */
                  [data appendBytes:&tag length:4];
                  [data appendBytes:&vr length:2];
                  vl=[attrs[key] count]*4;
                  [data appendBytes:&vl length:2];
                  uint32 AT;
                  for (NSString *string in attrs[key])
                  {
                     AT=shortshortFromFourByteHexaString(string);
                     [data appendBytes:&AT length:4];
                  }
                   break;
               }
               
               
               default://ERROR unknow VR
               {
#pragma mark ERROR4: unknown VR
                   LOG_ERROR(@"vr: %d", vr);
                   LOG_ERROR(@"ERROR4: unknown VR");
                   [data setLength:0];
                   return failure;
               }
            }
        }
    }
   return success;
}
