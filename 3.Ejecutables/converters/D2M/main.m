#import <Foundation/Foundation.h>
#import "DCMcharset.h"
#import "utils.h"
#import "ODLog.h"

//D2M
//stdin binary dicom
//stdout mapxmldicom xml (DICOM_contextualizedKey-values)
//https://raw.githubusercontent.com/jacquesfauquex/DICOM_contextualizedKey-values/master/mapxmldicom/mapxmldicom.xsd



#pragma mark - const data markers
const unsigned char zero=0x0;
static NSData *zeroData=nil;
const unsigned char backslash='\\';
static NSData *backslashData=nil;
const unsigned char equal='=';
static NSData *equalData=nil;


NSXMLElement *XMLdcmArray(
   NSString *branch,
   uint32 tag,
   uint16 vr
)
{
   NSXMLElement *node=[NSXMLElement elementWithName:@"array"];
   NSXMLNode *key=[NSXMLNode attributeWithName:@"key"stringValue:
                   [NSString
                    stringWithFormat:@"%@-%08X_%c%c",
                    branch,
                     ((tag & 0xff000000)>>16)
                    +((tag & 0x00ff0000)>>16)
                    +((tag & 0x0000ff00)<<16)
                    +((tag & 0x000000ff)<<16),
                    vr & 0xff,
                    vr >> 8
                   ]
                  ];
   [node addAttribute:key];
   return node;
}

NSXMLElement *XMLdcmArrayPrefixed(
   NSString *branch,
   uint32 tag,
   uint16 vr,
   NSString *p
)
{
  NSXMLElement *node=[NSXMLElement elementWithName:@"array"];
  NSXMLNode *key=[NSXMLNode attributeWithName:@"key"stringValue:
                  [NSString
                   stringWithFormat:@"%@-%08X_%@%c%c",
                   branch,
                    ((tag & 0xff000000)>>16)
                   +((tag & 0x00ff0000)>>16)
                   +((tag & 0x0000ff00)<<16)
                   +((tag & 0x000000ff)<<16),
                   p,
                   vr & 0xff,
                   vr >> 8
                  ]
                 ];
  [node addAttribute:key];
  return node;
}


NSXMLElement *XMLdcmNull(
   NSString *branch,
   uint32 tag,
   uint16 vr
)
{
   NSXMLElement *XMLdcmNull=[NSXMLElement elementWithName:@"null"];
   NSXMLNode *key=[NSXMLNode attributeWithName:@"key"stringValue:
                   [NSString
                    stringWithFormat:@"%@-%08X_%c%c",
                    branch,
                     ((tag & 0xff000000)>>16)
                    +((tag & 0x00ff0000)>>16)
                    +((tag & 0x0000ff00)<<16)
                    +((tag & 0x000000ff)<<16),
                    vr & 0xff,
                    vr >> 8
                   ]
                  ];
   [XMLdcmNull addAttribute:key];
   return XMLdcmNull;
}

#pragma mark -

NSUInteger D2M(
                         NSData *data,
                         unsigned short *shortsBuffer,
                         NSUInteger shortsIndex,
                         NSUInteger postShortsIndex,
                         NSString *branch,
                         NSXMLElement *XMLdataset,
                         NSString *vrCharsetPrefix,
                         uint16 vrCharsetUint16
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
            NSXMLElement *XMLelement=XMLdcmArray(branch,tag,vr);
            if (vl)
            {
               [XMLelement addChild:[NSXMLElement elementWithName:@"string" stringValue:[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange((shortsIndex+4)*2,vl)] encoding:NSISOLatin1StringEncoding]]];
            }
            [XMLdataset addChild:XMLelement];
            shortsIndex+=4+(vl/2);
            break;
         }

            
