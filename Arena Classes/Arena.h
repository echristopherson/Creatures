//
//  Arena.h
//  Creatures
//
//  Created by mikeash on Thu Oct 25 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PixmapUtils.h"

typedef enum { kEdgeWrap, kEdgeBlock, kEdgeKill } eEdgeType;

enum {
	kSpawnAsexual = 1,
	kSpawnMating = 2
};

@interface Arena : NSObject <NSCoding> {
	int xSize, ySize;
	int step;
	NSMutableSet *computingCreaturesList;
	NSMutableSet *barrierList;
	id *arena;
	unsigned char *foodArena;

	PixelUnion *pixmap;
	BOOL continuousUpdates;

	NSMutableSet *regions;
	BOOL drawsRegions;
	
	double mutationRate;
	double birthMutationRate;
	double foodGrowthRate;
	int foodRegenerationThreshold;
	int creatureRegenerationThreshold;
	int spawnEnergy;
	int spawnMask;

	BOOL biasFoodGrowth;
	double biasFoodGrowthProportion;
	int biasFoodGrowthAmount;

	BOOL useStopThresholdPopulation;
	int stopThresholdPopulation;

	eEdgeType edgeBehavior;
}

+ (void)setArena:a;

- initWithX:(float)x Y:(float)y;
- (NSArray *)creaturesNear:(int)x :(int)y;
- (id *)creatureStorage;
- (void)addCreature:creature;
- (void)addComputingCreature:creature;
- (void)addBarrier:barrier;
- (void)addToRedrawList:creature;
- (void)removeCreature:creature;
- (void)removeBarrier:barrier;
- (BOOL)registerCreature:creature at:(int)x :(int)y;
- (void)removeCreature:creature at:(int)x :(int)y;
- creatureFor:(int)x :(int)y;
- (void)setFoodValue:(int)val at:(int)x :(int)y;
- (int)foodValueAt:(int)x :(int)y;
- (void)step;
- (void)draw;
- (unsigned char *)foodData;
- (void)setContinuousUpdates:(BOOL)u;
- (BOOL)continuousUpdates;
- (PixelUnion *)pixmap;
- (void)drawOnPixmap:(PixelUnion *)pixmap width:(int)pixWidth;
- (void)update;
- (int)xSize;
- (int)ySize;
- (int)population;
- (int)stepNumber;

- (void)setDrawsRegions:(BOOL)d;
- (void)addRegion:region;
- (void)removeRegion:region;
- (NSSet *)regions;

- (double)mutationRate;
- (void)setMutationRate:(double)r;
- (double)birthMutationRate;
- (void)setBirthMutationRate:(double)r;
- (double)foodGrowthRate;
- (void)setFoodGrowthRate:(double)i;
- (eEdgeType)edgeBehavior;
- (void)setEdgeBehavior:(eEdgeType)b;
- (int)spawnEnergy;
- (void)setSpawnEnergy:(int)e;
- (int)spawnMask;
- (void)setSpawnMask:(int)mask;
- (BOOL)biasFoodGrowth;
- (void)setBiasFoodGrowth:(BOOL)a;
- (double)biasFoodGrowthProportion;
- (void)setBiasFoodGrowthProportion:(double)a;
- (int)biasFoodGrowthAmount;
- (void)setBiasFoodGrowthAmount:(int)a;
- (BOOL)useStopThresholdPopulation;
- (void)setUseStopThresholdPopulation:(BOOL)a;
- (int)stopThresholdPopulation;
- (void)setStopThresholdPopulation:(int)a;

@end
