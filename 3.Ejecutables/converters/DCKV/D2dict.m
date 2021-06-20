//
//  D2dict.m
//  D2J
//
//  Created by jacquesfauquex on 2021-02-23.
//

#import <Foundation/Foundation.h>
#import "DCMcharset.h"
#import "NSData+DCMmarkers.h"
#import "ODLog.h"
#import "B64.h"

#import "D2dict.h"

void trimLeadingSpaces(NSMutableString *mutableString)
{
   while ([mutableString hasPrefix:@" "])
   {
      [mutableString deleteCharactersInRange:NSMakeRange(0,1)];
   }
}

void trimTrailingSpaces(NSMutableString *mutableString)
{
   while ([mutableString hasSuffix:@" "])
   {
      [mutableString deleteCharactersInRange:NSMakeRange(mutableString.length-1,1)];
   }
}

void trimLeadingAndTrailingSpaces(NSMutableString *mutableString)
{
   trimLeadingSpaces(mutableString);
   trimTrailingSpaces(mutableString);
}


NSString *key(
   NSString *branch,
   uint32 tag,
   uint16 vr
)
{
   return [NSString
                    stringWithFormat:@"%@_%08X-%c%c",
                    branch,
                     ((tag & 0xff000000)>>16)
                    +((tag & 0x00ff0000)>>16)
                    +((tag & 0x0000ff00)<<16)
                    +((tag & 0x000000ff)<<16),
                    vr & 0xff,
                    vr >> 8
   ];
}

NSString *keyPrefixed(
   NSString *branch,
   uint32 tag,
   uint16 vr,
   NSString *p
)
{
  return [NSString
                   stringWithFormat:@"%@_%08X-%@%c%c",
                   branch,
                    ((tag & 0xff000000)>>16)
                   +((tag & 0x00ff0000)>>16)
                   +((tag & 0x0000ff00)<<16)
                   +((tag & 0x000000ff)<<16),
                   p,
                   vr & 0xff,
                   vr >> 8
  ];
}



