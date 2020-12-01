#import <Foundation/Foundation.h>

#pragma mark - terminal execution
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
   if (terminationStatus!=0) NSLog(@"ERROR task terminationStatus: %d",terminationStatus);
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
    else*/ NSLog(@"%@",writeString);
   
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
   if (terminationStatus!=0) NSLog(@"ERROR task terminationStatus: %d",terminationStatus);
   return terminationStatus;
}

int bash(NSData *writeData, NSMutableData *readData)
{
   return task(@"/bin/bash",@[@"-s"], writeData, readData);
}

#pragma mark - mysql queries
NSData *dicomattrs4pk(long long pk)
{
   NSMutableData *dicomattrsdata=[NSMutableData data];
   NSDictionary *sqlpwdenv=@{@"MYSQL_PWD":@"ridi.SUY2014-pacs"};
   NSString *bashcmdstring=[NSString stringWithFormat:@"echo \"select HEX(attrs) from dicomattrs where pk=%lld\" |  /usr/local/mysql/bin/mysql -u root -h 10.200.120.19 --column-names=0 pacsdb",pk];
   //NSLog(@"%@",bashcmdstring);
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
      octet = (byte2cuartet[buffer[i+0]] << 4)
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
   unsigned char octet;
   NSMutableData *md = [NSMutableData data];//mutable data value itself
   while (tag!=fffee00d &&  index < postbuffer)
   {
      vr  = uint16FromCuartetBuffer(buffer,index+8);
      switch (vr) {
#pragma mark DA DT AS
         case 0x4144:
         case 0x4d54:
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
            NSLog(@"%@",headstrings.lastObject);
            
            //body
            setMutabledataFromCuartetBuffer(buffer,index+16,index+16+vl+vl,md);
            for (NSUInteger i=index+16; i<index+16+vl+vl; i+=2 )
            {
               octet = octetFromCuartetBuffer(buffer,i);
               [md appendBytes:&octet length:1];
            }
            [bodydatas addObject:[NSData dataWithData:md]];
            [bodystrings addObject:[[NSString alloc]initWithData:md encoding:NSISOLatin1StringEncoding]];
            index+=16+vl+vl;
            break;
         }
            
#pragma mark SH LO PN CS
         case 0x4853:
         case 0x4f4c:
         case 0x4e50:
         case 0x5343:
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
            NSLog(@"%@",headstrings.lastObject);
            
            //body
            setMutabledataFromCuartetBuffer(buffer,index+16,index+16+vl+vl,md);
            [bodydatas addObject:[NSData dataWithData:md]];
            
#pragma mark remove start and end spaces
            [bodystrings addObject:[[NSString alloc]initWithData:md encoding:NSISOLatin1StringEncoding]];
            index+=16+vl+vl;
            break;
         }
            
#pragma mark UI
         case 0x4955:
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
            NSLog(@"%@",headstrings.lastObject);
            
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
            
#pragma mark UT
         case 0x5455:
         {
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
            NSLog(@"%@",headstrings.lastObject);
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
               NSLog(@"%@",headstrings.lastObject);
               //NSLog(@"%@",headdatas.lastObject);
               
               [bodydatas addObject:[NSData data]];
               [bodystrings addObject:@""];
               
               index+=16;
            }
            else if (nexttag!=ffffffff) //SQ with defined length
            {
#pragma mark ERROR1
               NSLog(@"ERROR1: SQ with defined length. NOT IMPLEMENTED YET");
               setMutabledataFromCuartetBuffer(buffer,index,postbuffer,md);
               NSLog(@"%@",md.description);
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
               NSLog(@"%@",headstrings.lastObject);
               //NSLog(@"%@",headdatas.lastObject);
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
#pragma mark ERROR2
                     NSLog(@"ERROR2: no item start");
                     setMutabledataFromCuartetBuffer(buffer,index,postbuffer,md);
                     NSLog(@"%@",md.description);
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
                        NSLog(@"%@",headstrings.lastObject);
                        //NSLog(@"%@",headdatas.lastObject);
                        [bodydatas addObject:[NSData data]];
                        [bodystrings addObject:@""];
                        index+=16;
                     }
                     else if (itemlength!=ffffffff) //item with defined length
                     {
#pragma mark ERROR3
                        NSLog(@"ERROR3: item with defined length. NOT IMPLEMENTED YET");
                        setMutabledataFromCuartetBuffer(buffer,index,postbuffer,md);
                        NSLog(@"%@",md.description);
                        exit(3);
                     }
                     else //undefined length item
                     {
                        //item head
                        [headdatas addObject:[NSData dataWithBytes:&fffee000ffffffff length:8]];
                        [headstrings addObject:[NSString stringWithFormat:@"%@%@%@",basetag,tagstring,newbranch]];
                        NSLog(@"%@",headstrings.lastObject);
                        //NSLog(@"%@",headdatas.lastObject);
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
                        NSLog(@"%@",headstrings.lastObject);
                        //NSLog(@"%@",headdatas.lastObject);
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
               NSLog(@"%@",headstrings.lastObject);
               //NSLog(@"%@",headdatas.lastObject);
               [bodydatas addObject:[NSData data]];
               [bodystrings addObject:@""];
               index+=16;
            }
            
            break;
         }
            
            
         default://ERROR unknow VR
         {
#pragma mark ERROR4
            NSLog(@"vr: %d", vr);
            NSLog(@"ERROR4: unknown VR");
            setMutabledataFromCuartetBuffer(buffer,index,postbuffer,md);
            NSLog(@"%@",md.description);
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
      else
      {
         // read and update dicomattrs
         NSData *stdinData =[[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
         inputstring=[[NSString alloc]initWithData:stdinData encoding:NSUTF8StringEncoding];
      }
      NSArray *pksarray=[inputstring componentsSeparatedByString:@"\n"];
      NSLog(@"%@",pksarray.description);
      
      //get dicomattrs
      for (NSString *pk in pksarray)
      {
         NSLog(@"pk:%@",pk);
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
         NSLog(@"%@",headstrings);
         //NSLog(@"%@",headdatas.description);
         //NSLog(@"%@",bodystrings);
         //NSLog(@"%@",bodydatas.description);

      }
      
   }//end autorelease pool
   return 0;
}
