#import <Foundation/Foundation.h>
#import "utils.h"
#import "ODLog.h"

//H2X
//stdin string based dicom mysql hexa representation
//stdout opendicom xml (DICOM_contextualizedKey-values)
//https://github.com/jacquesfauquex/DICOM_contextualizedKey-values/blob/master/xml/xmldicom.xsd

#pragma mark cuartet parsing

const unsigned char zero=0x0;
static NSData *zeroData=nil;

const unsigned char byte2cuartet[] =
{
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,
   0x08,0x09,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0x0A,0x0B,0x0C,0x0D,0x0E,0x0F,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0x0A,0x0B,0x0C,0x0D,0x0E,0x0F,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
   0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF
};

UInt16 uint16FromCuartetBuffer( unsigned char* buffer, NSUInteger index)
{
   return   (byte2cuartet[buffer[index  ]] << 4)
   + (byte2cuartet[buffer[index+1]] << 0)
   + (byte2cuartet[buffer[index+2]] << 12)
   + (byte2cuartet[buffer[index+3]] << 8)
   ;
}


UInt32 uint32FromCuartetBuffer( unsigned char* buffer, NSUInteger index)
{
   return   (byte2cuartet[buffer[index  ]] << 4)
          + (byte2cuartet[buffer[index+1]] << 0)
          + (byte2cuartet[buffer[index+2]] << 12)
          + (byte2cuartet[buffer[index+3]] << 8)
          + (byte2cuartet[buffer[index+4]] << 20)
          + (byte2cuartet[buffer[index+5]] << 16)
          + (byte2cuartet[buffer[index+6]] << 28)
          + (byte2cuartet[buffer[index+7]] << 24)
          ;
}

uint32 uint32visual(uint32 tag)
{
   return   ((tag & 0xff000000)>>16)
           +((tag & 0x00ff0000)>>16)
           +((tag & 0x0000ff00)<<16)
           +((tag & 0x000000ff)<<16);
}

UInt8 octetFromCuartetBuffer( unsigned char* buffer, NSUInteger index)
{
   return   (byte2cuartet[buffer[index  ]] << 4)
   + (byte2cuartet[buffer[index+1]] << 0)
   ;
}

void setMutabledataFromCuartetBuffer( unsigned char* buffer, NSUInteger startindex, NSUInteger afterindex, NSMutableData *md)
{
   [md setLength:0];
   uint8 octet;
   for (NSUInteger i=startindex; i<afterindex; i+=2 )
   {
      octet = (byte2cuartet[buffer[i  ]] << 4)
            + (byte2cuartet[buffer[i+1]] << 0)
            ;
      [md appendBytes:&octet length:1];
   }
}


#pragma mark - xml elements

NSXMLElement *aEmpty(NSString *branch, NSString *tagchain, NSString *vrstring)
{
   
   NSXMLElement *a=[NSXMLElement elementWithName:@"a"];
   [a addAttribute:[NSXMLNode attributeWithName:@"b" stringValue:branch]];
   [a addAttribute:[NSXMLNode attributeWithName:@"t" stringValue:tagchain]];
   [a addAttribute:[NSXMLNode attributeWithName:@"r" stringValue:vrstring]];
   return a;
}

NSXMLElement *aArray(NSString *branch, NSString *chain, uint32 tag, uint16 vr, NSArray *array, BOOL trimLeading, BOOL trimTrailing)
{
   NSString *vrString=[NSString stringWithFormat:@"%c%c", vr & 0xff, vr >> 8];
   NSXMLElement *a=aEmpty(
                       branch,
                       [NSString stringWithFormat:@"%@%08x",chain,uint32visual(tag)],
                       vrString
                       );
   for (NSString *value in array)
   {
      NSMutableString *mutableString=[NSMutableString stringWithString:value];
      if (trimLeading) trimLeadingSpaces(mutableString);
      if (trimTrailing) trimTrailingSpaces(mutableString);
      [a addChild:[NSXMLElement elementWithName:vrString stringValue:mutableString]];
   }
   return a;
}

#pragma mark -

