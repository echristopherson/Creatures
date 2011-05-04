//
//  FamilyTreeView.m
//  Creatures
//
//  Created by Michael Ash on Fri Mar 15 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "FamilyTreeView.h"
#import "Genome.h"
#import "GenomeGraphic.h"
#import "NSViewAdditions.h"


/*

 Where to place Genome graphics.

 1) sibling genomes should always be adjacent
 2) parent's x coordinate should be the average of the children's x coords
 3) 1 and 2 together mean that children may have to be moved around a bit as well

 and we then come to algorithm

 determine the X position of genome 0

 to determine the X position of any given genome
 {
	 determine the X position of the children, in left-to-right order (important!!!)
	 take the average of children's X positions
	 if the average is less than the position of the genome to the left plus a suitable buffer
	 {
		 shift our position right by whatever's needed to give us enough space
		 if this extends past the rightmost child's X
			 recursively shift the children enough to line the rightmost child up with us
	 }
 }

 Coming back to this thing after a hell of a long time away (it is now January 11, 2003).
 This algorithm is insanely complicated, and I have the fun task of making it 100% iterative,
 since recursive calls on Genomes overflow the stack after a while. Whoot!

 Ok, this basically boils down to a depth-first tree traversal problem, with some side bits.

 So, traverse the tree depth-first (heading down the left to start with, of course). The first
 node is the far leftmost child, so he gets an x position of 0. What we do is track the maximum
 x position of every row, and use that to assign positions.

 This ignores the problem of making parents and children line up nicely, but that should
 probably be done in a second pass anyway.
		 
 */


@interface FamilyTreeView (Private)

- (void)updateVisibleGraphicsSet;
- (void)buildGenomeStructure;
- (NSSize)requiredBoundsSize;
- (void)setFrameSize;
- (void)destroyStructures;
- (void)reflectChangedZoomFactor;
- (void)centerGenome:(GenomeGraphic *)graphic;

@end

@implementation FamilyTreeView (Private)

- (void)updateVisibleGraphicsSet
{
	NSRect rect = [self visibleRect];
	float graphicYSpace = [GenomeGraphic ySize];
	int startRow = rect.origin.y / graphicYSpace;
	int endRow = (rect.origin.y + rect.size.height) / graphicYSpace;

	if(startRow < 0)
		startRow = 0;
	if(endRow >= [rows count])
		endRow = [rows count] - 1;

	NSMutableArray *newViewsArray = [NSMutableArray array];

	int x, y;
	for(y = startRow; y <= endRow; y++)
	{
		int count = [[rows objectAtIndex:y] count];
		for(x = 0; x < count; x++)
		{
			GenomeGraphic *obj = [[rows objectAtIndex:y] objectAtIndex:x];
			if(NSIntersectsRect(rect, [obj viewRect]))
				[newViewsArray addObject:obj];
		}
	}

	NSSet *newVisibleGraphics = [[NSSet alloc] initWithArray:newViewsArray];
	NSMutableSet *graphicsToRemove = [NSMutableSet setWithSet:visibleGraphics];
	[graphicsToRemove minusSet:newVisibleGraphics];

	NSMutableSet *graphicsToAdd = [NSMutableSet setWithSet:newVisibleGraphics];
	[graphicsToAdd minusSet:visibleGraphics];

	[visibleGraphics release];
	visibleGraphics = newVisibleGraphics;

	[graphicsToRemove makeObjectsPerformSelector:@selector(removeView)];
	[graphicsToAdd    makeObjectsPerformSelector:@selector(insertView)];
}

- (void)notifyVisibleRectChanged:(NSNotification *)notification
{
	[self setFrameSize];
	//[self performSelector:@selector(updateVisibleGraphicsSet) withObject:nil afterDelay:0];
}

- (void)makeGraphicObjects
{
	graphicsDict = [[NSMutableDictionary alloc] init];

	NSEnumerator *enumerator = [[Genome genomeList] objectEnumerator];
	id obj;
	while((obj = [enumerator nextObject]))
	{
		GenomeGraphic *graphic = [[GenomeGraphic alloc] initWithGenome:obj view:self];
		[graphicsDict setObject:graphic forKey:obj];
		[graphic release];
	}

	enumerator = [graphicsDict objectEnumerator];
	while((obj = [enumerator nextObject]))
	{
		if([[obj genome] parent])
			[(GenomeGraphic *)obj setParent:[graphicsDict objectForKey:[[obj genome] parent]]];
		else
			[rootGraphics addObject:obj];

		NSEnumerator *childEnumerator = [[[obj genome] children] objectEnumerator];
		id child;
		while((child = [childEnumerator nextObject]))
		{
			[(GenomeGraphic *)obj addChild:[graphicsDict objectForKey:child]];
		}
	}
}

