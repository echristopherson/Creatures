//
//  Creature.m
//  Creatures
//
//  Created by mikeash on Thu Oct 25 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "Creature.h"

#import <objc/objc-class.h>

@implementation Creature

static int deaths = 0;

static unsigned int memoryAllocated = 0;
static unsigned int allocations = 0, deallocations = 0;

static int arenaXSize;
static int arenaYSize;


+ (void)initialize
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(arenaChanged:) name:@"ArenaChanged" object:[Arena class]];
}

+ (void)arenaChanged:(NSNotification *)notification
{
	id a = [notification userInfo];
	arenaXSize = [a xSize];
	arenaYSize = [a ySize];
}

+ (int)deaths
{
	return deaths;
}

+ allocWithZone:(NSZone *)zone
{
	memoryAllocated += ((struct objc_class *)self)->instance_size;
	allocations++;
	return [super allocWithZone:zone];
}

- init
{
	if((self = [super init]))
	{
		energy = 10;
	}
	return self;
}

- initWithArena:(Arena *)a location:(int)x :(int)y
{
	arena = a;
	if((self = [self init]))
	{
		xLoc = x;
		yLoc = y;

		if(x >= 0 && x < [arena xSize] && y >= 0 && y < [arena ySize] && [arena creatureFor:x :y] == nil)
		{
			[arena addCreature:self];
			[arena registerCreature:self at:x :y];

			//[self setColor:[NSColor blueColor]];
			//[self setNeedsRedraw];
		}
		else
		{
			//((FoodCreature *)self)->stillborn = 'stbn';
			[self release];
			return nil;
		}
	}
	return self;
}

- (BOOL)moveToPointX:(int)x Y:(int)y
{
	// *** needs fixing: energy cost should vary somehow with speed (how long it's been since the last move)
	int dx, dy;
	
	if(x < 0 || y < 0 || x >= arenaXSize || y >= arenaYSize)
	{
		switch([arena edgeBehavior])
		{
			case kEdgeWrap:
				x = (x + arenaXSize) % arenaXSize;
				y = (y + arenaYSize) % arenaYSize;
				break;
			case kEdgeBlock:
				return NO;
				break;
			case kEdgeKill:
				[self die];
				return NO;
				break;
		}
	}

	dx = x - xLoc;
	dy = y - yLoc;
	//if(dx > 1 || dx < -1 || dy > 1 || dy < -1)
	//	return NO;

	if([arena creatureFor:x :y])
		return NO;
//	if([arena foodValueAt:x :y] > 0)
//		return NO;
	if([arena foodValueAt:x :y] > 0)
	{
		return NO;
		/*
		 All this crap is to allow creatures to push food around.
		 I'm disabling it because I don't feel like testing it out
		 or putting in a checkbox to control it.
		 */
		/*
		int foodMoveX = xLoc + 2*dx, foodMoveY = yLoc + 2*dy;
		if(foodMoveX < 0 || foodMoveY < 0 || foodMoveX >= arenaXSize || foodMoveY >= arenaYSize)
		{
			switch([arena edgeBehavior])
			{
				case kEdgeWrap:
					foodMoveX = (foodMoveX + arenaXSize) % arenaXSize;
					foodMoveY = (foodMoveY + arenaYSize) % arenaYSize;
					break;
				case kEdgeBlock:
				case kEdgeKill:
					return NO;
					break;
			}
		}
		 if([arena foodValueAt:foodMoveX :foodMoveY] > 0 || [arena creatureFor:foodMoveX :foodMoveY])
			return NO;
		else
		{
			[arena setFoodValue:[arena foodValueAt:x :y] at:foodMoveX :foodMoveY];
			[arena setFoodValue:0 at:x :y];
		}*/
	}
	
	[arena removeCreature:self at:xLoc :yLoc];
	xLoc = x;
	yLoc = y;
	[arena registerCreature:self at:xLoc :yLoc];
	energy -= 2.0 / (double)((age - lastMoveTime) * (age - lastMoveTime));
	lastMoveTime = age;
	//[self setNeedsRedraw];
	return YES;
}

- (BOOL)canMoveToPoint:(int)x :(int)y
{
	if(x < 0 || y < 0 || x >= arenaXSize || y >= arenaYSize)
	{
		switch([arena edgeBehavior])
		{
			case kEdgeWrap:
				x = (x + arenaXSize) % arenaXSize;
				y = (y + arenaYSize) % arenaYSize;
				break;
			case kEdgeBlock:
			case kEdgeKill:
				return NO;
				break;
		}
	}

	if([arena creatureFor:x :y])
		return NO;
	if([arena foodValueAt:x :y] > 0)
		return NO;

	return YES;
}

