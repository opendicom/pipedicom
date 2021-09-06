//  Created by pcs on 29/1/21.
//  Copyright © 2021 opendicom.com. All rights reserved.
//

enum {
   native=0,
   j2kBase,
   j2kFast,
   j2kHres,
   idem,
   jpeg50
};
// j2kBase, j2kFast, j2kHres require FrameBFHI JSON codification

int dict2D(NSString *baseURLString, NSDictionary *dict, NSMutableData *data, NSUInteger pixelMode, NSDictionary *blobDict);