- (void)buildRowsMatrix
{
	NSMutableArray *stack = [NSMutableArray array];
	NSEnumerator *enumerator = [rootGraphics reverseObjectEnumerator];
	id obj;
	while((obj = [enumerator nextObject]))
	{
		[stack addObject:obj];
	}

	while([stack count] > 0)
	{
		id graphic = [stack lastObject];
		[stack removeLastObject];
		int yIndex = [graphic yIndex];
		MyAssert([rows count] >= yIndex, @"");
		if([rows count] == yIndex)
			[rows insertObject:[NSMutableArray array] atIndex:yIndex];
		[graphic setXIndex:[[rows objectAtIndex:yIndex] count]];
		[[rows objectAtIndex:yIndex] addObject:graphic];

		NSEnumerator *childEnumerator = [[graphic children] reverseObjectEnumerator];
		id child;
		while((child = [childEnumerator nextObject]))
		{
			[stack addObject:child];
		}
	}
}

- (void)deplaceGraphic:(GenomeGraphic *)parent andChildrenBy:(float)dx
{
	NSMutableArray *stack = [NSMutableArray arrayWithObject:parent];
	while([stack count] > 0)
	{
		GenomeGraphic *graphic = [stack lastObject];
		[stack removeLastObject];
		[graphic setXPos:[graphic xPos] + dx];
		if([graphic children])
			[stack addObjectsFromArray:[graphic children]];
	}
}

- (void)assignXCoordinates
{
	/* construct a depth-first non-recursive traversal of the graphics tree */
	/*
	 normally you do:
	 [recurse on all children]
	 [do it for us]
	 */
	NSMutableArray *traverseStack = [NSMutableArray array];
	NSMutableArray *actionStack = [NSMutableArray array];
	NSEnumerator *enumerator = [rootGraphics objectEnumerator];
	id obj;
	while((obj = [enumerator nextObject]))
	{
		[traverseStack addObject:obj];
	}

	while([traverseStack count] > 0)
	{
		id graphic = [traverseStack lastObject];
		[traverseStack removeLastObject];
		[actionStack addObject:graphic];
		if([graphic children])
			[traverseStack addObjectsFromArray:[graphic children]];
	}

	NSEnumerator *graphicEnumerator = [actionStack reverseObjectEnumerator];
	id graphic;
	while((graphic = [graphicEnumerator nextObject]))
	{
		NSArray *row = [rows objectAtIndex:[graphic yIndex]];
		if([[graphic children] count] == 0)
		{
			if([graphic xIndex] == 0)
				[graphic setXPos:0];
			else
			{
				GenomeGraphic *neighbor = [row objectAtIndex:[graphic xIndex] - 1];
				[graphic setXPos:[neighbor xPos] + [GenomeGraphic xSize]];
			}
		}
		else
		{
			float childXPosTotal = 0.0;
			NSEnumerator *childEnumerator = [[graphic children] objectEnumerator];
			id child;
			while((child = [childEnumerator nextObject]))
			{
				childXPosTotal += [child xPos];
			}
			[graphic setXPos:rint(childXPosTotal / (float)[[graphic children] count])];
			if([graphic xIndex] > 0)
			{
				GenomeGraphic *neighbor = [row objectAtIndex:[graphic xIndex] - 1];
				float dx = [neighbor xPos] + [GenomeGraphic xSize] - [graphic xPos];
				if(dx > 0)
					[self deplaceGraphic:graphic andChildrenBy:dx];
			}
		}
	}
}

- (void)buildGenomeStructure
{
	rows = [[NSMutableArray alloc] init];
	rootGenomes = [[NSMutableArray alloc] init];
	rootGraphics = [[NSMutableArray alloc] init];
	visibleGraphics = [[NSSet alloc] init];

	[GenomeGraphic initCaches];

	NSEnumerator *enumerator = [[Genome genomeList] objectEnumerator];
	id obj;
	while((obj = [enumerator nextObject]))
	{
		if([obj parent] == nil)
			[rootGenomes addObject:obj];
	}

	[self makeGraphicObjects];
	[self buildRowsMatrix];
	[self assignXCoordinates];
}

- (void)genomeDestroyed:(NSNotification *)notification
{
	Genome *genome = [notification object];
	GenomeGraphic *graphic = [graphicsDict objectForKey:genome];
	if(graphic)
	{
		NSMutableArray *row = [rows objectAtIndex:[graphic yIndex]];
		
		[graphic removeView];
		[[graphic parent] removeChild:graphic];
		[row removeObjectIdenticalTo:graphic];
		[graphicsDict removeObjectForKey:genome];
		
		[self setNeedsDisplay:YES];
	}
}

- (NSSize)requiredBoundsSize
{
	NSEnumerator *enumerator;
	id obj;
	float largestX = 0;
	enumerator = [rows objectEnumerator];
	while((obj = [enumerator nextObject]))
	{
		float x = [[obj lastObject] xPos] + [GenomeGraphic xSize];
		if(x > largestX)
			largestX = x;
	}

	float largestY = [rows count] * [GenomeGraphic ySize];

	return NSMakeSize(largestX, largestY);
}