- attemptSpawnAt:(int)x :(int)y withClass:class
{
	const int kSpawnEnergy = [arena spawnEnergy];

	if(energy >= kSpawnEnergy)
	{
		Creature *newCreature;
		int dx, dy;
		
		energy -= kSpawnEnergy;
		
		dx = x - xLoc;
		dy = y - yLoc;
		if(x < 0 || y < 0 || x >= arenaXSize || y >= arenaYSize)
		{
			switch([arena edgeBehavior])
			{
				case kEdgeWrap:
					x = (x + arenaXSize) % arenaXSize;
					y = (y + arenaYSize) % arenaYSize;
					break;
				case kEdgeBlock:
				case kEdgeKill:
					return nil;
					break;
			}
		}
		if(dx < -1 || dx > 1 || dy < -1 || dy > 1 || (dx == 0 && dy == 0))
			return nil;
		if([arena creatureFor:x :y])
			return nil;
		if([arena foodValueAt:x :y] > 0)
			return nil;
		
		newCreature = [[class alloc] initWithArena:arena location:x :y];

		[newCreature setColor:color];
		
		[newCreature setDirection:moveDirection];
		[newCreature release];
		//NSLog(@"Spawn! (%f, %f)", loc.x, loc.y);
		return newCreature;
	}
	else
	{
		energy /= 2;
		return nil;
	}
}

- (BOOL)attemptEatAt:(int)x :(int)y
{
	const int kEatEnergy = 2;

	if(energy >= kEatEnergy)
	{
		int dx, dy;
		id obj;
		
		energy -= kEatEnergy;
		
		dx = x - xLoc;
		dy = y - yLoc;
		if(x < 0 || y < 0 || x >= arenaXSize || y >= arenaYSize)
		{
			switch([arena edgeBehavior])
			{
				case kEdgeWrap:
					x = (x + arenaXSize) % arenaXSize;
					y = (y + arenaYSize) % arenaYSize;
					break;
				case kEdgeBlock:
				case kEdgeKill:
					return NO;
					break;
			}
		}
		if(dx < -1 || dx > 1 || dy < -1 || dy > 1)
			return NO;

		obj = [arena creatureFor:x :y];
		if(obj == nil)
		{
			int foodValue = [arena foodValueAt:x :y];
			if(foodValue == 0)
			{
				return NO;
			}
			else
			{
				energy += foodValue;
				[arena setFoodValue:0 at:x :y];
				return YES;
			}
		}
		else if([obj isCreature])
		{
			int totalEnergy = energy + [obj energy];
			if(random() % totalEnergy < energy)
			{
				energy += [obj energy];
				[obj die];
				return YES;
			}
			else
				return NO;
		}
		else
			return NO;
	}
	else
	{
		energy -= kEatEnergy;
		return NO;
	}
}

- (void)attemptGiveEnergy:(float)e At:(int)x :(int)y
{
	if(energy >= e && e > 0)
	{
		int dx, dy;
		id obj;
		
		dx = x - xLoc;
		dy = y - yLoc;
		if(x < 0 || y < 0 || x >= arenaXSize || y >= arenaYSize)
		{
			switch([arena edgeBehavior])
			{
				case kEdgeWrap:
					x = (x + arenaXSize) % arenaXSize;
					y = (y + arenaYSize) % arenaYSize;
					break;
				case kEdgeBlock:
				case kEdgeKill:
					return;
					break;
			}
		}
		if(dx < -1 || dx > 1 || dy < -1 || dy > 1)
			return;
		//if(dx * dx + dy * dy < size * size)
		//	return NO;

		obj = [arena creatureFor:x :y];
		if(obj != nil && [obj isCreature])
		{
			energy -= e;
			[obj addEnergy:e];
		}
	}
}

- (void)setDirection:(int)dir
{
	moveDirection = dir;
}

- (void)addEnergy:(float)e
{
	energy += e;
}

- (void)setNeedsRedraw
{
	//needsRedraw = 1;
	//[arena addToRedrawList:self];
}

- (void)die
{
	//NSLog(@"Die! age = %d", age);
	//[arena addToDeathList:self];
	//[self setNeedsRedraw];

	isDead = 1;
	
	[arena removeCreature:self at:xLoc :yLoc];
	[arena removeCreature:self];
	//NSLog(@"0x%x died", self);
}

