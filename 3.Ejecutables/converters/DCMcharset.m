#import "DCMcharset.h"
#import "ODLog.h"


#pragma mark macos relative constants

const NSUInteger ISO_IR13=NSISO2022JPStringEncoding;//japanese
const NSUInteger ISO_IR100=NSISOLatin1StringEncoding;//latin 1
const NSUInteger ISO_IR101=NSISOLatin2StringEncoding;//latin 2
const NSUInteger ISO_IR109=0;//latin 3
const NSUInteger ISO_IR110=0;//latin 4
const NSUInteger ISO_IR126=NSWindowsCP1253StringEncoding;//greek
const NSUInteger ISO_IR127=0;//arabic
const NSUInteger ISO_IR138=0;//hebrew
const NSUInteger ISO_IR144=NSWindowsCP1251StringEncoding;//cyrilic
const NSUInteger ISO_IR148=0;//latin 5
const NSUInteger ISO_IR166=0;//thai
const NSUInteger ISO_IR192=NSUTF8StringEncoding;

const NSUInteger ISO2022IR6=NSASCIIStringEncoding;//default
const NSUInteger ISO2022IR13=NSISO2022JPStringEncoding;//japanese
const NSUInteger ISO2022IR58=0;//simplified chinese
const NSUInteger ISO2022IR87=0;//japanese
const NSUInteger ISO2022IR100=NSISOLatin1StringEncoding;//latin 1
const NSUInteger ISO2022IR101=NSISOLatin2StringEncoding;//latin 2
const NSUInteger ISO2022IR109=0;//latin 3
const NSUInteger ISO2022IR110=0;//latin 4
const NSUInteger ISO2022IR126=NSWindowsCP1253StringEncoding;//greek
const NSUInteger ISO2022IR127=0;//arabic
const NSUInteger ISO2022IR138=0;//hebrew
const NSUInteger ISO2022IR144=NSWindowsCP1251StringEncoding;//cyrilic
const NSUInteger ISO2022IR148=0;//latin 5
const NSUInteger ISO2022IR149=0;//korean
const NSUInteger ISO2022IR159=0;//japanese
const NSUInteger ISO2022IR166=0;//thai

const NSUInteger GB18030=0;//
const NSUInteger GBK=0;

const NSUInteger encodingTotal=31;

NSString *encodingPrefixString[]={
   @"0000",
   @"1100",
   @"1101",
   @"1109",
   @"1110",
   @"1144",
   @"1127",
   @"1126",
   @"1138",
   @"1148",
   @"1013",
   @"1166",
   @"2006",
   @"2100",
   @"2101",
   @"2109",
   @"2110",
   @"2144",
   @"2127",
   @"2126",
   @"2138",
   @"2148",
   @"2013",
   @"2166",
   @"2087",
   @"2159",
   @"2149",
   @"2058",
   @"1192",
   @"3000",
   @"4000"
};

NSString *encodingCS[]={
   @"",
   @"ISO_IR 100",
   @"ISO_IR 101",
   @"ISO_IR 109",
   @"ISO_IR 110",
   @"ISO_IR 144",
   @"ISO_IR 127",
   @"ISO_IR 126",
   @"ISO_IR 138",
   @"ISO_IR 148",
   @"ISO_IR 13",
   @"ISO_IR 166",
   @"ISO 2022 IR 6",
   @"ISO 2022 IR 100",
   @"ISO 2022 IR 101",
   @"ISO 2022 IR 109",
   @"ISO 2022 IR 110",
   @"ISO 2022 IR 144",
   @"ISO 2022 IR 127",
   @"ISO 2022 IR 126",
   @"ISO 2022 IR 138",
   @"ISO 2022 IR 148",
   @"ISO 2022 IR 13",
   @"ISO 2022 IR 166",
   @"ISO 2022 IR 87",
   @"ISO 2022 IR 159",
   @"ISO 2022 IR 149",
   @"ISO 2022 IR 58",
   @"ISO_IR 192",
   @"GB18030",
   @"GBK"
};

uint64 encodingPrefixuint64[]={
   0x0000,
   0x1100,
   0x1101,
   0x1109,
   0x1110,
   0x1144,
   0x1127,
   0x1126,
   0x1138,
   0x1148,
   0x1013,
   0x1166,
   0x2006,
   0x2100,
   0x2101,
   0x2109,
   0x2110,
   0x2144,
   0x2127,
   0x2126,
   0x2138,
   0x2148,
   0x2013,
   0x2166,
   0x2087,
   0x2159,
   0x2149,
   0x2058,
   0x1192,
   0x3000,
   0x4000
};
NSUInteger encodingNS[]={
   ISO2022IR6,
   ISO_IR100,
   ISO_IR101,
   ISO_IR109,
   ISO_IR110,
   ISO_IR144,
   ISO_IR127,
   ISO_IR126,
   ISO_IR138,
   ISO_IR148,
   ISO_IR13,
   ISO_IR166,
   ISO2022IR6,
   ISO2022IR100,
   ISO2022IR101,
   ISO2022IR109,
   ISO2022IR110,
   ISO2022IR144,
   ISO2022IR127,
   ISO2022IR126,
   ISO2022IR138,
   ISO2022IR148,
   ISO2022IR13,
   ISO2022IR166,
   ISO2022IR87,
   ISO2022IR159,
   ISO2022IR149,
   ISO2022IR58,
   ISO_IR192,
   GB18030,
   GBK
};





