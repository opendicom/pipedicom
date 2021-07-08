//
//  fileManager.m
//  DCKV
//
//  Created by jacquesfauquex on 2021-07-07.
//

#import "fileManager.h"
#import "ODLog.h"

int visibleRelativeFiles(NSFileManager *fileManager, NSString *base, NSArray *mountPoints, NSMutableArray *paths)
{
   BOOL isDirectory=false;
   for (NSString *relativeMountPoint in mountPoints)
   {
      NSString *lastPathComponent=[relativeMountPoint lastPathComponent];
      if ([lastPathComponent hasPrefix:@"."]) continue;
      if ([lastPathComponent hasPrefix:@"DISCARDED"]) continue;
      if ([lastPathComponent hasPrefix:@"ORIGINALS"]) continue;
      if ([lastPathComponent hasPrefix:@"COERCED"]) continue;
      if ([lastPathComponent hasPrefix:@"UNKNOWNSOURCE"]) continue;
      NSString *absoluteMountPoint=[[[base stringByAppendingPathComponent:relativeMountPoint] stringByExpandingTildeInPath] stringByResolvingSymlinksInPath];

      if ([fileManager fileExistsAtPath:absoluteMountPoint isDirectory:&isDirectory])
      {
         if (isDirectory)
         {
            NSError *error;
            NSArray *contents=[fileManager contentsOfDirectoryAtPath:absoluteMountPoint error:&error];
            
            if (error)
            {
               NSLog(@"bad directory path %@",absoluteMountPoint);
               return failure;
            }
            
            NSMutableArray *contentsPaths=[NSMutableArray array];
            for (NSString *name in contents)
            {
               [contentsPaths addObject:[relativeMountPoint stringByAppendingPathComponent:name]];
            }
            
            if (visibleRelativeFiles(fileManager,base,contentsPaths, paths) != success) return failure;
         }
         else [paths addObject:relativeMountPoint];
      }
   }
   return success;
}


int enclosingDirectoryWritable(NSFileManager *fileManager, NSMutableSet *writableDirSet, NSString *filePath)
{
   NSString *dirPath=[filePath stringByDeletingLastPathComponent];
   if ([writableDirSet containsObject:dirPath]) return success;
   BOOL isDirectory;
   NSError *error;
   if ([fileManager fileExistsAtPath:dirPath isDirectory:&isDirectory])
   {
      if (isDirectory)
      {
         [writableDirSet addObject:dirPath];
         return success;
      }
      NSLog(@"should be directory:%@",dirPath);
      return failure;
   }
   if([fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&error])
   {
      [writableDirSet addObject:dirPath];
      return success;
   }
   NSLog(@"can not create dir: %@",dirPath);
   return failure;
}

@implementation fileManager

@end
