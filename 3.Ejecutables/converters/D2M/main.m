#import <Foundation/Foundation.h>
#import "utils.h"
#import "ODLog.h"

//D2M
//stdin binary dicom
//stdout mapxmldicom xml (DICOM_contextualizedKey-values)
//https://raw.githubusercontent.com/jacquesfauquex/DICOM_contextualizedKey-values/master/mapxmldicom/mapxmldicom.xsd

#pragma mark - xml elements
const unsigned char zero=0x0;
static NSData *zeroData=nil;


NSXMLElement *dcmArray(
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


NSXMLElement *dcmNull(
   NSString *branch,
   uint32 tag,
   uint16 vr
)
{
   NSXMLElement *dcmNull=[NSXMLElement elementWithName:@"null"];
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
   [dcmNull addAttribute:key];
   return dcmNull;
}

#pragma mark -

NSUInteger parseAttrList(
                         NSData *data,
                         unsigned short *shortsBuffer,
                         NSUInteger shortsIndex,
                         NSUInteger postShortsIndex,
                         NSString *branch,
                         NSXMLElement *dataset
                         )
{
   UInt16 vr;//value representation
   UInt32 tag =   shortsBuffer[shortsIndex  ]
              + ( shortsBuffer[shortsIndex+1] << 16 );
   while (tag!=0xe00dfffe &&  shortsIndex < postShortsIndex) //(end item)
   {
      UInt16 vl = shortsBuffer[shortsIndex+3];//for AE,AS,AT,CS,DA,DS,DT,FL,FD,IS,LO,LT,PN,SH,SL,SS,ST,TM,UI,UL,US
      
      vr = shortsBuffer[shortsIndex+2];
      switch (vr) {

#pragma mark AE CS DT LO LT PN SH ST TM
         case 0x4541://AE
         case 0x5343://CS
         case 0x5444://DT
         case 0x4f4c://LO
         case 0x544c://LT
         case 0x4e50://PN
         case 0x4853://SH
         case 0x5453://ST
         case 0x4d54://TM
         {
            //variable length (eventually ended with 0x20
            
            NSArray *arrayContents=[[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange((shortsIndex+4)*2,vl)] encoding:NSISOLatin1StringEncoding]componentsSeparatedByString:@"\\"];

            NSXMLElement *element=dcmArray(branch,tag,vr);
            for (NSString *value in arrayContents)
            {
               NSMutableString *mutableString=[NSMutableString stringWithString:value];
               trimLeadingSpaces(mutableString);
               trimTrailingSpaces(mutableString);
               [element addChild:[NSXMLElement elementWithName:@"string" stringValue:mutableString]];
            }
            [dataset addChild:element];
            
            shortsIndex+=4+(vl/2);
            break;
         }


#pragma mark AS DA
         case 0x5341://AS 4 chars (one value only)
         case 0x4144://DA 8 chars (one value only)
         {
            NSXMLElement *element=dcmArray(branch,tag,vr);
            [element addChild:[NSXMLElement elementWithName:@"string" stringValue:[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange((shortsIndex+4)*2,vl)] encoding:NSISOLatin1StringEncoding]]];
            [dataset addChild:element];
            
            shortsIndex+=4+(vl/2);
            break;
         }

#pragma mark UC
         case 0x4355:
         /*
          Unlimited Characters
         */
#pragma mark UR
         case 0x5255://UR
         /*
          Universal Resource Identifier or Universal Resource Locator (URI/URL)
         */
#pragma mark UT
         case 0x5455://UT
         /*
          A character string that may contain one or more paragraphs. It may contain the Graphic Character set and the Control Characters, CR, LF, FF, and ESC. It may be padded with trailing spaces, which may be ignored, but leading spaces are considered to be significant. Data Elements with this VR shall not be multi-valued and therefore character code 5CH (the BACKSLASH "\" in ISO-IR 6) may be used.
         */
         {
            uint32 vll = ( shortsBuffer[shortsIndex+4]       )
                       + ( shortsBuffer[shortsIndex+5] << 16 )
            ;
            NSXMLElement *element=dcmArray(branch,tag,vr);
            [element addChild:[NSXMLElement elementWithName:@"string" stringValue:[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange((shortsIndex+6)*2,vll)] encoding:NSISOLatin1StringEncoding]]];
            [dataset addChild:element];
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
            NSArray *arrayContents=[[[NSString alloc]initWithData:md encoding:NSISOLatin1StringEncoding]componentsSeparatedByString:@"\\"];

            NSXMLElement *element=dcmArray(branch,tag,vr);
            for (NSString *value in arrayContents)
            {
               NSMutableString *mutableString=[NSMutableString stringWithString:value];
               [element addChild:[NSXMLElement elementWithName:@"string" stringValue:mutableString]];
            }
            [dataset addChild:element];
            
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
               [dataset addChild:dcmArray(branch,tag,vr)];
               [dataset addChild:dcmNull([branchTag stringByAppendingFormat:@".%08X",itemcounter],0xe0ddfffe,vr)];
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
               [dataset addChild:dcmArray(branch,tag,vr)];
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
                        [dataset addChild:dcmNull([branchTag stringByAppendingFormat:@".%08X",itemcounter],0x0,0x5149)];//IQ

                        [dataset addChild:dcmNull([branchTag stringByAppendingFormat:@".%08X",itemcounter],0x0,0x5A49)];//IZ

                        shortsIndex+=4;//out of empty item
                     }
                     else if (itemlength!=0xffffffff)
                     {
#pragma mark IT defined length
                        NSLog(@"ERROR3: item with defined length. NOT IMPLEMENTED YET");
                        exit(3);
                     }
                     else
                     {
#pragma mark IT with closing marker
                        [dataset addChild:dcmNull([branchTag stringByAppendingFormat:@".%08X",itemcounter],0x0,0x5149)];//IQ
                        shortsIndex+=4;//inside item
#pragma mark recursion
                        shortsIndex=parseAttrList(
   data,
   shortsBuffer,
   shortsIndex,
   postShortsIndex,
   [branchTag stringByAppendingFormat:@".%08X",itemcounter],
   dataset
                                                  );

                        [dataset addChild:dcmNull([branchTag stringByAppendingFormat:@".%08X",itemcounter],0xe00dfffe,0x5A49)];//IZ
                     }
                     nexttag=shortsBuffer[shortsIndex]+(shortsBuffer[shortsIndex+1]<<16);

                     itemcounter++;
                  }
               }
