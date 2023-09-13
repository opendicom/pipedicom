#import "B64.h"

static NSString *JSONb64[]={
   @"A",
   @"B",
   @"C",
   @"D",
   @"E",
   @"F",
   @"G",
   @"H",
   @"I",
   @"J",
   @"K",
   @"L",
   @"M",
   @"N",
   @"O",
   @"P",
   @"Q",
   @"R",
   @"S",
   @"T",
   @"U",
   @"V",
   @"W",
   @"X",
   @"Y",
   @"Z",
   @"a",
   @"b",
   @"c",
   @"d",
   @"e",
   @"f",
   @"g",
   @"h",
   @"i",
   @"j",
   @"k",
   @"l",
   @"m",
   @"n",
   @"o",
   @"p",
   @"q",
   @"r",
   @"s",
   @"t",
   @"u",
   @"v",
   @"w",
   @"x",
   @"y",
   @"z",
   @"0",
   @"1",
   @"2",
   @"3",
   @"4",
   @"5",
   @"6",
   @"7",
   @"8",
   @"9",
   @"+",
   @"\\/",//JSON escaping !!!
   @"=",
};

char const  base64EncodingTable[65] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
char const  base64DecodingTable[128] = {
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -1, -2, -1, -1, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-1, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 62, -2, -2, -2, 63,
	52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -2, -2, -2, -2, -2, -2,
	-2,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
	15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -2, -2, -2, -2, -2,
	-2, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
	41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -2, -2, -2, -2, -2
};

NSMutableString* B64JSONstringWithData(NSData *binData)
{
   // Get the Raw Data length and ensure we actually have data
   NSUInteger binLength = [binData length];
   if (binLength == 0) return [NSMutableString string];
   
   const unsigned char *binBytes = [binData bytes];
   NSMutableString *base64String = [NSMutableString string];
   
   //3-bytes groups
   while (binLength > 2)
   {
      [base64String appendString:JSONb64[binBytes[0] >> 2]];
      [base64String appendString:JSONb64[((binBytes[0] & 0x03) << 4) + (binBytes[1] >> 4)]];
      [base64String appendString:JSONb64[((binBytes[1] & 0x0f) << 2) + (binBytes[2] >> 6)]];
      [base64String appendString:JSONb64[binBytes[2] & 0x3f]];
      binBytes += 3;
      binLength -= 3;
   }
   
   //tail
   if (binLength != 0) {
      [base64String appendString:JSONb64[binBytes[0] >> 2]];
      if (binLength > 1) {
         [base64String appendString:JSONb64[((binBytes[0] & 0x03) << 4) + (binBytes[1] >> 4)]];
         [base64String appendString:JSONb64[(binBytes[1] & 0x0f) << 2]];
         [base64String appendString:JSONb64[64]];
      } else {
         [base64String appendString:JSONb64[(binBytes[0] & 0x03) << 4]];
         [base64String appendString:JSONb64[64]];
         [base64String appendString:JSONb64[64]];
      }
   }
   return base64String;
};

NSData* B64dataWithData(NSData *binData)
{
	// Get the Raw Data length and ensure we actually have data
	NSUInteger binLength = [binData length];
	if (binLength == 0) return [NSData data];
	
	const unsigned char *binBytes = [binData bytes];
	NSMutableData *base64Data = [NSMutableData dataWithCapacity:((binLength + 2) / 3) * 4];
	
	//3-bytes groups
	while (binLength > 2) 
	{ 
		[base64Data appendBytes:&base64EncodingTable[binBytes[0] >> 2] length:1];
		[base64Data appendBytes:&base64EncodingTable[((binBytes[0] & 0x03) << 4) + (binBytes[1] >> 4)] length:1];
		[base64Data appendBytes:&base64EncodingTable[((binBytes[1] & 0x0f) << 2) + (binBytes[2] >> 6)] length:1];
		[base64Data appendBytes:&base64EncodingTable[binBytes[2] & 0x3f] length:1];
		binBytes += 3;
		binLength -= 3; 
	}
	
	//tail
	if (binLength != 0) {
		[base64Data appendBytes:&base64EncodingTable[binBytes[0] >> 2] length:1];
		if (binLength > 1) {
			[base64Data appendBytes:&base64EncodingTable[((binBytes[0] & 0x03) << 4) + (binBytes[1] >> 4)] length:1];
			[base64Data appendBytes:&base64EncodingTable[(binBytes[1] & 0x0f) << 2] length:1];
			[base64Data appendBytes:&base64EncodingTable[64] length:1];
		} else {
			[base64Data appendBytes:&base64EncodingTable[(binBytes[0] & 0x03) << 4] length:1];
			[base64Data appendBytes:&base64EncodingTable[64] length:1];
			[base64Data appendBytes:&base64EncodingTable[64] length:1];
		}
	}
	return [NSData dataWithData:base64Data];	
}

