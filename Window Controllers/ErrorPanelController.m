//
//  ErrorPanelController.m
//  Creatures
//
//  Created by Michael Ash on Sat Oct 11 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ErrorPanelController.h"


@implementation ErrorPanelController

+ (void)runPanelWithError:(NSString *)e report:(NSString *)r fatal:(BOOL)fatal
{
	ErrorPanelController *controller = [[self alloc] init];
	[controller setError:e];
	[controller setReport:r];
	[controller setFatal:fatal];
	[NSApp runModalForWindow:[controller window]];
	[controller release];
}

- init
{
	if((self = [super initWithWindowNibName:@"ErrorPanel"]))
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

- (void)awakeFromNib
{
	[errorField setStringValue:error];
	[reportTextView setString:report];
}

- (void)dealloc
{
	[error release];
	[report release];
	[super dealloc];
}

- (void)setError:(NSString *)e
{
	[error autorelease];
	error = [e copy];
}

- (void)setReport:(NSString *)r
{
	[report autorelease];
	report = [r copy];
}

- (void)setFatal:(BOOL)fatal
{
	if(!fatal)
	{
		MyNonfatalErrorLog(@"Nonfatal errors not supported in this controller");
	}
}

- (void)quit:sender
{
	[NSApp stopModal];
}

- (void)sendEmail:sender
{
	[[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
	[[NSPasteboard generalPasteboard] setString:report forType:NSStringPboardType];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:creaturesbugs@mikeash.com"]];
}

- (void)saveAs:sender
{
	[[NSApp delegate] saveAs:nil];
}

@end
