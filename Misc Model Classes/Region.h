//
//  Region.h
//  Creatures
//
//  Created by Michael Ash on Sat Jan 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PixmapUtils.h"


@class Arena;

@interface Region : NSObject {
	id windowController;
	
	Arena *arena;
	
	int ulx, uly, lrx, lry;
	BOOL isSelected;

	double mutationRate;
	double foodGrowthRate;

	BOOL biasFoodGrowth;
	double biasFoodGrowthProportion;
	int biasFoodGrowthAmount;
}

- initWithRect:(NSRect)rect;
- (void)setRect:(NSRect)rect;
- (NSRect)rect;
- (void)setWindowController:controller;
- windowController;
- (void)setArena:a;
- (void)step;
- (void)drawOnPixmap:(PixelUnion *)pixmap width:(int)pixWidth;
- (BOOL)isSelected;
- (void)setIsSelected:(BOOL)s;
- (double)mutationRate;
- (void)setMutationRate:(double)r;
- (double)foodGrowthRate;
- (void)setFoodGrowthRate:(double)r;
- (BOOL)biasFoodGrowth;
- (void)setBiasFoodGrowth:(BOOL)a;
- (double)biasFoodGrowthProportion;
- (void)setBiasFoodGrowthProportion:(double)a;
- (int)biasFoodGrowthAmount;
- (void)setBiasFoodGrowthAmount:(int)a;

- (NSString *)coordinatesString;

@end
