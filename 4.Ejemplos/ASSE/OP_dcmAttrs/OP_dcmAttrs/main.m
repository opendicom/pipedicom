#import <Foundation/Foundation.h>

#pragma mark - terminal execution

/*
void ERLog(NSString *format, ...)
{
   
   va_list args;
   va_start(args, format);
   [[[NSString alloc] initWithFormat:format arguments:args] writeToFile:@"/Users/Shared/e_dcmAttrs.log" atomically:false encoding:NSUTF8StringEncoding error:nil];
   va_end(args);
    
}
*/

int execTask(NSDictionary *environment, NSString *launchPath, NSArray *launchArgs, NSData *writeData, NSMutableData *readData)
{
   NSTask *task=[[NSTask alloc]init];
   
   task.environment=environment;
   
   [task setLaunchPath:launchPath];
   [task setArguments:launchArgs];
   NSPipe *writePipe = [NSPipe pipe];
   NSFileHandle *writeHandle = [writePipe fileHandleForWriting];
   [task setStandardInput:writePipe];
   
   NSPipe* readPipe = [NSPipe pipe];
   NSFileHandle *readingFileHandle=[readPipe fileHandleForReading];
   [task setStandardOutput:readPipe];
   [task setStandardError:readPipe];
   
   [task launch];
   [writeHandle writeData:writeData];
   [writeHandle closeFile];
   
   NSData *dataPiped = nil;
   while((dataPiped = [readingFileHandle availableData]) && [dataPiped length])
   {
      [readData appendData:dataPiped];
   }
   //while( [task isRunning]) [NSThread sleepForTimeInterval: 0.1];
   //[task waitUntilExit];      // <- This is VERY DANGEROUS : the main runloop is continuing...
   //[aTask interrupt];
   
   [task waitUntilExit];
   int terminationStatus = [task terminationStatus];
   if (terminationStatus!=0) exit(terminationStatus);//ERLog(@"ERROR task terminationStatus: %d",terminationStatus);
   return terminationStatus;
}

int execUTF8Bash(NSDictionary *environment, NSString *writeString, NSMutableData *readData)
{
   /*NSArray *whereSeparated=[writeString componentsSeparatedByString:@"WHERE"];
    
    if  (whereSeparated.count==2)
    {
    NSString *sqlOnly=[whereSeparated [1] componentsSeparatedByString:@"\"|"][0];
    NSRange firstBackSlashOffset=[sqlOnly rangeOfString:@"\\"];
    LOG_VERBOSE(@"%@",[sqlOnly substringFromIndex:firstBackSlashOffset.location + 2]);
    }
    else*/ //ERLog(@"%@",writeString);
   
   return execTask(environment, @"/bin/bash",@[@"-s"], [writeString dataUsingEncoding:NSUTF8StringEncoding], readData);
}


int task(NSString *launchPath, NSArray *launchArgs, NSData *writeData, NSMutableData *readData)
{
   NSTask *task=[[NSTask alloc]init];
   [task setLaunchPath:launchPath];
   [task setArguments:launchArgs];
   //LOG_INFO(@"%@",[task arguments]);
   NSPipe *writePipe = [NSPipe pipe];
   NSFileHandle *writeHandle = [writePipe fileHandleForWriting];
   [task setStandardInput:writePipe];
   
   NSPipe* readPipe = [NSPipe pipe];
   NSFileHandle *readingFileHandle=[readPipe fileHandleForReading];
   [task setStandardOutput:readPipe];
   [task setStandardError:readPipe];
   
   [task launch];
   [writeHandle writeData:writeData];
   [writeHandle closeFile];
   
   NSData *dataPiped = nil;
   while((dataPiped = [readingFileHandle availableData]) && [dataPiped length])
   {
      [readData appendData:dataPiped];
   }
   //while( [task isRunning]) [NSThread sleepForTimeInterval: 0.1];
   //[task waitUntilExit];      // <- This is VERY DANGEROUS : the main runloop is continuing...
   //[aTask interrupt];
   
   [task waitUntilExit];
   int terminationStatus = [task terminationStatus];
   if (terminationStatus!=0) exit(terminationStatus); //ERLog(@"ERROR task terminationStatus: %d",terminationStatus);
   return terminationStatus;
}

int bash(NSData *writeData, NSMutableData *readData)
{
   return task(@"/bin/bash",@[@"-s"], writeData, readData);
}
/*
int writeToFile(NSString *filepath, NSArray *headdatas, NSArray *bodydatas)
{
   NSMutableData *outputdata=[NSMutableData data];
   for (NSUInteger i=0; i<headdatas.count;i++)
   {
      [outputdata appendData:headdatas[i]];
      //ERLog(@"%@",[headdatas[i] description]);
      [outputdata appendData:bodydatas[i]];
      //ERLog(@"         %@",[bodydatas[i] description]);
   }
   [outputdata writeToFile:filepath atomically:NO];
   return 0;
}
*/

