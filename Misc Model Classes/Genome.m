//
//  Genome.m
//  Creatures
//
//  Created by mikeash on Sun Oct 28 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "Genome.h"
#import "GenomeWindowController.h"
#import "GenomeLibrary.h"
#import "CreatureController.h"
#import "VirtualMachineAssembler.h"
//#import "StackTrace.h"


@implementation Genome

NSString *GenomeDragDataType = @"com.mikeash.creatures.genomeDragDataType";
NSString *GenomeDestroyedNotification = @"GenomeDestroyed";

static NSMutableArray *genomeList, *IDList, *openWindowsList;
static id genomeListController = nil;
static id creatureController = nil;

// NSZone

+ (void)initialize
{
	genomeList = [[NSMutableArray alloc] init];
	openWindowsList = [[NSMutableArray alloc] init];
	IDList = [[NSMutableArray alloc] init];
}

+ (Genome *)defaultGenome
{
	if([genomeList count] > 0)
		return [genomeList objectAtIndex:0];

	id path = [[NSBundle bundleForClass:self] pathForResource:@"defaultprogram" ofType:@"txt"];
	MyAssert(path != nil, @"Couldn't find defaultprogram.txt!");
	id fileString = [NSString stringWithContentsOfFile:path];
	MyAssert(fileString != nil, @"Couldn't read defaultprogram.txt!");

	id assembler = [[VirtualMachineAssembler alloc] initWithString:fileString];
	[assembler scan];
	MyAssert([[assembler errors] count] == 0,
		  @"While assembling defaultprogram.txt, got %d errors:\n%@",
		  [[assembler errors] count], [[assembler errors] componentsJoinedByString:@"\n"]);
	
	NSData *defaultData = [assembler assembledData];

	VirtualMachine *vm = [[VirtualMachine alloc] initWithData:defaultData pad:0];
	Genome *genome = [[Genome alloc] initWithVM:vm];
	[vm release];
	[assembler release];

	Pixel24 blue = {0, 0, 255};
	[genome setColor:blue];
	[genome setOriginalCode:fileString];
	[genome release];
	return genome;
}

+ (NSArray *)genomeList
{
	return genomeList;
}

+ (void)reverseGenomeList
{
	NSMutableArray *newArray = [[NSMutableArray alloc] initWithCapacity:[genomeList count]];
	NSEnumerator *enumerator = [genomeList reverseObjectEnumerator];
	id obj;
	while((obj = [enumerator nextObject]))
		[newArray addObject:obj];
	[genomeList release];
	genomeList = newArray;
}

+ (void)destroyListContents
{
	[genomeList removeAllObjects];
	[IDList removeAllObjects];
	[self defaultGenome];
	[genomeList addObjectsFromArray:[[GenomeLibrary library] allGenomes]];
}

+ (void)setListController:c
{
	genomeListController = c;
}

+ (void)setCreatureController:c
{
	creatureController = c;
}

+ (CreatureController *)creatureController
{
	return creatureController;
}

+ (int)newIDForMutations:(int)m
{
	if(m >= [IDList count])
	{
		int i;
		for(i = [IDList count]; i <= m; i++)
			[IDList insertObject:[NSNumber numberWithInt:0] atIndex:i];
	}
	int retval = [[IDList objectAtIndex:m] intValue];
	[IDList replaceObjectAtIndex:m withObject:[NSNumber numberWithInt:retval + 1]];
	return retval;
}

+ (void)registerID:(int)theID forMutations:(int)m
{
	if(m >= [IDList count])
	{
		int i;
		for(i = [IDList count]; i <= m; i++)
			[IDList insertObject:[NSNumber numberWithInt:0] atIndex:i];
	}
	int curval = [[IDList objectAtIndex:m] intValue];
	if(theID >= curval)
		[IDList replaceObjectAtIndex:m withObject:[NSNumber numberWithInt:theID + 1]];
}

