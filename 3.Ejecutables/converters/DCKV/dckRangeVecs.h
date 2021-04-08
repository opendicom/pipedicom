#ifndef dckRangeVecs_h
#define dckRangeVecs_h

#import <Foundation/Foundation.h>

struct dckRange
{
   NSString *dck;
   NSUInteger loc;
   NSUInteger len;
};

struct dckRangeVecs
{
   NSUInteger vecsSize;
   NSInteger curTop;
   NSMutableArray *dcks;
   NSMutableArray *locs;
   NSMutableArray *lens;
};
struct dckRangeVecs newDckRangeVecs(NSUInteger size);

NSUInteger countDckRange(struct dckRangeVecs *pt);

NSUInteger pushDckRange(
   struct dckRangeVecs pt,
   NSString *dck,
   NSUInteger loc,
   NSUInteger len
);//returns err code

struct dckRange peekDckRange(struct dckRangeVecs pt,NSUInteger idx);

struct dckRange popDckRange(struct dckRangeVecs pt);


#endif /* dckRangeVecs_h */
