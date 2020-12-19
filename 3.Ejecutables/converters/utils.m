#import <Foundation/Foundation.h>

#pragma mark - terminal execution
/*
void logger(NSString *format, ... )
{
   //https://azizuysal.wordpress.com/2011/01/02/redirecting-nslog-output-to-a-file-on-demand-for-iphone-debugging/
   //writes to stderr which was defined as first arg of the function
   NSString *string=nil;
   
   va_list args;
   va_start(args, format);
   string=[[NSString alloc] initWithFormat:format arguments:args];
   va_end(args);
   
   NSFileHandle *e=[NSFileHandle fileHandleForUpdatingAtPath:@"/dev/stderr"];
   if (e)
   {
      [e seekToEndOfFile];
      [e writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
   }
}
*/

int execTask(NSDictionary *environment, NSString *launchPath, NSArray *launchArgs, NSData *writeData, NSMutableData *readData)
{
   NSTask *task=[[NSTask alloc]init];
   
   task.environment=environment;
   
   [task setLaunchPath:launchPath];
   [task setArguments:launchArgs];
   NSPipe *writePipe = [NSPipe pipe];
   NSFileHandle *writeHandle = [writePipe fileHandleForWriting];
   [task setStandardInput:writePipe];
   
   NSPipe* readPipe = [NSPipe pipe];
   NSFileHandle *readingFileHandle=[readPipe fileHandleForReading];
   [task setStandardOutput:readPipe];
   [task setStandardError:readPipe];
   
   [task launch];
   [writeHandle writeData:writeData];
   [writeHandle closeFile];
   
   NSData *dataPiped = nil;
   while((dataPiped = [readingFileHandle availableData]) && [dataPiped length])
   {
      [readData appendData:dataPiped];
   }
   //while( [task isRunning]) [NSThread sleepForTimeInterval: 0.1];
   //[task waitUntilExit];      // <- This is VERY DANGEROUS : the main runloop is continuing...
   //[aTask interrupt];
   
   [task waitUntilExit];
   int terminationStatus = [task terminationStatus];
   return terminationStatus;
}



#pragma mark - string functions

void trimLeadingSpaces(NSMutableString *mutableString)
{
   while ([mutableString hasPrefix:@" "])
   {
      [mutableString deleteCharactersInRange:NSMakeRange(0,1)];
   }
}

void trimTrailingSpaces(NSMutableString *mutableString)
{
   while ([mutableString hasSuffix:@" "])
   {
      [mutableString deleteCharactersInRange:NSMakeRange(mutableString.length-1,1)];
   }
}

void trimLeadingAndTrailingSpaces(NSMutableString *mutableString)
{
   trimLeadingSpaces(mutableString);
   trimTrailingSpaces(mutableString);
}



