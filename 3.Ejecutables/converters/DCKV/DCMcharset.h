#ifndef DCMcharset_h
#define DCMcharset_h

#import <Foundation/Foundation.h>

#pragma mark doc
/*
 Support of Character Repertoires
 Values that are text or character strings can be composed of Graphic and Control Characters. The Graphic Character set, independent of its encoding, is referred to as a Character Repertoire. Depending on the native language context in which Application Entities wish to exchange data using the DICOM Standard, different Character Repertoires will be used for th Value representations:
 
 SH (Short String),
 LO (Long String),
 UC (Unlimited Characters),
 ST (Short Text),
 LT (Long Text),
 UT (Unlimited Text)
 PN (Person Name)
 
 The relevant "Specific Character Set" shall be defined as an attribute of the SOP Common Module (0008,0005)

 
 
The Character Repertoires supported by DICOM are:
 
ISO 646:1990 (ISO-IR 6) =ASCII=common character set of ISO 8859
UTF-8  ISO 10646-1, 10646-2, supplements and extensions (v.3.2)
ISO 8859
GB 18030
GB2312
GBK
JIS X 0201-1976 Information Interchange
JIS X 0208-1990 Japanese Graphic Character set for information interchange
JIS X 0212-1990 supplementary Japanese Graphic Character set for information interchange
KS X 1001 (registered as ISO-IR 149) for Korean Language
TIS 620-2533 (1990) Thai Characters Code for Information Interchange

 0x00 0000 null
 
 http://dicom.nema.org/medical/dicom/current/output/html/part03.html#table_C.12-2
 Single-Byte Character Sets Without Code Extensions
 
 0x01 1100 ISO_IR 100    latin 1
 0x02 1101 ISO_IR 101    latin 2
 0x03 1109 ISO_IR 109    latin 3
 0x04 1110 ISO_IR 110    latin 4
 0x05 1144 ISO_IR 144    cyrilic
 0x06 1127 ISO_IR 127    arabic
 0x07 1126 ISO_IR 126    greek
 0x08 1138 ISO_IR 138    hebrew
 0x09 1148 ISO_IR 148    latin 5
 0x0A 1013 ISO_IR 13     japanese
 0x0B 1166 ISO_IR 166    thai

 http://dicom.nema.org/medical/dicom/current/output/html/part03.html#table_C.12-3
 Single-Byte Character Sets with Code Extensions

 0x0C 2006 ISO 2022 IR 6      default
 0x0D 2100 ISO 2022 IR 100    latin 1
 0x0E 2101 ISO 2022 IR 101    latin 2
 0x0F 2109 ISO 2022 IR 109    latin 3
 0x10 2110 ISO 2022 IR 110    latin 4
 0x11 2144 ISO 2022 IR 144    cyrilic
 0x12 2127 ISO 2022 IR 127    arabic
 0x13 2126 ISO 2022 IR 126    greek
 0x14 2138 ISO 2022 IR 138    hebrew
 0x15 2148 ISO 2022 IR 148    latin 5
 0x16 2013 ISO 2022 IR 13     japanese
 0x17 2166 ISO 2022 IR 166    thai
 
 http://dicom.nema.org/medical/dicom/current/output/html/part03.html#table_C.12-4
 Multi-Byte Character Sets with Code Extensions
 
 0x18 2087 ISO 2022 IR 87     japanese
 0x19 2159 ISO 2022 IR 159    japanese
 0x1A 2149 ISO 2022 IR 149    korean
 0x1B 2058 ISO 2022 IR 58     simplified chinese
 
 http://dicom.nema.org/medical/dicom/current/output/html/part03.html#table_C.12-5
 Multi-Byte Character Sets Without Code Extensions
 
 0x1C 1192 ISO_IR 192         Unicode in UTF-8
 0x1D 3000 GB18030            GB18030
 0x1E 4000 GBK                GBK
 
 */

/*
 For M representation, for SH,LO,UC,ST,LT,UT and PN we prefix the VR with the corresponding (0008,0005) encoding, optionally so if the encoding is latin 1.
 
 For PN there may be up to three encodings, the first being null or not. There are appened from left to right after the hyphen.
 Example: -000020584000PN  (first person name with first encoding null, second simplified chinese and third GBK
 
 This example is hypothetic for now in M, since in its first version, it only accepts latin1 (as default, with no corresponding markup, ant UTF-8 as single encoding characterized by the number 1192 (ISO_IR 192)
 
 The encoding prefix is one digit followd by three digits.
 
 The first digit is:
 1 for ISO_IR
 2 for ISO 2022 IR
 3 for GB18030
 4 for GBK
 
 The three following digits are the number iso or 000 for the two chinese GB18030 and GBK encodings
 
 */

#pragma mark macos relative constants


extern const NSUInteger encodingTotal;
extern NSString *evr[];
extern NSString *encodingCS[];
extern uint64 encodingPrefixuint64[];
extern NSUInteger encodingNS[];



#pragma mark simple functions

char encodingCSindex(NSString *ecs);





// ===============================================
/*
#pragma mark - stack

struct uint64stack
{
    int maxsize;
    int top;
    uint64 *items;
};

struct uint64stack* newEncodingPrefixStack(void);

NSUInteger size(struct uint64stack *pt);
BOOL isEmpty(struct uint64stack *pt);
BOOL isFull(struct uint64stack *pt);

NSString *pushSpecificCharacterSetString(struct uint64stack *pt, NSString *scs);//returns prefix (eventually composed)

uint64 peekUint64(struct uint64stack *pt);
uint64 popUint64(struct uint64stack *pt);

NSString *peekString(struct uint64stack *pt);
NSString *popString(struct uint64stack *pt);
*/

#endif /* DCMcharset_h */
