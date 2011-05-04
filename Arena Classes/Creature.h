//
//  Creature.h
//  Creatures
//
//  Created by mikeash on Thu Oct 25 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "Arena.h"
#import "PixmapUtils.h"

@interface Creature : NSObject <NSCoding> {
	id arena;
	
	int xLoc, yLoc;
	Pixel24 color;
	//NSColor *color;
	
	int moveDirection;
	int lastMoveTime;
	
	int age;

	int isDead;
	
	float energy;
}

+ (int)deaths;
- initWithArena:(Arena *)a location:(int)x :(int)y;
- (BOOL)moveToPointX:(int)x Y:(int)y;
- (BOOL)canMoveToPoint:(int)x :(int)y;
- attemptSpawnAt:(int)x :(int)y withClass:class;
- (BOOL)attemptEatAt:(int)x :(int)y;
- (void)attemptGiveEnergy:(float)e At:(int)x :(int)y;
- (void)setDirection:(int)dir;
- (void)addEnergy:(float)e;
- (void)setNeedsRedraw;
- (void)die;
- (void)step;
//- (void)draw;
- (void)eraseIfNeeded;
- (void)drawIfNeeded;
- (void)drawOnPixmap:(PixelUnion *)pixmap width:(int)pixWidth;
- (void)eraseIfNeededOnPixmap:(PixelUnion *)pixmap width:(int)pixWidth;
- (void)drawIfNeededOnPixmap:(PixelUnion *)pixmap width:(int)pixWidth;
- (int)direction;
- (int)xLoc;
- (int)yLoc;
- (BOOL)isCreature;
- (NSPoint)creatureLocation;
- (float)energy;
- (int)age;
- (void)setAge:(int)a;
- (Pixel24)color;
- (void)setColor:(Pixel24)c;

@end