#pragma mark SQ closing marker
               [dataset addChild:dcmNull([branchTag stringByAppendingPathExtension:@"FFFFFFFF"],0xe0ddfffe,0x5A51)];
               shortsIndex+=8;
            }
            break;
         }

#pragma mark - IS DS
         case 0x5344://DS
         case 0x5349://IS
         {
            //variable length (eventually ended with 0x20
            
            NSArray *arrayContents=[[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange((shortsIndex+4)*2,vl)] encoding:NSISOLatin1StringEncoding]componentsSeparatedByString:@"\\"];

            NSXMLElement *element=dcmArray(branch,tag,vr);
            for (NSString *value in arrayContents)
            {
               NSMutableString *mutableString=[NSMutableString stringWithString:value];
               trimLeadingSpaces(mutableString);
               trimTrailingSpaces(mutableString);
               [element addChild:[NSXMLElement elementWithName:@"number" stringValue:mutableString]];
            }
            [dataset addChild:element];
            
            shortsIndex+=4+(vl/2);
            break;
         }


#pragma mark SL
         case 0x4C53:
         {
            //Signed Long
            NSXMLElement *element=dcmArray(branch,tag,vr);
            
            shortsIndex+=4;
            NSUInteger afterValues=shortsIndex + (vl/2);
            long sl;
            while (shortsIndex < afterValues)
            {
               sl=shortsBuffer[shortsIndex] + (shortsBuffer[shortsIndex+1]<<16);
               [element addChild:[NSXMLElement elementWithName:@"number" stringValue:[NSString stringWithFormat:@"%ld",sl]]];
               shortsIndex+=2;
            }
            
            [dataset addChild:element];
            break;
         }
            
#pragma mark UL
         case 0x4C55:
         {
            //Unsigned Long
            NSXMLElement *element=dcmArray(branch,tag,vr);
            
            shortsIndex+=4;
            NSUInteger afterValues=shortsIndex + (vl/2);
            unsigned long ul;
            while (shortsIndex < afterValues)
            {
               ul=shortsBuffer[shortsIndex] + (shortsBuffer[shortsIndex+1]<<16);
               [element addChild:[NSXMLElement elementWithName:@"number" stringValue:[NSString stringWithFormat:@"%lul",ul]]];
               shortsIndex+=2;
            }
            
            [dataset addChild:element];
            break;
         }

            
#pragma mark SS
         case 0x5353:
         {
            //Signed Short
            NSXMLElement *element=dcmArray(branch,tag,vr);
            
            shortsIndex+=4;
            NSUInteger afterValues=shortsIndex + (vl/2);
            short ss;
            while (shortsIndex < afterValues)
            {
               ss=shortsBuffer[shortsIndex];
               [element addChild:[NSXMLElement elementWithName:@"number" stringValue:[NSString stringWithFormat:@"%d",ss]]];
               shortsIndex++;
            }
            
            [dataset addChild:element];
            break;
         }
            
#pragma mark US
         case 0x5355:
         {
            //Unsigned Short
            NSXMLElement *element=dcmArray(branch,tag,vr);
            
            shortsIndex+=4;
            NSUInteger afterValues=shortsIndex + (vl/2);
            unsigned short us;
            while (shortsIndex < afterValues)
            {
               us=shortsBuffer[shortsIndex];
               [element addChild:[NSXMLElement elementWithName:@"number" stringValue:[NSString stringWithFormat:@"%d",us]]];
               shortsIndex++;
            }
            
            [dataset addChild:element];
            break;
         }

