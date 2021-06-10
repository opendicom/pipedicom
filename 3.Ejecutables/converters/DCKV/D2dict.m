//
//  D2dict.m
//  D2J
//
//  Created by jacquesfauquex on 2021-02-23.
//

#import <Foundation/Foundation.h>
#import "DCMcharset.h"
#import "NSData+DCMmarkers.h"
#import "utils.h"
#import "ODLog.h"
#import "B64.h"

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

NSUInteger D2J(
                         NSData *data,
                         unsigned short *shortsBuffer,
                         NSUInteger shortsIndex,
                         NSUInteger postShortsIndex,
                         NSString *branch,
                         NSMutableDictionary *attrDict,
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
   UInt32 tag =   shortsBuffer[shortsIndex  ]
              + ( shortsBuffer[shortsIndex+1] << 16 );
   NSMutableString *vrCharsetPrefixNew=[NSMutableString stringWithString:vrCharsetPrefix];
   uint16 vrCharsetUint16New=vrCharsetUint16;
   while (tag!=0xe00dfffe &&  shortsIndex < postShortsIndex) //(end item)
   {
      UInt16 vl = shortsBuffer[shortsIndex+3];//for AE,AS,AT,CS,DA,DS,DT,FL,FD,IS,LO,LT,PN,SH,SL,SS,ST,TM,UI,UL,US
      
      vr = shortsBuffer[shortsIndex+2];
      switch (vr) {

            
#pragma mark AS DA
         case 0x5341://AS 4 chars (one value only)
         case 0x4144://DA 8 chars (one value only)
         {
            if (!vl)
            {
               [attrDict setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               [attrDict setObject:@[[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange((shortsIndex+4)*2,vl)] encoding:NSISOLatin1StringEncoding]] forKey:key(branch,tag,vr)];
            }
            shortsIndex+=4+(vl/2);
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
               [attrDict setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSArray *arrayContents=[[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange((shortsIndex+4)*2,vl)] encoding:NSISOLatin1StringEncoding]componentsSeparatedByString:@"\\"];

               NSMutableArray *values=[NSMutableArray array];
               for (NSString *value in arrayContents)
               {
                  NSMutableString *mutableString=[NSMutableString stringWithString:value];
                  trimLeadingSpaces(mutableString);
                  trimTrailingSpaces(mutableString);
                  [values addObject:mutableString];
               }
               [attrDict setObject:values forKey:key(branch,tag,vr)];
            }
            shortsIndex+=4+(vl/2);
            break;
         }

            
#pragma mark CS
         case 0x5343://CS
         {
            //variable length (eventually ended with 0x20
            if (!vl)
            {
               [attrDict setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSArray *arrayContents=[[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange((shortsIndex+4)*2,vl)] encoding:NSISOLatin1StringEncoding]componentsSeparatedByString:@"\\"];

               NSMutableArray *values=[NSMutableArray array];
               for (NSString *value in arrayContents)
               {
                  NSMutableString *mutableString=[NSMutableString stringWithString:value];
                  trimLeadingSpaces(mutableString);
                  trimTrailingSpaces(mutableString);
                  [values addObject:mutableString];
               }
               [attrDict setObject:values forKey:key(branch,tag,vr)];
    
               
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
            shortsIndex+=4+(vl/2);
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
               [attrDict setObject:@[] forKey:keyPrefixed(branch,tag,vr,vrCharsetPrefixNew)];
            }
            else
            {
               NSArray *arrayContents=[[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange((shortsIndex+4)*2,vl)] encoding:encodingNS[vrCharsetUint16]]componentsSeparatedByString:@"\\"];

               NSMutableArray *values=[NSMutableArray array];
               for (NSString *value in arrayContents)
               {
                  NSMutableString *mutableString=[NSMutableString stringWithString:value];
                  trimLeadingSpaces(mutableString);
                  trimTrailingSpaces(mutableString);
                  [values addObject:mutableString];
               }
               [attrDict setObject:values forKey:keyPrefixed(branch,tag,vr,vrCharsetPrefixNew)];
            }
            shortsIndex+=4+(vl/2);
            break;
         }

#pragma mark PN
         case 0x4e50://PN
         {
            //variable length (eventually ended with 0x20
            //specific charset
            if (!vl)
            {
               [attrDict setObject:@[] forKey:keyPrefixed(branch,tag,vr,vrCharsetPrefixNew)];
            }
            else
            {
               NSData *contentsData=[data subdataWithRange:NSMakeRange((shortsIndex+4)*2,vl)];
               
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
                  [attrDict setObject:values forKey:keyPrefixed(branch,tag,vr,vrCharsetPrefixNew)];
               }
            }
            shortsIndex+=4+(vl/2);
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
            uint32 vll = ( shortsBuffer[shortsIndex+4]       )
                       + ( shortsBuffer[shortsIndex+5] << 16 )
            ;
            if (!vll)
            {
               [attrDict setObject:@[] forKey:keyPrefixed(branch,tag,vr,vrCharsetPrefixNew)];
            }
            else
            {
               [attrDict setObject:@[[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange((shortsIndex+6)*2,vll)] encoding:encodingNS[vrCharsetUint16]]] forKey:keyPrefixed(branch,tag,vr,vrCharsetPrefixNew)];
            }
            shortsIndex+=6+(vll/2);
            break;
         }

