//
//  Arena.m
//  Creatures
//
//  Created by mikeash on Thu Oct 25 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "Arena.h"
#import "ComputingCreature.h"
#import "Genome.h"
#import "strings.h"


@implementation Arena

+ (void)initialize
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = [NSDictionary
        dictionaryWithObjectsAndKeys:
		[NSNumber numberWithDouble:0], @"DefaultMutationRate",
		[NSNumber numberWithDouble:0.1], @"DefaultBirthMutationRate",
		[NSNumber numberWithDouble:0.0025], @"DefaultFoodGrowthRate",
		[NSNumber numberWithInt:5], @"DefaultFoodRegenerationThreshold",
		[NSNumber numberWithInt:5], @"DefaultCreatureRegenerationThreshold",
		[NSNumber numberWithInt:200], @"DefaultSpawnEnergy",
		[NSNumber numberWithInt:kEdgeBlock], @"DefaultArenaEdgeBehavior",
		[NSNumber numberWithInt:kSpawnAsexual | kSpawnMating], @"DefaultSpawnMask",
		nil];
	[defaults registerDefaults:appDefaults];
}

+ (void)setArena:a
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ArenaChanged" object:self userInfo:a];
}

- initWithX:(float)x Y:(float)y
{
	//NSLog(@"%s", __FUNCTION__);
	if((self = [super init]))
	{
		xSize = x;
		ySize = y;

		computingCreaturesList = [[NSMutableSet alloc] init];
		barrierList = [[NSMutableSet alloc] init];
		regions = [[NSMutableSet alloc] init];
		//redrawList = [[NSMutableSet alloc] init];
		arena = malloc(x * y * sizeof(id));
		bzero(arena, x * y * sizeof(id));
		foodArena = malloc(x * y * sizeof(int));
		bzero(foodArena, x * y * sizeof(int));

		[self setContinuousUpdates:YES];

		mutationRate = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DefaultMutationRate"] doubleValue];
		birthMutationRate = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DefaultBirthMutationRate"] doubleValue];
		foodGrowthRate = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DefaultFoodGrowthRate"] doubleValue];
		foodRegenerationThreshold = [[NSUserDefaults standardUserDefaults] integerForKey:@"DefaultFoodRegenerationThreshold"];
		creatureRegenerationThreshold = [[NSUserDefaults standardUserDefaults] integerForKey:@"DefaultCreatureRegenerationThreshold"];
		edgeBehavior = [[NSUserDefaults standardUserDefaults] integerForKey:@"DefaultArenaEdgeBehavior"];
		spawnEnergy = [[NSUserDefaults standardUserDefaults] integerForKey:@"DefaultSpawnEnergy"];
		spawnMask = [[NSUserDefaults standardUserDefaults] integerForKey:@"DefaultSpawnMask"];

		biasFoodGrowth = NO;
		biasFoodGrowthProportion = .75;
		biasFoodGrowthAmount = 100;
	}
	
	return self;
}

- (void)addCreature:creature
{
	//[creaturesList addObject:creature];
}

- (void)addComputingCreature:creature
{
	[computingCreaturesList addObject:creature];
}

- (void)addBarrier:barrier
{
	[barrierList addObject:barrier];
}

- (void)removeCreature:creature
{
	//NSLog(@"Removing 0x%x from computingCreaturesList", creature);
	[computingCreaturesList removeObject:creature];
}

- (void)removeBarrier:barrier
{
	[barrierList removeObject:barrier];
}

- (id *)creatureStorage
{
	return arena;
}

- (NSArray *)creaturesNear:(int)x :(int)y
{

	/* FIX FIX FIX */
	/* details: it doesn't actually do anything useful except return
	   an array full of the creature at the point indicated. It also
	   doesn't respect edge conditions at all.

	   Update: looks like I fixed this problem and didn't say so, gave me a bit of a scare.
	*/
	int dx, dy;
	NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:9];

	for(dx = -1; dx <= 1; dx++)
		for(dy = -1; dy <= 1; dy++)
		{
			int lookx = x + dx;
			int looky = y + dy;
			if(lookx < 0 || looky < 0 || lookx >= xSize || looky >= ySize)
			{
				switch(edgeBehavior)
				{
					case kEdgeWrap:
						lookx = (lookx + xSize) % xSize;
						looky = (looky + ySize) % ySize;
						break;
					case kEdgeBlock:
						continue;
						break;
					case kEdgeKill:
						continue;
						break;
				}
			}
			if(arena[looky * xSize + lookx] != nil && [arena[looky * xSize + lookx] isCreature])
				[returnArray addObject:arena[looky * xSize + lookx]];
		}
			
	return returnArray;
}

