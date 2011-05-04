//
//  GenomeWindowController.h
//  Creatures
//
//  Created by mikeash on Wed Oct 31 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>


@class Genome;

@interface GenomeWindowController : NSWindowController {
	IBOutlet NSFormCell *populationCurrentField;
	IBOutlet NSFormCell *populationTotalField;
	IBOutlet NSFormCell *populationPeakField;
	IBOutlet NSFormCell *mutationsField;
	IBOutlet NSFormCell *lifetimeField;
	IBOutlet NSColorWell *colorWell;

	IBOutlet NSTextView *commentTextView;

	IBOutlet NSButton *showCOGButton;
	IBOutlet NSButton *parentButton;
	
	Genome *genome;
}

- initWithGenome:g;
- (void)update;
- (void)showParent:sender;
- (void)showDisassembly:sender;
- (void)showCOG:sender;
- (void)setColor:sender;

@end
