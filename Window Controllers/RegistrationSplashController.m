//
//  RegistrationSplashController.m
//  Creatures
//
//  Created by Michael Ash on Thu Oct 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "RegistrationSplashController.h"


@implementation RegistrationSplashController

+ (int)runRegistrationSplashWithMessage:(NSString *)message notYetDelay:(NSTimeInterval)delay;
{
	// returns 1 for 'purchase', 2 for 'enter serial number', 3 for 'not yet'
	RegistrationSplashController *controller = [[self alloc] init];
	[controller setMessage:message delay:delay];
	int returnCode = [NSApp runModalForWindow:[controller window]];
	[[controller window] orderOut:self];
	[controller release];
	return returnCode;
}

- init
{
	if((self = [super initWithWindowNibName:@"RegistrationSplash"]))
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

- (void)setMessage:(NSString *)message delay:(NSTimeInterval)delay;
{
	[self window]; // make sure the nib is loaded
	MyAssert(messageField != nil, @"error loading nib");

	[messageField setStringValue:message];

	[notYetButton setEnabled:NO];
	[self performSelector:@selector(enableNotYetButton) withObject:nil afterDelay:delay inModes:[NSArray arrayWithObject:NSModalPanelRunLoopMode]];
}

- (void)enableNotYetButton
{
	[notYetButton setEnabled:YES];
}

- (void)purchase:sender
{
	[NSApp stopModalWithCode:1];
}

- (void)doRegister:sender
{
	[NSApp stopModalWithCode:2];
}

- (void)notYet:sender
{
	[NSApp stopModalWithCode:3];
}

@end
