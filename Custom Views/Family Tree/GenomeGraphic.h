//
//  GenomeGraphic.h
//  Creatures
//
//  Created by Michael Ash on Sun Mar 17 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Genome.h"


@class GenomeBox;

@interface GenomeGraphicNibLoader : NSObject {
	IBOutlet NSView *view;
	IBOutlet NSView *insideView;
	IBOutlet GenomeBox *genomeBox;
	IBOutlet NSTextField *genomeNameField;
	IBOutlet NSTextField *mutationsField;
	IBOutlet NSTextField *populationField;
}

+ nibLoaderWithNibNamed:(NSString *)s;
+ nibLoader;
- initWithNibNamed:(NSString *)s;
- view;
- insideView;
- genomeBox;
- genomeNameField;
- mutationsField;
- populationField;

@end

@interface GenomeGraphic : NSObject {
	IBOutlet NSView *view;
	IBOutlet NSView *insideView;
	GenomeGraphicNibLoader *loader;

	NSView *treeView;
	Genome *genome;
	GenomeGraphic *parent;
	NSMutableArray *children;

	unsigned xIndex;
	unsigned yIndex;
	float xPos;
}

+ genomeGraphicWithGenome:(Genome *)g view:(NSView *)v;
+ (float)xSize;
+ (float)ySize;
+ (void)initCaches;
+ (void)clearCaches;
- initWithGenome:(Genome *)g view:(NSView *)v;
- (void)setParent:(GenomeGraphic *)p;
- (GenomeGraphic *)parent;
- genome;
- (void)addChild:(GenomeGraphic *)c;
- (void)removeChild:(GenomeGraphic *)c;
- children;
- (void)setXIndex:(unsigned)index;
- (unsigned)xIndex;
- (unsigned)yIndex;
- (unsigned)row;
- (void)setXPos:(float)x;
- (float)xPos;
//- (void)determineXCoordInMatrix:(NSArray *)matrix;
//- (float)xSize;
//- (float)ySize;
- (NSRect)viewRect;
- (void)insertView;
- (void)removeView;
- (NSPoint)location;
- (NSPoint)topLineAttachLocation;
- (NSPoint)bottomLineAttachLocation;
- (NSRect)displayRect;
- (void)drawLines;
/*- (void)draw;
- (void)drawWithGraphicView:(NSView *)view;
*/

@end