#pragma mark AE DT TM
         case 0x4541://AE
         case 0x5444://DT
         case 0x4d54://TM
         {
            //variable length (eventually ended with 0x20
            NSXMLElement *XMLelement=XMLdcmArray(branch,tag,vr);
            if (vl)
            {
               NSArray *arrayContents=[[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange((shortsIndex+4)*2,vl)] encoding:NSISOLatin1StringEncoding]componentsSeparatedByString:@"\\"];

               for (NSString *value in arrayContents)
               {
                  NSMutableString *mutableString=[NSMutableString stringWithString:value];
                  trimLeadingSpaces(mutableString);
                  trimTrailingSpaces(mutableString);
                  [XMLelement addChild:[NSXMLElement elementWithName:@"string" stringValue:mutableString]];
               }
            }
            [XMLdataset addChild:XMLelement];
            shortsIndex+=4+(vl/2);
            break;
         }


#pragma mark CS
         case 0x5343://CS
         {
            //variable length (eventually ended with 0x20
            NSXMLElement *XMLelement=XMLdcmArray(branch,tag,vr);
            if (vl)
            {
               NSArray *arrayContents=[[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange((shortsIndex+4)*2,vl)] encoding:NSISOLatin1StringEncoding]componentsSeparatedByString:@"\\"];

               for (NSString *value in arrayContents)
               {
                  NSMutableString *mutableString=[NSMutableString stringWithString:value];
                  trimLeadingSpaces(mutableString);
                  trimTrailingSpaces(mutableString);
                  [XMLelement addChild:[NSXMLElement elementWithName:@"string" stringValue:mutableString]];
               }
               
               if (tag==0x050008)
               {
                  [vrCharsetPrefixNew setString:@""];
                  vrCharsetUint16New=0;
                  
                  int nextFiveBits=1;
                  for (NSXMLNode *charsetNode in [XMLelement children])
                  {
                     uint16 i=encodingCSindex([charsetNode stringValue]);
                     if (i==encodingTotal)//=not in the array
                     {
                        LOG_WARNING(@"%@: bad encoding %@. Replaced by default charset",XMLelement.name,[charsetNode stringValue]);
                        i=0;
                     }
                     vrCharsetUint16New += i * nextFiveBits;
                     [vrCharsetPrefixNew appendString:encodingPrefixString[i]];
                     nextFiveBits*=32;
                  }
               }
            }
            [XMLdataset addChild:XMLelement];
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
            
            NSXMLElement *XMLelement=XMLdcmArrayPrefixed(branch,tag,vr,vrCharsetPrefixNew);
            if (vl)
            {
               NSArray *arrayContents=[[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange((shortsIndex+4)*2,vl)] encoding:encodingNS[vrCharsetUint16]]componentsSeparatedByString:@"\\"];

               for (NSString *value in arrayContents)
               {
                  NSMutableString *mutableString=[NSMutableString stringWithString:value];
                  trimLeadingSpaces(mutableString);
                  trimTrailingSpaces(mutableString);
                  [XMLelement addChild:[NSXMLElement elementWithName:@"string" stringValue:mutableString]];
               }
            }
            [XMLdataset addChild:XMLelement];
            shortsIndex+=4+(vl/2);
            break;
         }

#pragma mark PN
         case 0x4e50://PN
         {
            //variable length (eventually ended with 0x20
            //specific charset

            NSXMLElement *XMLelement=XMLdcmArrayPrefixed(branch,tag,vr,vrCharsetPrefixNew);
            if (vl)
            {
               NSData *contentsData=[data subdataWithRange:NSMakeRange((shortsIndex+4)*2,vl)];
               
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
                        NSRange backslashRange=[contentsData rangeOfData:backslashData options:0 range:remainingContentsRange];
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
                     NSMutableString *nameString=[NSMutableString string];
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
                           NSRange equalRange=[contentsData rangeOfData:equalData options:0 range:remainingNameRange];
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
                        [nameString appendString:representationString];
                        compoundEncoding /= 32;
                    }
                     [XMLelement addChild:[NSXMLElement elementWithName:@"string" stringValue:nameString]];
                  }
               }
            }
            [XMLdataset addChild:XMLelement];
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
            NSXMLElement *XMLelement=XMLdcmArrayPrefixed(branch,tag,vr,vrCharsetPrefixNew);
            if (vll)
            {
               [XMLelement addChild:[NSXMLElement elementWithName:@"string" stringValue:[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange((shortsIndex+6)*2,vll)] encoding:encodingNS[vrCharsetUint16]]]];
            }
            [XMLdataset addChild:XMLelement];
            shortsIndex+=6+(vll/2);
            break;
         }

