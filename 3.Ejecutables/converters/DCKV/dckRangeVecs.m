#import "dckRangeVecs.h"
#import "ODLog.h"

struct dckRangeVecs newDckRangeVecs(NSUInteger size)
{
   NSMutableArray *dcks=[NSMutableArray arrayWithCapacity:size];
   NSMutableArray *locs=[NSMutableArray arrayWithCapacity:size];
   NSMutableArray *lens=[NSMutableArray arrayWithCapacity:size];
   struct dckRangeVecs vecs = { size, NSNotFound, dcks, locs, lens};
   return vecs;
}


NSUInteger countDckRange(struct dckRangeVecs *pt)
{
   return pt->curTop + 1;
}


NSUInteger pushDckRange(
                        struct dckRangeVecs pt,
                        NSString *dck,
                        NSUInteger loc,
                        NSUInteger len
)
{
   NSUInteger idx=pt.curTop + 1;
   if (idx == pt.vecsSize)
   {
      LOG_WARNING(@"size of dckRangeVecs %lu duplicated to %lu",(unsigned long)pt.vecsSize, (unsigned long)pt.vecsSize * 2);
      pt.vecsSize=pt.vecsSize * 2;
#pragma mark TODO vecs memory allocation
   }
   pt.curTop=idx;
   [pt.dcks addObject:dck];
   [pt.locs addObject:[NSNumber numberWithUnsignedInteger:loc]];
   [pt.lens addObject:[NSNumber numberWithUnsignedInteger:len]];
   return success;
}
 
struct dckRange peekDckRange(struct dckRangeVecs pt,NSUInteger idx)
{
    // check for an empty Vecs
    if (pt.curTop == NSNotFound)
    {
       struct dckRange emptyDckRange = { nil, 0, 0};
       return emptyDckRange;
    }
   struct dckRange existingDckRange = {
      (pt.dcks)[idx],
      [(pt.locs)[idx] unsignedIntegerValue],
      [(pt.lens)[idx] unsignedIntegerValue]
      };
   return existingDckRange;
}
 
struct dckRange popDckRange(struct dckRangeVecs pt)
{
   struct dckRange peek=peekDckRange(pt,pt.curTop);
   if (!peek.dck) pt.curTop--;
   return peek;
}

