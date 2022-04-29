//
//  fileManager.m
//  DCKV
//
//  Created by jacquesfauquex on 2021-07-07.
//

#import "fileManager.h"
#import "ODLog.h"

//new
NSString *moveVersionedInstance(
                        NSFileManager *fileManager,
                        NSString *srciPath,
                        NSString *dstePath,
                        NSString *sopiuid
                        )
{
   /*
    e = studyDirectory
    i = instance (which may be a file or a directory containing one or more versions of it)
    srce < srci [ < srcv ]
    dste < dsti [ < dstv ]
    
    - move file
    - move dir
    - move file to dir
    - move dir to dir
    - move file to file (converted to dir)
    - move dir to file (converted to dir)
    */

   NSError *e=nil;
   
   
   //dste exists?
   BOOL dsteIsDir=false;
   if ([fileManager fileExistsAtPath:dstePath isDirectory:&dsteIsDir])
   {
      if (!dsteIsDir) return [NSString stringWithFormat:@"@fm39 file instead of dir exists at: %@\r\n",dstePath];
   }
   else // dste does not exist
   {
       if (![fileManager createDirectoryAtPath:dstePath withIntermediateDirectories:YES attributes:nil error:&e])
          return [NSString stringWithFormat:@"@fm44 %@\r\n", e.description];
   }
    
   
   //dsti exists?
   NSString *dstiPath=[dstePath stringByAppendingPathComponent:sopiuid];
   BOOL dstiIsDir=false;
   BOOL dstiExists=[fileManager fileExistsAtPath:dstiPath isDirectory:&dstiIsDir];
    
   
   
#pragma mark  source instance is dir
   BOOL srciIsDir=false;
   if (![fileManager fileExistsAtPath:srciPath isDirectory:&srciIsDir])
       return [NSString stringWithFormat:@"@fm58 src does not exist: %@\r\n",srciPath];
   if (srciIsDir)
   {
      
      //remove empty src dir
      NSArray *srciContents=[fileManager contentsOfDirectoryAtPath:srciPath error:&e];
      if (!srciContents)
         return [NSString stringWithFormat:@"@fm65 %@\r\n", e.description];
      NSUInteger srciCount=srciContents.count;
      if (
             (srciCount==0)
           ||(
                (srciCount==1)
              &&[srciContents[0] hasPrefix:@"."]
             )
           )
      {
          if (![fileManager removeItemAtPath:srciPath error:&e])
             return [NSString stringWithFormat:@"@fm76 %@\r\n", e.description];
          return @"";
      }

      
      //there is no such instance in dst -> cp srci
      if (!dstiExists)
      {
          if (![fileManager moveItemAtPath:srciPath toPath:dstiPath error:&e])
              return [NSString stringWithFormat:@"@fm85 %@\r\n", e.description];
          return @"";
      }

      
      //dsti exists and is file
      if (!dstiIsDir)
      {
         //remove from src v which are equals to dst i
         for (NSString *srcvName in srciContents)
         {
            NSString *srcvPath=[srciPath stringByAppendingPathComponent:srcvName];

            if ([srcvName hasPrefix:@"."])
            {
               if (![fileManager removeItemAtPath:srcvPath error:&e])
                  return [NSString stringWithFormat:@"@fm101 %@\r\n", e.description];
               srciCount--;
            }
            else
            {
               if ([fileManager contentsEqualAtPath:srcvPath andPath:dstiPath])
               {
                  if (![fileManager removeItemAtPath:srcvPath error:&e])
                     return [NSString stringWithFormat:@"@fm109 %@\r\n", e.description];
               }
               srciCount--;
            }
         }
         
         //if there is at least one v in src i to be moved to dest
         if (srciCount > 0)
         {
            NSString *tmpFile=[dstiPath stringByAppendingPathComponent:@"tmp"];
            if (![fileManager moveItemAtPath:dstiPath toPath:tmpFile error:&e])
               return [NSString stringWithFormat:@"@fm120 %@\r\n", e.description];
            if (![fileManager createDirectoryAtPath:dstiPath withIntermediateDirectories:true attributes:nil error:&e])
               return [NSString stringWithFormat:@"@fm122 %@\r\n", e.description];
            if (![fileManager moveItemAtPath:tmpFile toPath:[NSString stringWithFormat:@"%@/1.dcm",dstiPath] error:&e])
               return [NSString stringWithFormat:@"@fm124 %@\r\n", e.description];

            NSUInteger counter=2;
            for (NSString *srcvName in [fileManager contentsOfDirectoryAtPath:srciPath error:nil])
            {
               if (![fileManager moveItemAtPath:[srciPath stringByAppendingPathComponent:srcvName] toPath:[NSString stringWithFormat:@"%@/%lul.dcm",dstiPath,(unsigned long)counter] error:&e])
                  return [NSString stringWithFormat:@"@fm130 %@\r\n", e.description];
               counter++;
            }
         }
         else if (![fileManager removeItemAtPath:srciPath error:&e])
            return [NSString stringWithFormat:@"@fm135 %@\r\n", e.description];
      }
      else //dstIsDir
      {
         NSArray *dstiContents=[fileManager contentsOfDirectoryAtPath:dstiPath error:&e];
         if (!dstiContents)
            return [NSString stringWithFormat:@"@fm141 %@\r\n", e.description];
         
         NSUInteger dstiCount=dstiContents.count;
         for (NSString *srcvName in srciContents)
         {
            NSString *srcvPath=[srciPath stringByAppendingPathComponent:srcvName];
            BOOL sameFile=false;
            for (NSString *dstvName in dstiContents)
            {
               if ([fileManager contentsEqualAtPath:srcvPath andPath:[dstiPath stringByAppendingPathComponent:dstvName]])
               {
                  sameFile=true;
                  break;
               }
            }
            if (sameFile)
            {
               if (![fileManager removeItemAtPath:srcvPath error:&e])
                  return [NSString stringWithFormat:@"@fm159 %@\r\n", e.description];
            }
            else //move src file to dst folder
            {
               dstiCount++;
               while ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/%lu.dcm",dstiPath,dstiCount]])
               {
                  dstiCount++;
               }
               if (![fileManager moveItemAtPath:srcvPath toPath:[NSString stringWithFormat:@"%@/%lu.dcm",dstiPath,dstiCount] error:&e])
                   return [NSString stringWithFormat:@"@fm169 %@\r\n", e.description];
            }
         }
      }
   }
   else
   {
#pragma mark source instance is file
      
      if (!dstiExists) [fileManager moveItemAtPath:srciPath toPath:dstiPath error:nil];
      else if (dstiIsDir==false)//file already exists in dst
      {
         if ([fileManager contentsEqualAtPath:srciPath andPath:dstiPath])
         {
            if (![fileManager removeItemAtPath:srciPath error:&e])
               return [NSString stringWithFormat:@"@fm184 %@\r\n", e.description];
         }
         else //different files : keep both of them
         {
            NSString *tmpFile=[dstiPath stringByAppendingPathComponent:@"tmp"];
            if (![fileManager moveItemAtPath:dstiPath toPath:tmpFile error:&e])
               return [NSString stringWithFormat:@"@fm190 %@\r\n", e.description];
            if (![fileManager createDirectoryAtPath:dstiPath withIntermediateDirectories:true attributes:nil error:&e])
               return [NSString stringWithFormat:@"@fm192 %@\r\n", e.description];
            if (![fileManager moveItemAtPath:tmpFile toPath:[dstiPath stringByAppendingPathComponent:@"1.dcm"] error:&e])
               return [NSString stringWithFormat:@"@fm194 %@\r\n", e.description];
            if (![fileManager moveItemAtPath:srciPath toPath:[dstiPath stringByAppendingPathComponent:@"2.dcm"] error:&e])
               return [NSString stringWithFormat:@"@fm196 %@\r\n", e.description];
         }
      }
      else //folder already exists in dstiPath
      {
         BOOL sameFile=false;
         NSArray *dstiContents=[fileManager contentsOfDirectoryAtPath:dstiPath error:nil];
         NSUInteger dstiCount=dstiContents.count;
         for (NSString *dstvName in dstiContents)
         {
            if ([fileManager contentsEqualAtPath:srciPath andPath:[dstiPath stringByAppendingPathComponent:dstvName]])
            {
               sameFile=true;
               break;
            }
         }
         if (sameFile)
         {
            if (![fileManager removeItemAtPath:srciPath error:&e])
               return [NSString stringWithFormat:@"@fm215 %@\r\n", e.description];
         }
         else
         {
            dstiCount++;
            while ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/%lu.dcm",dstiPath,dstiCount]])
            {
               dstiCount++;
            }
            if (![fileManager moveItemAtPath:srciPath toPath:[NSString stringWithFormat:@"%@/%lu.dcm",dstiPath,dstiCount] error:&e])
               return [NSString stringWithFormat:@"@fm225 %@\r\n", e.description];
         }
      }
   }
   return @"";
}