- (void)step
{
	if(isDead)
	{
		//NSLog(@"Dead creature 0x%x stepping!", self);
		return;
	}

	if(age < 0)
		return;
	age++;
	
	//if(age == 251)
		//[self setColor:[NSColor blueColor]];
	
	if(energy < 2 || isnan(energy) || !isfinite(energy)) // || energy > 1000000)
		[self die];
	else if(age < 250)
	{
		/*int numNeighbors = [[arena creaturesNearPoint:location] count] - 1;
		int energyChange = 6 - numNeighbors;
		if(energyChange > 0)
			energy += energyChange;
		*/
		//energy += 2;
	}
	/*else*/
	energy -= .125;
	if(energy > 1000)
		energy -= (energy - 100) * 0.02;
}

/*- (void)draw
{
	NSRect rect;
	rect.origin.x = xLoc;
	rect.origin.y = yLoc;
	rect.size.width = 1;
	rect.size.height = 1;
	
	[color set];
	[NSBezierPath fillRect:rect];
}*/

- (void)eraseIfNeeded
{
	MyErrorLog(@"method shouldn't be called");
}

- (void)drawIfNeeded
{
	MyErrorLog(@"method shouldn't be called");
}

- (void)drawOnPixmap:(PixelUnion *)pixmap width:(int)pixWidth
{
	PixelUnion pixel;
	
	pixel.components.a = 255.0;
	pixel.components.r = color.r;
	pixel.components.g = color.g;
	pixel.components.b = color.b;
	MyAssert(xLoc >= 0 && yLoc >= 0 && xLoc < arenaXSize && yLoc < arenaYSize, @"Bad location (%d, %d)", xLoc, yLoc);
	pixmap[xLoc + (arenaYSize - yLoc - 1) * pixWidth] = pixel;
}

- (void)eraseIfNeededOnPixmap:(PixelUnion *)pixmap width:(int)pixWidth
{
	MyErrorLog(@"method shouldn't be called");
}

- (void)drawIfNeededOnPixmap:(PixelUnion *)pixmap width:(int)pixWidth
{
	MyErrorLog(@"method shouldn't be called");
}

- (int)direction
{
	return moveDirection;
}

- (int)xLoc
{
	return xLoc;
}

- (int)yLoc
{
	return yLoc;
}

- (BOOL)isCreature
{
	return YES;
}

- (NSPoint)creatureLocation
{
	NSPoint loc = {xLoc, yLoc};
	return loc;
}

- (float)energy
{
	return energy;
}

- (int)age
{
	return age;
}

- (void)setAge:(int)a
{
	age = a;
}

- (Pixel24)color
{
	return color;
}

- (void)setColor:(Pixel24)c
{
	color = c;
	if([arena continuousUpdates])
	{
		[arena removeCreature:self at:xLoc :yLoc];
		[arena registerCreature:self at:xLoc :yLoc];
		// remove and re-add to get the changed color
	}
}


- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeInt:arenaXSize forKey:@"arenaXSize"];
	[coder encodeInt:arenaYSize forKey:@"arenaYSize"];
	[coder encodeInt:xLoc forKey:@"xLoc"];
	[coder encodeInt:yLoc forKey:@"yLoc"];
	
	[coder encodeInt:moveDirection forKey:@"moveDirection"];
	[coder encodeInt:age forKey:@"age"];
	[coder encodeFloat:energy forKey:@"energy"];

	EncodePixel24(color, coder);
	
	[coder encodeConditionalObject:arena forKey:@"arena"];
}

- initWithCoder:(NSCoder *)coder
{
	[super init];

	arenaXSize = [coder decodeIntForKey:@"arenaXSize"];
	arenaYSize = [coder decodeIntForKey:@"arenaYSize"];
	xLoc = [coder decodeIntForKey:@"xLoc"];
	yLoc = [coder decodeIntForKey:@"yLoc"];
	
	moveDirection = [coder decodeIntForKey:@"moveDirection"];
	age = [coder decodeIntForKey:@"age"];
	energy = [coder decodeFloatForKey:@"energy"];

	[self setColor:DecodePixel24(coder)];
	
	arena = [coder decodeObjectForKey:@"arena"];
	
	return self;
}


- (unsigned)hash
{
	return (unsigned)self;
}

- (BOOL)isEqual:other
{
	if(self == other)
		return YES;
	else
		return NO;
}

- (void)dealloc
{
	memoryAllocated -= isa->instance_size;
	deallocations++;
	[super dealloc];
}

@end
