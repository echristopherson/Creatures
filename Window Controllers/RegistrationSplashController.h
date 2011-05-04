//
//  RegistrationSplashController.h
//  Creatures
//
//  Created by Michael Ash on Thu Oct 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface RegistrationSplashController : NSWindowController {
	IBOutlet NSButton *notYetButton;
	IBOutlet NSTextField *messageField;
}

+ (int)runRegistrationSplashWithMessage:(NSString *)message notYetDelay:(NSTimeInterval)delay;
	// returns 1 for 'purchase', 2 for 'enter serial number', 3 for 'not yet'

- (void)setMessage:(NSString *)message delay:(NSTimeInterval)delay;
- (void)purchase:sender;
- (void)doRegister:sender;
- (void)notYet:sender;

@end
