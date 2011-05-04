//
//  GenomeAssemblerController.h
//  Creatures
//
//  Created by Michael Ash on Tue Jun 03 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>


@class VirtualMachineAssembler;

@interface GenomeAssemblerController : NSWindowController {
	IBOutlet NSButton *saveButton;
	IBOutlet NSTextView *textView;
	IBOutlet NSDrawer *errorDrawer;
	IBOutlet NSTableView *errorTable;

	NSArray *errors;
	VirtualMachineAssembler *assembler;
}

- initWithString:(NSString *)s;
- (IBAction)assembleClicked:sender;
- (IBAction)saveClicked:sender;
- (IBAction)errorTableClicked:sender;

@end
