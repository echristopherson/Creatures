//
//  ToolInteractionView.h
//  Creatures
//
//  Created by Michael Ash on Sun Oct 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@class CreatureController;

@interface ToolInteractionView : NSQuickDrawView {  // inherits from NSQDV because
													// CreaturesView needs it
	IBOutlet CreatureController *controller;
	double zoomFactor;
	int pixWidth, pixHeight;
}

- (void)setController:(CreatureController *)c;
- (void)zoomIn:sender;
- (void)zoomOut:sender;
- (void)centerInView:(int)x :(int)y;

@end
