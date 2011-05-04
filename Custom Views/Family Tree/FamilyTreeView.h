//
//  FamilyTreeView.h
//  Creatures
//
//  Created by Michael Ash on Fri Mar 15 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "ToolInteractionView.h"
#import "GenomeGraphic.h"


@interface FamilyTreeView : ToolInteractionView {
	NSMutableArray *rows;
	NSMutableArray *rootGenomes;
	NSMutableArray *rootGraphics;
	NSSet *visibleGraphics;
	NSMutableDictionary *graphicsDict;
	//NSMutableArray *genomeGraphics;
}

- (void)zoomIn:sender;
- (void)zoomOut:sender;
- (void)reloadTree:sender;
- (void)centerFirstGenome:sender;

@end