#pragma mark -
//(bi=shortsBufferIndex, bip=pastShortBufferIndex)
NSUInteger D2J(
                         NSData *data,
                         unsigned short *shortsBuffer,
                         unsigned long bi,
                         unsigned long bip,
                         NSString *branch,
                         NSMutableDictionary *parsedAttrs,
                         NSString *vrCharsetPrefix,
                         uint16 vrCharsetUint16,
                         long long blobMinSize,
                         int blobMode,
                         NSString* blobRefPrefix,
                         NSString* blobRefSuffix,
                         NSMutableDictionary *blobDict
                         )
{
   UInt16 vr;//value representation
   UInt32 tag =   shortsBuffer[bi  ]
              + ( shortsBuffer[bi+1] << 16 );
   NSMutableString *vrCharsetPrefixNew=[NSMutableString stringWithString:vrCharsetPrefix];
   uint16 vrCharsetUint16New=vrCharsetUint16;
    while (tag!=0xe00dfffe &&  bi < bip) //(end item)
   {
      UInt16 vl = shortsBuffer[bi+3];//for AE,AS,AT,CS,DA,DS,DT,FL,FD,IS,LO,LT,PN,SH,SL,SS,ST,TM,UI,UL,US
      
      vr = shortsBuffer[bi+2];
      LOG_DEBUG(@"%lu  %@.%04X%04X %c%c", bi+bi,[branch substringFromIndex:8],tag & 0xFFFF,tag >> 16,vr&0xFF,vr>>8);
      switch (vr) {

            
#pragma mark AS DA
         case 0x5341://AS 4 chars (one value only)
         case 0x4144://DA 8 chars (one value only)
         {
            if (!vl)
            {
               [parsedAttrs setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               [parsedAttrs setObject:@[[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange(bi+bi+8,vl)] encoding:NSISOLatin1StringEncoding]] forKey:key(branch,tag,vr)];
            }
            bi+=4+(vl/2);
            break;
         }

            
#pragma mark AE DT TM
         case 0x4541://AE
         case 0x5444://DT
         case 0x4d54://TM
         {
            //variable length (eventually ended with 0x20
            
            if (!vl)
            {
               [parsedAttrs setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSArray *arrayContents=[[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange(bi+bi+8,vl)] encoding:NSISOLatin1StringEncoding]componentsSeparatedByString:@"\\"];

               NSMutableArray *values=[NSMutableArray array];
               for (NSString *value in arrayContents)
               {
                  NSMutableString *mutableString=[NSMutableString stringWithString:value];
                  trimLeadingSpaces(mutableString);
                  trimTrailingSpaces(mutableString);
                  [values addObject:mutableString];
               }
               [parsedAttrs setObject:values forKey:key(branch,tag,vr)];
            }
            bi+=4+(vl/2);
            break;
         }

            
#pragma mark CS
         case 0x5343://CS
         {
            //variable length (eventually ended with 0x20
            if (!vl)
            {
               [parsedAttrs setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSArray *arrayContents=[[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange(bi+bi+8,vl)] encoding:NSISOLatin1StringEncoding]componentsSeparatedByString:@"\\"];

               NSMutableArray *values=[NSMutableArray array];
               for (NSString *value in arrayContents)
               {
                  NSMutableString *mutableString=[NSMutableString stringWithString:value];
                  trimLeadingSpaces(mutableString);
                  trimTrailingSpaces(mutableString);
                  [values addObject:mutableString];
               }
               [parsedAttrs setObject:values forKey:key(branch,tag,vr)];
    
               
               if (tag==0x050008)
               {
                  [vrCharsetPrefixNew setString:@""];
                  vrCharsetUint16New=0;
                  
                  int nextFiveBits=1;
                  for (NSString *cs in values)
                  {
                     uint16 i=encodingCSindex(cs);
                     if (i==encodingTotal)//=not in the array
                     {
                        LOG_WARNING(@"%@: bad encoding %@. Replaced by default charset",key(branch,tag,vr),cs);
                        i=0;
                     }
                     vrCharsetUint16New += i * nextFiveBits;
                     [vrCharsetPrefixNew appendString:evr[i]];
                     nextFiveBits*=32;
                  }
               }
            }
            bi+=4+(vl/2);
            break;
         }


#pragma mark LO LT PN SH ST
         case 0x4f4c://LO
         case 0x544c://LT
         case 0x4853://SH
         case 0x5453://ST
         {
            //variable length (eventually ended with 0x20
            //specific charset
            if (!vl)
            {
               [parsedAttrs setObject:@[] forKey:keyPrefixed(branch,tag,vr,vrCharsetPrefixNew)];
            }
            else
            {
               NSArray *arrayContents=[[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange(bi+bi+8,vl)] encoding:encodingNS[vrCharsetUint16]]componentsSeparatedByString:@"\\"];

               NSMutableArray *values=[NSMutableArray array];
               for (NSString *value in arrayContents)
               {
                  NSMutableString *mutableString=[NSMutableString stringWithString:value];
                  trimLeadingSpaces(mutableString);
                  trimTrailingSpaces(mutableString);
                  [values addObject:mutableString];
               }
               [parsedAttrs setObject:values forKey:keyPrefixed(branch,tag,vr,vrCharsetPrefixNew)];
            }
            bi+=4+(vl/2);
            break;
         }

#pragma mark PN
         case 0x4e50://PN
         {
            //variable length (eventually ended with 0x20
            //specific charset
            if (!vl)
            {
               [parsedAttrs setObject:@[] forKey:keyPrefixed(branch,tag,vr,vrCharsetPrefixNew)];
            }
            else
            {
               NSData *contentsData=[data subdataWithRange:NSMakeRange(bi+bi+8,vl)];
               
               NSMutableArray *values=[NSMutableArray array];
               if (contentsData.length)
               {
   #pragma mark for each name
                  NSRange remainingContentsRange=NSMakeRange(0, contentsData.length);
                  while (remainingContentsRange.location <= contentsData.length)
                  {
                     NSRange nameRange;
                     if (remainingContentsRange.location == contentsData.length)
                     {
                        nameRange=NSMakeRange(0,0);
                        remainingContentsRange.location +=1;
                     }
                     else
                     {
                        NSRange backslashRange=[contentsData rangeOfData:NSData.backslash options:0 range:remainingContentsRange];
                        if (backslashRange.location==NSNotFound)
                        {
                           nameRange=NSMakeRange(remainingContentsRange.location, remainingContentsRange.length);
                           remainingContentsRange.location=contentsData.length + 1;
                        }
                        else
                        {
                           nameRange=NSMakeRange(remainingContentsRange.location, backslashRange.location - remainingContentsRange.location);
                           remainingContentsRange.location=backslashRange.location + 1;
                           remainingContentsRange.length=contentsData.length - remainingContentsRange.location ;
                        }
                     }
                     NSData *nameData=[contentsData subdataWithRange:nameRange];
                     int compoundEncoding=vrCharsetUint16New;
                     
   #pragma mark for each representation
                     NSRange remainingNameRange=NSMakeRange(0, nameData.length);
                     while (remainingNameRange.location <= nameData.length)
                     {
                        NSRange representationRange;
                        if (remainingNameRange.location == nameData.length)
                        {
                           representationRange=NSMakeRange(0,0);
                           remainingNameRange.location +=1;
                        }
                        else
                        {
                           NSRange equalRange=[contentsData rangeOfData:NSData.equal options:0 range:remainingNameRange];
                           if (equalRange.location==NSNotFound)
                           {
                              representationRange=NSMakeRange(remainingNameRange.location, remainingNameRange.length);
                              remainingNameRange.location=nameData.length + 1;
                           }
                           else
                           {
                              representationRange=NSMakeRange(remainingNameRange.location, equalRange.location - remainingNameRange.location);
                              remainingNameRange.location=equalRange.location + 1;
                              remainingNameRange.length=nameData.length - remainingNameRange.location ;
                           }
                        }
                        NSData *representationData=[contentsData subdataWithRange:representationRange];
                        NSMutableString *representationString=[[NSMutableString alloc]initWithData:representationData encoding:encodingNS[compoundEncoding & 31]];
                        trimLeadingSpaces(representationString);
                        trimTrailingSpaces(representationString);
                        [values addObject:representationString];
                        compoundEncoding /= 32;
                    }
                  }
                  [parsedAttrs setObject:values forKey:keyPrefixed(branch,tag,vr,vrCharsetPrefixNew)];
               }
            }
            bi+=4+(vl/2);
            break;
         }

            
#pragma mark UC UT
            
         // specific charset dependant
         case 0x4355:
         /*
          Unlimited Characters
         */
         case 0x5455://UT
         /*
          A character string that may contain one or more paragraphs. It may contain the Graphic Character set and the Control Characters, CR, LF, FF, and ESC. It may be padded with trailing spaces, which may be ignored, but leading spaces are considered to be significant. Data Elements with this VR shall not be multi-valued and therefore character code 5CH (the BACKSLASH "\" in ISO-IR 6) may be used.
         */
         {
            uint32 vll = ( shortsBuffer[bi+4]       )
                       + ( shortsBuffer[bi+5] << 16 )
            ;
            if (!vll)
            {
               [parsedAttrs setObject:@[] forKey:keyPrefixed(branch,tag,vr,vrCharsetPrefixNew)];
            }
            else
            {
               [parsedAttrs setObject:@[[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange((bi+6)*2,vll)] encoding:encodingNS[vrCharsetUint16]]] forKey:keyPrefixed(branch,tag,vr,vrCharsetPrefixNew)];
            }
            bi+=6+(vll/2);
            break;
         }

#pragma mark UR
         case 0x5255://UR
         /*
          Universal Resource Identifier or Universal Resource Locator (URI/URL)
          always UTF-8
         */
         {
            uint32 vll = ( shortsBuffer[bi+4]       )
                       + ( shortsBuffer[bi+5] << 16 )
            ;
            if (!vll)
            {
               [parsedAttrs setObject:@[] forKey:keyPrefixed(branch,tag,vr,vrCharsetPrefixNew)];
            }
            else
            {
               [parsedAttrs setObject:@[[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange(bi+bi+12,vll)] encoding:NSUTF8StringEncoding]] forKey:key(branch,tag,vr)];
            }
            bi+=6+(vll/2);
            break;
         }

            
