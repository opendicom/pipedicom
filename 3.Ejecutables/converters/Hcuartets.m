#import "Hcuartets.h"


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