//
//  FamilyTreeWindowController.m
//  Creatures
//
//  Created by Michael Ash on Fri Mar 15 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "FamilyTreeWindowController.h"


@implementation FamilyTreeWindowController

static FamilyTreeWindowController *controller = nil;

+ controller
{
	if(controller == nil)
		controller = [[self alloc] init];

	return controller;
}

+ (void)reset
{
	[[controller window] performClose:nil];
	[controller release];
	controller = nil;
}

- init
{
	if((self = [super initWithWindowNibName:@"FamilyTreeWindow"]))
	{
		[self retain];
	}
	return self;
}

- initWithWindowNibName:name
{
	MyErrorLog(@"method should never be called");
	[self release];
	return nil;	
}

- (FamilyTreeView *)treeView
{
	return treeView;
}

/*- (BOOL)windowShouldClose:sender
{
	[self release];
	return YES;
}*/

@end