#pragma mark SV
         case 0x5653:
         {
            //Signed 64-bit Very Long
            uint32 vll = ( shortsBuffer[shortsIndex+4]       )
                       + ( shortsBuffer[shortsIndex+5] << 16 )
            ;

            NSXMLElement *element=dcmArray(branch,tag,vr);
            
            shortsIndex+=6;
            NSUInteger afterValues=shortsIndex + (vll/2);
            long long sll;
            while (shortsIndex < afterValues)
            {
               sll=  shortsBuffer[shortsIndex]
                  + (shortsBuffer[shortsIndex+1]*0x10000)
                  + (shortsBuffer[shortsIndex+2]*0x100000000)
                  + (shortsBuffer[shortsIndex+3]*0x1000000000000)
               ;
               [element addChild:[NSXMLElement elementWithName:@"number" stringValue:[NSString stringWithFormat:@"%lld",sll]]];
               shortsIndex+=4;
            }
            
            [dataset addChild:element];
            break;
         }

#pragma mark UV
         case 0x5655:
         {
            //Unsigned 64-bit Very Long
            uint32 vll = ( shortsBuffer[shortsIndex+4]       )
                       + ( shortsBuffer[shortsIndex+5] << 16 )
            ;

            NSXMLElement *element=dcmArray(branch,tag,vr);
            
            shortsIndex+=6;
            NSUInteger afterValues=shortsIndex + (vll/2);
            unsigned long long ull;
            while (shortsIndex < afterValues)
            {
               ull=  shortsBuffer[shortsIndex]
                  + (shortsBuffer[shortsIndex+1]*0x10000)
                  + (shortsBuffer[shortsIndex+2]*0x100000000)
                  + (shortsBuffer[shortsIndex+3]*0x1000000000000)
               ;
               [element addChild:[NSXMLElement elementWithName:@"number" stringValue:[NSString stringWithFormat:@"%lld",ull]]];
               shortsIndex+=4;
            }
            
            [dataset addChild:element];
            break;
         }

#pragma mark FL
         case 0x4C46:
         {
            //Unsigned Long
            NSXMLElement *element=dcmArray(branch,tag,vr);
            
            shortsIndex+=4;
            NSUInteger afterValues=shortsIndex + (vl/2);
            unsigned long ul;
            const unsigned long *pul=&ul;
            const float *pf=NULL;
            pf=(float*)pul;
            while (shortsIndex < afterValues)
            {
               ul=shortsBuffer[shortsIndex] + (shortsBuffer[shortsIndex+1]<<16);
               [element addChild:[NSXMLElement elementWithName:@"number" stringValue:[NSString stringWithFormat:@"%f",*pf]]];
               shortsIndex+=2;
            }
            
            [dataset addChild:element];
            break;
         }
            
#pragma mark FD
         case 0x4446:
         {
            NSXMLElement *element=dcmArray(branch,tag,vr);
            
            shortsIndex+=4;
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
               [element addChild:[NSXMLElement elementWithName:@"number" stringValue:[NSString stringWithFormat:@"%f",*pd]]];
               shortsIndex+=4;
            }
            
            [dataset addChild:element];
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

            NSString *base64string= [[NSString alloc] initWithData:[[data subdataWithRange:NSMakeRange((shortsIndex+6)*2,vll)]base64EncodedDataWithOptions:0] encoding:NSASCIIStringEncoding];

            NSXMLElement *element=dcmArray(branch,tag,vr);
            [element addChild:[NSXMLElement elementWithName:@"string" stringValue:base64string]];
            [dataset addChild:element];

            shortsIndex+= 6 + (vll/2);

            break;
         }
            
            
#pragma mark TODO AT (hexBinary 4 bytes)
         case 0x5441:
         {
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
      

      //D2MtestPath
      NSData *data=nil;
      NSString *testPath=environment[@"D2MtestPath"];
      if (testPath) data=[NSData dataWithContentsOfFile:testPath];
      else data = [[NSFileHandle fileHandleWithStandardInput] availableData];
      
      LOG_DEBUG(@"environment:\r%@",[environment description]);
      
#pragma mark in out
      if (data.length)
      {
         unsigned short *shorts=(unsigned short*)[data bytes];
         if (data.length < 5)
         {
            LOG_WARNING(@"dicom binary data too small %@",[data description]);
            [[NSData data] writeToFile:@"/dev/stdout" atomically:NO];
         }
         
         NSUInteger datasetShortOffset=0;
         //skip preambule?
         if (data.length > 132 && shorts[64]==0x4944 && shorts[65]==0x4d43) datasetShortOffset=66;

         NSXMLElement *root=[NSXMLElement elementWithName:@"map"];
         NSXMLElement *dataset=[NSXMLElement elementWithName:@"map"];
         [root addChild:dataset];
         [dataset addAttribute:[NSXMLNode attributeWithName:@"key"stringValue:@"dataset"]];
         
         
         NSUInteger index=parseAttrList(
data,
shorts,
datasetShortOffset,
(data.length -1) / 2,
@"00000001",
dataset
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
       
         id result=nil;
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
            [[result XMLData] writeToFile:@"/dev/stdout" atomically:NO];
         else [result writeToFile:@"/dev/stdout" atomically:NO];
      }
      else [[NSData data] writeToFile:@"/dev/stdout" atomically:NO];//empty data
   }//end autorelease pool
   return 0;
}