NSUInteger parseAttrList(
                         unsigned char* buffer,
                         NSUInteger index,
                         NSUInteger postbuffer,
                         NSString *chain,
                         NSString *branch,
                         NSXMLElement *dataset
                         )
{
   UInt32 tag = uint32FromCuartetBuffer(buffer,index);
   UInt16 vr;//value representation
   UInt16 vl;//value length
   UInt32 vll;// 4 bytes value length
   NSMutableData *md=[NSMutableData data];
   
   
   while (tag!=0xe00dfffe &&  index < postbuffer) //fffee00d
   {
      vr = uint16FromCuartetBuffer(buffer,index+8);
      vl = uint16FromCuartetBuffer(buffer,index+12);
      
      switch (vr) {
            
#pragma mark attribute AT (hexBinary 4 bytes)
         case 0x5441:
         {
            break;
         }

#pragma mark AE AS CS DA DS DT IS LO LT PN SH ST TM
         case 0x4541://AE
         case 0x5341://AS
         case 0x5343://CS
         case 0x4144://DA
         case 0x5344://DS
         case 0x5444://DT
         case 0x5349://IS
         case 0x4f4c://LO
         case 0x544c://LT
         case 0x4e50://PN
         case 0x4853://SH
         case 0x5453://ST
         case 0x4d54://TM
         {
            setMutabledataFromCuartetBuffer(buffer,index+16,index+16+vl+vl,md);
            [dataset addChild:aArray(branch,chain,tag,vr,[[[NSString alloc]initWithData:md encoding:NSISOLatin1StringEncoding]componentsSeparatedByString:@"\\"],true,true)];
            index+=16+vl+vl;
            break;
         }


#pragma mark UC
         case 0x4355:
         {
            //Unlimited Characters
            break;
         }

#pragma mark UI
         case 0x4955://UI
         {
            setMutabledataFromCuartetBuffer(buffer,index+16,index+16+vl+vl,md);
            NSRange zerorange=[md rangeOfData:zeroData options:NSDataSearchBackwards range:NSMakeRange(0,md.length)];
            //remove eventual padding 0x00
            while (zerorange.location != NSNotFound)
            {
               [md replaceBytesInRange:zerorange withBytes:NULL length:0];
               zerorange=[md rangeOfData:zeroData options:NSDataSearchBackwards range:NSMakeRange(0,zerorange.location)];
            }
            [dataset addChild:aArray(branch,chain,tag,vr, [[[NSString alloc]initWithData:md encoding:NSISOLatin1StringEncoding]componentsSeparatedByString:@"\\"],false,false)];
            index+=16+vl+vl;
            break;
         }

#pragma mark UR
         case 0x5255://UR
         {
            //Universal Resource Identifier or Universal Resource Locator (URI/URL)
            break;
         }

#pragma mark UT
         case 0x5455://UT
         {
            /*
             A character string that may contain one or more paragraphs. It may contain the Graphic Character set and the Control Characters, CR, LF, FF, and ESC. It may be padded with trailing spaces, which may be ignored, but leading spaces are considered to be significant. Data Elements with this VR shall not be multi-valued and therefore character code 5CH (the BACKSLASH "\" in ISO-IR 6) may be used.
             */
            vll = uint32FromCuartetBuffer(buffer,index+16);
            setMutabledataFromCuartetBuffer(buffer,index+24,index+24+vll+vll,md);
            [dataset addChild:aArray(
                                     branch,
                                     chain,
                                     tag,
                                     vr,
                                     @[[[NSString alloc]initWithData:md encoding:NSISOLatin1StringEncoding]],
                                     false,
                                     true
                                     )];
            index+=24+vll+vll;
            break;
         }
            
#pragma mark SQ
         case 0x5153://SQ
         {
            //SQ unknown length
            
            //SQ empty?
            uint32 nexttag=uint32FromCuartetBuffer(buffer,index+16);
            if (nexttag==0x0)
            {
               [dataset addChild:aArray(branch,chain,tag,vr,@[],false,false)];
               index+=16;
            }
            else if (nexttag!=0xffffffff) //SQ with defined length
            {
#pragma mark ERROR1: SQ defined length
               //logger(@"ERROR1: SQ with defined length. NOT IMPLEMENTED YET");
               setMutabledataFromCuartetBuffer(buffer,index,postbuffer,md);
               //logger(@"%@",md.description);
               exit(1);
            }
            else //SQ with feff0dde end tag
            {
               index+=24;
               nexttag=uint32FromCuartetBuffer(buffer,index);
               if (nexttag==0xe0ddfffe) [dataset addChild:aArray(branch,chain,tag,vr,@[],false,false)];//fffee0dd
               NSUInteger itemcounter=0;
               while (nexttag!=0xe0ddfffe)//not the end of the SQ
               {
                  itemcounter++;
                  NSString *newbranch=[branch stringByAppendingFormat:@".%lu",(unsigned long)itemcounter];
                  NSString *tagstring=[NSString stringWithFormat:@"%08x",uint32visual(tag)];
                  NSString *newchain=[NSString stringWithFormat:@"%@%@.",chain,tagstring];
                  
                  if (nexttag!=0xe000fffe) //fffee000 ERROR item without header
                  {
#pragma mark ERROR2: no item start
                     //logger(@"ERROR2: no item start");
                     setMutabledataFromCuartetBuffer(buffer,index,postbuffer,md);
                     //logger(@"%@",md.description);
                     exit(2);
                  }
                  else
                  {
                     uint32 itemlength=uint32FromCuartetBuffer(buffer,index+8);
                     if (itemlength==0)//empty item
                     {
                        [dataset addChild:aArray(newbranch,newchain,tag,vr,@[],false,false)];
                        index+=16;
                     }
                     else if (itemlength!=0xffffffff) //item with defined length
                     {
#pragma mark ERROR3: item defined length
                        //logger(@"ERROR3: item with defined length. NOT IMPLEMENTED YET");
                        setMutabledataFromCuartetBuffer(buffer,index,postbuffer,md);
                        //logger(@"%@",md.description);
                        exit(3);
                     }
                     else //undefined length item
                     {
#pragma mark recursion
                        index=parseAttrList(buffer,index,postbuffer,newchain,newbranch,dataset);
                        index+=16;
                        nexttag=uint32FromCuartetBuffer(buffer,index);
                     }
                  }
               }
               index+=16;
            }
            
            break;
         }

#pragma mark attribute UN
         case 0x4E55:
         {
            //Unknown
            break;
         }

#pragma mark attribute SL
         case 0x4C53:
         {
            //Signed Long
            break;
         }
            
#pragma mark attribute UL
         case 0x4C55:
         {
            //Unsigned Long
            break;
         }

            
#pragma mark attribute SS
         case 0x5353:
         {
            //Signed Short
            break;
         }
            
#pragma mark attribute US
         case 0x5355:
         {
            //Unsigned Short
            break;
         }

#pragma mark attribute SV
         case 0x5653:
         {
            //Signed 64-bit Very Long
            break;
         }

#pragma mark attribute UV
         case 0x5655:
         {
            //Unsigned 64-bit Very Long
            break;
         }

#pragma mark attribute FL
         case 0x4C46:
         {
            break;
         }
            
#pragma mark attribute FD
         case 0x4446:
         {
            break;
         }

#pragma mark attribute OB
         case 0x424F:
         {
            /*
             An octet-stream where the encoding of the contents is specified by the negotiated Transfer Syntax. OB is a VR that is insensitive to byte ordering (see Section 7.3). The octet-stream shall be padded with a single trailing NULL byte value (00H) when necessary to achieve even length.
             */
            break;
         }
            
#pragma mark attribute OD
         case 0x444F:
         {
            /*
             A stream of 64-bit IEEE 754:1985 floating point words. OD is a VR that requires byte swapping within each 64-bit word when changing byte ordering (see Section 7.3).
             */
            break;
         }
            
#pragma mark attribute OF
         case 0x464F:
         {
            /*
             A stream of 32-bit IEEE 754:1985 floating point words. OF is a VR that requires byte swapping within each 32-bit word when changing byte ordering (see Section 7.3).
             */
            break;
         }
            
#pragma mark attribute OL
         case 0x4C4F:
         {
            /*
             A stream of 32-bit words where the encoding of the contents is specified by the negotiated Transfer Syntax. OL is a VR that requires byte swapping within each word when changing byte ordering (see Section 7.3).
             */
            break;
         }
            
#pragma mark attribute OV
         case 0x564F:
         {
            /*
             A stream of 64-bit words where the encoding of the contents is specified by the negotiated Transfer Syntax. OV is a VR that requires byte swapping within each word when changing byte ordering (see Section 7.3).
             */
            break;
         }
            
#pragma mark attribute OW
         case 0x574F:
         {
            /*
             A stream of 16-bit words where the encoding of the contents is specified by the negotiated Transfer Syntax. OW is a VR that requires byte swapping within each word when changing byte ordering (see Section 7.3).
             */
            break;
         }
            

         default://ERROR unknow VR
         {
#pragma mark ERROR4: unknown VR
            //logger(@"vr: %d", vr);
            //logger(@"ERROR4: unknown VR");
            setMutabledataFromCuartetBuffer(buffer,index,postbuffer,md);
            //logger(@"%@",md.description);
            exit(4);
            
            break;
         }
      }
      tag = uint32FromCuartetBuffer(buffer,index);
   }
   return index;
}

