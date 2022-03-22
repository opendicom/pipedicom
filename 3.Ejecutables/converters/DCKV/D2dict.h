//
//  dict4D.h
//  converters
//
//  Created by jacquesfauquex on 2021-02-23.

enum blobModeOptions {
   blobModeInline,
   blobModeSource,
   blobModeResources
} ;

NSString *jsonObject4attrs(NSDictionary *attrs);

int D2dict(
           NSData *data,
           NSMutableDictionary *attrs,
           long long blobMinSize,
           int blobMode,
           NSString* blobRefPrefix,
           NSString* blobRefSuffix,
           NSMutableDictionary *blobDict
           );

int parse(
           NSMutableData *data,
           NSMutableDictionary *filemetainfoAttrs,
           NSMutableDictionary *datasetAttrs,
           NSMutableDictionary *nativeAttrs,
           NSMutableDictionary *j2kAttrs,
           NSMutableDictionary *blobDict,
           NSMutableDictionary *j2kBlobDict,
           long long blobMinSize,
           int blobMode,
           NSString* blobRefPrefix,
           NSString* blobRefSuffix,
           BOOL toJ2KR,
           BOOL toBFHI
           );