+ (void)updateOpenWindows
{
	// stuff
}

int cullDisableCount = 0;
NSMutableArray *delayedCullGenomes = nil;

+ (void)disableCulling
{
	if(cullDisableCount == 0)
		delayedCullGenomes = [[NSMutableArray alloc] init];
	cullDisableCount++;
}

static int SortFunction(id a, id b, void *context)
{
	int aLevel = [a mutations];
	int bLevel = [b mutations];
	if(aLevel < bLevel)
		return NSOrderedAscending;
	else if (aLevel > bLevel)
		return NSOrderedDescending;
	else
		return NSOrderedSame;
}

+ (void)performCulling
{
	// cull all delayed culls
	
	[delayedCullGenomes sortUsingFunction:SortFunction context:nil];
	NSArray *array = delayedCullGenomes;
	delayedCullGenomes = nil;
	[array makeObjectsPerformSelector:@selector(chainEvaluateShouldCull)];
	[array release];	
}

+ (void)enableCulling
{
	MyAssert(cullDisableCount != 0, @"cullDisableCount == 0, this shouldn't happen!");

	cullDisableCount--;
	if(cullDisableCount == 0)
		[self performSelector:@selector(performCulling) withObject:nil afterDelay:0];
}

+ (void)removeOldGenomes:(int)generationsToKeep
{
	/*
	 No function that handles genomes can be recursive, because the tree can get too large.
	 
	 Basic algorithm:
	 
	 create a set of genomes to keep
	 
	 For each genome:
		if it has no population, skip
		otherwise, iterate up the parent tree generationsToKeep times
		add each genome encountered to the set
	 
	 For each genome (do this one forwards to eliminate problems with recursion):
		if genome is not in the set, remove it from the list
	 */
	
	NSMutableSet *keep = [[NSMutableSet alloc] init];
	
	NSEnumerator *enumerator = [genomeList objectEnumerator];
	Genome *genome;
	while((genome = [enumerator nextObject]))
	{
		if([genome population] == 0)
			continue;
		
		Genome *obj = genome;
		int i;
		for(i = 0; i < generationsToKeep + 1 && obj != nil; i++)
		{
			[keep addObject:obj];
			obj = [obj parent];
		}
	}
	
	[keep addObjectsFromArray:[[GenomeLibrary library] allGenomes]];
	[keep addObject:[genomeList objectAtIndex:0]]; // genome 0 is the original genome that should always stay
	
	int i;
	for(i = 0; i < [genomeList count]; i++)
	{
		genome = [genomeList objectAtIndex:i];
		
		if(![keep member:genome])
		{
			// first remove everybody from their parent's list in case the
			// parent is not being removed
			[[genome parent] cullChild:genome];
			[[genome children] makeObjectsPerformSelector:@selector(setParent:) withObject:nil];
		}
	}
	for(i = 0; i < [genomeList count]; i++)
	{
		genome = [genomeList objectAtIndex:i];
		
		if(![keep member:genome])
		{
			// then remove the genome from the list itself
			[[NSNotificationCenter defaultCenter] postNotificationName:GenomeDestroyedNotification object:genome];
			[genomeList removeObjectAtIndex:i];
			i--; // have to do this here because everything's shifted by 1 now
		}
	}
	[keep release];
}


- initWithVM:(VirtualMachine *)vm
{
	representative = [vm copy];
	[representative setTrapHandlerObject:nil selector:nil];
	parent = nil;
	genomeID = [Genome newIDForMutations:mutations];
	rootID = genomeID;
	members = [[NSMutableArray alloc] init];
	[genomeList addObject:self];
	return self;
}

