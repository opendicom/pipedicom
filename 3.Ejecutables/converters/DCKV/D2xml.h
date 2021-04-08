//
//  D2xml.h
//  converters
//
//  Created by jacquesfauquex on 2021-02-23.
//

#import <DCKV/dckRangeVecs.h>

#ifndef D2xml_h
#define D2xml_h


int D2xml(
          NSData *data,
          NSXMLElement *xml,
          long long bulkdataMinSize,
          NSString *bulkdataUrlTemplate,
          struct dckRangeVecs bulkdataVecs
          );
#endif /* D2xml_h */

/*
 if bulkdataMinSize -> not inlined
 
 if bulkdataUrlTemplate -> byReference to pointer in data
 else copied to bulkdatas with key dckv
 */
