#import <Foundation/Foundation.h>
#import "utils.h"
#import "ODLog.h"

//H2X
//stdin binary dicom representation
//stdout mapxmldicom xml (DICOM_contextualizedKey-values)
//https://raw.githubusercontent.com/jacquesfauquex/DICOM_contextualizedKey-values/master/mapxmldicom/mapxmldicom.xsd

#pragma mark - xml elements
const unsigned char zero=0x0;
static NSData *zeroData=nil;


NSXMLNode *makeKey(NSString *branch,uint32 tag,uint16 vr)
{
   return [NSXMLNode attributeWithName:@"key"stringValue:
           [NSString
            stringWithFormat:@"%@-%08X_%c%c",
            branch,
            uint32visual(tag),
            vr & 0xff,
            vr >> 8
           ]
          ];
}

NSXMLElement *stringOrArray(
   NSString *branch,
   uint32 tag,
   uint16 vr,
   NSArray *array,
   BOOL trimLeading,
   BOOL trimTrailing
)
{
   NSXMLElement *node=nil;
   NSXMLNode *key=makeKey(branch,tag,vr);
   
   if (array.count==1)
   {
      node=[NSXMLElement elementWithName:@"string"];
      [node addAttribute:key];
      if (trimLeading || trimTrailing)
      {
         NSMutableString *mutableString=[NSMutableString stringWithString:array[0]];
         if (trimLeading) trimLeadingSpaces(mutableString);
         if (trimTrailing) trimTrailingSpaces(mutableString);
         [node setStringValue:mutableString];
      }
      else [node setStringValue:array[0]];
   }
   else
   {
      node=[NSXMLElement elementWithName:@"array"];
      [node addAttribute:key];

      if (trimLeading || trimTrailing)
      {
         for (NSString *value in array)
         {
            NSMutableString *mutableString=[NSMutableString stringWithString:value];
            if (trimLeading) trimLeadingSpaces(mutableString);
            if (trimTrailing) trimTrailingSpaces(mutableString);
            [node addChild:[NSXMLElement elementWithName:@"string" stringValue:mutableString]];
         }
      }
      else
      {
         for (NSString *value in array)
         {
            [node addChild:[NSXMLElement elementWithName:@"string" stringValue:value]];
         }
      }
   }
   return node;
}



NSXMLElement *numberOrArray(
   NSString *branch,
   uint32 tag,
   uint16 vr,
   NSArray *array
)
{
   NSXMLElement *node=nil;
   NSXMLNode *key=makeKey(branch,tag,vr);

   if (array.count==1)
   {
      node=[NSXMLElement elementWithName:@"number"];
      [node addAttribute:key];
      [node setStringValue:array[0]];
   }
   else
   {
      node=[NSXMLElement elementWithName:@"array"];
      [node addAttribute:key];

      for (NSString *value in array)
      {
         [node addChild:[NSXMLElement elementWithName:@"number" stringValue:value]];
      }
   }
   return node;
}


NSXMLElement *emptyArray(
   NSString *branch,
   uint32 tag,
   uint16 vr
)
{
   NSXMLElement *node=[NSXMLElement elementWithName:@"array"];
   NSXMLNode *key=makeKey(branch,tag,vr);
   [node addAttribute:key];
   return node;
}

/*
NSXMLElement *null(
   NSString *branch,
   uint32 tag,
   uint16 vr
)
{
   NSXMLElement *node=[NSXMLElement elementWithName:@"null"];
   NSXMLNode *key=makeKey(branch,tag,vr);
   [node addAttribute:key];
   return node;
}


NSXMLElement *booleanTrue(
   NSString *branch,
   uint32 tag,
   uint16 vr
)
{
   NSXMLElement *node=[NSXMLElement elementWithName:@"boolean"];
   NSXMLNode *key=makeKey(branch,tag,vr);
   [node addAttribute:key];
   [node setStringValue:@"true"];
   return node;
}


NSXMLElement *booleanFalse(
   NSString *branch,
   uint32 tag,
   uint16 vr
)
{
   NSXMLElement *node=[NSXMLElement elementWithName:@"boolean"];
   NSXMLNode *key=makeKey(branch,tag,vr);
   [node addAttribute:key];
   [node setStringValue:@"false"];
   return node;
}
*/
#pragma mark -