#pragma mark UR
         case 0x5255://UR
         /*
          Universal Resource Identifier or Universal Resource Locator (URI/URL)
          always UTF-8
         */
         {
            uint32 vll = ( shortsBuffer[shortsIndex+4]       )
                       + ( shortsBuffer[shortsIndex+5] << 16 )
            ;
            if (!vll)
            {
               [attrDict setObject:@[] forKey:keyPrefixed(branch,tag,vr,vrCharsetPrefixNew)];
            }
            else
            {
               [attrDict setObject:@[[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange((shortsIndex+6)*2,vll)] encoding:NSUTF8StringEncoding]] forKey:key(branch,tag,vr)];
            }
            shortsIndex+=6+(vll/2);
            break;
         }

            
#pragma mark UI
         case 0x4955://UI
         {
            NSMutableData *md=[NSMutableData dataWithData:[data subdataWithRange:NSMakeRange((shortsIndex+4)*2,vl)]];
            NSRange zerorange=[md rangeOfData:NSData.zero options:NSDataSearchBackwards range:NSMakeRange(0,md.length)];
            //remove eventual padding 0x00
            while (zerorange.location != NSNotFound)
            {
               [md replaceBytesInRange:zerorange withBytes:NULL length:0];
               zerorange=[md rangeOfData:NSData.zero options:NSDataSearchBackwards range:NSMakeRange(0,zerorange.location)];
            }
            if (!md.length)
            {
               [attrDict setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSArray *arrayContents=[[[NSString alloc]initWithData:md encoding:NSUTF8StringEncoding]componentsSeparatedByString:@"\\"];
               [attrDict setObject:arrayContents forKey:key(branch,tag,vr)];
            }

            shortsIndex+=4+(vl/2);
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

            uint32 nexttag=shortsBuffer[shortsIndex+4]+(shortsBuffer[shortsIndex+5]<<16);//SQ size
            if (nexttag==0x0)
            {
#pragma mark SQ empty
               [attrDict setObject:[NSNull null] forKey:key(branch,tag,vr)];
               [attrDict setObject:[NSNull null] forKey:key([branchTag stringByAppendingFormat:@".%08X",itemcounter],0xe0ddfffe,vr)];
               shortsIndex+=6;
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
               [attrDict setObject:[NSNull null] forKey:key(branch,tag,vr)];
               shortsIndex+=6;//inside the SQ
               nexttag=shortsBuffer[shortsIndex]+(shortsBuffer[shortsIndex+1]<<16);
               if (nexttag!=0xe0ddfffe)//SQ with contents
               {
                  while (nexttag==0xe000fffe)
                  {
                     uint32 itemlength=shortsBuffer[shortsIndex+2]+(shortsBuffer[shortsIndex+3]<<16);;
                     if (itemlength==0)
                     {
#pragma mark IT empty
                        [attrDict setObject:[NSNull null] forKey:key([branchTag stringByAppendingFormat:@".%08X",itemcounter],0x0,0x5149)];//IQ

                        [attrDict setObject:[NSNull null] forKey:key([branchTag stringByAppendingFormat:@".%08X",itemcounter],0x0,0x5A49)];//IZ

                        shortsIndex+=4;//out of empty item
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
                        [attrDict setObject:[NSNull null] forKey:key([branchTag stringByAppendingFormat:@".%08X",itemcounter],0x0,0x5149)];//IQ
                        shortsIndex+=4;//inside item
#pragma mark recursion
                        shortsIndex=D2J(
   data,
   shortsBuffer,
   shortsIndex,
   postShortsIndex,
   [branchTag stringByAppendingFormat:@".%08X",itemcounter],
   attrDict,
   vrCharsetPrefixNew,
   vrCharsetUint16New,
   blobMinSize,
   blobMode,
   blobRefPrefix,
   blobRefSuffix,
   blobDict
   );

                        [attrDict setObject:[NSNull null] forKey:key([branchTag stringByAppendingFormat:@".%08X",itemcounter],0xe00dfffe,0x5A49)];//IZ
                     }
                     nexttag=shortsBuffer[shortsIndex]+(shortsBuffer[shortsIndex+1]<<16);

                     itemcounter++;
                  }
               }
#pragma mark SQ closing marker
               [attrDict setObject:[NSNull null] forKey:key([branchTag stringByAppendingPathExtension:@"FFFFFFFF"],0xe0ddfffe,0x5A53)];
               shortsIndex+=8;
            }
            break;
         }

#pragma mark - IS
         case 0x5349://IS
         {
            //variable length (eventually ended with 0x20
            if (!vl)
            {
               [attrDict setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSArray *arrayContents=[[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange((shortsIndex+4)*2,vl)] encoding:NSISOLatin1StringEncoding]componentsSeparatedByString:@"\\"];

               NSMutableArray *values=[NSMutableArray array];
               for (NSString *value in arrayContents)
               {
                  [values addObject:[NSNumber numberWithLongLong:[value longLongValue]]];
               }
               [attrDict setObject:values forKey:key(branch,tag,vr)];
            }
            shortsIndex+=4+(vl/2);
            break;
         }


#pragma mark DS
         case 0x5344://DS
         {
            //variable length (eventually ended with 0x20
            if (!vl)
            {
               [attrDict setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSArray *arrayContents=[[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange((shortsIndex+4)*2,vl)] encoding:NSISOLatin1StringEncoding]componentsSeparatedByString:@"\\"];

               NSMutableArray *values=[NSMutableArray array];
               for (NSString *value in arrayContents)
               {
                  [values addObject:[NSNumber numberWithDouble:[value doubleValue]]];
               }
               [attrDict setObject:values forKey:key(branch,tag,vr)];
            }
            shortsIndex+=4+(vl/2);
            break;
         }

#pragma mark SL
         case 0x4C53:
         {
            //Signed Long
            shortsIndex+=4;
            if (!vl)
            {
               [attrDict setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSUInteger afterValues=shortsIndex + (vl/2);
               long sl;
               NSMutableArray *values=[NSMutableArray array];
               while (shortsIndex < afterValues)
               {
                  sl=shortsBuffer[shortsIndex] + (shortsBuffer[shortsIndex+1]<<16);
                  [values addObject:[NSNumber numberWithLong:sl]];
                  shortsIndex+=2;
               }
               [attrDict setObject:values forKey:key(branch,tag,vr)];
            }
            break;
         }
            
#pragma mark UL
         case 0x4C55:
         {
            //Unsigned Long
            shortsIndex+=4;
            if (!vl)
            {
               [attrDict setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSUInteger afterValues=shortsIndex + (vl/2);
               unsigned long ul;
               NSMutableArray *values=[NSMutableArray array];
               while (shortsIndex < afterValues)
               {
                  ul=shortsBuffer[shortsIndex] + (shortsBuffer[shortsIndex+1]<<16);
                  [values addObject:[NSNumber numberWithUnsignedLong:ul]];
                  shortsIndex+=2;
               }
               [attrDict setObject:values forKey:key(branch,tag,vr)];
            }
            break;
         }

            
#pragma mark SS
         case 0x5353:
         {
            //Signed Short
            shortsIndex+=4;
            if (!vl)
            {
               [attrDict setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSUInteger afterValues=shortsIndex + (vl/2);
               short ss;
               NSMutableArray *values=[NSMutableArray array];
               while (shortsIndex < afterValues)
               {
                  ss=shortsBuffer[shortsIndex];
                  [values addObject:[NSNumber numberWithShort:ss]];
                  shortsIndex++;
               }
               [attrDict setObject:values forKey:key(branch,tag,vr)];
            }
            break;
         }
            
#pragma mark US
         case 0x5355:
         {
            //Unsigned Short
            shortsIndex+=4;
            if (!vl)
            {
               [attrDict setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSUInteger afterValues=shortsIndex + (vl/2);
               unsigned short us;
               NSMutableArray *values=[NSMutableArray array];
               while (shortsIndex < afterValues)
               {
                  us=shortsBuffer[shortsIndex];
                  [values addObject:[NSNumber numberWithUnsignedShort:us]];
                  shortsIndex++;
               }
               [attrDict setObject:values forKey:key(branch,tag,vr)];
            }
            break;
         }

#pragma mark SV
         case 0x5653:
         {
            //Signed 64-bit Very Long
            uint32 vll = ( shortsBuffer[shortsIndex+4]       )
                       + ( shortsBuffer[shortsIndex+5] << 16 )
            ;
            shortsIndex+=6;
            if (!vll)
            {
               [attrDict setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSUInteger afterValues=shortsIndex + (vll/2);
               long long sll;
               NSMutableArray *values=[NSMutableArray array];
               while (shortsIndex < afterValues)
               {
                  sll=  shortsBuffer[shortsIndex]
                     + (shortsBuffer[shortsIndex+1]*0x10000)
                     + (shortsBuffer[shortsIndex+2]*0x100000000)
                     + (shortsBuffer[shortsIndex+3]*0x1000000000000)
                  ;
                  [values addObject:[NSNumber numberWithLongLong:sll]];
                  shortsIndex+=4;
               }
               [attrDict setObject:values forKey:key(branch,tag,vr)];
            }
            break;
         }

#pragma mark UV
         case 0x5655:
         {
            //Unsigned 64-bit Very Long
            uint32 vll = ( shortsBuffer[shortsIndex+4]       )
                       + ( shortsBuffer[shortsIndex+5] << 16 )
            ;
            shortsIndex+=6;
            if (!vll)
            {
               [attrDict setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSUInteger afterValues=shortsIndex + (vll/2);
               unsigned long long ull;
               NSMutableArray *values=[NSMutableArray array];
               while (shortsIndex < afterValues)
               {
                  ull=  shortsBuffer[shortsIndex]
                     + (shortsBuffer[shortsIndex+1]*0x10000)
                     + (shortsBuffer[shortsIndex+2]*0x100000000)
                     + (shortsBuffer[shortsIndex+3]*0x1000000000000)
                  ;
                  [values addObject:[NSNumber numberWithUnsignedLongLong:ull]];
                  shortsIndex+=4;
               }
               [attrDict setObject:values forKey:key(branch,tag,vr)];
            }
            break;
         }

#pragma mark FL
         case 0x4C46:
         {
            //Float
            shortsIndex+=4;
            if (!vl)
            {
               [attrDict setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSUInteger afterValues=shortsIndex + (vl/2);
               unsigned long ul;
               const unsigned long *pul=&ul;
               const float *pf=NULL;
               pf=(float*)pul;
               NSMutableArray *values=[NSMutableArray array];
               while (shortsIndex < afterValues)
               {
                  ul=shortsBuffer[shortsIndex] + (shortsBuffer[shortsIndex+1]<<16);
                  [values addObject:[NSNumber numberWithFloat:*pf]];
                  shortsIndex+=2;
               }
               [attrDict setObject:values forKey:key(branch,tag,vr)];
            }
            break;
         }
            
#pragma mark FD
         case 0x4446:
         {
            //Double
            shortsIndex+=4;
            if (!vl)
            {
               [attrDict setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
              NSUInteger afterValues=shortsIndex + (vl/2);
               unsigned long long ull;
               const unsigned long long *pull=&ull;
               const double *pd=NULL;
               pd=(double*)pull;
               NSMutableArray *values=[NSMutableArray array];
               while (shortsIndex < afterValues)
               {
                  ull=  shortsBuffer[shortsIndex]
                     + (shortsBuffer[shortsIndex+1]*0x10000)
                     + (shortsBuffer[shortsIndex+2]*0x100000000)
                     + (shortsBuffer[shortsIndex+3]*0x1000000000000)
                  ;
                  [values addObject:[NSNumber numberWithDouble:*pd]];
                  shortsIndex+=4;
               }
               [attrDict setObject:values forKey:key(branch,tag,vr)];
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
            uint32 vll = ( shortsBuffer[shortsIndex+4]       )
                       + ( shortsBuffer[shortsIndex+5] << 16 )
            ;
            NSString *blobKey=key(branch,tag,vr);
            if (!vll)//empty
            {
               [attrDict setObject:@[] forKey:blobKey];
               shortsIndex+= 6 + (vll/2);
               break;
            }

            if ([blobKey hasPrefix:@"00000001_7FE00010"] && (vll==0xFFFFFFFF))
#pragma mark · fragments
            {
               //offset of first fragment
               shortsIndex+=6;
               if (shortsIndex + 4 >= postShortsIndex)
               {
                  LOG_WARNING(@"%@ truncated",blobKey);
                  return failure;
               }
               tag = shortsBuffer[shortsIndex]
                   + ( shortsBuffer[shortsIndex+1] << 16 );
               if (tag == 0xe0ddfffe)
               {
                  LOG_WARNING(@"%@ no fragment item",blobKey);
                  return shortsIndex;
               }
               if (tag!=0xe000fffe)
               {
                  LOG_WARNING(@"%@ encapsulated does not start with a fragment item",blobKey);
                  return failure;
               }
               vll = ( shortsBuffer[shortsIndex+2]       )
                   + ( shortsBuffer[shortsIndex+3] << 16 );
                  
               
               NSMutableData *frameData=[NSMutableData data];
               //frames used for blobModeResources and blobModeInline
               NSMutableArray *frames=[NSMutableArray array];
               NSMutableArray *fragmentRefs=[NSMutableArray array];
               NSMutableData *offsetData=[NSMutableData data];
               uint32 *offsets;//tabla de offsets de fragmentos
               int currentFrameOffset=0;//primer fragment de un frame en la tabla
               int offsetCount=0;//by default, no table
               int offsetAfter=0xFFFFFFFF;
               
               if (vll != 0)
#pragma mark ·· first fragment is an offset table ?
               {
                  //is this an offset table?
                  //is there at least a 00000000 offset (which is the first value of the table) ?
                  
                  uint32 tableFirst = shortsBuffer[shortsIndex + 4]
                      + ( shortsBuffer[shortsIndex + 5] << 16 );
                  
                  if (tableFirst != 0xe000fffe)
                  {
                     
                     [offsetData appendData:[data subdataWithRange:NSMakeRange(((shortsIndex+4)*2)+4,vll)]];
                     [offsetData appendBytes:&offsetAfter length:4];
                     offsets=(uint32 *)[offsetData bytes];
                     offsetCount= sizeof(offsets) / 4;//or offsetTable.length / 4
                     
                     //for blobModeSource
                     NSString *urlString=[NSString stringWithFormat:@"file:%@?offset=%lu&amp;length=%d",blobRefPrefix,(shortsIndex+2)*2, vll];
                     [fragmentRefs addObject:@{ @"Fragment#00000000":@[urlString]}];

                     
                     
                     //first fragment
                     shortsIndex+=4 + (vll/2);
                     tag = shortsBuffer[shortsIndex]
                         + ( shortsBuffer[shortsIndex+1] << 16 );
                     
                     if (tag == 0xe0ddfffe)
                     {
                        LOG_WARNING(@"%@ no fragment after offsetTable",blobKey);
                        return shortsIndex;
                     }

                     if (tag!=0xe000fffe)
                     {
                        LOG_WARNING(@"%@ encapsulated item markup problem",blobKey);
                        return failure;
                     }
                     vll = ( shortsBuffer[shortsIndex+2]       )
                         + ( shortsBuffer[shortsIndex+3] << 16 );
                  }

               }
               else //(vll == 0)
#pragma mark ·· first fragment is NOT an offset table
               {
                  [offsetData appendBytes:&offsetAfter length:4];
                  offsets=(uint32 *)[offsetData bytes];
                  offsetCount=1;
                  //next fragment
                  shortsIndex+=4;
                  tag = shortsBuffer[shortsIndex]
                      + ( shortsBuffer[shortsIndex+1] << 16 );
                  
                  if (tag!=0xe000fffe)
                  {
                     LOG_WARNING(@"%@ encapsulated item markup problem",blobKey);
                     return failure;
                  }
                  vll = ( shortsBuffer[shortsIndex+2]       )
                      + ( shortsBuffer[shortsIndex+3] << 16 );
               }
               
               
#pragma mark .. loop fragments
               while (shortsIndex < postShortsIndex) //(end of sequence)
               {
                  if (
                         (tag==0xe0ddfffe)
                      || (shortsIndex > offsets[currentFrameOffset])
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
                  NSString *urlString=[NSString stringWithFormat:@"file:%@?offset=%lu&amp;length=%d",blobRefPrefix,(shortsIndex+2)*2, vll];
                  NSString *itemString=[NSString stringWithFormat:@"Fragment#%08d",fragmentRefs.count+1];
                  [fragmentRefs addObject:
                   @{
                      itemString : @[ urlString ]
                   }
                   ];
                  [frameData appendData:[data subdataWithRange:NSMakeRange(shortsIndex+shortsIndex+8,vll)]];

                  
                  //new tag and length
                  shortsIndex += ((vll / 2) + 4);
                  tag = shortsBuffer[shortsIndex]
                      + ( shortsBuffer[shortsIndex+1] << 16 );
                  vll = ( shortsBuffer[shortsIndex+2]       )
                      + ( shortsBuffer[shortsIndex+3] << 16 );
               }//end loop fragments
               
#pragma mark .. finalize
               switch (blobMode) {
                     
#pragma mark ···blobModeSource
                  case blobModeSource:
                     [attrDict setObject:fragmentRefs forKey:blobKey];
                     break;
                     
#pragma mark ···blobModeResources
                  case blobModeResources:
                  {
                     NSString *extension;
                     NSArray *tsArray=(attrDict[@"00000001_00020010-UI"]);
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
                     [attrDict setObject:bulkdatas forKey:blobKey];
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
                     [attrDict setObject:b64s forKey:blobKey];
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
                     NSString *urlString=[NSString stringWithFormat:@"file:%@?offset=%lu&amp;length=%d",blobRefPrefix,(shortsIndex+6)*2,vll];
                     [attrDict setObject:@[@{ @"Native":@[urlString]}] forKey:blobKey];
                  }
                     break;

                  case blobModeResources:
                  {
                     NSString *extension;
                     NSString *sopClass=(attrDict[@"00000001_00080016-UI"])[0];

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
                     [attrDict setObject:@[@{ @"Native":@[urlString]}] forKey:blobKey];
                     [blobDict setObject:[data subdataWithRange:NSMakeRange((shortsIndex+6)*2,vll)] forKey:urlString];
                  }
                     break;

                  default://blobModeInline || vll < blobMinSize
                  {
                     NSData *contents=[data subdataWithRange:NSMakeRange((shortsIndex+6)*2,vll)];
                     
                     //convert to JSON base64 (solidus written \/)
                     [attrDict setObject:@[B64JSONstringWithData(contents)] forKey:blobKey];
                     //for eventual j2k compression
                     
                     if ([blobKey hasPrefix:@"00000001_7FE00010"])
                     {
                        NSString *urlString=[NSString stringWithFormat:@"%@%@%@",
                                                blobRefPrefix?blobRefPrefix:@"",
                                               blobKey,
                                                blobRefSuffix?blobRefSuffix:@""
                                                ];
                        [blobDict setObject:contents forKey:urlString];
                     }
                  }
                     break;
               }

            }
            
            shortsIndex+= 6 + (vll/2);

            break;
         }
            
            
#pragma mark AT
         case 0x5441:
         {
            //hexBinary 4 bytes

            shortsIndex+=4;
            if (!vl)
            {
               [attrDict setObject:@[] forKey:key(branch,tag,vr)];
            }
            else
            {
               NSUInteger afterValues=shortsIndex + (vl/2);
               uint16 group=0;
               uint16 element=0;
               NSMutableArray *values=[NSMutableArray array];
               while (shortsIndex < afterValues)
               {
                  group=shortsBuffer[shortsIndex];
                  element=shortsBuffer[shortsIndex+1];
                  [values addObject:[NSString stringWithFormat:@"%02X%02X%02X%02X",group / 0x100,group & 0xFF,element / 0x100,element & 0xFF]];
                  shortsIndex+=4;
               }
               [attrDict setObject:values forKey:key(branch,tag,vr)];
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
      tag=shortsBuffer[shortsIndex]+(shortsBuffer[shortsIndex+1]<<16);
   }
   return shortsIndex;
}

#pragma mark -



int D2dict(
           NSData *data,
           NSMutableDictionary *attrDict,
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
                     attrDict,
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

NSMutableString* json4attrDict(NSMutableDictionary *attrDict)
{
   //NSData *JSONdata=[NSJSONSerialization dataWithJSONObject:@{@"dataset":dict} options:NSJSONWritingSortedKeys error:&error];//10.15 || NSJSONWritingWithoutEscapingSlashes

   NSMutableString *JSONstring=[NSMutableString stringWithString:@"{ \"dataset\": { "];
   NSArray *keys=[[attrDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
   
   
#pragma mark loop on ordered keys
   for (NSString *key in keys)
   {
      LOG_DEBUG(@"%@",key);
      [JSONstring appendFormat:@"\"%@\": ",key];
      
      switch ([key characterAtIndex:key.length-2]+([key characterAtIndex:key.length-1]*0x100))
      {
         
#pragma mark · string based attributes
//AS DA AE DT TM CS LO LT PN SH ST PN UC UT UR UI OB OD OF OL OV OW UN AT
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
            switch ([attrDict[key] count]) {
               case 0:
               {
                  [JSONstring appendString:@"[], "];
                  break;
               }

               case 1:
               {
                  [JSONstring appendFormat:@"[ \"%@\" ], ",
                   (attrDict[key])[0]];
                  break;
               }

               default:
               {
                  [JSONstring appendString:@"[ "];
                  for (NSString *string in attrDict[key])
                  {
                     [JSONstring appendFormat:@"\"%@\", ",
                      string];
                  }
                  [JSONstring deleteCharactersInRange:NSMakeRange(JSONstring.length-2,2)];
                  [JSONstring appendString:@"], "];

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
            switch ([attrDict[key] count]) {
               case 0:
               {
                  [JSONstring appendString:@"[], "];
                  break;
               }

               case 1:
               {
                  id obj=(attrDict[key])[0];
                  if ([obj isKindOfClass:[NSString class]])
                  {
                     [JSONstring appendFormat:@"[ \"%@\" ], ",
                   obj];
                  }
                  else //@[@{ @"Frame#00000001":[urlString]}]
                  {
                     NSString *subKey=([obj allKeys])[0];
                     [JSONstring appendFormat:@"[ { \"%@\": [ \"%@\" ] } ], ",subKey, obj[subKey][0]];
                  }
                  break;
               }

               default://more than one value
               {
                  [JSONstring appendString:@"[ "];
                  id obj=(attrDict[key])[0];
                  if ([obj isKindOfClass:[NSString class]])
                  {
                     for (NSString *string in attrDict[key])
                     {
                        [JSONstring appendFormat:@"\"%@\", ",
                         string];
                     }
                     [JSONstring deleteCharactersInRange:NSMakeRange(JSONstring.length-2,2)];
                     [JSONstring appendString:@" ], "];
                  }
                  else //@[@{ @"BulkData":urlString}]
                  {
                     for (NSDictionary *d in attrDict[key])
                     {
                        NSString *subKey=([d allKeys])[0];
                        [JSONstring appendFormat:@"{ \"%@\": [ \"%@\" ] }, ",subKey, d[subKey][0]];
                     }
                     [JSONstring deleteCharactersInRange:NSMakeRange(JSONstring.length-2,2)];
                     [JSONstring appendString:@"], "];
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
            [JSONstring appendString:@"null, "];
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
            switch ([attrDict[key] count]) {
               case 0:
               {
                  [JSONstring appendString:@"[], "];
                  break;
               }

               case 1:
               {
                  [JSONstring appendFormat:@"[ %@ ], ",
                   (attrDict[key])[0]];
                  break;
               }

               default:
               {
                  [JSONstring appendString:@"[ "];
                  for (NSString *string in attrDict[key])
                  {
                     [JSONstring appendFormat:@"%@, ",
                      string];
                  }
                  [JSONstring deleteCharactersInRange:NSMakeRange(JSONstring.length-2,2)];
                  [JSONstring appendString:@"], "];

                  break;
               }
            }
            break;
         }
      }
   }
   [JSONstring deleteCharactersInRange:NSMakeRange(JSONstring.length-2,2)];
   [JSONstring appendString:@" } }"];
   return JSONstring;
}
