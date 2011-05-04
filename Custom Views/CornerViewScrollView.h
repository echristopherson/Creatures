//
//  CornerViewScrollView.h
//  Creatures
//
//  Created by Michael Ash on Wed Oct 22 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CornerViewScrollView : NSScrollView {
	IBOutlet NSView *cornerView;
	BOOL enforceSquare;
}

- (void)setCornerView:(NSView *)view;
- (void)setEnforceSquareCornerView:(BOOL)e;

@end
