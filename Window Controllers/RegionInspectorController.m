//
//  RegionInspectorController.m
//  Creatures
//
//  Created by Michael Ash on Sat Jan 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "RegionInspectorController.h"
#import "Region.h"


@implementation RegionInspectorController

- initWithRegion:(Region *)r
{
	if((self = [super initWithWindowNibName:@"RegionInspector"]))
	{
		region = r;
	}
	return self;
}

- initWithWindowNibName:name
{
	MyErrorLog(@"method should never be called");
	[self release];
	return nil;
}

- (BOOL)windowShouldClose:sender
{
	[region setWindowController:nil];
	return YES;
}

- (void)windowDidLoad
{
	[coordinatesField setStringValue:[region coordinatesString]];
	[mutationRateField setDoubleValue:[region mutationRate]];
	[foodGrowthRateField setDoubleValue:[region foodGrowthRate]];
	[biasFoodProportionField setDoubleValue:([region biasFoodGrowthProportion]*100.0)];
	[biasFoodAmountField setIntValue:[region biasFoodGrowthAmount]];
	if([region biasFoodGrowth])
	{
		[biasFoodCheckbox setState:NSOnState];
		[biasFoodProportionField setEnabled:YES];
		[biasFoodAmountField setEnabled:YES];
	}
	else
	{
		[biasFoodCheckbox setState:NSOffState];
		[biasFoodProportionField setEnabled:NO];
		[biasFoodAmountField setEnabled:NO];
	}
	[[self window] setDelegate:self];
}

- (IBAction)mutationRateChanged:sender
{
	[region setMutationRate:[sender doubleValue]];
}

- (IBAction)foodGrowthRateChanged:sender
{
	[region setFoodGrowthRate:[sender doubleValue]];
}

- (IBAction)biasFoodCheckboxClicked:sender
{
	if([sender state] == NSOnState)
	{
		[region setBiasFoodGrowth:YES];
		[biasFoodProportionField setEnabled:YES];
		[biasFoodAmountField setEnabled:YES];
	}
	else
	{
		[region setBiasFoodGrowth:NO];
		[biasFoodProportionField setEnabled:NO];
		[biasFoodAmountField setEnabled:NO];
	}
}

- (IBAction)biasFoodProportionChanged:sender
{
	[region setBiasFoodGrowthProportion:([sender doubleValue]/100.0)];
}

- (IBAction)biasFoodAmountChanged:sender
{
	[region setBiasFoodGrowthAmount:[sender intValue]];
}

@end
