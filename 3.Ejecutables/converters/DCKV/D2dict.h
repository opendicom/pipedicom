//
//  dict4D.h
//  converters
//
//  Created by jacquesfauquex on 2021-02-23.
//

#ifndef D2dict_h
#define D2dict_h

enum blobModeOptions {
   blobModeInline,
   blobModeSource,
   blobModeResources
} ;

int D2dict(
           NSData *data,
           NSMutableDictionary *parsedAttrs,
           long long blobMinSize,
           int blobMode,
           NSString* blobRefPrefix,
           NSString* blobRefSuffix,
           NSMutableDictionary *blobDict
           );

NSString *jsonObject4attrs(NSDictionary *attrs);

#endif /* D2dict_h */
