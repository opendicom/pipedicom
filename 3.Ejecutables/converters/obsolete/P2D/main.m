// P2D
// P Plist [[headstrings],[bodystrings],[headdatas],[bodydatas]]
// D DICOM binario
// mo logging

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[]) {
   @autoreleasepool {
      
      id data=nil;
      NSError *error=nil;
      NSMutableData *mutableData=[NSMutableData data];


      NSArray *args=[[NSProcessInfo processInfo] arguments];
      if (args.count > 1)
      {
         data=[NSData dataWithContentsOfFile:args[1]];
      }
      else
      {
         data = [[NSFileHandle fileHandleWithStandardInput] availableData];
      }

      id rootarray=
      [
       NSPropertyListSerialization
       propertyListWithData:data
       options:NSPropertyListImmutable
       format:nil
       error:&error
       ];
      if ([rootarray  isKindOfClass:[NSArray class]])
      {
         if ([rootarray count]==4)
         {
            NSArray *headdatas=rootarray[2];
            NSArray *bodydatas=rootarray[3];
            for (NSUInteger i=0; i<headdatas.count;i++)
            {
               [mutableData appendData:headdatas[i]];
               [mutableData appendData:bodydatas[i]];
            }

         }
      }
      
      [mutableData writeToFile:@"/dev/stdout" atomically:NO];

   }
   return 0;
}
