//
//  GenomeDragAcceptTextField.h
//  Creatures
//
//  Created by Michael Ash on Thu Jun 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>


@class Genome;

@interface GenomeDragAcceptTextField : NSTextField {
	Genome *genome;
}

- (void)setGenome:(Genome *)g;
- (Genome *)genome;

@end
