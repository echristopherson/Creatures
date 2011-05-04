//
//  EnterRegistrationController.m
//  Creatures
//
//  Created by Michael Ash on Wed Oct 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "EnterRegistrationController.h"


@implementation EnterRegistrationController

+ (void)doRegister
{
	EnterRegistrationController *controller = [[self alloc] init];
	[NSApp runModalForWindow:[controller window]];
	[[controller window] orderOut:self];
	[controller release];
}

- init
{
	if((self = [super initWithWindowNibName:@"EnterRegistration"]))
	{
		// stuff
	}
	return self;
}

- initWithWindowNibName:name
{
	MyErrorLog(@"method should never be called");
	[self release];
	return nil;
}

- (void)controlTextDidChange:(NSNotification *)obj
{
	if([[nameField stringValue] length] && [[serialNumberField stringValue] length])
		[registerButton setEnabled:YES];
	else
		[registerButton setEnabled:NO];
}

- (void)doRegister:sender
{
	NSRunAlertPanel(NSLocalizedString(@"Registration successful!", @""), NSLocalizedString(@"Thank you for registering Creatures!", @""), NSLocalizedString(@"OK", @"default button title"), nil, nil);
	[NSApp stopModal];
}

- (void)purchase:sender
{
	[[self window] orderOut:self];
	[NSApp stopModal];
}

- (void)cancel:sender
{
	[NSApp stopModal];
}

@end