- (void)setFrameSize
{
	NSSize boundsSize = [self requiredBoundsSize];
	float largestX = boundsSize.width;
	float largestY = boundsSize.height;
	
	largestX *= zoomFactor;
	largestY *= zoomFactor;
	
	NSSize visibleSize = [[[self enclosingScrollView] contentView] bounds].size;
	largestX = MAX(largestX, visibleSize.width);
	largestY = MAX(largestY, visibleSize.height);
	
	[self setFrameSize:NSMakeSize(largestX, largestY)];	
}

- (void)destroyStructures
{
	[[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[rows release];
	rows = nil;
	[rootGenomes release];
	rootGenomes = nil;
	[rootGraphics release];
	rootGraphics = nil;
	[visibleGraphics release];
	visibleGraphics = nil;
	[graphicsDict release];
	graphicsDict = nil;
	[GenomeGraphic clearCaches];
}

- (void)reflectChangedZoomFactor
{
	NSPoint center = [self centerVisiblePoint];
	NSSize boundsSize = [self requiredBoundsSize];
	NSSize frameSize = NSMakeSize(boundsSize.width * zoomFactor, boundsSize.height * zoomFactor);
	[self setFrameSize:frameSize];
	[self setBoundsSize:boundsSize];

	[self centerPointInView:center];
	[self setFrameSize];
	[self setNeedsDisplay:YES];
}

- (void)centerGenome:(GenomeGraphic *)graphic
{
	[self setFrameSize];
	
	NSRect rect = [self visibleRect];
	NSRect genomeRect = [graphic viewRect];
	rect.origin = genomeRect.origin;
	rect.origin.x -= (rect.size.width - genomeRect.size.width)/2.0;
	[self scrollRectToVisible:rect];
	[self setNeedsDisplay:YES];	
}

@end

@implementation FamilyTreeView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		zoomFactor = 1;
    }
    return self;
}

- (void)awakeFromNib
{
	//NSLog(@"[%@ superview] = %@", self, [self superview]);

	[[self superview] setPostsBoundsChangedNotifications:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyVisibleRectChanged:) name:NSViewBoundsDidChangeNotification object:[self superview]];

	[[self superview] setPostsFrameChangedNotifications:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyVisibleRectChanged:) name:NSViewFrameDidChangeNotification object:[self superview]];
	
	//[[self superview] scrollTo

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(genomeDestroyed:) name:GenomeDestroyedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(destroyStructures) name:NSWindowWillCloseNotification object:[self window]];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self destroyStructures];
	[super dealloc];
}

- (BOOL)isFlipped
{
	return YES;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSScrollView *scrollView = [self enclosingScrollView];
	NSClipView *clipView = [scrollView contentView];

	NSPoint oldOrigin = [clipView bounds].origin;
	NSPoint newOrigin = [clipView constrainScrollPoint:NSMakePoint(oldOrigin.x - [theEvent deltaX], oldOrigin.y - [theEvent deltaY])];
	[clipView scrollToPoint:newOrigin];
	[scrollView reflectScrolledClipView:clipView];
}

- (void)drawRect:(NSRect)rect {
	if(rows == nil)
	{
		[self buildGenomeStructure];
		[self setFrameSize];
	}
	
	[self updateVisibleGraphicsSet];
	float graphicYSpace = [GenomeGraphic ySize];
	int startRow = rect.origin.y / graphicYSpace;
	int endRow = (rect.origin.y + rect.size.height) / graphicYSpace + 1;
	//[(GenomeGraphic *)[[rows do] do] draw];
	int x, y;

	if(startRow < 0)
		startRow = 0;
	if(endRow >= [rows count])
		endRow = [rows count] - 1;

	for(y = startRow; y <= endRow; y++)
		for(x = 0; x < [[rows objectAtIndex:y] count]; x++)
		{
			GenomeGraphic *obj = [[rows objectAtIndex:y] objectAtIndex:x];
			if(NSIntersectsRect(rect, [obj displayRect]))
				[obj drawLines];
			//if(NSIntersectsRect(rect, [obj viewRect]))
			//	[obj insertView];
		}
}

- (void)zoomIn:sender
{
	if(zoomFactor >= 1) // don't allow zooming greater than 1:1
		return;

	zoomFactor *= 2;
	[self reflectChangedZoomFactor];
}

- (void)zoomOut:sender
{
	if(zoomFactor <= 1.0/8.0) // don't allow zooming less than 1:16
		return;
	
	zoomFactor /= 2;
	[self reflectChangedZoomFactor];
}

- (void)reloadTree:sender
{
	[self destroyStructures];
	[self buildGenomeStructure];
	[self centerFirstGenome:self];
	[self setNeedsDisplay:YES];
}

- (void)centerFirstGenome:sender
{
	if(rows)
		[self centerGenome:[[rows objectAtIndex:0] objectAtIndex:0]];
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

@end