int stream4arrays(NSArray *headstrings, NSArray *bodystrings, NSArray *headdatas, NSArray *bodydatas)
{
   NSError *error;//dataWithPropertyList:format:options:error:
   NSData *data =
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
    ];
   [data writeToFile:@"/dev/stdout" atomically:NO];
   //[[NSFileHandle fileHandleWithStandardOutput]writeData:data];
   return 0;
}

#pragma mark - string functions

NSString *trimLeadingAndTrailingSpaces(NSString *inputString)
{
   NSMutableString *mutableString=[NSMutableString stringWithString:inputString];
   while ([mutableString hasPrefix:@" "])
   {
      [mutableString deleteCharactersInRange:NSMakeRange(0,1)];
   }
   while ([mutableString hasSuffix:@" "])
   {
      [mutableString deleteCharactersInRange:NSMakeRange(mutableString.length-1,1)];
   }
   return [NSString stringWithString:mutableString];
}
#pragma mark - mysql queries
NSData *dicomattrs4pk(long long pk)
{
   NSMutableData *dicomattrsdata=[NSMutableData data];
   NSDictionary *sqlpwdenv=@{@"MYSQL_PWD":@"ridi.SUY2014-pacs"};
   NSString *bashcmdstring=[NSString stringWithFormat:@"echo \"select HEX(attrs) from dicomattrs where pk=%lld\" |  /usr/local/mysql/bin/mysql -u root -h 10.200.120.19 --column-names=0 pacsdb",pk];
   //ERLog(@"%@",bashcmdstring);
   NSData *bashcmddata=[bashcmdstring dataUsingEncoding:NSUTF8StringEncoding];
   if (!execTask(sqlpwdenv, @"/bin/bash", @[@"-s"], bashcmddata, dicomattrsdata)) return [NSData dataWithData:dicomattrsdata];
   return nil;
}

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
            //ERLog(@"%@",headstrings.lastObject);
            
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
            //ERLog(@"%@",headstrings.lastObject);
            
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
            
            [bodystrings addObject:
             trimLeadingAndTrailingSpaces([[NSString alloc]initWithData:md encoding:NSASCIIStringEncoding])
             ];
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
            //ERLog(@"%@",headstrings.lastObject);
            
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
            //ERLog(@"%@",headstrings.lastObject);
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
               //ERLog(@"%@",headstrings.lastObject);
               //ERLog(@"%@",headdatas.lastObject);
               
               [bodydatas addObject:[NSData data]];
               [bodystrings addObject:@""];
               
               index+=16;
            }
            else if (nexttag!=ffffffff) //SQ with defined length
            {
#pragma mark ERROR1: SQ defined length
               //ERLog(@"ERROR1: SQ with defined length. NOT IMPLEMENTED YET");
               setMutabledataFromCuartetBuffer(buffer,index,postbuffer,md);
               //ERLog(@"%@",md.description);
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
               //ERLog(@"%@",headstrings.lastObject);
               //ERLog(@"%@",headdatas.lastObject);
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
                     //ERLog(@"ERROR2: no item start");
                     setMutabledataFromCuartetBuffer(buffer,index,postbuffer,md);
                     //ERLog(@"%@",md.description);
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
                        //ERLog(@"%@",headstrings.lastObject);
                        //ERLog(@"%@",headdatas.lastObject);
                        [bodydatas addObject:[NSData data]];
                        [bodystrings addObject:@""];
                        index+=16;
                     }
                     else if (itemlength!=ffffffff) //item with defined length
                     {
#pragma mark ERROR3: item defined length
                        //ERLog(@"ERROR3: item with defined length. NOT IMPLEMENTED YET");
                        setMutabledataFromCuartetBuffer(buffer,index,postbuffer,md);
                        //ERLog(@"%@",md.description);
                        exit(3);
                     }
                     else //undefined length item
                     {
                        //item head
                        [headdatas addObject:[NSData dataWithBytes:&fffee000ffffffff length:8]];
                        [headstrings addObject:[NSString stringWithFormat:@"%@%@%@",basetag,tagstring,newbranch]];
                        //ERLog(@"%@",headstrings.lastObject);
                        //ERLog(@"%@",headdatas.lastObject);
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
                        //ERLog(@"%@",headstrings.lastObject);
                        //ERLog(@"%@",headdatas.lastObject);
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
               //ERLog(@"%@",headstrings.lastObject);
               //ERLog(@"%@",headdatas.lastObject);
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
            //ERLog(@"vr: %d", vr);
            //ERLog(@"ERROR4: unknown VR");
            setMutabledataFromCuartetBuffer(buffer,index,postbuffer,md);
            //ERLog(@"%@",md.description);
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
      
      
      NSString *inputstring;
      NSArray *args=[[NSProcessInfo processInfo] arguments];
      if (args.count>1) inputstring=args[1];
      else inputstring = [[[NSString alloc] initWithData:[[NSFileHandle fileHandleWithStandardInput] availableData] encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];

      NSArray *pksarray=[inputstring componentsSeparatedByString:@"\n"];
      //ERLog(@"%@",pksarray.description);
      
      //get dicomattrs
      for (NSString *pk in pksarray)
      {
         //ERLog(@"--------------");
         //ERLog(@"pk:%@",pk);
#pragma mark loop for each pk parse dicom attrs
         NSData *dicomattrs=dicomattrs4pk([pk longLongValue]);
         unsigned char* cuartets=(unsigned char*)[dicomattrs bytes];
         NSMutableArray *headstrings=[NSMutableArray array];
         NSMutableArray *headdatas=[NSMutableArray array];
         NSMutableArray *bodystrings=[NSMutableArray array];//corresponding data
         NSMutableArray *bodydatas=[NSMutableArray array];
         NSUInteger index=parseAttrList(
                                        cuartets,
                                        0,
                                        dicomattrs.length-1,
                                        @"",
                                        @"",
                                        headstrings,
                                        headdatas,
                                        bodystrings,
                                        bodydatas
                                        );
         //ERLog(@"%@",headstrings);
         //ERLog(@"%@",headdatas.description);
         //ERLog(@"%@",bodystrings);
         //ERLog(@"%@",bodydatas.description);

         BOOL modify=false;
#pragma mark find attr 00080080~LO (institution)
         NSUInteger institutionindex=[headstrings indexOfObject:@"00080080~LO"];
         if (institutionindex!=NSNotFound)
         {
            //ERLog(@" '%@' %@",
            //      bodystrings[institutionindex],
            //      bodydatas[institutionindex]
            //      );
            if ([bodystrings[institutionindex] isEqualToString:@"Documents "])
            {
               modify=true;
               [bodystrings replaceObjectAtIndex:institutionindex withObject:@"HPediatrico"];
               NSData *HPediatricodata=[@"HPediatrico " dataUsingEncoding:NSISOLatin1StringEncoding];
               [bodydatas replaceObjectAtIndex:institutionindex withObject:HPediatricodata];
               //ERLog(@"='%@' %@",
               //      bodystrings[institutionindex],
               //      bodydatas[institutionindex]
               //      );

               NSMutableData *institutionheaddata=[NSMutableData dataWithData:headdatas[institutionindex]];
               uint16 HPediatricolength=HPediatricodata.length;
               [institutionheaddata replaceBytesInRange:NSMakeRange(6,2) withBytes:&HPediatricolength];
               [headdatas replaceObjectAtIndex:institutionindex withObject:institutionheaddata];
               //ERLog(@"%@ %@",headstrings[institutionindex],headdatas[institutionindex]);
            }
         }
         
#pragma mark find attr 00081060~PN (reporting)
         NSUInteger reportingindex=[headstrings indexOfObject:@"00081060~PN"];
         if (reportingindex!=NSNotFound)
         {
            //ERLog(@" '%@' %@",
            //      bodystrings[reportingindex],
            //      [bodydatas[reportingindex] description]
            //      );
            if ([bodystrings[reportingindex] isEqualToString:@"Documents^^-"])
            {
               modify=true;
               [bodystrings replaceObjectAtIndex:reportingindex withObject:@"HPediatrico^^-"];
               NSData *HPediatricodata=[@"HPediatrico^^-" dataUsingEncoding:NSISOLatin1StringEncoding];
               [bodydatas replaceObjectAtIndex:reportingindex withObject:HPediatricodata];
              
               NSMutableData *reportingheaddata=[NSMutableData dataWithData:headdatas[reportingindex]];
               uint16 HPediatricolength=HPediatricodata.length;
               [reportingheaddata replaceBytesInRange:NSMakeRange(6,2) withBytes:&HPediatricolength];
               [headdatas replaceObjectAtIndex:reportingindex withObject:reportingheaddata];
               //ERLog(@"%@ %@",headstrings[reportingindex],headdatas[reportingindex]);
            }
         }
         
#pragma mark output
         stream4arrays(headstrings, bodystrings, headdatas, bodydatas);
         /*
         if (modify) writeToFile([[@"/Users/Shared/dicomattrs" stringByAppendingPathComponent:pk]stringByAppendingPathExtension:@"dcm"], headdatas, bodydatas);
          */
      }
      
   }//end autorelease pool
   return 0;
}
