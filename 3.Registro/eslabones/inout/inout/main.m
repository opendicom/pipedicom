#import <Foundation/Foundation.h>

int main(int argc, const char * argv[]) {
   @autoreleasepool {
      NSData *stdinData =[[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
      
       NSLog(@"%@",stdinData.description);
   }
   return 0;
}
