//
//  NSViewAdditions.h
//  Creatures
//
//  Created by Michael Ash on Fri Aug 29 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSView (ZoomAndCenterAdditions)

- (void)centerPointInView:(NSPoint)center;
- (NSPoint)centerVisiblePoint;

@end
