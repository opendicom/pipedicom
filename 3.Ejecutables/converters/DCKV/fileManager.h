//
//  fileManager.h
//  DCKV
//
//  Created by jacquesfauquex on 2021-07-07.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

int visibleRelativeFiles(NSFileManager *fileManager, NSString *base, NSArray *mountPoints, NSMutableArray *paths);

int enclosingDirectoryWritable(NSFileManager *fileManager, NSMutableSet *writableDirSet, NSString *filePath);

@interface fileManager : NSObject

@end

NS_ASSUME_NONNULL_END