NSUInteger parseAttrList(
                         unsigned char* buffer,
                         NSUInteger index,
                         NSUInteger postbuffer,
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
            [dataset addChild:stringOrArray(branch,tag,vr,[[[NSString alloc]initWithData:md encoding:NSISOLatin1StringEncoding]componentsSeparatedByString:@"\\"],true,true)];
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
            [dataset addChild:stringOrArray(branch,tag,vr, [[[NSString alloc]initWithData:md encoding:NSISOLatin1StringEncoding]componentsSeparatedByString:@"\\"],false,false)];
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
            [dataset addChild:stringOrArray(
                                     branch,
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
            unsigned int itemcounter=1;
            NSString *branchTag=[branch stringByAppendingFormat:@"-%08X",uint32visual(tag)];

            //SQ empty?
            uint32 nexttag=uint32FromCuartetBuffer(buffer,index+16);
            if (nexttag==0x0)
            {
               [dataset addChild:emptyArray(branch,tag,vr)];
               index+=16;
               [dataset addChild:emptyArray([branchTag stringByAppendingFormat:@".%08X",itemcounter],0xe0ddfffe,vr)];
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
               while (nexttag!=0xe0ddfffe)//not the end of the SQ
               {
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
                        [dataset addChild:emptyArray([branchTag stringByAppendingFormat:@".%08X",itemcounter],0x0,0x5149)];//IQ

                        [dataset addChild:emptyArray([branchTag stringByAppendingFormat:@".%08X",itemcounter],0x0,0x5A49)];//IZ
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
                        [dataset addChild:emptyArray([branchTag stringByAppendingFormat:@".%08X",itemcounter],0x0,0x5149)];//IQ

#pragma mark recursion
                        index=parseAttrList(buffer,index,postbuffer,[branchTag stringByAppendingFormat:@".%08X",itemcounter],dataset);

                        [dataset addChild:emptyArray([branchTag stringByAppendingFormat:@".%08X",itemcounter],0xe00dfffe,0x5A49)];//IZ

                        index+=16;
                        nexttag=uint32FromCuartetBuffer(buffer,index);
                     }
                  }
                  itemcounter++;
               }
               
               [dataset addChild:emptyArray([branchTag stringByAppendingString:@"FFFFFFFF"],0xe0ddfffe,0x5A51)];

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

      zeroData=[NSData dataWithBytes:&zero length:1];
      
      NSProcessInfo *processInfo=[NSProcessInfo processInfo];
      
#pragma marks environment

      NSDictionary *environment=processInfo.environment;
      
      //H2XlogLevel
      if (environment[@"H2XlogLevel"])
      {
         NSUInteger logLevel=[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:environment[@"H2XlogLevel"]];
         if (logLevel!=NSNotFound) ODLogLevel=(ODLogLevelEnum)logLevel;
         else ODLogLevel=4;//ERROR (default)
      }
      else ODLogLevel=4;//ERROR (default)
      
      
      //H2XlogPath
      NSString *logPath=environment[@"H2XlogPath"];
      if (logPath && ([logPath hasPrefix:@"/Users/Shared"] || [logPath hasPrefix:@"/Volumes/LOG"]))
      {
         if ([logPath hasSuffix:@".log"])
            freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
         else freopen([[logPath stringByAppendingPathExtension:@".log"] cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      }
      else freopen([@"/Users/Shared/H2X.log" cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
      

      //H2XtestPath
      NSData *linedata=nil;
      NSString *testPath=environment[@"H2XtestPath"];
      if (testPath) linedata=[NSData dataWithContentsOfFile:testPath];
      else linedata = [[NSFileHandle fileHandleWithStandardInput] availableData];
      
      LOG_DEBUG(@"environment:\r%@",[environment description]);
      
#pragma mark in out
      if (linedata.length)
      {
         unsigned char* cuartets=(unsigned char*)[linedata bytes];
         
         NSXMLElement *root=[NSXMLElement elementWithName:@"map"];
         NSXMLElement *dataset=[NSXMLElement elementWithName:@"map"];
         [root addChild:dataset];
         [dataset addAttribute:[NSXMLNode attributeWithName:@"key"stringValue:@"dataset"]];
         
         NSUInteger index=parseAttrList(
                                        cuartets,
                                        0,
                                        linedata.length-1,
                                        //@"",
                                        @"00000001",
                                        dataset
                                        );
         LOG_VERBOSE(@"index:%lu size:%lu",(unsigned long)index,linedata.length-1);
         
         NSXMLDocument *xmlDocument=[[NSXMLDocument alloc] initWithRootElement:root];
         [xmlDocument setCharacterEncoding:@"UTF-8"];
         [xmlDocument setVersion:@"1.0"];

#pragma marks args
         
         NSArray *args=processInfo.arguments;
       
         //without args: in>out
         if (args.count==1) [[xmlDocument XMLData] writeToFile:@"/dev/stdout" atomically:NO];
         else //H2X [XSL1TransformationPath [params...]]
         {
            NSData *xsl1data=[NSData dataWithContentsOfFile:args[1]];
            if (!xsl1data)
            {
               LOG_ERROR(@"arg XSL1TransformationPath %@ not available",args[1]);
               exit(2);
            }

            NSMutableDictionary *xslparams=[NSMutableDictionary dictionary];
            for (NSString *string in [args subarrayWithRange:NSMakeRange(2,args.count - 2)])
            {
               NSArray *keyValue=[string componentsSeparatedByString:@"="];
               if (keyValue.count != 2)
               {
                  LOG_ERROR(@"xsl1t params in %@ should be key=value",args[1]);
                  exit(3);
               }
               [xslparams setValue:keyValue[1] forKey:keyValue[0]];
            }

            LOG_DEBUG(@"xsl1t %@ with params : %@",args[1],[xslparams description]);
            
            NSError *error=nil;
            id result=[xmlDocument objectByApplyingXSLT:xsl1data arguments:xslparams error:&error];
            if (!result)
            {
               LOG_WARNING(@"Error with xsl %@",[args description]);
               [[NSData data] writeToFile:@"/dev/stdout" atomically:NO];
            }
            else if ([result isMemberOfClass:[NSXMLDocument class]])
            {
               LOG_VERBOSE(@"xml result");
               [[result XMLData] writeToFile:@"/dev/stdout" atomically:NO];
            }
            else
            {
               LOG_VERBOSE(@"data result");
               [result writeToFile:@"/dev/stdout" atomically:NO];
            }
         }
      }
      else [[NSData data] writeToFile:@"/dev/stdout" atomically:NO];
   }//end autorelease pool
   return 0;
}