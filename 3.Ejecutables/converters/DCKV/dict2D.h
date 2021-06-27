//  Created by pcs on 29/1/21.
//  Copyright © 2021 opendicom.com. All rights reserved.
//

enum NSUInteger {
   dicomExplicit=NSNotFound,
   dicomExplicitJ2kBase=1,
   dicomExplicitJ2kFast,
   dicomExplicitJ2kHres,
   dicomExplicitJ2kIdem
} dicomExplicitPixelMode;


int dict2D(NSString *baseURLString, NSDictionary *dict, NSMutableData *data, NSUInteger pixelMode);
