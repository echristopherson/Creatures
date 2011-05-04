//
//  Creatures_Screen_SaverView.m
//  Creatures Screen Saver
//
//  Created by Michael Ash on Thu Jan 16 2003.
//  Copyright (c) 2003, __MyCompanyName__. All rights reserved.
//

#import "Creatures_Screen_SaverView.h"


@implementation Creatures_Screen_SaverView

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/30.0];
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