#pragma mark UR
         case 0x5255://UR
         /*
          Universal Resource Identifier or Universal Resource Locator (URI/URL)
          UTF-8
         */
         {
            uint32 vll = ( shortsBuffer[shortsIndex+4]       )
                       + ( shortsBuffer[shortsIndex+5] << 16 )
            ;
            NSXMLElement *XMLelement=XMLdcmArray(branch,tag,vr);
            if (vll)
            {
               [XMLelement addChild:[NSXMLElement elementWithName:@"string" stringValue:[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange((shortsIndex+6)*2,vll)] encoding:NSUTF8StringEncoding]]];
            }
            [XMLdataset addChild:XMLelement];
            shortsIndex+=6+(vll/2);
            break;
         }

            
#pragma mark UI
         case 0x4955://UI
         {
            NSMutableData *md=[NSMutableData dataWithData:[data subdataWithRange:NSMakeRange((shortsIndex+4)*2,vl)]];
            NSRange zerorange=[md rangeOfData:zeroData options:NSDataSearchBackwards range:NSMakeRange(0,md.length)];
            //remove eventual padding 0x00
            while (zerorange.location != NSNotFound)
            {
               [md replaceBytesInRange:zerorange withBytes:NULL length:0];
               zerorange=[md rangeOfData:zeroData options:NSDataSearchBackwards range:NSMakeRange(0,zerorange.location)];
            }
            NSXMLElement *XMLelement=XMLdcmArray(branch,tag,vr);
            if (md.length)
            {
               NSArray *arrayContents=[[[NSString alloc]initWithData:md encoding:NSISOLatin1StringEncoding]componentsSeparatedByString:@"\\"];

               for (NSString *value in arrayContents)
               {
                  NSMutableString *mutableString=[NSMutableString stringWithString:value];
                  [XMLelement addChild:[NSXMLElement elementWithName:@"string" stringValue:mutableString]];
               }
            }
            [XMLdataset addChild:XMLelement];
            shortsIndex+=4+(vl/2);
            break;
         }
            
#pragma mark - SQ
         case 0x5153://SQ
         {
            unsigned int itemcounter=1;
            NSString *branchTag=[branch stringByAppendingFormat:@"-%08X",
                                  ((tag & 0xff000000)>>16)
                                 +((tag & 0x00ff0000)>>16)
                                 +((tag & 0x0000ff00)<<16)
                                 +((tag & 0x000000ff)<<16)
                                 ];

            uint32 nexttag=shortsBuffer[shortsIndex+4]+(shortsBuffer[shortsIndex+5]<<16);//SQ size
            if (nexttag==0x0)
            {
#pragma mark SQ empty
               [XMLdataset addChild:XMLdcmNull(branch,tag,vr)];
               [XMLdataset addChild:XMLdcmNull([branchTag stringByAppendingFormat:@".%08X",itemcounter],0xe0ddfffe,vr)];
               shortsIndex+=6;
            }
            else if (nexttag!=0xffffffff) //SQ with defined length
            {
#pragma mark SQ defined length
               NSLog(@"ERROR1: SQ with defined length. NOT IMPLEMENTED YET");
               exit(1);
            }
            else //SQ with feff0dde end tag
            {
#pragma mark SQ with closing marker
               [XMLdataset addChild:XMLdcmNull(branch,tag,vr)];
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
                        [XMLdataset addChild:XMLdcmNull([branchTag stringByAppendingFormat:@".%08X",itemcounter],0x0,0x5149)];//IQ

                        [XMLdataset addChild:XMLdcmNull([branchTag stringByAppendingFormat:@".%08X",itemcounter],0x0,0x5A49)];//IZ

                        shortsIndex+=4;//out of empty item
                     }
                     else if (itemlength!=0xffffffff)
                     {
#pragma mark IT defined length
                        NSLog(@"ERROR3: item with defined length. NOT IMPLEMENTED");
                        exit(3);
                     }
                     else
                     {
#pragma mark IT with closing marker
                        [XMLdataset addChild:XMLdcmNull([branchTag stringByAppendingFormat:@".%08X",itemcounter],0x0,0x5149)];//IQ
                        shortsIndex+=4;//inside item
#pragma mark recursion
                        shortsIndex=D2M(
   data,
   shortsBuffer,
   shortsIndex,
   postShortsIndex,
   [branchTag stringByAppendingFormat:@".%08X",itemcounter],
   XMLdataset,
   vrCharsetPrefixNew,
   vrCharsetUint16New
                                                  );

                        [XMLdataset addChild:XMLdcmNull([branchTag stringByAppendingFormat:@".%08X",itemcounter],0xe00dfffe,0x5A49)];//IZ
                     }
                     nexttag=shortsBuffer[shortsIndex]+(shortsBuffer[shortsIndex+1]<<16);

                     itemcounter++;
                  }
               }