- (BOOL)registerCreature:creature at:(int)x :(int)y
{
	MyAssert(arena[y * xSize + x] == nil, @"Error: (%d, %d) already occupied in %s", x, y, __FUNCTION__);
	//NSLog(@"Registering 0x%x at (%d, %d)", creature, x, y);
	arena[y * xSize + x] = creature;
	if(continuousUpdates)
	{
		Pixel24 c = [(Creature *)creature color];
		PixelUnion drawc = {{255, c.r, c.g, c.b}};
		pixmap[(ySize - y - 1) * xSize + x] = drawc;
	}
	return YES;
	//NSLog(@"%s: assigning to arena[%d]", __FUNCTION__, y*xSize + x);
}

- (void)removeCreature:creature at:(int)x :(int)y
{
	MyAssert(arena[y * xSize + x] != nil, @"nil creature");
	MyAssert(arena[y * xSize + x] == creature, @"wrong creature at (%d, %d), existing creature is 0x%x and creature to remove is 0x%x", x, y, arena[y * xSize + x], creature);
	//NSLog(@"Removing 0x%x at (%d, %d)", creature, x, y);
	arena[y * xSize + x] = nil;
	if(continuousUpdates)
	{
		pixmap[(ySize - y - 1) * xSize + x].components.r = 0;
		pixmap[(ySize - y - 1) * xSize + x].components.g = foodArena[(ySize - y - 1) * xSize + x];
		pixmap[(ySize - y - 1) * xSize + x].components.b = 0;
	}
	//NSLog(@"%s: setting arena[%d] to nil", __FUNCTION__, y*xSize + x);
}

- (void)addToRedrawList:creature
{
	//[redrawList addObject:creature];
}

- creatureFor:(int)x :(int)y
{
	if(x < 0 || y < 0 || x >= xSize || y >= ySize)
		return nil;
	else
		return arena[y * xSize + x];
}

- (void)setFoodValue:(int)val at:(int)x :(int)y
{
	if(val > 255)
		val = 255;
	foodArena[(ySize - y - 1) * xSize + x] = val;
	if(continuousUpdates)
	{
		pixmap[(ySize - y - 1) * xSize + x].components.r = 0;
		pixmap[(ySize - y - 1) * xSize + x].components.g = val;
		pixmap[(ySize - y - 1) * xSize + x].components.b = 0;
	}
}

- (int)foodValueAt:(int)x :(int)y
{
	return foodArena[(ySize - y - 1) * xSize + x];
}

- (void)spawnFood
{
	int x = random() % xSize;
	int y = random() % ySize;

	int origVal = foodArena[x + y * xSize];
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
		if([self creatureFor:x :(ySize - y - 1)] == nil && foodArena[x + y * xSize] == 0)
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
			foodArena[x + y * xSize] = newVal;
			if(continuousUpdates)
			{
				pixmap[x + y * xSize].components.r = 0;
				pixmap[x + y * xSize].components.g = newVal;
				pixmap[x + y * xSize].components.r = 0;
			}
		}
	}
}

- (void)step
{
	int i;
	int numTimes;
	id computingArray;

	numTimes = [computingCreaturesList count] * mutationRate;
	computingArray = [computingCreaturesList allObjects];
	if(numTimes == 0 && [computingCreaturesList count] != 0)
	{
		int a, b;
		a = (random() % (int)(1.0/mutationRate));
		b = [computingCreaturesList count];
		if(a < b)
			numTimes = 1;
	}

	for(i = 0; i < numTimes; i++)
	{
		int index = random() % [computingCreaturesList count];
		[[computingArray objectAtIndex:index] mutate];
	}
	
	numTimes = xSize * ySize * foodGrowthRate;
	for(i = 0; i < numTimes; i++)
		[self spawnFood];

	[regions makeObjectsPerformSelector:@selector(step)];

	[computingArray makeObjectsPerformSelector:@selector(step)];
	
	step++;
}

- (void)draw
{
	MyErrorLog(@"method should never be called");
	//[creaturesList makeObjectsPerformSelector:@selector(draw)];
	//[redrawList release];
	//redrawList = [[NSMutableSet alloc] init];
}

- (unsigned char *)foodData
{
	return foodArena;
}

- (void)drawOnPixmap:(PixelUnion *)pmap width:(int)pixWidth
{
	int index = 0;
	int size = xSize * ySize;
	for(index = 0; index < size; index++)
	{
		pmap[index].components.r = 0;
		pmap[index].components.g = foodArena[index];
		pmap[index].components.b = 0;
		//pmap[index].components.r = 0;
		//pmap[index].components.g = foodArena[index];
		//pmap[index].components.b = 0;
	}
	NSEnumerator *enumerator;
	id obj;

	enumerator = [computingCreaturesList objectEnumerator];
	while((obj = [enumerator nextObject]))
		[obj drawOnPixmap:pmap width:pixWidth];

	enumerator = [barrierList objectEnumerator];
	while((obj = [enumerator nextObject]))
		[obj drawOnPixmap:pmap width:pixWidth];

	if(drawsRegions)
	{
		enumerator = [regions objectEnumerator];
		while((obj = [enumerator nextObject]))
			[obj drawOnPixmap:pmap width:pixWidth];
	}
	//[redrawList release];
	//redrawList = [[NSMutableSet alloc] init];
}

