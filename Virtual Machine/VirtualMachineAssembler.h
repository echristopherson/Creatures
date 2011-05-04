//
//  VirtualMachineAssembler.h
//  CVM
//
//  Created by Michael Ash on Sun Apr 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface VirtualMachineAssembler : NSObject {
	NSString *inString;
	NSScanner *scanner;
	NSMutableDictionary *opcodeDictionary;
	NSMutableDictionary *trapDictionary;
	NSMutableDictionary *labelDictionary;
	NSMutableArray *labelReferenceList;
	NSMutableArray *errors;
	NSMutableData *assembledData;
	int curLine;
	int curLineStartIndex;
	BOOL startNewLineForNextToken;
}

+ (NSString *)disassemblyForData:(NSData *)data;
- initWithString:(NSString *)s;
- (void)recordError:(NSString *)s;
- (void)scan;
- (void)sortErrors;
- (NSArray *)errors;
- (NSData *)assembledData;

@end
