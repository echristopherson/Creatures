//
//  SimpleWebController.h
//  Creatures
//
//  Created by Michael Ash on Mon Jul 28 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface SimpleWebController : NSWindowController {
	IBOutlet id webView;

	NSURL *theURL;
	NSString *identifier;
}

+ (void)loadWebKit; // has to be loaded right away to avoid evil posing problems
+ (void)openURL:(NSURL *)url withIdentifier:(NSString *)identifier;

@end