#pragma mark SQ closing marker
               [XMLdataset addChild:XMLdcmNull([branchTag stringByAppendingPathExtension:@"FFFFFFFF"],0xe0ddfffe,0x5A51)];
               shortsIndex+=8;
            }
            break;
         }

#pragma mark - IS DS
         case 0x5344://DS
         case 0x5349://IS
         {
            //variable length (eventually ended with 0x20
            NSXMLElement *XMLelement=XMLdcmArray(branch,tag,vr);
            if (vl)
            {
               NSArray *arrayContents=[[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange((shortsIndex+4)*2,vl)] encoding:NSISOLatin1StringEncoding]componentsSeparatedByString:@"\\"];

               for (NSString *value in arrayContents)
               {
                  NSMutableString *mutableString=[NSMutableString stringWithString:value];
                  trimLeadingSpaces(mutableString);
                  trimTrailingSpaces(mutableString);
                  [XMLelement addChild:[NSXMLElement elementWithName:@"number" stringValue:mutableString]];
               }
            }
            [XMLdataset addChild:XMLelement];
            
            shortsIndex+=4+(vl/2);
            break;
         }


#pragma mark SL
         case 0x4C53:
         {
            //Signed Long
            NSXMLElement *XMLelement=XMLdcmArray(branch,tag,vr);
            shortsIndex+=4;
            if (vl)
            {
               NSUInteger afterValues=shortsIndex + (vl/2);
               long sl;
               while (shortsIndex < afterValues)
               {
                  sl=shortsBuffer[shortsIndex] + (shortsBuffer[shortsIndex+1]<<16);
                  [XMLelement addChild:[NSXMLElement elementWithName:@"number" stringValue:[NSString stringWithFormat:@"%ld",sl]]];
                  shortsIndex+=2;
               }
            }
            [XMLdataset addChild:XMLelement];
            break;
         }
            
#pragma mark UL
         case 0x4C55:
         {
            //Unsigned Long
            NSXMLElement *XMLelement=XMLdcmArray(branch,tag,vr);
            shortsIndex+=4;
            if (vl)
            {
               NSUInteger afterValues=shortsIndex + (vl/2);
               unsigned long ul;
               while (shortsIndex < afterValues)
               {
                  ul=shortsBuffer[shortsIndex] + (shortsBuffer[shortsIndex+1]<<16);
                  [XMLelement addChild:[NSXMLElement elementWithName:@"number" stringValue:[NSString stringWithFormat:@"%lu",ul]]];
                  shortsIndex+=2;
               }
            }
            [XMLdataset addChild:XMLelement];
            break;
         }

            
#pragma mark SS
         case 0x5353:
         {
            //Signed Short
            NSXMLElement *XMLelement=XMLdcmArray(branch,tag,vr);
            shortsIndex+=4;
            if (vl)
            {
               NSUInteger afterValues=shortsIndex + (vl/2);
               short ss;
               while (shortsIndex < afterValues)
               {
                  ss=shortsBuffer[shortsIndex];
                  [XMLelement addChild:[NSXMLElement elementWithName:@"number" stringValue:[NSString stringWithFormat:@"%d",ss]]];
                  shortsIndex++;
               }
            }
            [XMLdataset addChild:XMLelement];
            break;
         }
            
