//
//  CreatureInspectorWindowController.h
//  Creatures
//
//  Created by Michael Ash on Thu Oct 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "VirtualMachine.h"


@class ComputingCreature;
@class Genome;

@interface CreatureInspectorWindowController : NSWindowController {
	IBOutlet NSTextField *mutationsField;
	IBOutlet NSTextField *energyField;
	IBOutlet NSTextField *ageField;
	IBOutlet NSTextField *messageField;
	IBOutlet NSTextField *pcField;

	IBOutlet NSTextView *disassemblyTextView;

	IBOutlet NSButton *showGenomeButton;

	int r[VM_NUM_REGS];

	Genome *creatureGenome;
}

+ (void)showWindowWithCreature:(ComputingCreature *)creature;
- (void)showGenome:sender;

@end