#pragma mark -
int main(int argc, const char * argv[]) {
   @autoreleasepool {
      NSData *linedata=nil;//stdin (1 message only)
      zeroData=[NSData dataWithBytes:&zero length:1];
#pragma marks args
      //H2X [logfile [loglevel [testsampleline]]]
      //1 logfile default: /Volumes/LOG/H2P.log
      //2 loglevel [ DEBUG | VERBOSE | INFO | WARNING | ERROR | EXCEPTION] default: ERROR
      //3 testsampleline para testing desde IDE
      
      
      NSArray *args=[[NSProcessInfo processInfo] arguments];
      switch (args.count) {
         case 4:
            linedata=[args[3] dataUsingEncoding:NSUTF8StringEncoding];
            
         case 3:
#pragma mark loglevel
            ODLogLevel=(ODLogLevelEnum)[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:args[2]];

         case 2:
#pragma mark logfile
            if (
                   ![args[1] hasPrefix:@"/Users/Shared"]
                && ![args[1] hasPrefix:@"/Volumes/LOG"]
                )
            {
               NSLog(@"usage : H2P [logfile [loglevel [testsampleline]]]. Logfile should be in /Users/Shared or /Volumes/LOG");
               exit(0);
            }
            if ([args[1] hasSuffix:@".log"])
               freopen([args[1] cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
            else freopen([[args[1] stringByAppendingPathExtension:@".log"] cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
            break;

         case 1:
#pragma mark defaults
            //no arguments
            ODLogLevel=4;//ERROR
            freopen([@"/Users/Shared/H2P.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
            linedata = [[NSFileHandle fileHandleWithStandardInput] availableData];
            break;
            
         default:
            NSLog(@"usage : H2P [logfile [loglevel [testsampleline]]]");
            exit(0);
            break;
      }

      LOG_DEBUG(@"%@",[args description]);
      
#pragma mark in out
      if (linedata.length)
      {
         unsigned char* cuartets=(unsigned char*)[linedata bytes];
         
         NSXMLElement *dataset=[NSXMLElement elementWithName:@"dataset"];
         [dataset addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"xmldicom.xsd"]];
         [dataset addNamespace:[NSXMLNode namespaceWithName:@"xsi" stringValue:@"http://www.w3.org/2001/XMLSchema-instance"]];
         [dataset addAttribute:[NSXMLNode attributeWithName:@"xsi:schemaLocation" stringValue:@"xmldicom.xsd https://raw.githubusercontent.com/jacquesfauquex/DICOM_contextualizedKey-values/master/xml/xmldicom.xsd"]];
 
         NSUInteger index=parseAttrList(
                                        cuartets,
                                        0,
                                        linedata.length-1,
                                        @"",
                                        @"1",
                                        dataset
                                        );
         LOG_VERBOSE(@"index:%lu size:%lu",(unsigned long)index,linedata.length-1);
         
         NSXMLDocument *xmlDocument=[[NSXMLDocument alloc] initWithRootElement:dataset];
         [xmlDocument setCharacterEncoding:@"UTF-8"];
         [xmlDocument setVersion:@"1.1"];
         [[xmlDocument XMLData] writeToFile:@"/dev/stdout" atomically:NO];
      }
      else [[NSData data] writeToFile:@"/dev/stdout" atomically:NO];
   }//end autorelease pool
   return 0;
}