#pragma mark US
         case 0x5355:
         {
            //Unsigned Short
            NSXMLElement *XMLelement=XMLdcmArray(branch,tag,vr);
            shortsIndex+=4;
            if (vl)
            {
               NSUInteger afterValues=shortsIndex + (vl/2);
               unsigned short us;
               while (shortsIndex < afterValues)
               {
                  us=shortsBuffer[shortsIndex];
                  [XMLelement addChild:[NSXMLElement elementWithName:@"number" stringValue:[NSString stringWithFormat:@"%d",us]]];
                  shortsIndex++;
               }
            }
               
            [XMLdataset addChild:XMLelement];
            break;
         }

#pragma mark SV
         case 0x5653:
         {
            //Signed 64-bit Very Long
            uint32 vll = ( shortsBuffer[shortsIndex+4]       )
                       + ( shortsBuffer[shortsIndex+5] << 16 )
            ;

            NSXMLElement *XMLelement=XMLdcmArray(branch,tag,vr);
            shortsIndex+=6;
            if (vll)
            {
               NSUInteger afterValues=shortsIndex + (vll/2);
               long long sll;
               while (shortsIndex < afterValues)
               {
                  sll=  shortsBuffer[shortsIndex]
                     + (shortsBuffer[shortsIndex+1]*0x10000)
                     + (shortsBuffer[shortsIndex+2]*0x100000000)
                     + (shortsBuffer[shortsIndex+3]*0x1000000000000)
                  ;
                  [XMLelement addChild:[NSXMLElement elementWithName:@"number" stringValue:[NSString stringWithFormat:@"%lld",sll]]];
                  shortsIndex+=4;
               }
            }
            [XMLdataset addChild:XMLelement];
            break;
         }

#pragma mark UV
         case 0x5655:
         {
            //Unsigned 64-bit Very Long
            uint32 vll = ( shortsBuffer[shortsIndex+4]       )
                       + ( shortsBuffer[shortsIndex+5] << 16 )
            ;

            NSXMLElement *XMLelement=XMLdcmArray(branch,tag,vr);
            shortsIndex+=6;
            if (vll)
            {
               NSUInteger afterValues=shortsIndex + (vll/2);
               unsigned long long ull;
               while (shortsIndex < afterValues)
               {
                  ull=  shortsBuffer[shortsIndex]
                     + (shortsBuffer[shortsIndex+1]*0x10000)
                     + (shortsBuffer[shortsIndex+2]*0x100000000)
                     + (shortsBuffer[shortsIndex+3]*0x1000000000000)
                  ;
                  [XMLelement addChild:[NSXMLElement elementWithName:@"number" stringValue:[NSString stringWithFormat:@"%lld",ull]]];
                  shortsIndex+=4;
               }
            }
            [XMLdataset addChild:XMLelement];
            break;
         }

#pragma mark FL
         case 0x4C46:
         {
            //Float
            NSXMLElement *XMLelement=XMLdcmArray(branch,tag,vr);
            shortsIndex+=4;
            if (vl)
            {
               NSUInteger afterValues=shortsIndex + (vl/2);
               unsigned long ul;
               const unsigned long *pul=&ul;
               const float *pf=NULL;
               pf=(float*)pul;
               while (shortsIndex < afterValues)
               {
                  ul=shortsBuffer[shortsIndex] + (shortsBuffer[shortsIndex+1]<<16);
                  [XMLelement addChild:[NSXMLElement elementWithName:@"number" stringValue:[NSString stringWithFormat:@"%f",*pf]]];
                  shortsIndex+=2;
               }
            }
            [XMLdataset addChild:XMLelement];
            break;
         }
            
