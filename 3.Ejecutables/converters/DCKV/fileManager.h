//
//  fileManager.h
//  DCKV
//
//  Created by jacquesfauquex on 2021-07-07.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//new
NSString *moveVersionedInstance(NSFileManager *fileManager, NSString *srciPath, NSString *dstePath, NSString *sopiuid);

//old
NSString *moveForD2ForD(NSFileManager *fileManager, NSString *srciPath, NSString *srcSuffix,NSString *dstePath,BOOL dstePathExists, NSString *iName);

int visibleFiles(NSFileManager *fileManager, NSArray *mountPoints, NSMutableArray *paths);

int visibleRelativeFiles(NSFileManager *fileManager, NSString *base, NSArray *mountPoints, NSMutableArray *paths);

int enclosingDirectoryWritable(NSFileManager *fileManager, NSMutableSet *writableDirSet, NSString *filePath);

NSString * moveDup(NSFileManager *fileManager, NSString *srcFile,NSString *dstFile);

NSString * mergeDir(NSFileManager *fileManager, NSString *srcDir, NSString *dstDir);


@interface fileManager : NSObject

@end

NS_ASSUME_NONNULL_END
