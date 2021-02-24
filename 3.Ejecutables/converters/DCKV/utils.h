#import <Foundation/Foundation.h>


#pragma mark - terminal execution

//void logger(NSString *format, ... );
int execTask(NSDictionary *environment, NSString *launchPath, NSArray *launchArgs, NSData *writeData, NSMutableData *readData);


#pragma mark - string functions

void trimLeadingSpaces(NSMutableString *mutableString);
void trimTrailingSpaces(NSMutableString *mutableString);
void trimLeadingAndTrailingSpaces(NSMutableString *mutableString);