#pragma mark FD
         case 0x4446:
         {
            //double
            NSXMLElement *XMLelement=XMLdcmArray(branch,tag,vr);
            shortsIndex+=4;
            if (vl)
            {
               NSUInteger afterValues=shortsIndex + (vl/2);
               unsigned long long ull;
               const unsigned long long *pull=&ull;
               const double *pd=NULL;
               pd=(double*)pull;
               while (shortsIndex < afterValues)
               {
                  ull=  shortsBuffer[shortsIndex]
                     + (shortsBuffer[shortsIndex+1]*0x10000)
                     + (shortsBuffer[shortsIndex+2]*0x100000000)
                     + (shortsBuffer[shortsIndex+3]*0x1000000000000)
                  ;
                  [XMLelement addChild:[NSXMLElement elementWithName:@"number" stringValue:[NSString stringWithFormat:@"%f",*pd]]];
                  shortsIndex+=4;
               }
            }
            [XMLdataset addChild:XMLelement];
            break;
         }

#pragma mark OB OD OF OL OV OW UN
         case 0x424F:
            /*
             An octet-stream where the encoding of the contents is specified by the negotiated Transfer Syntax. OB is a VR that is insensitive to byte ordering (see Section 7.3). The octet-stream shall be padded with a single trailing NULL byte value (00H) when necessary to achieve even length.
             */
         case 0x444F:
            /*
             A stream of 64-bit IEEE 754:1985 floating point words. OD is a VR that requires byte swapping within each 64-bit word when changing byte ordering (see Section 7.3).
             */
         case 0x464F:
            /*
             A stream of 32-bit IEEE 754:1985 floating point words. OF is a VR that requires byte swapping within each 32-bit word when changing byte ordering (see Section 7.3).
             */
         case 0x4C4F:
            /*
             A stream of 32-bit words where the encoding of the contents is specified by the negotiated Transfer Syntax. OL is a VR that requires byte swapping within each word when changing byte ordering (see Section 7.3).
             */
         case 0x564F:
            /*
             A stream of 64-bit words where the encoding of the contents is specified by the negotiated Transfer Syntax. OV is a VR that requires byte swapping within each word when changing byte ordering (see Section 7.3).
             */
         case 0x574F:
            /*
             A stream of 16-bit words where the encoding of the contents is specified by the negotiated Transfer Syntax. OW is a VR that requires byte swapping within each word when changing byte ordering (see Section 7.3).
             */
         case 0x4E55:
         {
            uint32 vll = ( shortsBuffer[shortsIndex+4]       )
                       + ( shortsBuffer[shortsIndex+5] << 16 )
            ;
            NSXMLElement *XMLelement=XMLdcmArray(branch,tag,vr);
            if (vll)
            {
               NSString *base64string= [[NSString alloc] initWithData:[[data subdataWithRange:NSMakeRange((shortsIndex+6)*2,vll)]base64EncodedDataWithOptions:0] encoding:NSASCIIStringEncoding];

               [XMLelement addChild:[NSXMLElement elementWithName:@"string" stringValue:base64string]];
            }
            [XMLdataset addChild:XMLelement];

            shortsIndex+= 6 + (vll/2);

            break;
         }
            
            
#pragma mark AT
         case 0x5441:
         {
            //hexBinary 4 bytes

            NSXMLElement *XMLelement=XMLdcmArray(branch,tag,vr);
            shortsIndex+=4;
            if (vl)
            {
               NSUInteger afterValues=shortsIndex + (vl/2);
               uint16 group;
               uint16 element;
               while (shortsIndex < afterValues)
               {
                  group=shortsBuffer[shortsIndex];
                  element=shortsBuffer[shortsIndex+1];
                  [XMLelement addChild:[NSXMLElement elementWithName:@"string" stringValue:[NSString stringWithFormat:@"%02X%02X%02X%02X",group/0x100,group & 0xFF,element/0x100,element & 0xFF]]];
                  shortsIndex+=4;
               }
            }
            [XMLdataset addChild:XMLelement];
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
      tag=shortsBuffer[shortsIndex]+(shortsBuffer[shortsIndex+1]<<16);
   }
   return shortsIndex;
}

