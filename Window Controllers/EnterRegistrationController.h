//
//  EnterRegistrationController.h
//  Creatures
//
//  Created by Michael Ash on Wed Oct 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface EnterRegistrationController : NSWindowController {
	IBOutlet NSTextField *nameField;
	IBOutlet NSTextField *serialNumberField;
	IBOutlet NSButton *registerButton;
}

+ (void)doRegister;
- (void)doRegister:sender;
- (void)purchase:sender;
- (void)cancel:sender;

@end
