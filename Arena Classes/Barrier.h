//
//  Barrier.h
//  Creatures
//
//  Created by Michael Ash on Sun Jan 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PixmapUtils.h"


@class Arena;

@interface Barrier : NSObject {
	Arena *arena;
	int xLoc, yLoc;
}

- initWithArena:a location:(int)x :(int)y;
- (void)drawOnPixmap:(PixelUnion *)pixmap width:(int)pixWidth;
- (void)die;
- (int)xLoc;
- (int)yLoc;
- (BOOL)isCreature;
- (Pixel24)color;

@end
