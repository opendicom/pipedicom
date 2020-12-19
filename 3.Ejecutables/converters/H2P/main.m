#import <Foundation/Foundation.h>
#import "utils.h"
#import "ODLog.h"

//H2P
//stdin string based dicom mysql hexa representation
//stdout data based plist with 4 arrays (headstrings,bodystrings,headdatas,bodydatas)

#pragma mark - cuartet parsing
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

static uint16 zerozero=0x0;
static uint32 zerozerozerozero=0x0;
static uint32 ffffffff=0xffffffff;

static uint32 fffee000=0xe000fffe;//start empty item
static uint64 fffee00000000000=0xe000fffe;//start empty item
static uint64 fffee000ffffffff=0xffffffffe000fffe;//start undefined item

static uint64 fffee00d=0xe00dfffe;//end item
static uint64 fffee00d00000000=0xe00dfffe;//end item

static uint32 fffee0dd=0xe0ddfffe;//end sq
static uint64 fffee0dd00000000=0xe0ddfffe;//end sq

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


NSUInteger parseAttrList(
                         unsigned char* buffer,
                         NSUInteger index,
                         NSUInteger postbuffer,
                         NSString *basetag,
                         NSString *branch,
                         NSMutableArray *headstrings,
                         NSMutableArray *headdatas,
                         NSMutableArray *bodystrings,
                         NSMutableArray *bodydatas
                         )
{
   UInt32 tag = uint32FromCuartetBuffer(buffer,index);
   UInt16 vr;//value representation
   UInt16 vl;//value length
   UInt32 vll;// 4 bytes value length
   NSMutableData *md = [NSMutableData data];//mutable data value itself
   while (tag!=fffee00d &&  index < postbuffer)
   {
      vr  = uint16FromCuartetBuffer(buffer,index+8);
      switch (vr) {
#pragma mark attribute AT
         case 0x5441:
         {
            break;
         }

#pragma mark DA AS (pair fixed width ISO-IR 6)
         case 0x4144:
         case 0x5341:
         {
            //head
            [md setLength:0];
            [md appendBytes:&tag length:4];
            [md appendBytes:&vr length:2];
            vl = uint16FromCuartetBuffer(buffer,index+12);
            [md appendBytes:&vl length:2];
            [headdatas addObject:[NSData dataWithData:md]];
            [headstrings addObject:[NSString stringWithFormat:@"%@%08x%@~%c%c",
                                    basetag,
                                    uint32visual(tag),
                                    branch,
                                    vr & 0xff,
                                    vr >> 8
                                    ]
             ];
            //logger(@"%@",headstrings.lastObject);
            
            //body
            setMutabledataFromCuartetBuffer(buffer,index+16,index+16+vl+vl,md);
            [bodydatas addObject:[NSData dataWithData:md]];
            [bodystrings addObject:[[NSString alloc]initWithData:md encoding:NSISOLatin1StringEncoding]];
            index+=16+vl+vl;
            break;
         }
            
#pragma mark TM (ISO-IR 6)
         case 0x4d54:
         {
            /*
             A string of characters of the format HHMMSS.FFFFFF; where HH contains hours (range "00" - "23"), MM contains minutes (range "00" - "59"), SS contains seconds (range "00" - "60"), and FFFFFF contains a fractional part of a second as small as 1 millionth of a second (range "000000" - "999999"). A 24-hour clock is used. Midnight shall be represented by only "0000" since "2400" would violate the hour range. The string may be padded with trailing spaces. Leading and embedded spaces are not allowed.
             
             One or more of the components MM, SS, or FFFFFF may be unspecified as long as every component to the right of an unspecified component is also unspecified, which indicates that the value is not precise to the precision of those unspecified components.
             
             The FFFFFF component, if present, shall contain 1 to 6 digits. If FFFFFF is unspecified the preceding "." shall not be included.
             
             Examples:
             
             "070907.0705 " represents a time of 7 hours, 9 minutes and 7.0705 seconds.
             
             "1010" represents a time of 10 hours, and 10 minutes.
             
             "021 " is an invalid value.
             
             Note
             The ACR-NEMA Standard 300 (predecessor to DICOM) supported a string of characters of the format HH:MM:SS.frac for this VR. Use of this format is not compliant.
             
             See also DT VR in this table.
             
             The SS component may have a value of 60 only for a leap second.
             */
            //head
            [md setLength:0];
            [md appendBytes:&tag length:4];
            [md appendBytes:&vr length:2];
            vl = uint16FromCuartetBuffer(buffer,index+12);
            [md appendBytes:&vl length:2];
            [headdatas addObject:[NSData dataWithData:md]];
            [headstrings addObject:[NSString stringWithFormat:@"%@%08x%@~%c%c",
                                    basetag,
                                    uint32visual(tag),
                                    branch,
                                    vr & 0xff,
                                    vr >> 8
                                    ]
             ];
            //logger(@"%@",headstrings.lastObject);
            
            //body
            setMutabledataFromCuartetBuffer(buffer,index+16,index+16+vl+vl,md);
            [bodydatas addObject:[NSData dataWithData:md]];
            [bodystrings addObject:[[NSString alloc]initWithData:md encoding:NSISOLatin1StringEncoding]];
            index+=16+vl+vl;
            break;         }

#pragma mark DT (datetime ISO-IR 6)
         case 0x5444:
         {
            break;
         }

#pragma mark CS DS IS AE (ISO-IR 6 <16 trim first and last spaces)
         case 0x5343:
         case 0x5344:
         case 0x5349:
         case 0x4541:
         {
            //body string without start and end spaces
            //head
            [md setLength:0];
            [md appendBytes:&tag length:4];
            [md appendBytes:&vr length:2];
            vl = uint16FromCuartetBuffer(buffer,index+12);
            [md appendBytes:&vl length:2];
            [headdatas addObject:[NSData dataWithData:md]];
            
            [headstrings addObject:[NSString stringWithFormat:@"%@%08x%@~%c%c",
                                    basetag,
                                    uint32visual(tag),
                                    branch,
                                    vr & 0xff,
                                    vr >> 8
                                    ]
             ];
            setMutabledataFromCuartetBuffer(buffer,index+16,index+16+vl+vl,md);
            [bodydatas addObject:[NSData dataWithData:md]];
            NSMutableString *mutableString=[[NSMutableString alloc]initWithData:md encoding:NSASCIIStringEncoding];
            trimLeadingAndTrailingSpaces(mutableString);
            [bodystrings addObject:mutableString];
            index+=16+vl+vl;
            break;
         }

         
#pragma mark SH LO PN LT ST
         case 0x4853:
         case 0x4f4c:
         case 0x4e50:
         case 0x544c:
         case 0x5453:
         {
            //body string without start and end spaces
            //head
            [md setLength:0];
            [md appendBytes:&tag length:4];
            [md appendBytes:&vr length:2];
            vl = uint16FromCuartetBuffer(buffer,index+12);
            [md appendBytes:&vl length:2];
            [headdatas addObject:[NSData dataWithData:md]];
            
            [headstrings addObject:[NSString stringWithFormat:@"%@%08x%@~%c%c",
                                    basetag,
                                    uint32visual(tag),
                                    branch,
                                    vr & 0xff,
                                    vr >> 8
                                    ]
             ];
            setMutabledataFromCuartetBuffer(buffer,index+16,index+16+vl+vl,md);
            [bodydatas addObject:[NSData dataWithData:md]];
            
#pragma mark remove start and end spaces
            [bodystrings addObject:[[NSString alloc]initWithData:md encoding:NSISOLatin1StringEncoding]];
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
         case 0x4955:
         {
            //Unique Identifier (UID)
            //head
            [md setLength:0];
            [md appendBytes:&tag length:4];
            [md appendBytes:&vr length:2];
            vl = uint16FromCuartetBuffer(buffer,index+12);
            [md appendBytes:&vl length:2];
            [headdatas addObject:[NSData dataWithData:md]];
            
            [headstrings addObject:[NSString stringWithFormat:@"%@%08x%@~%c%c",
                                    basetag,
                                    uint32visual(tag),
                                    branch,
                                    vr & 0xff,
                                    vr >> 8
                                    ]
             ];
            //logger(@"%@",headstrings.lastObject);
            
            //body
            setMutabledataFromCuartetBuffer(buffer,index+16,index+16+vl+vl,md);
            [bodydatas addObject:[NSData dataWithData:md]];
            
            //remove eventual last  zero
            uint8 lastByte;
            [md getBytes:&lastByte range:NSMakeRange(md.length -1,1)];
            if (lastByte==0)
               
               [bodystrings addObject:[[NSString alloc]initWithData:[md subdataWithRange:NSMakeRange(0,md.length -1)] encoding:NSISOLatin1StringEncoding]];
            else
               [bodystrings addObject:[[NSString alloc]initWithData:md  encoding:NSISOLatin1StringEncoding]];
            
            index+=16+vl+vl;
            break;
         }

#pragma mark UR
         case 0x5255:
         {
            //Universal Resource Identifier or Universal Resource Locator (URI/URL)
            break;
         }

#pragma mark UT
         case 0x5455:
         {
            /*
             A character string that may contain one or more paragraphs. It may contain the Graphic Character set and the Control Characters, CR, LF, FF, and ESC. It may be padded with trailing spaces, which may be ignored, but leading spaces are considered to be significant. Data Elements with this VR shall not be multi-valued and therefore character code 5CH (the BACKSLASH "\" in ISO-IR 6) may be used.
             */
            //head
            [md setLength:0];
            [md appendBytes:&tag length:4];
            [md appendBytes:&vr length:2];
            [md appendBytes:&zerozero length:2];
            vll = uint32FromCuartetBuffer(buffer,index+16);
            [md appendBytes:&vll length:4];
            [headdatas addObject:[NSData dataWithData:md]];
            
            [headstrings addObject:[NSString stringWithFormat:@"%@%08x%@~%c%c",
                                    basetag,
                                    uint32visual(tag),
                                    branch,
                                    vr & 0xff,
                                    vr >> 8
                                    ]
             ];
            
            //body
          setMutabledataFromCuartetBuffer(buffer,index+24,index+24+vll+vll,md);
            //logger(@"%@",headstrings.lastObject);
            [bodydatas addObject:[NSData dataWithData:md]];
            [bodystrings addObject:[[NSString alloc]initWithData:md  encoding:NSISOLatin1StringEncoding]];
            index+=24+vll+vll;
            break;
         }
            
#pragma mark SQ
         case 0x5153:
         {
            //SQ unknown length
            
            //SQ empty?
            uint32 nexttag=uint32FromCuartetBuffer(buffer,index+16);
            if (nexttag==zerozerozerozero)
            {
               //empty sequence without end tag
               [md setLength:0];
               [md appendBytes:&tag length:4];
               [md appendBytes:&vr length:2];
               [md appendBytes:&zerozero length:2];
               [md appendBytes:&zerozerozerozero length:4];
               [headdatas addObject:[NSData dataWithData:md]];
               [headstrings addObject:[NSString stringWithFormat:@"%@%08x%@",
                                       basetag,
                                       uint32visual(tag),
                                       branch.length?[branch stringByAppendingPathExtension:@"0"]:@"#0"
                                       ]
                ];
               //logger(@"%@",headstrings.lastObject);
               //logger(@"%@",headdatas.lastObject);
               
               [bodydatas addObject:[NSData data]];
               [bodystrings addObject:@""];
               
               index+=16;
            }
            else if (nexttag!=ffffffff) //SQ with defined length
            {
#pragma mark ERROR1: SQ defined length
               //logger(@"ERROR1: SQ with defined length. NOT IMPLEMENTED YET");
               setMutabledataFromCuartetBuffer(buffer,index,postbuffer,md);
               //logger(@"%@",md.description);
               exit(1);
            }
            else //SQ with feff0dde end tag
            {
               //SQ head & body
               [md setLength:0];
               [md appendBytes:&tag length:4];
               [md appendBytes:&vr length:2];
               [md appendBytes:&zerozero length:2];
               [md appendBytes:&ffffffff length:4];
               [headdatas addObject:[NSData dataWithData:md]];
               [headstrings addObject:[NSString stringWithFormat:@"%@%08x%@#",
                                       basetag,
                                       uint32visual(tag),
                                       branch
                                       ]
                ];
               //logger(@"%@",headstrings.lastObject);
               //logger(@"%@",headdatas.lastObject);
               [bodydatas addObject:[NSData data]];
               [bodystrings addObject:@""];
               
               index+=24;
               nexttag=uint32FromCuartetBuffer(buffer,index);
               NSUInteger itemcounter=0;
               
               
               while (nexttag!=fffee0dd)//not the end of the SQ
               {
                  itemcounter++;
                  
                  //newbasetag
                  NSString *tagstring=[NSString stringWithFormat:@"%08x",uint32visual(tag)];
                  NSString *newbasetag=[NSString stringWithFormat:@"%@%@.",basetag,tagstring];
                  
                  //newbranch
                  NSString *newbranch=nil;
                  if (branch.length)newbranch=[branch stringByAppendingFormat:@".%lu",(unsigned long)itemcounter];
                  else  newbranch=[NSString stringWithFormat:@"#%lu",(unsigned long)itemcounter];
                  
                  if (nexttag!=fffee000) //ERROR item without header
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
                        //empty sequence without end tag
                        [headdatas addObject:[NSData dataWithBytes:&fffee00000000000 length:8]];
                        [headstrings addObject:[newbasetag stringByAppendingString:newbranch]];
                        //logger(@"%@",headstrings.lastObject);
                        //logger(@"%@",headdatas.lastObject);
                        [bodydatas addObject:[NSData data]];
                        [bodystrings addObject:@""];
                        index+=16;
                     }
                     else if (itemlength!=ffffffff) //item with defined length
                     {
#pragma mark ERROR3: item defined length
                        //logger(@"ERROR3: item with defined length. NOT IMPLEMENTED YET");
                        setMutabledataFromCuartetBuffer(buffer,index,postbuffer,md);
                        //logger(@"%@",md.description);
                        exit(3);
                     }
                     else //undefined length item
                     {
                        //item head
                        [headdatas addObject:[NSData dataWithBytes:&fffee000ffffffff length:8]];
                        [headstrings addObject:[NSString stringWithFormat:@"%@%@%@",basetag,tagstring,newbranch]];
                        //logger(@"%@",headstrings.lastObject);
                        //logger(@"%@",headdatas.lastObject);
                        [bodydatas addObject:[NSData data]];
                        [bodystrings addObject:@""];
                        
                        index+=16;
                        
                        index=parseAttrList(
                                            buffer,
                                            index,
                                            postbuffer,
                                            newbasetag,
                                            newbranch,
                                            headstrings,
                                            headdatas,
                                            bodystrings,
                                            bodydatas
                                            );
                        
                        [headdatas addObject:[NSData dataWithBytes:&fffee00d00000000 length:8]];
                        [headstrings addObject:
                         [NSString stringWithFormat:
                          @"%@fffee00d%@",
                          newbasetag,
                          newbranch
                          ]
                         ];
                        //logger(@"%@",headstrings.lastObject);
                        //logger(@"%@",headdatas.lastObject);
                        [bodydatas addObject:[NSData data]];
                        [bodystrings addObject:@""];
                        index+=16;
                        nexttag=uint32FromCuartetBuffer(buffer,index);
                     }
                  }
               }
               //SQ end (nextitem==feff0dde)   $branch.Z
               [md setLength:0];
               [md appendBytes:&fffee0dd00000000 length:8];
               [headdatas addObject:[NSData dataWithData:md]];
               [headstrings addObject:
                [NSString stringWithFormat:
                 @"%@%08x.fffee0dd%@",
                 basetag,
                 uint32visual(tag),
                 branch
                 ]
                ];
               //logger(@"%@",headstrings.lastObject);
               //logger(@"%@",headdatas.lastObject);
               [bodydatas addObject:[NSData data]];
               [bodystrings addObject:@""];
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
      
      NSProcessInfo *processInfo=[NSProcessInfo processInfo];
      
#pragma marks environment

      NSDictionary *environment=processInfo.environment;
      
      //H2PlogLevel
      if (environment[@"H2PlogLevel"])
      {
         NSUInteger logLevel=[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:environment[@"H2PlogLevel"]];
         if (logLevel!=NSNotFound) ODLogLevel=(ODLogLevelEnum)logLevel;
         else ODLogLevel=4;//ERROR (default)
      }
      else ODLogLevel=4;//ERROR (default)
      
      
      //H2PlogPath
      NSString *logPath=environment[@"H2PlogPath"];
      if (logPath && ([logPath hasPrefix:@"/Users/Shared"] || [logPath hasPrefix:@"/Volumes/LOG"]))
      {
         if ([logPath hasSuffix:@".log"])
            freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
         else freopen([[logPath stringByAppendingPathExtension:@".log"] cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      }
      else freopen([@"/Users/Shared/H2P.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      

      //H2PtestPath
      NSData *linedata=nil;
      NSString *testPath=environment[@"H2PtestPath"];
      if (testPath) linedata=[NSData dataWithContentsOfFile:testPath];
      else linedata = [[NSFileHandle fileHandleWithStandardInput] availableData];
      
      
      LOG_DEBUG(@"%@",[environment description]);


#pragma marks args
      //H2P

      
#pragma mark stdin
      if (linedata.length)
      {
         unsigned char* cuartets=(unsigned char*)[linedata bytes];
         NSMutableArray *headstrings=[NSMutableArray array];
         NSMutableArray *headdatas=[NSMutableArray array];
         NSMutableArray *bodystrings=[NSMutableArray array];
         NSMutableArray *bodydatas=[NSMutableArray array];
         NSUInteger index=parseAttrList(
                                        cuartets,
                                        0,
                                        linedata.length-1,
                                        @"",
                                        @"",
                                        headstrings,
                                        headdatas,
                                        bodystrings,
                                        bodydatas
                                        );
         LOG_VERBOSE(@"index:%lu size:%lu",(unsigned long)index,linedata.length-1);
         LOG_DEBUG(@"headstrings: %@",headstrings.description);
         //logger(@"%@",headdatas.description);
         //logger(@"%@",bodystrings);
         //logger(@"%@",bodydatas.description);

         
   #pragma mark stdout
         [
          [
          NSPropertyListSerialization
          dataWithPropertyList:@[
                                 headstrings,
                                 bodystrings,
                                 headdatas,
                                 bodydatas
                                 ]
          format:NSPropertyListBinaryFormat_v1_0
          options:0
          error:&error
          ]
          writeToFile:@"/dev/stdout"
          atomically:NO
          ];
      }
      else
      {
         [
          [
          NSPropertyListSerialization
          dataWithPropertyList:@[@[],@[],@[],@[]]
          format:NSPropertyListBinaryFormat_v1_0
          options:0
          error:&error
          ]
          writeToFile:@"/dev/stdout"
          atomically:NO
          ];
         // NSPropertyListBinaryFormat_v1_0
         // NSPropertyListXMLFormat_v1_0

      }
   }//end autorelease pool
   return 0;
}
