//
//  GenomeBox.h
//  Creatures
//
//  Created by Michael Ash on Wed Jul 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class Genome;

@interface GenomeBox : NSBox {
	Genome *genome;
}

- (void)setGenome:(Genome *)g;
- (Genome *)genome;

@end
