//
//  SimpleWebController.m
//  Creatures
//
//  Created by Michael Ash on Mon Jul 28 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "SimpleWebController.h"


@interface SimpleWebController (Private)

+ (BOOL)isWebKitAvailable;
- initWithURL:(NSURL *)url identifier:(NSString *)identifier;
- (void)reportError:(NSString *)errorString;

@end

@implementation SimpleWebController (Private)

+ (BOOL)isWebKitAvailable
{
    static BOOL _webkitAvailable=NO;
    static BOOL _initialized=NO;
	if (_initialized)
		return _webkitAvailable;
	NSBundle* webKitBundle;
	webKitBundle = [NSBundle bundleWithPath:@"/System/Library/Frameworks/WebKit.framework"];
	if (webKitBundle) {
		_webkitAvailable = [webKitBundle load];
	}
	_initialized=YES;
	return _webkitAvailable;
}

static NSMutableDictionary *controllersDictionary = nil;

- initWithURL:(NSURL *)url identifier:(NSString *)newIdentifier
{
	if((self = [super initWithWindowNibName:@"SimpleWebWindow"]))
	{
		theURL = [url retain];
		identifier = [newIdentifier copy];

		[[self window] setDelegate:self];
		[[self window] setTitle:identifier];
		[[self window] setFrameAutosaveName:identifier];
		[[self window] makeKeyAndOrderFront:self];
		
		[webView setFrameLoadDelegate:self];
		[webView takeStringURLFrom:self];

		if(controllersDictionary == nil)
			controllersDictionary = [[NSMutableDictionary alloc] init];
		[controllersDictionary setObject:self forKey:identifier];
	}
	return self;
}

- (void)reportError:(NSString *)errorString
{
	NSBeginAlertSheet(@"Could not load page.", @"OK", nil, nil, [self window], nil, nil, nil, nil, @"Error: %@.", errorString);
}

- stringValue
{
	return [theURL absoluteString];
}

@end

@implementation SimpleWebController

+ (void)loadWebKit
{
	[self isWebKitAvailable];
}

+ (void)openURL:(NSURL *)url withIdentifier:(NSString *)theIdentifier
{
	id controller = [controllersDictionary objectForKey:theIdentifier];
	if(controller)
	{
		[[controller window] makeKeyAndOrderFront:self];
		return;
	}
	
	if(![self isWebKitAvailable])
	{
		[[NSWorkspace sharedWorkspace] openURL:url];
		return;
	}

	[[[self alloc] initWithURL:url identifier:theIdentifier] release];
}

- initWithWindowNibName:name
{
	MyErrorLog(@"method should never be called");
	[self release];
	return nil;
}

- (void)dealloc
{
	[theURL release];
	[identifier release];
	[super dealloc];
}

- (BOOL)windowShouldClose:sender
{
	[controllersDictionary removeObjectForKey:identifier];
	return YES;
}

- (void)webView:sender didReceiveTitle:(NSString *)title forFrame:frame
{
    // Report feedback only for the main frame.
    if (frame == [sender mainFrame]){
        [[sender window] setTitle:title];
    }
}

- (void)webView:sender didFailProvisionalLoadWithError:error forFrame:frame
{
	[self reportError:[error localizedDescription]];
}

- (void)webView:sender didFailLoadWithError:error forFrame:frame
{
	[self reportError:[error localizedDescription]];
}

@end