#pragma mark UI
         case 0x4955://UI
         {
            NSMutableData *md=[NSMutableData dataWithData:[data subdataWithRange:NSMakeRange(bi+bi+8,vl)]];
            NSRange zerorange=[md rangeOfData:NSData.zero options:NSDataSearchBackwards range:NSMakeRange(0,md.length)];
            //remove eventual padding 0x00
            while (zerorange.location != NSNotFound)
            {
               [md replaceBytesInRange:zerorange withBytes:NULL length:0];
               zerorange=[md rangeOfData:NSData.zero options:NSDataSearchBackwards range:NSMakeRange(0,zerorange.location)];
            }
            if (!md.length)
            {
               [parsedAttrs setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSArray *arrayContents=[[[NSString alloc]initWithData:md encoding:NSUTF8StringEncoding]componentsSeparatedByString:@"\\"];
               [parsedAttrs setObject:arrayContents forKey:key(branch,tag,vr)];
            }

            bi+=4+(vl/2);
            break;
         }
            
#pragma mark - SQ
         case 0x5153://SQ
         {
            unsigned int itemcounter=1;
            NSString *branchTag=[branch stringByAppendingFormat:@"_%08X",
                                  ((tag & 0xff000000)>>16)
                                 +((tag & 0x00ff0000)>>16)
                                 +((tag & 0x0000ff00)<<16)
                                 +((tag & 0x000000ff)<<16)
                                 ];

            uint32 nexttag=shortsBuffer[bi+4]+(shortsBuffer[bi+5]<<16);//SQ size
            if (nexttag==0x0)
            {
#pragma mark SQ empty
               [parsedAttrs setObject:[NSNull null] forKey:key(branch,tag,vr)];
               [parsedAttrs setObject:[NSNull null] forKey:key([branchTag stringByAppendingFormat:@".%08X",itemcounter],0xe0ddfffe,vr)];
               bi+=6;
            }
            else if (nexttag!=0xffffffff) //SQ with defined length
            {
#pragma mark SQ defined length
               LOG_ERROR(@"ERROR1: SQ with defined length. NOT IMPLEMENTED YET");
               exit(1);
            }
            else //SQ with feff0dde end tag
            {
#pragma mark SQ with closing marker
               [parsedAttrs setObject:[NSNull null] forKey:key(branch,tag,vr)];
               bi+=6;//inside the SQ
               nexttag=shortsBuffer[bi]+(shortsBuffer[bi+1]<<16);
               if (nexttag!=0xe0ddfffe)//SQ with contents
               {
                  while (nexttag==0xe000fffe)
                  {
                     uint32 itemlength=shortsBuffer[bi+2]+(shortsBuffer[bi+3]<<16);;
                     if (itemlength==0)
                     {
#pragma mark IT empty
                        [parsedAttrs setObject:[NSNull null] forKey:key([branchTag stringByAppendingFormat:@".%08X",itemcounter],0x0,0x5149)];//IQ

                        [parsedAttrs setObject:[NSNull null] forKey:key([branchTag stringByAppendingFormat:@".%08X",itemcounter],0x0,0x5A49)];//IZ

                        bi+=4;//out of empty item
                     }
                     else if (itemlength!=0xffffffff)
                     {
#pragma mark IT defined length
                        LOG_ERROR(@"ERROR3: item with defined length. NOT IMPLEMENTED");
                        exit(3);
                     }
                     else
                     {
#pragma mark IT with closing marker
                        [parsedAttrs setObject:[NSNull null] forKey:key([branchTag stringByAppendingFormat:@".%08X",itemcounter],0x0,0x5149)];//IQ
                        bi+=4;//inside item
#pragma mark recursion
                        bi=D2J(
   data,
   shortsBuffer,
   bi,
   bip,
   [branchTag stringByAppendingFormat:@".%08X",itemcounter],
   parsedAttrs,
   vrCharsetPrefixNew,
   vrCharsetUint16New,
   blobMinSize,
   blobMode,
   blobRefPrefix,
   blobRefSuffix,
   blobDict
   );

                        [parsedAttrs setObject:[NSNull null] forKey:key([branchTag stringByAppendingFormat:@".%08X",itemcounter],0xe00dfffe,0x5A49)];//IZ
                        bi+=4;//past end item
                     }
                     nexttag=shortsBuffer[bi]+(shortsBuffer[bi+1]<<16);

                     itemcounter++;
                  }
               }
#pragma mark SQ closing marker
               [parsedAttrs setObject:[NSNull null] forKey:key([branchTag stringByAppendingPathExtension:@"FFFFFFFF"],0xe0ddfffe,0x5A53)];
               bi+=4;
            }
            break;
         }

#pragma mark - IS
         case 0x5349://IS
         {
            //variable length (eventually ended with 0x20
            if (!vl)
            {
               [parsedAttrs setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSArray *arrayContents=[[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange(bi+bi+8,vl)] encoding:NSISOLatin1StringEncoding]componentsSeparatedByString:@"\\"];

               NSMutableArray *values=[NSMutableArray array];
               for (NSString *value in arrayContents)
               {
                  [values addObject:[NSNumber numberWithLongLong:[value longLongValue]]];
               }
               [parsedAttrs setObject:values forKey:key(branch,tag,vr)];
            }
            bi+=4+(vl/2);
            break;
         }


#pragma mark DS
         case 0x5344://DS
         {
            //variable length (eventually ended with 0x20
            if (!vl)
            {
               [parsedAttrs setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSArray *arrayContents=[[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange(bi+bi+8,vl)] encoding:NSISOLatin1StringEncoding]componentsSeparatedByString:@"\\"];

               NSMutableArray *values=[NSMutableArray array];
               for (NSString *value in arrayContents)
               {
                  [values addObject:[NSNumber numberWithDouble:[value doubleValue]]];
               }
               [parsedAttrs setObject:values forKey:key(branch,tag,vr)];
            }
            bi+=4+(vl/2);
            break;
         }

#pragma mark SL
         case 0x4C53:
         {
            //Signed Long
            bi+=4;
            if (!vl)
            {
               [parsedAttrs setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSUInteger afterValues=bi + (vl/2);
               long sl;
               NSMutableArray *values=[NSMutableArray array];
               while (bi < afterValues)
               {
                  sl=shortsBuffer[bi] + (shortsBuffer[bi+1]<<16);
                  [values addObject:[NSNumber numberWithLong:sl]];
                  bi+=2;
               }
               [parsedAttrs setObject:values forKey:key(branch,tag,vr)];
            }
            break;
         }
            
#pragma mark UL
         case 0x4C55:
         {
            //Unsigned Long
            bi+=4;
            if (!vl)
            {
               [parsedAttrs setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSUInteger afterValues=bi + (vl/2);
               unsigned long ul;
               NSMutableArray *values=[NSMutableArray array];
               while (bi < afterValues)
               {
                  ul=shortsBuffer[bi] + (shortsBuffer[bi+1]<<16);
                  [values addObject:[NSNumber numberWithUnsignedLong:ul]];
                  bi+=2;
               }
               [parsedAttrs setObject:values forKey:key(branch,tag,vr)];
            }
            break;
         }

            
#pragma mark SS
         case 0x5353:
         {
            //Signed Short
            bi+=4;
            if (!vl)
            {
               [parsedAttrs setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSUInteger afterValues=bi + (vl/2);
               short ss;
               NSMutableArray *values=[NSMutableArray array];
               while (bi < afterValues)
               {
                  ss=shortsBuffer[bi];
                  [values addObject:[NSNumber numberWithShort:ss]];
                  bi++;
               }
               [parsedAttrs setObject:values forKey:key(branch,tag,vr)];
            }
            break;
         }
            
#pragma mark US
         case 0x5355:
         {
            //Unsigned Short
            bi+=4;
            if (!vl)
            {
               [parsedAttrs setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSUInteger afterValues=bi + (vl/2);
               unsigned short us;
               NSMutableArray *values=[NSMutableArray array];
               while (bi < afterValues)
               {
                  us=shortsBuffer[bi];
                  [values addObject:[NSNumber numberWithUnsignedShort:us]];
                  bi++;
               }
               [parsedAttrs setObject:values forKey:key(branch,tag,vr)];
            }
            break;
         }

#pragma mark SV
         case 0x5653:
         {
            //Signed 64-bit Very Long
            uint32 vll = ( shortsBuffer[bi+4]       )
                       + ( shortsBuffer[bi+5] << 16 )
            ;
            bi+=6;
            if (!vll)
            {
               [parsedAttrs setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSUInteger afterValues=bi + (vll/2);
               long long sll;
               NSMutableArray *values=[NSMutableArray array];
               while (bi < afterValues)
               {
                  sll=  shortsBuffer[bi]
                     + (shortsBuffer[bi+1]*0x10000)
                     + (shortsBuffer[bi+2]*0x100000000)
                     + (shortsBuffer[bi+3]*0x1000000000000)
                  ;
                  [values addObject:[NSNumber numberWithLongLong:sll]];
                  bi+=4;
               }
               [parsedAttrs setObject:values forKey:key(branch,tag,vr)];
            }
            break;
         }

#pragma mark UV
         case 0x5655:
         {
            //Unsigned 64-bit Very Long
            uint32 vll = ( shortsBuffer[bi+4]       )
                       + ( shortsBuffer[bi+5] << 16 )
            ;
            bi+=6;
            if (!vll)
            {
               [parsedAttrs setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSUInteger afterValues=bi + (vll/2);
               unsigned long long ull;
               NSMutableArray *values=[NSMutableArray array];
               while (bi < afterValues)
               {
                  ull=  shortsBuffer[bi]
                     + (shortsBuffer[bi+1]*0x10000)
                     + (shortsBuffer[bi+2]*0x100000000)
                     + (shortsBuffer[bi+3]*0x1000000000000)
                  ;
                  [values addObject:[NSNumber numberWithUnsignedLongLong:ull]];
                  bi+=4;
               }
               [parsedAttrs setObject:values forKey:key(branch,tag,vr)];
            }
            break;
         }

#pragma mark FL
         case 0x4C46:
         {
            //Float
            bi+=4;
            if (!vl)
            {
               [parsedAttrs setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSUInteger afterValues=bi + (vl/2);
               unsigned long ul;
               const unsigned long *pul=&ul;
               const float *pf=NULL;
               pf=(float*)pul;
               NSMutableArray *values=[NSMutableArray array];
               while (bi < afterValues)
               {
                  ul=shortsBuffer[bi] + (shortsBuffer[bi+1]<<16);
                  [values addObject:[NSNumber numberWithFloat:*pf]];
                  bi+=2;
               }
               [parsedAttrs setObject:values forKey:key(branch,tag,vr)];
            }
            break;
         }
            
#pragma mark FD
         case 0x4446:
         {
            //Double
            bi+=4;
            if (!vl)
            {
               [parsedAttrs setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
              NSUInteger afterValues=bi + (vl/2);
               unsigned long long ull;
               const unsigned long long *pull=&ull;
               const double *pd=NULL;
               pd=(double*)pull;
               NSMutableArray *values=[NSMutableArray array];
               while (bi < afterValues)
               {
                  ull=  shortsBuffer[bi]
                     + (shortsBuffer[bi+1]*0x10000)
                     + (shortsBuffer[bi+2]*0x100000000)
                     + (shortsBuffer[bi+3]*0x1000000000000)
                  ;
                  [values addObject:[NSNumber numberWithDouble:*pd]];
                  bi+=4;
               }
               [parsedAttrs setObject:values forKey:key(branch,tag,vr)];
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
            uint32 vll = ( shortsBuffer[bi+4]       )
                       + ( shortsBuffer[bi+5] << 16 )
            ;
            NSString *blobKey=key(branch,tag,vr);
            if (!vll)//empty
            {
               [parsedAttrs setObject:@[] forKey:blobKey];
               bi+= 6 + (vll/2);
               break;
            }

            if ([blobKey containsString:@"7FE00010"] && (vll==0xFFFFFFFF))
#pragma mark · fragments
            {
               //offset of first fragment
               bi+=6;
               if (bi + 4 >= bip)
               {
                  LOG_WARNING(@"%@ truncated",blobKey);
                  return failure;
               }
               tag = shortsBuffer[bi]
                   + ( shortsBuffer[bi+1] << 16 );
               if (tag == 0xe0ddfffe)
               {
                  LOG_WARNING(@"%@ no fragment item",blobKey);
                  return bi;
               }
               if (tag!=0xe000fffe)
               {
                  LOG_WARNING(@"%@ encapsulated does not start with a fragment item",blobKey);
                  return failure;
               }
               vll = ( shortsBuffer[bi+2]       )
                   + ( shortsBuffer[bi+3] << 16 );
                  
               
               NSMutableData *frameData=[NSMutableData data];
               //frames used for blobModeResources and blobModeInline
               NSMutableArray *frames=[NSMutableArray array];
               NSMutableArray *fragmentRefs=[NSMutableArray array];
               NSMutableData *offsetData=[NSMutableData data];
               uint32 *offsets=nil;//tabla de offsets de fragmentos
               int currentFrameOffset=0;//primer fragment de un frame en la tabla
               int offsetCount=0;//by default, no table
               int offsetAfter=0xFFFFFFFF;
               
               if (vll != 0)
#pragma mark ·· first fragment is an offset table ?
               {
                  //is this an offset table?
                  //is there at least a 00000000 offset (which is the first value of the table) ?
                  
                  uint32 tableFirst = shortsBuffer[bi + 4]
                      + ( shortsBuffer[bi + 5] << 16 );
                  
                  if (tableFirst != 0xe000fffe)
                  {
                     
                     [offsetData appendData:[data subdataWithRange:NSMakeRange(bi+bi+12,vll)]];
                     [offsetData appendBytes:&offsetAfter length:4];
                     offsets=(uint32 *)[offsetData bytes];
                     offsetCount= sizeof(offsets) / 4;//or offsetTable.length / 4
                     
                     //for blobModeSource
                     NSString *urlString=[NSString stringWithFormat:@"file:%@?offset=%lu&amp;length=%d",blobRefPrefix,bi+bi+4, vll];
                     [fragmentRefs addObject:@{ @"Fragment#00000000":@[urlString]}];

                     
                     
                     //first fragment
                     bi+=4 + (vll/2);
                     tag = shortsBuffer[bi]
                         + ( shortsBuffer[bi+1] << 16 );
                     
                     if (tag == 0xe0ddfffe)
                     {
                        LOG_WARNING(@"%@ no fragment after offsetTable",blobKey);
                        return bi;
                     }

                     if (tag!=0xe000fffe)
                     {
                        LOG_WARNING(@"%@ encapsulated item markup problem",blobKey);
                        return failure;
                     }
                     vll = ( shortsBuffer[bi+2]       )
                         + ( shortsBuffer[bi+3] << 16 );
                  }
#pragma mark TODO revise parsing of fragments with table offset
                  while (bi < bip) //(end of sequence)
                  {
                     if (
                            (tag==0xe0ddfffe)
                         || (bi > offsets[currentFrameOffset])
                         ) //sequence end
                     {
                        //add a frame?
                        if (frameData.length)
                        {
                           [frames addObject:[NSData dataWithData:frameData]];
                           [frameData setData:[NSData data]];
                        }
                        //exit loop
                        break;
                     }
                     
                     
                     if (tag!=0xe000fffe)
                        //exit with error on syntaxis error
                     {
                        LOG_WARNING(@"%@ encapsulated item markup problem",blobKey);
                        return failure;
                     }
                     
                     //for blobModeSource
                     NSString *urlString=[NSString stringWithFormat:@"file:%@?offset=%lu&amp;length=%d",blobRefPrefix,bi+bi+8, vll];
                     NSString *itemString=[NSString stringWithFormat:@"Fragment#%08lu",fragmentRefs.count+1];
                     [fragmentRefs addObject:
                      @{
                         itemString : @[ urlString ]
                      }
                      ];
                     [frameData appendData:[data subdataWithRange:NSMakeRange(bi+bi+8,vll)]];

                     
                     //new tag and length
                     bi += ((vll / 4) + 4);
                     tag = shortsBuffer[bi]
                         + ( shortsBuffer[bi+1] << 16 );
                     vll = ( shortsBuffer[bi+2]       )
                         + ( shortsBuffer[bi+3] << 16 );
                  }//end loop fragments

               }
               else //(vll == 0)
#pragma mark ·· first fragment is NOT an offset table
               {
                  [offsetData appendBytes:&offsetAfter length:4];
                  offsets=(uint32 *)[offsetData bytes];
                  offsetCount=1;
                  //next fragment
                  bi+=4;
                  tag = shortsBuffer[bi]
                      + ( shortsBuffer[bi+1] << 16 );
                  vll = ( shortsBuffer[bi+2]       )
                      + ( shortsBuffer[bi+3] << 16 );
                  
#pragma mark ... loop fragments
                  while (tag!=0xe0ddfffe) //(end of sequence)
                  {
                     //for blobModeSource
                     NSString *urlString=[NSString stringWithFormat:@"file:%@?offset=%lu&amp;length=%d",blobRefPrefix,bi+bi+8, vll];
                     NSString *itemString=[NSString stringWithFormat:@"Fragment#%08lu",fragmentRefs.count+1];
                     [fragmentRefs addObject:
                      @{
                         itemString : @[ urlString ]
                      }
                      ];
                     [frameData appendData:[data subdataWithRange:NSMakeRange(bi+bi+8,vll)]];
                     bi += (vll>>1);

                     bi += 4;
                     
                     //new tag and length
                     tag = shortsBuffer[bi]
                         + ( shortsBuffer[bi+1] << 16 );
                     vll = ( shortsBuffer[bi+2]       )
                         + ( shortsBuffer[bi+3] << 16 );
                  }//end loop fragments
                  
                  //jump over 0xe0ddfffe
                  bi += 4;
                  tag = shortsBuffer[bi]
                      + ( shortsBuffer[bi+1] << 16 );
                  vll = ( shortsBuffer[bi+2]       )
                      + ( shortsBuffer[bi+3] << 16 );
               }
               
               
               
#pragma mark .. finalize
               switch (blobMode) {
                     
#pragma mark ···blobModeSource
                  case blobModeSource:
                     [parsedAttrs setObject:fragmentRefs forKey:blobKey];
                     break;
                     
#pragma mark ···blobModeResources
                  case blobModeResources:
                  {
                     NSString *extension;
                     NSArray *tsArray=(parsedAttrs[@"00000001_00020010-UI"]);
                     if (tsArray && tsArray.count && [tsArray[0] hasPrefix:@"1.2.840.10008.1.2.4.90"]) extension=@".j2k";
                     else extension=@"";
                     
                     //for each of the frames
                     //write an entry in blobDict
                     //with suffix frame number
                     //and create a bulkdataRef
                     NSMutableArray *bulkdatas=[NSMutableArray array];
                     for (int i=0; i<frames.count; i++)
                     {
                        NSString *relativeString=[NSString stringWithFormat:@"%@#%08d%@",blobKey,i+1,extension?extension:@""];
                        [blobDict setObject:frames[i] forKey:relativeString];
                        
                        [bulkdatas addObject:@{[NSString stringWithFormat:@"Frame#%08d",i+1] : @[[blobRefPrefix stringByAppendingPathComponent:relativeString]]}];
                     }
                     [parsedAttrs setObject:bulkdatas forKey:blobKey];
                  }
                     break;

#pragma mark ···blobModeInline
                  default://blobModeInline || vll < blobMinSize
                  {
                     NSMutableArray *b64s=[NSMutableArray array];
                     for (NSData *frame in frames)
                     {
                     //convert to JSON base64 (solidus written \/)
                        [b64s addObject:B64JSONstringWithData(frame)];
                     }
                     [parsedAttrs setObject:b64s forKey:blobKey];
                  }
                     break;
               }
            }
            else
#pragma mark · native (any binary or document)
            {
               switch (blobMode * (vll >= blobMinSize))
               {
                  case blobModeSource:
                  {
                     NSString *urlString=[NSString stringWithFormat:@"file:%@?offset=%lu&amp;length=%d",blobRefPrefix,bi+bi+12,vll];
                     [parsedAttrs setObject:@[@{ @"Native":@[urlString]}] forKey:blobKey];
                  }
                     break;

                  case blobModeResources:
                  {
                     NSString *extension;
                     NSString *sopClass=parsedAttrs[@"00000001_00080016-UI"][0];

                     if ([blobKey isEqualToString:@"00000001_00420011-OB"] && [sopClass hasPrefix:@"1.2.840.10008.​5.​1.​4.​1.​1.​104.​"]) //encapsulated
                     {
                        if  ([sopClass isEqualToString:@"1.2.840.10008.​5.​1.​4.​1.​1.​104.​1"]) extension=@".pdf";
                        else if  ([sopClass isEqualToString:@"1.2.840.10008.​5.​1.​4.​1.​1.​104.​2"]) extension=@".xml";
                        else if  ([sopClass isEqualToString:@"1.2.840.10008.​5.​1.​4.​1.​1.​104.​3"]) extension=@".stl";
                        else if  ([sopClass isEqualToString:@"1.2.840.10008.​5.​1.​4.​1.​1.​104.​4"]) extension=@".obj";
                        else if  ([sopClass isEqualToString:@"1.2.840.10008.​5.​1.​4.​1.​1.​104.​5"]) extension=@".mtl";
                     }

                     NSString *urlString=[NSString stringWithFormat:@"%@%@%@%@",
                                             blobRefPrefix?blobRefPrefix:@"",
                                            blobKey,
                                             blobRefSuffix?blobRefSuffix:@"",
                                          extension?extension:@""
                                             ];
                     [parsedAttrs setObject:@[@{ @"Native":@[urlString]}] forKey:blobKey];
                     [blobDict setObject:[data subdataWithRange:NSMakeRange(bi+bi+12,vll)] forKey:urlString];
                  }
                     break;

                  default://blobModeInline || vll < blobMinSize
                  {
                     NSData *contents=[data subdataWithRange:NSMakeRange(bi+bi+12,vll)];
                     
                     //convert to JSON base64 (solidus written \/)
                     [parsedAttrs setObject:@[B64JSONstringWithData(contents)] forKey:blobKey];
                  }
                     break;
               }
               bi+= 6 + (vll/2);
            }

            break;
         }
            
            
#pragma mark AT
         case 0x5441:
         {
            //hexBinary 4 bytes


            bi+=4;
            if (!vl)
            {
               [parsedAttrs setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSUInteger afterValues=bi + (vl/2);
               uint16 group=0;
               uint16 element=0;
               NSMutableArray *values=[NSMutableArray array];
               while (bi < afterValues)
               {
                  group=shortsBuffer[bi];
                  element=shortsBuffer[bi+1];
                  [values addObject:[NSString stringWithFormat:@"%02X%02X%02X%02X",group / 0x100,group & 0xFF,element / 0x100,element & 0xFF]];
                  bi+=2;
               }
               [parsedAttrs setObject:values forKey:key(branch,tag,vr)];
            }
            break;
         }


         default://ERROR unknow VR
         {
#pragma mark ERROR4: unknown VR
            LOG_ERROR(@"vr: %d", vr);
            LOG_ERROR(@"ERROR4: unknown VR");
            exit(4);
            break;
         }
      }
      tag=shortsBuffer[bi]+(shortsBuffer[bi+1]<<16);
   }
   return bi;
}

#pragma mark -



int D2dict(
           NSData *data,
           NSMutableDictionary *parsedAttrs,
           long long blobMinSize,
           int blobMode,
           NSString* blobRefPrefix,
           NSString* blobRefSuffix,
           NSMutableDictionary *blobDict
           )
{
   if (data.length <10)
   {
      LOG_WARNING(@"dicom binary data too small");
      return failure;
   }

   unsigned short *shorts=(unsigned short*)[data bytes];
   NSUInteger datasetShortOffset=0;
   NSString *vrCharsetPrefix=nil;
   uint16 vrCharsetUint16;
   //skip preambule?
   if (data.length > 132 && shorts[64]==0x4944 && shorts[65]==0x4d43)
   {
      datasetShortOffset=66;
      vrCharsetPrefix=@"2006";//default ISO 2022 IR 6 for part 10 files
      vrCharsetUint16=0;
   }
   else
   {
      vrCharsetPrefix=@"1100";//default latin1 for datasets
      vrCharsetUint16=1;
   }

   NSUInteger index=D2J(
                     data,
                     shorts,
                     datasetShortOffset,
                     (data.length -1) / 2,
                     @"00000001",
                     parsedAttrs,
                     vrCharsetPrefix,
                     vrCharsetUint16,
                     blobMinSize,
                     blobMode,
                     blobRefPrefix,
                     blobRefSuffix,
                     blobDict
                        );
   if (index < (data.length -1) / 2)
   {
      LOG_ERROR(@"parsing until index %lu",index * 2);
      return failure;
   }
   return success;
}



NSString *jsonObject4attrs(NSDictionary *attrs)
{
   //NSData *JSONdata=[NSJSONSerialization dataWithJSONObject:@{@"dataset":dict} options:NSJSONWritingSortedKeys error:&error];//10.15 || NSJSONWritingWithoutEscapingSlashes

   NSMutableString *JSONstring=[NSMutableString stringWithFormat:@"{"];
   NSArray *keys=[[attrs allKeys] sortedArrayUsingSelector:@selector(compare:)];
   
   
#pragma mark loop on ordered keys
   for (NSString *key in keys)
   {
      //LOG_DEBUG(@"%@",key);
      [JSONstring appendFormat:@" \"%@\" :",key];
      
      switch ([key characterAtIndex:key.length-2]+([key characterAtIndex:key.length-1]*0x100))
      {
         
#pragma mark · string based attributes
//AS DA AE DT TM CS LO LT SH ST PN UC UT UR UI AT
         case 0x5341://AS
         case 0x4144://DA
         case 0x4541://AE
         case 0x5444://DT
         case 0x4d54://TM
         case 0x5343://CS
         case 0x4f4c://LO
         case 0x544c://LT
         case 0x4853://SH
         case 0x5453://ST
         case 0x4e50://PN
         case 0x4355://UC
         case 0x5455://UT
         case 0x5255://UR
         case 0x4955://UI
         case 0x5441://AT
         {
            switch ([attrs[key] count]) {
               case 0:
               {
                  [JSONstring appendString:@"[ ],"];
                  break;
               }

               case 1:
               {
                  [JSONstring appendFormat:@"[\"%@\"],",
                   attrs[key][0]];
                  break;
               }

               default:
               {
                  [JSONstring appendString:@"["];
                  for (NSString *string in attrs[key])
                  {
                     [JSONstring appendFormat:@"\"%@\",",
                      string];
                  }
                  [JSONstring deleteCharactersInRange:NSMakeRange(JSONstring.length-1,1)];
                  [JSONstring appendString:@"],"];

                  break;
               }
            }
            
            break;
         }
            
            
#pragma mark · string or map based
         case 0x424F://OB
         case 0x444F://OD
         case 0x464F://OF
         case 0x4C4F://OL
         case 0x564F://OV
         case 0x574F://OW
         case 0x4E55://UN
         {
            switch ([attrs[key] count]) {
               case 0:
               {
                  [JSONstring appendString:@"[ ],"];
                  break;
               }

               case 1:
               {
                  id obj=attrs[key][0];
                  if ([obj isKindOfClass:[NSString class]])
                  {
                     [JSONstring appendFormat:@"[\"%@\"],",
                   obj];
                  }
                  else //@[@{ @"Frame#00000001" :[urlString]}]
                  {
                     NSString *subKey=[obj allKeys][0];
                     [JSONstring appendFormat:@"[{ \"%@\" :[",subKey];
                     for (NSString *url in obj[subKey])
                     {
                        [JSONstring appendFormat:@"\"%@\",",url];
                     }
                     [JSONstring replaceCharactersInRange:NSMakeRange(JSONstring.length-1,1) withString:@"]}],"];
                  }
                  break;
               }

               default://more than one value
               {
                  [JSONstring appendString:@"["];
                  id obj=attrs[key][0];
                  if ([obj isKindOfClass:[NSString class]])
                  {
                     for (NSString *string in attrs[key])
                     {
                        [JSONstring appendFormat:@"\"%@\",",
                         string];
                     }
                     [JSONstring deleteCharactersInRange:NSMakeRange(JSONstring.length-1,1)];
                     [JSONstring appendString:@"],"];
                  }
                  else //@[@{ @"BulkData":urlString}]
                  {
                     for (NSDictionary *d in attrs[key])
                     {
                        NSString *subKey=[d allKeys][0];
                        [JSONstring appendFormat:@"{ \"%@\" :[\"%@\"]},",subKey, d[subKey][0]];
                     }
                     [JSONstring deleteCharactersInRange:NSMakeRange(JSONstring.length-1,1)];
                     [JSONstring appendString:@"],"];
                  }
                  break;
               }
            }
            break;
         }
            
            
#pragma mark · null based
//SQ IQ IZ SZ
         case 0x5153://SQ
         case 0x5149://IQ
         case 0x5A49://IZ
         case 0x5A53://SZ
         {
            [JSONstring appendString:@"null,"];
            break;
         }

            
#pragma mark · number based attributes
//IS DS SL UL SS US SV UV FL FD
         case 0x5349://IS
         case 0x5344://DS
         case 0x4C53://SL
         case 0x4C55://UL
         case 0x5353://SS
         case 0x5355://US
         case 0x5653://SV
         case 0x5655://UV
         case 0x4C46://FL
         case 0x4446://FD
         {
            switch ([attrs[key] count]) {
               case 0:
               {
                  [JSONstring appendString:@"[ ],"];
                  break;
               }

               case 1:
               {
                  [JSONstring appendFormat:@"[%@],", attrs[key][0]];
                  break;
               }

               default:
               {
                  [JSONstring appendString:@"["];
                  for (NSString *string in attrs[key])
                  {
                     [JSONstring appendFormat:@"%@,",
                      string];
                  }
                  [JSONstring deleteCharactersInRange:NSMakeRange(JSONstring.length-1,1)];
                  [JSONstring appendString:@"],"];

                  break;
               }
            }
            break;
         }
      }
   }
   [JSONstring deleteCharactersInRange:NSMakeRange(JSONstring.length-1,1)];
   [JSONstring appendString:@"}"];
   return [NSString stringWithString:JSONstring];
}