NSData* dataWithB64String(NSString *base64NSString)
{
	const char *base64String = [base64NSString cStringUsingEncoding:NSUTF8StringEncoding];
	NSUInteger base64StringLength = strlen(base64String);
	if ((base64String == NULL) || (base64StringLength % 4 != 0)) return nil;
	while (base64StringLength > 0 && base64String[base64StringLength - 1] == '=') {base64StringLength--;}
	
	NSInteger decodedCharsLength = base64StringLength * 3 / 4;
  	NSMutableData* decodedData = [NSMutableData dataWithLength:decodedCharsLength];
	char *decodedChars = decodedData.mutableBytes;
	
	NSInteger base64StringPosition = 0;
	NSInteger decodedCharsPosition = 0;
	
	while (base64StringPosition < base64StringLength) 
	{
		char char0 = base64String[base64StringPosition++];
		char char1 = base64String[base64StringPosition++];
		char char2 = base64StringPosition < base64StringLength ? base64String[base64StringPosition++] : 'A'; /* 'A' will decode to \0 */
		char char3 = base64StringPosition < base64StringLength ? base64String[base64StringPosition++] : 'A';
		
		decodedChars[decodedCharsPosition++] =  (base64DecodingTable[char0] << 2)        | (base64DecodingTable[char1] >> 4);
		if (decodedCharsPosition < decodedCharsLength) decodedChars[decodedCharsPosition++] = ((base64DecodingTable[char1] & 0xf) << 4) | (base64DecodingTable[char2] >> 2);
		if (decodedCharsPosition < decodedCharsLength) decodedChars[decodedCharsPosition++] = ((base64DecodingTable[char2] & 0x3) << 6) |  base64DecodingTable[char3];
	}
	
	return [NSData dataWithData:decodedData];
}


#pragma mark -

NSString *B64CHAR[]={
@"-", @"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8",
@"9", @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I",
@"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S",
@"T", @"U", @"V", @"W", @"X", @"Y", @"Z", @"_", @"a", @"b",
@"c", @"d", @"e", @"f", @"g", @"h", @"i", @"j", @"k", @"l",
@"m", @"n", @"o", @"p", @"q", @"r", @"s", @"t", @"u", @"v",
@"w", @"x", @"y", @"z"
};

char u8u4( const char *byte_array, NSUInteger *idx) {
    // returns half_byte
    // updates idx
    
    // u4=half byte (0-15)
    // 0x0   1.2.840.10008.
    // 0x1   .
    // 0x2   0.
    // 0x3   0
    // 0x4   1.
    // 0x5   1
    // 0x6   2.
    // 0x7   2
    // 0x8   3.
    // 0x9   3
    // 0xA   4
    // 0xB   5
    // 0xC   6
    // 0xD   7
    // 0xE   8
    // 0xF   9
    
    char cur_byte = byte_array[*idx];
    switch (cur_byte) {
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
            *idx += 1;
            return cur_byte - 0x2A;
        case '.':
            *idx += 1;
            return 0x01;
        case '0':
        case '2':
        case '3': {
            if (byte_array[*idx+1] == '.')  {
                *idx += 2;
                return cur_byte + cur_byte - 0x5E;
            } else {
                *idx += 1;
                return cur_byte + cur_byte - 0x5D;
            }
        }
        case '1': {
            if (byte_array[*idx+1] == '.') {
                if (   sizeof(byte_array) - *idx > 14
                    && byte_array[*idx+2]  == '2'
                    && byte_array[*idx+3]  == '.'
                    && byte_array[*idx+4]  == '8'
                    && byte_array[*idx+5]  == '4'
                    && byte_array[*idx+6]  == '0'
                    && byte_array[*idx+7]  == '.'
                    && byte_array[*idx+8]  == '1'
                    && byte_array[*idx+9]  == '0'
                    && byte_array[*idx+10] == '0'
                    && byte_array[*idx+11] == '0'
                    && byte_array[*idx+12] == '8'
                    && byte_array[*idx+13] == '.'
                    )
                {
                    *idx += 14;
                    return 0x0;
                }
                else
                {
                    *idx += 2;
                    return 0x4;
                }
            } else {
                *idx += 1;
                return cur_byte + cur_byte - 0x5D;
            }
        }
       case ' ':
          *idx += 1;
          return 0x01;

        default:
            return 0xFF;
    }
}

NSString* b64ui(NSString* uidString){
    if (!uidString) return nil;
    NSUInteger length=uidString.length;
    if (length==0) return @"";
    const char *array=[[uidString stringByAppendingString:@"  "] cStringUsingEncoding:NSUTF8StringEncoding];
    NSUInteger index=0;
    unsigned char u4a,u4b,u4c;
    NSMutableString *b64String=[NSMutableString stringWithCapacity:(length+1)/2];
    while (index < length)
    {
        u4a=u8u4(array,&index);
        if (u4a > 0x10) return nil;
        u4b=u8u4(array,&index);
        if (u4b > 0x10) return nil;
        u4c=u8u4(array,&index);
        if (u4c > 0x10) return nil;
        [b64String appendString:B64CHAR[(u4a<<2) + (u4b>>2)]];
        [b64String appendString:B64CHAR[((u4b & 0x03) << 4) + u4c]];
    }
    return [NSString stringWithString:b64String];
}
