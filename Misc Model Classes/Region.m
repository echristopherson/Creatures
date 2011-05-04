//
//  Region.m
//  Creatures
//
//  Created by Michael Ash on Sat Jan 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "Region.h"
#import "Arena.h"
#import "ComputingCreature.h"


@implementation Region

- initWithRect:(NSRect)rect
{
	if((self = [self init]))
	{
		[self setRect:rect];
	}
	return self;
}

- (void)setRect:(NSRect)rect
{
	ulx = rect.origin.x;
	uly = rect.origin.y;
	lrx = ulx + rect.size.width;
	lry = uly + rect.size.height;
}

- (NSRect)rect
{
	return NSMakeRect(ulx, uly, lrx - ulx, lry - uly);
}

- (void)setWindowController:controller
{
	[windowController autorelease];
	windowController = [controller retain];
}

- windowController
{
	return windowController;
}

- (void)setArena:a
{
	arena = a;
}

- (void)step
{
	int numTimes;
	int i;
	int xSize = [arena xSize];
	int ySize = [arena ySize];
	eEdgeType edgeBehavior = [arena edgeBehavior];
	
	numTimes = (lrx - ulx + 1) * (lry - uly + 1) * foodGrowthRate;
	for(i = 0; i < numTimes; i++)
	{
		int x = ulx + random() % (lrx - ulx + 1);
		int y = uly + random() % (lry - uly + 1);

		int origVal = [arena foodValueAt:x :y];
		if(origVal > 1)
		{
			int r = random();
			int xory = r & 1;
			int plusorminus = r & 2;
			if(xory)
			{
				if(plusorminus)
					x += 1;
				else
					x -= 1;
			}
			else
			{
				if(plusorminus)
					y += 1;
				else
					y -= 1;
			}
			if(x < 0 || y < 0 || x >= xSize || y >= ySize)
			{
				if(edgeBehavior != kEdgeWrap)
					return;
				else
				{
					x = (x + xSize) % xSize;
					y = (y + ySize) % ySize;
				}
			}
			if([arena creatureFor:x :y] != nil)
				return;
			if([arena foodValueAt:x :y] == 0)
			{
				int newVal;

				if(biasFoodGrowth)
				{
					if((random() & 65535) < biasFoodGrowthProportion * 65536)
					{
						if(origVal < biasFoodGrowthAmount)
							newVal = origVal + 1;
						else
							newVal = origVal - 1;
					}
					else
					{
						if(origVal < biasFoodGrowthAmount)
							newVal = origVal - 1;
						else
							newVal = origVal + 1;
					}
				}
				else
				{
					if(r & 8)
						newVal = origVal + 1;
					else
						newVal = origVal - 1;
				}
				if(newVal > 255)
					newVal = 255;
				else if(newVal < 1)
					newVal = 1;
				[arena setFoodValue:newVal at:x :y];
			}
		}
	}

	numTimes = (lrx - ulx + 1) * (lry - uly + 1) * mutationRate;
	for(i = 0; i < numTimes; i++)
	{
		int x = ulx + random() % (lrx - ulx + 1);
		int y = uly + random() % (lry - uly + 1);
		id obj = [arena creatureFor:x :y];
		if(obj && [obj isCreature])
			[obj mutate];
	}
}

- (void)drawOnPixmap:(PixelUnion *)pixmap width:(int)pixWidth
{
	int xStarts[4] = {ulx, ulx, ulx, lrx};
	int yStarts[4] = {uly, uly, lry, uly};
	int xDirs[4] = {1, 0, 1, 0};
	int yDirs[4] = {0, 1, 0, 1};

	int i;

	int arenaYSize = [arena ySize];
	
	PixelUnion pixel;
	pixel.components.a = 255.0;
	pixel.components.r = 255.0/2;
	pixel.components.g = 255.0/2;
	pixel.components.b = 255.0/2;

	for(i = 0; i < 4; i++)
	{
		int xLoc, yLoc;
		for(xLoc = xStarts[i], yLoc = yStarts[i]; xLoc <= lrx && yLoc <= lry; xLoc += xDirs[i], yLoc += yDirs[i])
		{
			if(!isSelected || ((xLoc + yLoc) & 1) == 0)
				pixmap[xLoc + (arenaYSize - yLoc - 1) * pixWidth] = pixel;
		}
	}
}

- (BOOL)isSelected
{
	return isSelected;
}

- (void)setIsSelected:(BOOL)s
{
	isSelected = s;
}

- (double)mutationRate
{
	return mutationRate;
}

- (void)setMutationRate:(double)r
{
	mutationRate = r;
}

- (double)foodGrowthRate
{
	return foodGrowthRate;
}

- (void)setFoodGrowthRate:(double)r
{
	foodGrowthRate = r;
}

- (BOOL)biasFoodGrowth
{
	return biasFoodGrowth;
}

- (void)setBiasFoodGrowth:(BOOL)a
{
	biasFoodGrowth = a;
}

- (double)biasFoodGrowthProportion
{
	return biasFoodGrowthProportion;
}

- (void)setBiasFoodGrowthProportion:(double)a
{
	biasFoodGrowthProportion = a;
}

- (int)biasFoodGrowthAmount
{
	return biasFoodGrowthAmount;
}

- (void)setBiasFoodGrowthAmount:(int)a
{
	biasFoodGrowthAmount = a;
}


- (NSString *)coordinatesString
{
	return [NSString stringWithFormat:@"(%d, %d, %d, %d)", ulx, uly, lrx, lry];
}


- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeInt:ulx forKey:@"ulx"];
	[coder encodeInt:uly forKey:@"uly"];
	[coder encodeInt:lrx forKey:@"lrx"];
	[coder encodeInt:lry forKey:@"lry"];
	[coder encodeDouble:mutationRate forKey:@"mutationRate"];
	[coder encodeDouble:foodGrowthRate forKey:@"foodGrowthRate"];
	[coder encodeBool:biasFoodGrowth forKey:@"biasFoodGrowth"];
	[coder encodeDouble:biasFoodGrowthProportion forKey:@"biasFoodGrowthProportion"];
	[coder encodeInt:biasFoodGrowthAmount forKey:@"biasFoodGrowthAmount"];
	[coder encodeObject:arena forKey:@"arena"];
}

- initWithCoder:(NSCoder *)coder
{
	ulx = [coder decodeIntForKey:@"ulx"];
	uly = [coder decodeIntForKey:@"uly"];
	lrx = [coder decodeIntForKey:@"lrx"];
	lry = [coder decodeIntForKey:@"lry"];
	biasFoodGrowth = [coder decodeBoolForKey:@"biasFoodGrowth"];
	biasFoodGrowthProportion = [coder decodeDoubleForKey:@"biasFoodGrowthProportion"];
	biasFoodGrowthAmount = [coder decodeIntForKey:@"biasFoodGrowthAmount"];
	mutationRate = [coder decodeDoubleForKey:@"mutationRate"];
	foodGrowthRate = [coder decodeDoubleForKey:@"foodGrowthRate"];
	arena = [coder decodeObjectForKey:@"arena"];
	
	return self;
}

@end