- (void)update
{
	MyErrorLog(@"method should never be called");
	/*[creaturesList makeObjectsPerformSelector:@selector(eraseIfNeeded)];
	[deathDrawingList makeObjectsPerformSelector:@selector(eraseIfNeeded)];
	[deathDrawingList makeObjectsPerformSelector:@selector(drawIfNeeded)];
	[creaturesList makeObjectsPerformSelector:@selector(drawIfNeeded)];
	[deathDrawingList removeAllObjects];*/

	/*if(partialUpdates == NO || redrawList == nil)
	{
		[self draw];
		if(partialUpdates == YES && redrawList == nil)
			redrawList = [[NSMutableSet alloc] init];
	}
	else
	{
		[redrawList makeObjectsPerformSelector:@selector(eraseIfNeeded)];
		[redrawList makeObjectsPerformSelector:@selector(drawIfNeeded)];
		[redrawList release];
		redrawList = [[NSMutableSet alloc] init];
	}*/
}

- (void)setContinuousUpdates:(BOOL)u
{
	if(!u != !continuousUpdates) // if they're different...
	{ // using !u because if I compare them directly they could both be true but not equal
		continuousUpdates = u;
		if(continuousUpdates)
		{
			pixmap = malloc(xSize * ySize * sizeof(*pixmap));
			[self drawOnPixmap:pixmap width:xSize];
		}
		else
		{
			free(pixmap);
			pixmap = nil;
		}
	}
}

- (BOOL)continuousUpdates
{
	return continuousUpdates;
}

- (PixelUnion *)pixmap
{
	return pixmap;
}

- (int)xSize
{
	return xSize;
}

- (int)ySize
{
	return ySize;
}

- (int)population
{
	return [computingCreaturesList count];
}

- (int)stepNumber
{
	return step;
}


- (void)setDrawsRegions:(BOOL)d
{
	drawsRegions = d;
}

- (void)addRegion:region
{
	[region setArena:self];
	[regions addObject:region];
}

- (void)removeRegion:region
{
	if(region != nil && [regions member:region])
		[regions removeObject:region];
}

- (NSSet *)regions
{
	return regions;
}


- (void)dealloc
{
	[computingCreaturesList release];
	[barrierList release];
	[regions release];
	//[redrawList release];
	free(arena);
	free(foodArena);
	if(pixmap)
		free(pixmap);
	
	[super dealloc];
}


- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeInt:xSize forKey:@"xSize"];
	[coder encodeInt:ySize forKey:@"ySize"];
	[coder encodeInt:step forKey:@"step"];

	[coder encodeDouble:mutationRate forKey:@"mutationRate"];
	[coder encodeDouble:birthMutationRate forKey:@"birthMutationRate"];
	[coder encodeDouble:foodGrowthRate forKey:@"foodGrowthRate"];
	[coder encodeInt:edgeBehavior forKey:@"edgeBehavior"];
	[coder encodeInt:spawnEnergy forKey:@"spawnEnergy"];
	[coder encodeInt:spawnMask forKey:@"spawnMask"];
	[coder encodeBool:biasFoodGrowth forKey:@"biasFoodGrowth"];
	[coder encodeDouble:biasFoodGrowthProportion forKey:@"biasFoodGrowthProportion"];
	[coder encodeInt:biasFoodGrowthAmount forKey:@"biasFoodGrowthAmount"];
	[coder encodeBool:useStopThresholdPopulation forKey:@"useStopThresholdPopulation"];
	[coder encodeInt:stopThresholdPopulation forKey:@"stopThresholdPopulation"];

	// Encode the genomes here first so that we don't do any recursive encoding of
	// children or parents, which could overflow the stack

	// they have to be encoded backwards, because parents encode their children directly
	// but children encode their parents conditionally. So we want to encode the newest
	// genomes first to avoid recursive encoding
	// it would be bad policy to rely on the order of encoding for an NSArray, so
	// we'll encode it ourselves
	[coder encodeInt:[[Genome genomeList] count] forKey:@"genomeCount"];
	NSEnumerator *enumerator = [[Genome genomeList] reverseObjectEnumerator];
	id obj;
	while((obj = [enumerator nextObject]))
		[coder encodeObject:obj];
	
	[coder encodeObject:[NSData dataWithBytesNoCopy:foodArena length:xSize * ySize freeWhenDone:NO] forKey:@"charFood"];
	[coder encodeObject:computingCreaturesList forKey:@"computingCreaturesList"];
	[coder encodeObject:barrierList forKey:@"barrierList"];
	[coder encodeObject:regions forKey:@"regions"];
}