#pragma mark -
int main(int argc, const char * argv[]) {
   @autoreleasepool {

      zeroData=[NSData dataWithBytes:&zero length:1];
      backslashData=[NSData dataWithBytes:&backslash length:1];
      equalData=[NSData dataWithBytes:&equal length:1];
      NSProcessInfo *processInfo=[NSProcessInfo processInfo];
      
#pragma marks environment

      NSDictionary *environment=processInfo.environment;
      
      if (environment[@"D2MlogLevel"])
      {
         NSUInteger logLevel=[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:environment[@"D2MlogLevel"]];
         if (logLevel!=NSNotFound) ODLogLevel=(ODLogLevelEnum)logLevel;
         else ODLogLevel=4;//ERROR (default)
      }
      else ODLogLevel=4;//ERROR (default)
      
      
      //H2XlogPath
      NSString *logPath=environment[@"D2MlogPath"];
      if (logPath && ([logPath hasPrefix:@"/Users/Shared"] || [logPath hasPrefix:@"/Volumes/LOG"]))
      {
         if ([logPath hasSuffix:@".log"])
            freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
         else freopen([[logPath stringByAppendingPathExtension:@".log"] cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      }
      else freopen([@"/Users/Shared/D2M.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      
      //D2Moutput
      NSString *D2Moutput=environment[@"D2Moutput"];
      if (!D2Moutput) D2Moutput=@"/dev/stdout";

      //D2MtestPath
      NSData *data=nil;
      NSString *testPath=environment[@"D2MtestPath"];
      if (testPath) data=[NSData dataWithContentsOfFile:testPath];
      else data = [[NSFileHandle fileHandleWithStandardInput] availableData];
      
      LOG_DEBUG(@"environment:\r%@",[environment description]);
      
#pragma mark in out
      if (data.length <10)
      {
         LOG_WARNING(@"dicom binary data too small");
      }
      else
      {
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
         NSXMLElement *root=[NSXMLElement elementWithName:@"map"];
         [root addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://www.w3.org/2005/xpath-functions"]];
         NSXMLElement *XMLdataset=[NSXMLElement elementWithName:@"map"];
         [root addChild:XMLdataset];
         [XMLdataset addAttribute:[NSXMLNode attributeWithName:@"key"stringValue:@"dataset"]];

         NSUInteger index=D2M(
                              data,
                              shorts,
                              datasetShortOffset,
                              (data.length -1) / 2,
                              @"00000001",
                              XMLdataset,
                              vrCharsetPrefix,
                              vrCharsetUint16
                              );
         if (index < (data.length -1) / 2)
         {
            LOG_ERROR(@"parsing not completed");
         }

         NSXMLDocument *xmlDocument=[[NSXMLDocument alloc] initWithRootElement:root];
         [xmlDocument setCharacterEncoding:@"UTF-8"];
         [xmlDocument setVersion:@"1.0"];

#pragma marks args
         
         NSArray *args=processInfo.arguments;
         NSUInteger argscount=args.count;
         NSArray *xslt1Paths=nil;
         if (argscount>1)
            xslt1Paths =[args subarrayWithRange:NSMakeRange(1, argscount-1)];
         else xslt1Paths=[NSArray array];//empty array
       
         id result=xmlDocument;
         for (NSString *xslt1Path in xslt1Paths)
         {
            NSData *xsl1data=[NSData dataWithContentsOfFile:xslt1Path];
            if (!xsl1data)
            {
               LOG_ERROR(@"arg XSL1TransformationPath %@ not available",args[1]);
               exit(2);
            }

            NSMutableDictionary *xslparams=environment[[xslt1Path lastPathComponent]];
            LOG_DEBUG(@"xsl1t %@ with params : %@",args[1],[xslparams description]);
            
            NSError *error=nil;
            id result=[xmlDocument objectByApplyingXSLT:xsl1data arguments:xslparams error:&error];
            if (!result)
            {
               LOG_WARNING(@"Error 5 with xsl %@",[args description]);
               [[NSData data] writeToFile:@"/dev/stdout" atomically:NO];
               exit(5);
            }
            [xmlDocument setRootElement:[result rootElement]];
         }
         if ([result isMemberOfClass:[NSXMLDocument class]])
            [[result XMLData] writeToFile:D2Moutput atomically:NO];
         else [result writeToFile:D2Moutput atomically:NO];
      }
   }//end autorelease pool
   return 0;
}
