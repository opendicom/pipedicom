#import <Foundation/Foundation.h>

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
   if (terminationStatus!=0) NSLog(@"ERROR task terminationStatus: %d",terminationStatus);
   return terminationStatus;
}

NSData *dicomattrspk4study(NSString *select)
{
   NSMutableData *dicomattrsdata=[NSMutableData data];
   NSDictionary *sqlpwdenv=@{@"MYSQL_PWD":@"ridi.SUY2014-pacs"};
   NSString *bashcmdstring=[NSString stringWithFormat:@"echo \"%@\" |  /usr/local/mysql/bin/mysql -u root -h 10.200.120.19 --column-names=0 pacsdb",select];
   //NSLog(@"%@",bashcmdstring);
   NSData *bashcmddata=[bashcmdstring dataUsingEncoding:NSUTF8StringEncoding];
   if (!execTask(sqlpwdenv, @"/bin/bash", @[@"-s"], bashcmddata, dicomattrsdata)) return [NSData dataWithData:dicomattrsdata];
   return nil;
}

int main(int argc, const char * argv[]) {
   @autoreleasepool {
      NSData *stdinData =[[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
      NSString *stdinString=[[NSString alloc]initWithData:stdinData encoding:NSUTF8StringEncoding];

      NSData *pksData=dicomattrspk4study(stdinString);
      
      //NSString *pksString=[[NSString alloc]initWithData:pksdata encoding:NSUTF8StringEncoding];
      //NSArray *pksArray=[pksString componentsSeparatedByString:@"\n"];
      //NSLog(@"%@",pksArray.description);

      [[NSFileHandle fileHandleWithStandardOutput] writeData:pksData];
   }
   return 0;
}
