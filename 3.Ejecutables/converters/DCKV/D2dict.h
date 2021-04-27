//
//  dict4D.h
//  converters
//
//  Created by jacquesfauquex on 2021-02-23.
//

#ifndef D2dict_h
#define D2dict_h

enum blob_mode {
   blob_inline = 0,
   blob_sourcePointer,
   blob_dict
} ;

int D2dict(
           NSData *data,
           NSMutableDictionary *attrDict,
           long long blobMinSize,
           int blobMode,
           NSString* blobRefPrefix,
           NSString* blobRefSuffix,
           NSMutableDictionary *blobDict
           );

#endif /* D2dict_h */
