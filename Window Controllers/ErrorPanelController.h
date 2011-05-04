//
//  ErrorPanelController.h
//  Creatures
//
//  Created by Michael Ash on Sat Oct 11 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface ErrorPanelController : NSWindowController {
	IBOutlet NSTextField *errorField;
	IBOutlet NSTextView *reportTextView;
	IBOutlet NSTextField *cantSaveMessage;
	IBOutlet NSButton *quitButton;

	NSString *error;
	NSString *report;
}

+ (void)runPanelWithError:(NSString *)e report:(NSString *)r fatal:(BOOL)fatal;
- (void)setError:(NSString *)e;
- (void)setReport:(NSString *)r;
- (void)setFatal:(BOOL)fatal;
- (void)quit:sender;
- (void)sendEmail:sender;
- (void)saveAs:sender;

@end
