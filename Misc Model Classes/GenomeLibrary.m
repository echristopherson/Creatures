//
//  GenomeLibrary.m
//  Creatures
//
//  Created by Michael Ash on Thu Jul 10 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "GenomeLibrary.h"
#import "Genome.h"


@interface GenomeLibrary (Private)

- (void)saveToDefaults;

@end

@implementation GenomeLibrary (Private)

- (void)saveToDefaults
{
	NSMutableSet *tempSet = [NSMutableSet set];
	NSEnumerator *enumerator = [library objectEnumerator];
	Genome *genome;
	while((genome = [enumerator nextObject]))
		[tempSet addObject:[genome genomeForLibrary]];

	NSData *libraryData = [NSKeyedArchiver archivedDataWithRootObject:tempSet];
	[[NSUserDefaults standardUserDefaults] setObject:libraryData forKey:@"GenomeLibrary"];
}

- initFromDefaults
{
	NSData *libraryData = [[NSUserDefaults standardUserDefaults] objectForKey:@"GenomeLibrary"];
	if(libraryData)
	{
		NSSet *tempSet = [NSKeyedUnarchiver unarchiveObjectWithData:libraryData];
		library = [tempSet mutableCopy];
	}
	else
	{
		library = [[NSMutableSet alloc] init];
	}
	return self;
}

- init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (void)dealloc
{
	[library release];
	[super dealloc];
}

@end

@implementation GenomeLibrary

+ (GenomeLibrary *)library
{
	static GenomeLibrary *sharedInstance = nil;
	if(sharedInstance == nil)
		sharedInstance = [[self alloc] initFromDefaults];
	return sharedInstance;
}

- (void)addGenome:(Genome *)genome
{
	[library addObject:genome];
	[self saveToDefaults];
}

- (void)removeGenome:(Genome *)genome
{
	[library removeObject:genome];
	[self saveToDefaults];
}

- (BOOL)containsGenome:(Genome *)genome
{
	if([library member:genome])
		return YES;
	else
		return NO;
}

- (NSArray *)allGenomes
{
	return [library allObjects];
}

@end