- initWithComputingCreature:(ComputingCreature *)c;
{
	representative = [[c vm] copy];
	[representative setTrapHandlerObject:nil selector:nil];
	parent = [c genome];
	MyAssert(parent != self, @"");

	if(parent == nil)
		mutations = 0;
	else
		mutations = [parent mutations] + 1;
	genomeID = [Genome newIDForMutations:mutations];
	if(parent)
		rootID = [parent rootID];
	else
		rootID = genomeID;
	[parent addChild:self];
	
	members = [[NSMutableArray alloc] initWithObjects:c, nil];
	totalInGenome = 1;
	firstAppearanceStep = [[creatureController arena] stepNumber];
	peakPopulation = 1;
	centerOfGravityX = [c xLoc];
	centerOfGravityY = [c yLoc];
	[genomeList addObject:self];
	//[genomeListController update];
	return self;
}

- (void)addChild:(Genome *)child
{
	if(children == nil)
		children = [[NSMutableArray alloc] init];
	[children addObject:child];
}

- (void)cullChild:(Genome *)child
{
	totalCulledChildren += [child totalCulledChildren] + 1;
	culledChildrenDepth = MAX(culledChildrenDepth, [child culledChildrenDepth] + 1);
	totalCulledMembers += [child totalCulledMembers] + [child totalPopulation];
	[children removeObject:child];
}

- children
{
	return children;
}

- dataForIdentifier:identifier
{
	if([identifier isEqualToString:@"Name"])
		return [self name];
	else if([identifier isEqualToString:@"Population"])
		return [NSNumber numberWithInt:[members count]];
	else if([identifier isEqualToString:@"Total"])
		return [NSNumber numberWithInt:totalInGenome];
	else if([identifier isEqualToString:@"Parent"])
	{
		if(parent != nil)
			return [parent name];
		else
			return @"None";
	}
	else if([identifier isEqualToString:@"Mutations"])
		return [NSNumber numberWithInt:mutations];
	else if([identifier isEqualToString:@"Comment"])
	{
		if(comment != nil)
			return comment;
		else
			return [NSString string];
	}
	else if([identifier isEqualToString:@"FirstAppeared"])
		return [NSNumber numberWithInt:firstAppearanceStep];
	else if([identifier isEqualToString:@"LastAppeared"])
	{
		if(lastDeathStep != 0)
			return [NSNumber numberWithInt:lastDeathStep];
		else
			return [NSNumber numberWithInt:[[creatureController arena] stepNumber]];
	}
	else if([identifier isEqualToString:@"PeakPopulation"])
		return [NSNumber numberWithInt:peakPopulation];
	else if([identifier isEqualToString:@"ErasedChildGenomes"])
		return [NSNumber numberWithInt:totalCulledChildren];
	else if([identifier isEqualToString:@"ErasedGenomeCreatures"])
		return [NSNumber numberWithInt:totalCulledMembers];
	else if([identifier isEqualToString:@"SaveInLibrary"])
		return [NSNumber numberWithBool:[[GenomeLibrary library] containsGenome:self]];
	else
	{
		MyErrorLog(@"Error: identifier was something unexpected: %@", identifier);
		return nil;
	}
	return nil;
}

- (BOOL)evaluateShouldCull
{
	if(  self != [genomeList objectAtIndex:0] &&
		![[GenomeLibrary library] containsGenome:self] &&
		 [members count] == 0 &&
		 [children count] == 0)
	{
		[parent cullChild:self];
		parent = nil;
		[[NSNotificationCenter defaultCenter] postNotificationName:GenomeDestroyedNotification object:self];
		[genomeList removeObject:self];
		return YES;
	}
	else
		return NO;
}

- (void)chainEvaluateShouldCull
{
	if(cullDisableCount)
		[delayedCullGenomes addObject:self];
	else
	{
		id obj = self;
		id p = [obj parent];
		while([obj evaluateShouldCull])
		{
			obj = p;
			p = [obj parent];
		}
	}
}

