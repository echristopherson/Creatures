//
//  Genome.h
//  Creatures
//
//  Created by mikeash on Sun Oct 28 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ComputingCreature.h"
#import "VirtualMachine.h"
#import "PixmapUtils.h"


extern NSString * GenomeDragDataType;
extern NSString *  GenomeDestroyedNotification; // only sent when destroyed during a run,
													// not when destroyed because the world closes

@class CreatureController;

@interface Genome : NSObject <NSCoding> {
	id windowController; // store this in a dictionary somewhere

	Pixel24 color;
	
	Genome *parent;
	NSMutableArray *children;
	VirtualMachine *representative;
	int genomeID;
	int rootID;
	NSString *comment;
	NSString *originalCode;
	
	NSMutableArray *members;
	int mutations;
	int totalInGenome;

	int firstAppearanceStep;
	int lastDeathStep;
	int peakPopulation;
	float centerOfGravityX, centerOfGravityY;
	
	int totalCulledChildren;
	int culledChildrenDepth;
	int totalCulledMembers;
}

+ (Genome *)defaultGenome;
+ (NSArray *)genomeList;
+ (void)reverseGenomeList; // should ONLY be called by the arena when decoding a file
+ (void)destroyListContents;
+ (void)setListController:c;
+ (void)setCreatureController:c;
+ (CreatureController *)creatureController;
+ (int)newIDForMutations:(int)m;
+ (void)registerID:(int)theID forMutations:(int)m;
+ (void)updateOpenWindows;

+ (void)disableCulling;
+ (void)enableCulling; // these two are refcounted, enable must be called an equal
						// number of times as disable to re-enable

+ (void)removeOldGenomes:(int)generationsToKeep;

- initWithVM:(VirtualMachine *)vm;
- initWithComputingCreature:(ComputingCreature *)c;
- (void)addChild:(Genome *)child;
- (void)cullChild:(Genome *)child;
- children;
- dataForIdentifier:identifier;
- (BOOL)evaluateShouldCull;
- (void)chainEvaluateShouldCull;
- (void)addCreature:creature;
- (void)removeCreature:creature;
- (void)setColor:(Pixel24)c;
- (Pixel24)color;
- (VirtualMachine *)representative;
- (NSString *)name;
- (NSString *)comment;
- (void)setComment:(NSString *)c;
- (NSString *)originalCode;
- (void)setOriginalCode:(NSString *)c;
- (int)rootID;
- (int)genomeID;
- (int)population;
- (int)totalPopulation;
- (int)mutations;
- (int)firstAppearanceStep;
- (int)lastDeathStep;
- (int)peakPopulation;
- (float)centerOfGravityX;
- (float)centerOfGravityY;
- (int)totalCulledChildren;
- (int)culledChildrenDepth;
- (int)totalCulledMembers;
- (void)openWindow;
- (void)windowClosing;
- (void)setParent:(Genome *)p;
- parent;

- genomeForLibrary;

@end
