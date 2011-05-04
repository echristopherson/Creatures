//
//  CreaturesScreenSaverView.m
//  CreaturesScreenSaver
//
//  Created by Michael Ash on Sat Aug 09 2003.
//  Copyright (c) 2003, __MyCompanyName__. All rights reserved.
//

#import "CreaturesScreenSaverView.h"
#import "CreatureController.h"
#import "CreaturesView.h"


@implementation CreaturesScreenSaverView

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/20.0];
		view = [[CreaturesView alloc] initWithFrame:frame];
		[self addSubview:view];
		controller = [[CreatureController alloc] init];
		[controller awakeFromNib]; // HAX
		[view setController:controller];
		[controller initDefaultArena];
		[controller openFilename:@"/Users/mikeash/test.creatures"]; // HAX
		[controller toggleRun:self];
    }
    return self;
}

- (void)startAnimation
{
    [super startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
}

- (void)animateOneFrame
{
    return;
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}

@end
