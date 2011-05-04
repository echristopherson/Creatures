//
//  VirtualMachineError.h
//  Creatures
//
//  Created by Michael Ash on Tue Jun 03 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface VirtualMachineError : NSObject {
	NSString *message;
	int line;
	int character;
}

+ errorWithLine:(int)l character:(int)c message:(NSString *)m;
- initWithLine:(int)l character:(int)c message:(NSString *)m;
- (NSString *)message;
- (int)line;
- (int)character;
- (NSComparisonResult)comparePosition:other;

@end