#pragma mark simple functions

char encodingCSindex(NSString *ecs)
{
   for (char i=0; i<encodingTotal; i++ )
   {
      if ([ecs isEqualToString:encodingCS[i]]) return i;
   }
   return encodingTotal;//=31 =not found
}

/*
#pragma mark stack
static NSArray *encodingCSArray=nil;
static NSArray *encodingPrefixArray=nil;
struct uint64stack* newEncodingPrefixStack(void)
{
   encodingCSArray=@[
      @"",
      @"ISO_IR 100",
      @"ISO_IR 101",
      @"ISO_IR 109",
      @"ISO_IR 110",
      @"ISO_IR 144",
      @"ISO_IR 127",
      @"ISO_IR 126",
      @"ISO_IR 138",
      @"ISO_IR 148",
      @"ISO_IR 13",
      @"ISO_IR 166",
      @"ISO 2022 IR 6",
      @"ISO 2022 IR 100",
      @"ISO 2022 IR 101",
      @"ISO 2022 IR 109",
      @"ISO 2022 IR 110",
      @"ISO 2022 IR 144",
      @"ISO 2022 IR 127",
      @"ISO 2022 IR 126",
      @"ISO 2022 IR 138",
      @"ISO 2022 IR 148",
      @"ISO 2022 IR 13",
      @"ISO 2022 IR 166",
      @"ISO 2022 IR 87",
      @"ISO 2022 IR 159",
      @"ISO 2022 IR 149",
      @"ISO 2022 IR 58",
      @"ISO_IR 192",
      @"GB18030",
      @"GBK"
   ];

   encodingPrefixArray=@[
      @"0000",
      @"1100",
      @"1101",
      @"1109",
      @"1110",
      @"1144",
      @"1127",
      @"1126",
      @"1138",
      @"1148",
      @"1013",
      @"1166",
      @"2006",
      @"2100",
      @"2101",
      @"2109",
      @"2110",
      @"2144",
      @"2127",
      @"2126",
      @"2138",
      @"2148",
      @"2013",
      @"2166",
      @"2087",
      @"2159",
      @"2149",
      @"2058",
      @"1192",
      @"3000",
      @"4000"
   ];

   struct uint64stack *pt = (struct uint64stack*)malloc(sizeof(struct uint64stack));
 
    pt->maxsize = 30;//levels of SQ encapsulation
    pt->top = -1;
    pt->items = (uint64*)malloc(sizeof(uint64) * 10);
    
    //init with latin1
    pt->items[++pt->top] = 0x1100;
    return pt;
}
 

NSUInteger size(struct uint64stack *pt)
{
    return pt->top + 1;
}
 

BOOL isEmpty(struct uint64stack *pt)
{
    return pt->top == -1;
    // or return size(pt) == 0;
}
 

BOOL isFull(struct uint64stack *pt)
{
    return pt->top == pt->maxsize - 1;
    // or return size(pt) == pt->maxsize;
}
 

NSString *pushSpecificCharacterSet(struct uint64stack *pt, NSString *scs)
{
   // check if the stack is already full.
   //Then inserting an element would lead to stack overflow
   if (isFull(pt))
   {
      LOG_ERROR(@"Overflow charset stack");
      exit(EXIT_FAILURE);
   }

   //check valid scs
   if (!scs)
   {
      LOG_ERROR(@"null Specific Character Set. pushing latin1");
      pt->items[++pt->top] = 0x1100;
      return @"1100";
   }
   if (!scs.length)
   {
      LOG_ERROR(@"empty Specific Character Set. pushing latin1");
      pt->items[++pt->top] = 0x1100;
      return @"1100";
   }

   NSArray *scsArray=[scs componentsSeparatedByString:@"\\"];
   NSMutableString *scsPrefixString=[NSMutableString string];
   uint64 scsPrefixUint64=0;
   for (NSString *component in scsArray)
   {
      NSUInteger index=[encodingCSArray indexOfObject:component];
      if (index==NSNotFound)
      {
         LOG_ERROR(@"unknown Character Set '%@'. Pushing latin1", component);
         pt->items[++pt->top] = 0x1100;
         return @"1100";
      }
      [scsPrefixString appendString:encodingPrefixString[index]];
      scsPrefixUint64=(scsPrefixUint64 < 16) + encodingPrefixuint64[index];
   }

   
   // add an element and increment the top's index
   pt->items[++pt->top] = scsPrefixUint64;
   return [NSString stringWithString:scsPrefixString];
}
 

uint64 peekUint64(struct uint64stack *pt)
{
    // check for an empty stack
    if (!isEmpty(pt)) {
        return pt->items[pt->top];
    }
    else {
        exit(EXIT_FAILURE);
    }
}
 
uint64 popUint64(struct uint64stack *pt)
{
    // check for stack underflow
    if (isEmpty(pt))
    {
        printf("Underflow\nProgram Terminated\n");
        exit(EXIT_FAILURE);
    }
 
    // decrement stack size by 1 and (optionally) return the popped element
    return pt->items[pt->top--];
}

*/
