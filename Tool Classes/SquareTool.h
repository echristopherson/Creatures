//
//  SquareTool.h
//  Creatures
//
//  Created by Michael Ash on Sat Jan 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DrawingTool.h"


@class GenomeDragAcceptTextField;

@interface SquareTool : DrawingTool {
	IBOutlet NSMatrix *creatureTypeMatrix;
	IBOutlet NSTextField *foodValueField;
	IBOutlet NSButton *overwriteCheckbox;
	IBOutlet GenomeDragAcceptTextField *genomeField;
	IBOutlet NSSlider *radiusSlider;
	IBOutlet NSSlider *coverageSlider;

	NSTrackingRectTag trackingRectTag;
	int tracking;
	
	int curx, cury;
}

@end
