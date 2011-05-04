//
//  GenomeLibrary.h
//  Creatures
//
//  Created by Michael Ash on Thu Jul 10 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@class Genome;

@interface GenomeLibrary : NSObject {
	NSMutableSet *library;
}

+ (GenomeLibrary *)library;

- (void)addGenome:(Genome *)genome;
- (void)removeGenome:(Genome *)genome;
- (BOOL)containsGenome:(Genome *)genome;
- (NSArray *)allGenomes;

@end
