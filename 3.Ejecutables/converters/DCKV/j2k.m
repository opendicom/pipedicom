//
//  j2k.m
//  DCKV
//
//  Created by jacquesfauquex on 2021-06-15.
//

#import "j2k.h"
#import "NSData+DCMmarkers.h"
#import "NSData+MD5.h"
#import "ODLog.h"


int compress(
             NSString *pixelUrl,
             NSData *pixelData,
             NSMutableDictionary *parsedAttrs,
             NSMutableDictionary *j2kBlobDict,
             NSMutableDictionary *j2kAttrs,
             NSMutableString *message
             )
{
   //16 or less bits...
   uint16 columns=[parsedAttrs[@"00000001_00280011-US"][0] unsignedShortValue];
   uint16 rows   =[parsedAttrs[@"00000001_00280010-US"][0] unsignedShortValue];
   uint16 samples=[parsedAttrs[@"00000001_00280002-US"][0] unsignedShortValue];
   uint16 bits=   [parsedAttrs[@"00000001_00280101-US"][0] unsignedShortValue];
   uint16 sign=   [parsedAttrs[@"00000001_00280103-US"][0] unsignedShortValue];
   
   NSString *F=[NSString stringWithFormat:@"%u,%u,%d,%d,%@",
               columns,
               rows,
               samples,
               bits,
               sign?@"s":@"u"
               ];
   
   NSArray *params=@[
      @"-F",
      F,
      @"-i",
      @"stdin.rawl",
      @"-o",
      @"stdout.j2k",
      @"-n",
      @"6",
      @"-r",
      @"6,5,4,3,2,1", //6 quality layers (6,5 or 4=base,3=fast,2=hres,1=idem)
      @"-p",
      @"RLCP",//B.11.1.2 Resolution-layer-component-position
      @"-TP",
      @"R"//Tile-parts based on quality
   ];
   
#pragma mark loop frames
   NSUInteger pixelTotalLength=pixelData.length;
   NSMutableArray *frames=[NSMutableArray array];
   NSUInteger frameTotal=1;//default
   if (parsedAttrs[@"00000001_00280008-IS"]) frameTotal=[parsedAttrs[@"00000001_00280008-IS"][0] unsignedIntegerValue];
   NSUInteger frameLength=pixelTotalLength / frameTotal;

   NSDate *start = [NSDate date];
   NSUInteger j2kTotalLength=0;
   for (NSUInteger frameNumber=0; frameNumber<frameTotal; frameNumber++)
   {
      NSMutableArray *pixelAttrArray=[NSMutableArray array];

      NSMutableData *j2kData=[NSMutableData data];
      NSTask *task=[[NSTask alloc]init];
      //task.environment=@{};
      task.currentDirectoryPath=@"/usr/local/bin";
      task.launchPath=@"/usr/local/bin/opj_compress";
      task.arguments=params;
      
      NSPipe *writePipe = [NSPipe pipe];
      NSFileHandle *writeHandle = [writePipe fileHandleForWriting];
      task.standardInput=writePipe;
      
      NSPipe* readPipe = [NSPipe pipe];
      NSFileHandle *readingFileHandle=[readPipe fileHandleForReading];
      task.standardOutput=readPipe;
      //task.standardError=readPipe;
      
      [task launch];
      switch (samples) {
         case 1:
            [writeHandle writeData:[pixelData subdataWithRange:NSMakeRange(frameNumber*frameLength,frameLength)]];
            break;
         case 3://RGB
         {
            NSData *RGB=[pixelData subdataWithRange:NSMakeRange(frameNumber*frameLength,frameLength)];
            NSMutableData *R=[NSMutableData data];
            NSMutableData *G=[NSMutableData data];
            NSMutableData *B=[NSMutableData data];
            unsigned char *pixel=(unsigned char *)[RGB bytes];
            unsigned long i=0;
            const NSUInteger afterLastR=RGB.length;
            while (i<afterLastR)
            {
               [R appendBytes:&pixel[i++] length:1];
               [G appendBytes:&pixel[i++] length:1];
               [B appendBytes:&pixel[i++] length:1];
            }
            [R appendData:G];
            [R appendData:B];
            [writeHandle writeData:R];
         }
            break;

         default:
            NSLog(@"%d samples pixels not handled",samples);
            break;
      }
      
      [writeHandle closeFile];
      
      NSData *dataPiped = nil;
      while((dataPiped = [readingFileHandle availableData]) && [dataPiped length])
      {
         [j2kData appendData:dataPiped];
      }

      //while( [task isRunning]) [NSThread sleepForTimeInterval: 0.1];
      //[task waitUntilExit];      // <- This is VERY DANGEROUS : the main runloop is continuing...
      //[aTask interrupt];
      [task waitUntilExit];
      int terminationStatus = [task terminationStatus];
      if (terminationStatus!=0)
      {
         [message appendFormat:@"ERROR task terminationStatus: %d\r\n",terminationStatus];//warning
         NSString *errorString=[[NSString alloc]initWithData:j2kData encoding:NSUTF8StringEncoding];
         [message appendFormat:@"compression J2K: %@",errorString];
         return failure;
      }
      else
      {
#pragma mark · subdivide j2kData
         j2kTotalLength+=j2kData.length;

         NSUInteger fragmentOffset=0;
         int fragmentCounter=0;
         NSUInteger j2kLength=j2kData.length;
         NSRange j2kRange=NSMakeRange(fragmentOffset,j2kLength);
         NSRange nextSOCRange=[j2kData rangeOfData:NSData.SOT
                                           options:0
                                             range:j2kRange];
         NSArray *SOCs=@[@"",@"",@"",@".dcmj2kbase",@".dcmj2kfast",@".dcmj2khres"];
         while (nextSOCRange.location != NSNotFound)
         {
            if (fragmentCounter > 2)
            {
               //register fragment
               NSString *fragmentName=[NSString stringWithFormat:@"%@-%08lu%@",pixelUrl,frameNumber+1,SOCs[fragmentCounter]];
               [pixelAttrArray addObject:fragmentName];

               [j2kBlobDict setObject:[j2kData subdataWithRange:NSMakeRange(fragmentOffset, nextSOCRange.location - fragmentOffset)] forKey:fragmentName];
               
               
               fragmentOffset=nextSOCRange.location;
            }

            j2kRange.location=nextSOCRange.location + nextSOCRange.length;
            j2kRange.length=j2kLength-j2kRange.location;
            nextSOCRange=[j2kData rangeOfData:NSData.SOT
                                              options:0
                                                range:j2kRange];
            fragmentCounter++;
         }
         
         //last tile-part (ended with EOC)
         nextSOCRange=[j2kData rangeOfData:NSData.EOC
                                           options:0
                                             range:j2kRange];
         NSString *fragmentName=[NSString stringWithFormat:@"%@-%08lu.dcmj2kidem",pixelUrl,frameNumber+1]
         ;
         [pixelAttrArray addObject:fragmentName];
         [j2kBlobDict setObject:[j2kData subdataWithRange:NSMakeRange(fragmentOffset, nextSOCRange.location + nextSOCRange.length - fragmentOffset)] forKey:fragmentName];



      }
      [frames addObject:[NSDictionary dictionaryWithObject:pixelAttrArray forKey:[NSString stringWithFormat:@"FrameBFHI#%08lu",frameNumber+1]]];
   }
   [message appendFormat:@"ele->j2k(s,KB,KB,*)\t%f\t%lu\t%lu\t%f\r\n",
    [[NSDate date] timeIntervalSinceDate:start],
    (unsigned long)pixelTotalLength/1024,
    (unsigned long)j2kTotalLength/1024,
    (float)pixelTotalLength / j2kTotalLength
    ];
#pragma mark · new attrs related to transfer syntax j2k

   [j2kAttrs setObject:frames forKey:@"00000001_7FE00010-OB"];
   [j2kAttrs setObject:@[@"1.2.840.10008.1.2.4.90"] forKey:@"00000001_00020010-UI"];
   [j2kAttrs setObject:@[[NSString stringWithFormat:@"lossless compression J2K codec openjpeg 2.5. Original data size:%lu md5:%@)",(unsigned long)pixelData.length,[pixelData MD5String]]] forKey:@"00000001_00082111-ST"];
   [j2kAttrs setObject:@[@"dcmj2kidem; 4 tile-part quality layer (50,20,10,1)"] forKey:@"00000001_00204000-2006LT"];

   return success;
}


@implementation j2k

@end