- (void)addCreature:creature
{
	int population;
	[members addObject:creature];
	if(totalInGenome == 0)
		firstAppearanceStep = [[creatureController arena] stepNumber];
	totalInGenome++;
	population = [members count];
	if(population > peakPopulation)
		peakPopulation = population;
	/*
	 (oldaverage * oldtotal + newvalue) / newtotal = newaverage
	 oldaverage * oldtotal / newtotal + newvalue / newtotal = newAverage
	 */
	centerOfGravityX = centerOfGravityX * (((float)totalInGenome - 1)/((float)totalInGenome)) + (float)[creature xLoc]/((float)totalInGenome);
	centerOfGravityY = centerOfGravityY * (((float)totalInGenome - 1)/((float)totalInGenome)) + (float)[creature yLoc]/((float)totalInGenome);
	//[genomeListController update];
}



- (void)removeCreature:creature
{
	[members removeObjectIdenticalTo:creature];
	if([members count] == 0)
	{
		lastDeathStep = [[creatureController arena] stepNumber];
		[self performSelector:@selector(chainEvaluateShouldCull) withObject:nil afterDelay:0];
	}
	//[genomeListController update];
}

- (void)setColor:(Pixel24)c
{
	color = c;
	NSEnumerator *enumerator = [members objectEnumerator];
	Creature *obj;
	while((obj = [enumerator nextObject]))
	{
		[obj setColor:c];
	}
}

- (Pixel24)color
{
	return color;
}

- (VirtualMachine *)representative
{
	return representative;
}

- (NSString *)name
{
	return [NSString stringWithFormat:@"%d %d:%d-%d", [self rootID], [parent genomeID], genomeID, mutations];
}

- (NSString *)comment
{
	if(comment != nil)
		return comment;
	else
		return [NSString string];
}

- (void)setComment:(NSString *)c
{
	[comment autorelease];
	if([c length] > 0)
		comment = [c copy];
	else
		comment = nil;
}

- (NSString *)originalCode
{
	return originalCode;
}

- (void)setOriginalCode:(NSString *)c
{
	[originalCode autorelease];
	originalCode = [c copy];
}

- (int)rootID
{
	if(rootID == -1)
	{
		if(!parent)
		{
			rootID = genomeID = [Genome newIDForMutations:0];
		}
		else
		{
			Genome *cur = self;
			while([cur parent] != nil)
				cur = [cur parent];
			rootID = [cur genomeID];
		}
	}
	return rootID;
}

- (int)genomeID
{
	return genomeID;
}

- (int)population
{
	return [members count];
}

- (int)totalPopulation
{
	return totalInGenome;
}

- (int)mutations
{
	return mutations;
}

- (int)firstAppearanceStep
{
	return firstAppearanceStep;
}

- (int)lastDeathStep
{
	return lastDeathStep;
}

- (int)peakPopulation
{
	return peakPopulation;
}

- (float)centerOfGravityX
{
	return centerOfGravityX;
}

- (float)centerOfGravityY
{
	return centerOfGravityY;
}


- (int)totalCulledChildren
{
	return totalCulledChildren;
}

- (int)culledChildrenDepth
{
	return culledChildrenDepth;
}

- (int)totalCulledMembers
{
	return totalCulledMembers;
}

- (void)setParent:(Genome *)p
{
	parent = p;
}

- parent
{
	return parent;
}

- (void)openWindow
{
	if(windowController == nil)
	{
		windowController = [[GenomeWindowController alloc] initWithGenome:self];
		[openWindowsList addObject:self];
		[windowController showWindow:self];
	}
	else
		[[windowController window] makeKeyAndOrderFront:nil];
	[windowController update];
}

- (void)update
{
	[windowController update];
}

- (void)windowClosing
{
	[windowController release];
	windowController = nil;
	[openWindowsList removeObjectIdenticalTo:self];
}

- genomeForLibrary
{
	Genome *genome = [[Genome alloc] initWithVM:representative];
	[genomeList removeObject:genome];
	[genome setComment:comment];
	[genome setColor:color];
	[genome setOriginalCode:originalCode];
	return [genome autorelease];
}



- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeConditionalObject:parent forKey:@"parent"];
	if(children)
		[coder encodeObject:children forKey:@"children"];

	EncodePixel24(color, coder);
	
	[coder encodeObject:representative forKey:@"representative"];
	[coder encodeInt:genomeID forKey:@"genomeID"];
	if(comment)
		[coder encodeObject:comment forKey:@"comment"];
	if(originalCode)
		[coder encodeObject:originalCode forKey:@"originalCode"];
	[coder encodeObject:members forKey:@"members"];
	[coder encodeInt:mutations forKey:@"mutations"];
	[coder encodeInt:totalInGenome forKey:@"totalInGenome"];
	[coder encodeInt:firstAppearanceStep forKey:@"firstAppearanceStep"];
	if(lastDeathStep > 0)
		[coder encodeInt:lastDeathStep forKey:@"lastDeathStep"];
	[coder encodeInt:peakPopulation forKey:@"peakPopulation"];
	[coder encodeFloat:centerOfGravityX forKey:@"centerOfGravityX"];
	[coder encodeFloat:centerOfGravityY forKey:@"centerOfGravityY"];
	if(totalCulledChildren > 0)
		[coder encodeInt:totalCulledChildren forKey:@"totalCulledChildren"];
	if(culledChildrenDepth > 0)
		[coder encodeInt:culledChildrenDepth forKey:@"culledChildrenDepth"];
	if(totalCulledMembers > 0)
		[coder encodeInt:totalCulledMembers forKey:@"totalCulledMembers"];
}

- initWithCoder:(NSCoder *)coder
{
	//parent = [coder decodeObjectForKey:@"parent"];
	if([coder containsValueForKey:@"children"])
		children = [[coder decodeObjectForKey:@"children"] retain];
	[children makeObjectsPerformSelector:@selector(setParent:) withObject:self];

	[self setColor:DecodePixel24(coder)];

	representative = [[coder decodeObjectForKey:@"representative"] retain];
	genomeID = [coder decodeIntForKey:@"genomeID"];
	if([coder containsValueForKey:@"comment"])
		comment = [[coder decodeObjectForKey:@"comment"] retain];
	if([coder containsValueForKey:@"originalCode"])
		originalCode = [[coder decodeObjectForKey:@"originalCode"] retain];
	members = [[coder decodeObjectForKey:@"members"] retain];
	mutations = [coder decodeIntForKey:@"mutations"];
	totalInGenome = [coder decodeIntForKey:@"totalInGenome"];
	firstAppearanceStep = [coder decodeIntForKey:@"firstAppearanceStep"];
	if([coder containsValueForKey:@"lastDeathStep"])
		lastDeathStep = [coder decodeIntForKey:@"lastDeathStep"];
	peakPopulation = [coder decodeIntForKey:@"peakPopulation"];
	centerOfGravityX = [coder decodeFloatForKey:@"centerOfGravityX"];
	centerOfGravityY = [coder decodeFloatForKey:@"centerOfGravityY"];
	if([coder containsValueForKey:@"totalCulledChildren"])
		totalCulledChildren = [coder decodeIntForKey:@"totalCulledChildren"];
	if([coder containsValueForKey:@"culledChildrenDepth"])
		culledChildrenDepth = [coder decodeIntForKey:@"culledChildrenDepth"];
	if([coder containsValueForKey:@"totalCulledMembers"])
		totalCulledMembers = [coder decodeIntForKey:@"totalCulledMembers"];

	[genomeList addObject:self];

	[Genome registerID:genomeID forMutations:mutations];
	
	return self;
}

- (BOOL)isEqual:other
{
	if(self == other)
		return YES;
	else
		return NO;
}

- (unsigned)hash
{
	return (unsigned)self;
}

- copyWithZone:(NSZone *)zone
{
	return [self retain];
}

- (void)dealloc
{
	[children autorelease];
	[comment release];
	[originalCode release];
	[members release];
	[representative release];
	[super dealloc];
}

@end
