//  Created by pcs on 29/1/21.
//  Copyright © 2021 opendicom.com. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <DCKV/DCKV.h>



int dict2D(
           NSString *baseURLString,
           NSDictionary *dict,
           NSMutableData *data,
           NSUInteger pixelMode,
           NSDictionary *blobDict
           );