//old
NSString *moveForD2ForD(NSFileManager *fileManager, NSString *srciPath, NSString *srcSuffix,NSString *dstePath,BOOL dstePathExists, NSString *iName)
{
   // srce < srci
   // srce < srci < copy
   // dste

   NSError *moveError=nil;
   
    
    NSString *dstiPath=[dstePath stringByAppendingPathComponent:iName];
    BOOL dstiIsDir=false;
    BOOL dstiExists=[fileManager fileExistsAtPath:dstiPath isDirectory:&dstiIsDir];
    
    //source is file or dir?
    BOOL srciIsDir=false;
    //BOOL srciExists=[fileManager fileExistsAtPath:srciPath isDirectory:&srciIsDir];
    if (srciIsDir) //source is a dir
    {
       NSArray *srciContents=[fileManager contentsOfDirectoryAtPath:srciPath error:nil];
       NSUInteger srciCount=srciContents.count;
       if (
             (srciCount==0)
           ||(
                (srciCount==1)
              &&[srciContents[0] hasPrefix:@"."]
              )
           )
       {
          if (![fileManager removeItemAtPath:srciPath error:&moveError]) return moveError.description;
          return @"";
       }

       if (!dstiExists)
       {
          if (![fileManager moveItemAtPath:srciPath toPath:dstiPath error:&moveError])
              return moveError.description;
          return @"";
       }
       //dstiExists
       if (!dstiIsDir)
       {
         for (NSString *srccName in srciContents)
         {
            NSString *srccPath=[srciPath stringByAppendingPathComponent:srccName];
            NSUInteger srccSize=[[fileManager attributesOfItemAtPath:srccPath error:nil] fileSize];
            if (
                  [srccName hasPrefix:@"."]
                ||([[fileManager attributesOfItemAtPath:dstiPath error:nil] fileSize]==srccSize)
               )
            {
                  [fileManager removeItemAtPath:srccPath error:nil];
                  srciCount--;
            }
         }
         if (srciCount > 0)
         {
            NSString *tmpFile=[[dstiPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"tmp"];
            if (![fileManager moveItemAtPath:dstiPath toPath:tmpFile error:&moveError]) return moveError.description;
            if (![fileManager createDirectoryAtPath:dstiPath withIntermediateDirectories:true attributes:nil error:&moveError]) return moveError.description;
            if (![fileManager moveItemAtPath:tmpFile toPath:[NSString stringWithFormat:@"%@/1.dcm",dstiPath] error:&moveError]) return moveError.description;

            NSUInteger counter=2;
            for (NSString *srccName in [fileManager contentsOfDirectoryAtPath:srciPath error:nil])
            {
               if (![fileManager moveItemAtPath:[srciPath stringByAppendingPathComponent:srccName] toPath:[NSString stringWithFormat:@"%@/%lul.dcm",dstiPath,(unsigned long)counter] error:&moveError])
                  return moveError.description;
               counter++;
            }
         }
         else [fileManager removeItemAtPath:srciPath error:nil];
      }
      else //dstIsDirectory
      {
         NSArray *dstiContents=[fileManager contentsOfDirectoryAtPath:dstiPath error:nil];
         NSUInteger dstcCount=dstiContents.count;
         for (NSString *srccName in srciContents)
         {
            NSString *srccPath=[srciPath stringByAppendingPathComponent:srccName];
            NSUInteger srccSize=[[fileManager attributesOfItemAtPath:srccPath error:nil] fileSize];

            //is there a copy with same size already in dst?
            BOOL sameSize=false;
            for (NSString *dstcName in dstiContents)
            {
               NSString *dstcPath=[dstiPath stringByAppendingPathComponent:dstcName];
               if ([[fileManager attributesOfItemAtPath:dstcPath error:nil] fileSize]==srccSize)
                     sameSize=true;
            }
            if (sameSize) [fileManager removeItemAtPath:srccPath error:nil];
            else //add iuid_timePath to iuidFailurePath
            {
               dstcCount++;
               [fileManager moveItemAtPath:srccPath toPath:[NSString stringWithFormat:@"%@/%lu.dcm",dstiPath,dstcCount] error:nil];
            }
         }
      }
   }
   else //source is a file
   {
      if (!dstiExists) [fileManager moveItemAtPath:srciPath toPath:dstiPath error:nil];
      else if (dstiIsDir==false)//file already exists in iuidFailurePath
      {
         //same size? remove it
         if ([[fileManager attributesOfItemAtPath:srciPath error:nil] fileSize]==[[fileManager attributesOfItemAtPath:dstiPath error:nil] fileSize])
            [fileManager removeItemAtPath:srciPath error:nil];
         else //different files : keep both of them
         {
            NSString *tmpFile=[[dstiPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"tmp"];
            if (![fileManager moveItemAtPath:dstiPath toPath:tmpFile error:&moveError]) return moveError.description;
            if (![fileManager createDirectoryAtPath:dstiPath withIntermediateDirectories:true attributes:nil error:&moveError]) return moveError.description;
            if (![fileManager moveItemAtPath:tmpFile toPath:[dstiPath stringByAppendingPathComponent:@"1.dcm"] error:&moveError]) return moveError.description;
            if (![fileManager moveItemAtPath:srciPath toPath:[dstiPath stringByAppendingPathComponent:@"2.dcm"] error:&moveError]) return moveError.description;
         }
      }
      else //folder already exists in dstiPath
      {
         NSUInteger srciPathSize=[[fileManager attributesOfItemAtPath:srciPath error:nil] fileSize];
         BOOL sameSize=false;
         NSArray *dstiContents=[fileManager contentsOfDirectoryAtPath:dstiPath error:nil];
         NSUInteger dstcCount=dstiContents.count;
         for (NSString *dstcName in dstiContents)
         {
            NSString *dstcPath=[dstiPath stringByAppendingPathComponent:dstcName];
            if ([[fileManager attributesOfItemAtPath:dstcPath error:nil] fileSize]==srciPathSize) sameSize=true;
         }
         if (sameSize) [fileManager removeItemAtPath:srciPath error:nil];
         else //add iuid_timePath to iuidFailurePath
            [fileManager moveItemAtPath:srciPath toPath:[NSString stringWithFormat:@"%@/%lu.dcm",dstiPath,dstcCount+1] error:nil];
      }
   }
   return @"";
}


int visibleFiles(NSFileManager *fileManager, NSArray *mountPoints, NSMutableArray *paths)
{
   BOOL isDirectory=false;
   for (NSString *mountPoint in mountPoints)
   {
      if ([mountPoint hasPrefix:@"."]) continue;
      
      NSString *noSymlink=[[mountPoint stringByExpandingTildeInPath] stringByResolvingSymlinksInPath];

      if ([fileManager fileExistsAtPath:noSymlink isDirectory:&isDirectory])
      {
         if (isDirectory)
         {
            NSError *error;
            NSArray *contents=[fileManager contentsOfDirectoryAtPath:noSymlink error:&error];
            
#pragma mark TODO agregar base URL prefix to each of the file names.
            
            if (error)
            {
               LOG_WARNING(@"bad directory path %@",noSymlink);
               return failure;
            }
            
            NSMutableArray *contentsPaths=[NSMutableArray array];
            for (NSString *name in contents)
            {
               [contentsPaths addObject:[mountPoint stringByAppendingPathComponent:name]];
            }
            
            if (visibleFiles(fileManager,contentsPaths, paths) != success) return failure;
         }
         else [paths addObject:noSymlink];
      }
   }
   return success;
}


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


NSString * moveDup(NSFileManager *fileManager, NSString *srcFile,NSString *dstFile)
{
   BOOL isDir;
   NSError *error;
   
   if ([fileManager fileExistsAtPath:dstFile isDirectory:&isDir])
   {
      if (isDir)
      {
         //directory already existing
         NSUInteger sameFileCount=[[fileManager contentsOfDirectoryAtPath:dstFile error:&error]count];
         if (![fileManager moveItemAtPath:srcFile toPath:[dstFile stringByAppendingPathComponent:[NSString stringWithFormat:@"%lu.dcm",sameFileCount + 1]] error:&error]) return error.description;
         return nil;
      }
      else
      {
         NSString *tmpFile=[[dstFile stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"1"];
         if (![fileManager moveItemAtPath:dstFile toPath:tmpFile error:&error]) return error.description;
         if (![fileManager createDirectoryAtPath:dstFile withIntermediateDirectories:true attributes:nil error:&error]) return error.description;
         if (![fileManager moveItemAtPath:tmpFile toPath:[dstFile stringByAppendingPathComponent:@"1.dcm"] error:&error]) return error.description;
         if (![fileManager moveItemAtPath:srcFile toPath:[dstFile stringByAppendingPathComponent:@"2.dcm"] error:&error]) return error.description;
         return nil;
      }
   }
   else if (![fileManager moveItemAtPath:srcFile toPath:dstFile error:&error]) return error.description;
   else return nil;
}


NSString *mergeDir(NSFileManager *fileManager, NSString *srcDir, NSString *dstDir)
{
   //returns:
   //  nil   srcDir moved
   //  @""   srcDir can be removed
   //  errorMessage
   NSError *err=nil;
   BOOL isDir=false;
   
   if (![fileManager fileExistsAtPath:dstDir])
   {
      if (![fileManager moveItemAtPath:srcDir toPath:dstDir error:&err])
         return [err description];
     return nil;
   }

   NSArray *children=[fileManager contentsOfDirectoryAtPath:srcDir error:nil];
   for (NSString *childName in children)
   {
      if ([childName hasPrefix:@"."]) continue;
      
      NSString *childDstPath=[dstDir stringByAppendingPathComponent:childName];
      NSString *childSrcPath=[srcDir stringByAppendingPathComponent:childName];
      [fileManager fileExistsAtPath:childSrcPath isDirectory:&isDir];
      if (isDir==false)
      {
         moveDup(fileManager,childSrcPath,childDstPath);
      }
      else //recursive
      {
         NSString *errMsg=mergeDir(fileManager,childSrcPath,childDstPath);
         if (errMsg && (errMsg.length)) return errMsg;
      }
   }
   if (![fileManager removeItemAtPath:srcDir error:&err]) return err.description;
   return nil;
}

@implementation fileManager

@end
