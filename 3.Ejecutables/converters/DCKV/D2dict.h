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
           NSMutableDictionary *attrDict,
           long long blobMinSize,
           int blobMode,
           NSString* blobRefPrefix,
           NSString* blobRefSuffix,
           NSMutableDictionary *blobDict
           );

NSMutableString* json4attrDict(NSMutableDictionary *attrDict);

#endif /* D2dict_h */
