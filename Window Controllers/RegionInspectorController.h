//
//  RegionInspectorController.h
//  Creatures
//
//  Created by Michael Ash on Sat Jan 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Region;

@interface RegionInspectorController : NSWindowController {
	IBOutlet NSTextField *coordinatesField;
	IBOutlet NSTextField *mutationRateField;
	IBOutlet NSTextField *foodGrowthRateField;
	IBOutlet NSButton *biasFoodCheckbox;
	IBOutlet NSTextField *biasFoodProportionField;
	IBOutlet NSTextField *biasFoodAmountField;
	
	Region *region;
}

- initWithRegion:(Region *)r;
- (IBAction)mutationRateChanged:sender;
- (IBAction)foodGrowthRateChanged:sender;
- (IBAction)biasFoodCheckboxClicked:sender;
- (IBAction)biasFoodProportionChanged:sender;
- (IBAction)biasFoodAmountChanged:sender;

@end
