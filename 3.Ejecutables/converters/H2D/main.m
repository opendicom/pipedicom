#import <Foundation/Foundation.h>
#import "ODLog.h"

//H2D
//stdin string based dicom mysql hexa representation
//stdout binary dicom

#pragma mark - static
static uint64 fffee00000000000=0xe000fffe;//start empty item
static uint64 fffee000ffffffff=0xffffffffe000fffe;//start undefined item
static uint64 fffee00d00000000=0xe00dfffe;//end item
static uint64 fffee0dd00000000=0xe0ddfffe;//end sq


#pragma mark - cuartets

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


#pragma mark -

NSUInteger parseAttrList(
                         unsigned char* buffer,
                         NSUInteger index,
                         NSUInteger postBuffer,
                         NSMutableData *D
                         )
{
   UInt32 tag = uint32FromCuartetBuffer(buffer,index);
   UInt16 vr;//value representation
   UInt16 vl;//value length
   UInt32 vll;// 4 bytes value length
   NSMutableData *md = [NSMutableData data];//mutable data value itself

   while (tag!=0xe00dfffe &&  index < postBuffer) //fffee00d=itemEnd
   {
      [D appendBytes:&tag length:4];
      vr = uint16FromCuartetBuffer(buffer,index+8);
      [D appendBytes:&vr length:2];
      vl = uint16FromCuartetBuffer(buffer,index+12);
      [D appendBytes:&vl length:2];
      switch (vr) {
            

#pragma mark vl
         case 0x4144://DA
         case 0x5341://AS
         case 0x4541://AE
         case 0x5441://AT
         case 0x5343://CS
         case 0x5344://DS
         case 0x5444://DT
         case 0x5349://IS
         case 0x4f4c://LO
         case 0x544c://LT
         case 0x4e50://PN
         case 0x4853://SH
         case 0x5453://ST
         case 0x4d54://TM
         case 0x4955://UI
         case 0x4C53://SL
         case 0x4C55://UL
         case 0x5353://SS
         case 0x5355://US
         case 0x4C46://FL
         case 0x4446://FD
         {
            [md setLength:0];
            setMutabledataFromCuartetBuffer(buffer,index+16,index+16+vl+vl,md);
            [D appendData:md];
            index+=16+vl+vl;
            break;
         }


#pragma mark vll
         case 0x4355:
         /*
          Unlimited Characters
         */
         case 0x5255://UR
         /*
          Universal Resource Identifier or Universal Resource Locator (URI/URL)
         */
         case 0x5455://UT
         case 0x5653://SV
         case 0x5655://UV
         case 0x4E55://UN
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
         {
            
            vll = uint32FromCuartetBuffer(buffer,index+16);
            [D appendBytes:&vll length:4];
            [md setLength:0];
            setMutabledataFromCuartetBuffer(buffer,index+24,index+24+vll+vll,md);
            [D appendData:md];
            index+=24+vll+vll;
            break;
             
         }
            
#pragma mark SQ
         case 0x5153://SQ
         {
            vll=uint32FromCuartetBuffer(buffer,index+16);
            [D appendBytes:&vll length:4];
            index+=24;

            //SQ empty?
            if (vll==0x0)
            {
               //nothing to do
            }
            else if (vll!=0xffffffff) //SQ with defined length
            {
#pragma mark ERROR1: SQ defined length
               //LOG_ERROR(@"ERROR1: SQ with defined length. NOT IMPLEMENTED YET");
               exit(1);
            }
            else //SQ with feff0dde end tag
            {
               uint32 nexttag=uint32FromCuartetBuffer(buffer,index);
               while (nexttag!=0xe0ddfffe)//not the end of the SQ
               {
                    uint32 itemlength=uint32FromCuartetBuffer(buffer,index+8);
                     if (itemlength==0)//empty item
                     {
                        [D appendBytes:&fffee00000000000 length:8];//item empty
                        index+=16;
                     }
                     else if (itemlength!=0xffffffff) //item with defined length
                     {
#pragma mark ERROR3: item defined length
                        LOG_ERROR(@"ERROR3: item with defined length. NOT IMPLEMENTED YET");
                        exit(3);
                     }
                     else //undefined length item
                     {
                        [D appendBytes:&fffee000ffffffff length:8];//item empty
                        index+=16;

#pragma mark recursion
                        index=parseAttrList(buffer,index,postBuffer,D);

                        [D appendBytes:&fffee00d00000000 length:8];//item empty
                        index+=16;

                        nexttag=uint32FromCuartetBuffer(buffer,index);
                     }
               }
               
               [D appendBytes:&fffee0dd00000000 length:8];//item empty
               index+=16;
            }
            
            break;
         }


         default://ERROR unknow VR
         {
#pragma mark ERROR4: unknown VR
            //logger(@"vr: %d", vr);
            //logger(@"ERROR4: unknown VR");
            setMutabledataFromCuartetBuffer(buffer,index,postBuffer,md);
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
      
      //H2DlogLevel
      if (environment[@"H2DlogLevel"])
      {
         NSUInteger logLevel=[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:environment[@"H2DlogLevel"]];
         if (logLevel!=NSNotFound) ODLogLevel=(ODLogLevelEnum)logLevel;
         else ODLogLevel=4;//ERROR (default)
      }
      else ODLogLevel=4;//ERROR (default)
      
      
      //H2DlogPath
      NSString *logPath=environment[@"H2DlogPath"];
      if (logPath && ([logPath hasPrefix:@"/Users/Shared"] || [logPath hasPrefix:@"/Volumes/LOG"]))
      {
         if ([logPath hasSuffix:@".log"])
            freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
         else freopen([[logPath stringByAppendingPathExtension:@".log"] cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      }
      else freopen([@"/Users/Shared/H2D.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      

      //H2Doutput
      NSString *H2Doutput=environment[@"H2Doutput"];
      if (!H2Doutput) H2Doutput=@"/dev/stdout";

      //H2DtestPath
      NSData *dataset=nil;//dataset is NOT part 10 file with preamble
      NSString *testPath=environment[@"H2DtestPath"];
      if (testPath) dataset=[NSData dataWithContentsOfFile:testPath];
      else dataset = [[NSFileHandle fileHandleWithStandardInput] availableData];
      
      LOG_DEBUG(@"environment:\r%@",[environment description]);
      
      
      
#pragma mark in out
      if (dataset.length < 12)
      {
         LOG_WARNING(@"error 1: dicom binary data too small");
         [[NSData data] writeToFile:@"/dev/stdout" atomically:NO];
      }
      else
      {
         unsigned char* cuartets=(unsigned char*)[dataset bytes];
         NSMutableData *D=[NSMutableData data];
         NSUInteger index=parseAttrList(
                                        cuartets,
                                        0,
                                        dataset.length -1,
                                        D
                                        );
         [D writeToFile:H2Doutput atomically:NO];
      }
   }//end autorelease pool
   return 0;
}