- initWithCoder:(NSCoder *)coder
{
	NSEnumerator *enumerator;
	id obj;
	NSData *foodData;
	
	[super init];
	xSize = [coder decodeIntForKey:@"xSize"];
	ySize = [coder decodeIntForKey:@"ySize"];
	step = [coder decodeIntForKey:@"step"];

	mutationRate = [coder decodeDoubleForKey:@"mutationRate"];
	birthMutationRate = [coder decodeDoubleForKey:@"birthMutationRate"];
	foodGrowthRate = [coder decodeDoubleForKey:@"foodGrowthRate"];
	edgeBehavior = [coder decodeIntForKey:@"edgeBehavior"];
	spawnEnergy = [coder decodeIntForKey:@"spawnEnergy"];
	spawnMask = [coder decodeIntForKey:@"spawnMask"];
	if(spawnMask == 0)
		spawnMask = kSpawnAsexual;
	biasFoodGrowth = [coder decodeBoolForKey:@"biasFoodGrowth"];
	biasFoodGrowthProportion = [coder decodeDoubleForKey:@"biasFoodGrowthProportion"];
	biasFoodGrowthAmount = [coder decodeIntForKey:@"biasFoodGrowthAmount"];
	useStopThresholdPopulation = [coder decodeBoolForKey:@"useStopThresholdPopulation"];
	stopThresholdPopulation = [coder decodeIntForKey:@"stopThresholdPopulation"];

	// destroy the genome's list contents because we're about to repopulate
	// it with the side effect of the next call
	[Genome destroyListContents];

	// decode the genomes and throw them away;
	// the decoded objects will be automagically placed into the real list
	int numGenomes = [coder decodeIntForKey:@"genomeCount"];
	while(numGenomes--)
		[coder decodeObject];
	
	[Genome reverseGenomeList]; // reverse the list so that it's in oldest-to-newest order again
	
	foodData = [coder decodeObjectForKey:@"charFood"];
	foodArena = malloc(xSize * ySize * sizeof(int));
	[foodData getBytes:foodArena length:xSize * ySize];
	computingCreaturesList = [[coder decodeObjectForKey:@"computingCreaturesList"] retain];
	barrierList = [[coder decodeObjectForKey:@"barrierList"] retain];
	regions = [[coder decodeObjectForKey:@"regions"] retain];
	
	arena = malloc(xSize * ySize * sizeof(id));
	bzero(arena, xSize * ySize * sizeof(id));
	enumerator = [computingCreaturesList objectEnumerator];
	while((obj = [enumerator nextObject]))
	{
		arena[[obj xLoc] + [obj yLoc] * xSize] = obj;
	}
	enumerator = [barrierList objectEnumerator];
	while((obj = [enumerator nextObject]))
	{
		arena[[obj xLoc] + [obj yLoc] * xSize] = obj;
	}
	//redrawList = [[NSMutableSet alloc] init];

	[self setContinuousUpdates:YES];

	foodRegenerationThreshold = [[NSUserDefaults standardUserDefaults] integerForKey:@"DefaultFoodRegenerationThreshold"];
	creatureRegenerationThreshold = [[NSUserDefaults standardUserDefaults] integerForKey:@"DefaultCreatureRegenerationThreshold"];

	return self;
}

- (double)mutationRate
{
	return mutationRate;
}

- (void)setMutationRate:(double)r
{
	mutationRate = r;
}

- (double)birthMutationRate
{
	return birthMutationRate;
}

- (void)setBirthMutationRate:(double)r
{
	birthMutationRate = r;
}

- (double)foodGrowthRate
{
	return foodGrowthRate;
}

- (void)setFoodGrowthRate:(double)i
{
	foodGrowthRate = i;
}

- (eEdgeType)edgeBehavior
{
	return edgeBehavior;
}

- (void)setEdgeBehavior:(eEdgeType)b
{
	edgeBehavior = b;
}

- (int)spawnEnergy
{
	return spawnEnergy;
}

- (void)setSpawnEnergy:(int)e
{
	spawnEnergy = e;
}

- (int)spawnMask
{
	return spawnMask;
}

- (void)setSpawnMask:(int)mask
{
	spawnMask = mask;
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

- (BOOL)useStopThresholdPopulation
{
	return useStopThresholdPopulation;
}

- (void)setUseStopThresholdPopulation:(BOOL)a
{
	useStopThresholdPopulation = a;
}

- (int)stopThresholdPopulation
{
	return stopThresholdPopulation;
}

- (void)setStopThresholdPopulation:(int)a
{
	stopThresholdPopulation = a;
}


@end
