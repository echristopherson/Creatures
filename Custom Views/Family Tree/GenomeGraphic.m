//
//  GenomeGraphic.m
//  Creatures
//
//  Created by Michael Ash on Sun Mar 17 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "GenomeGraphic.h"
#import "StackTrace.h"
#import "GenomeBox.h"


@implementation GenomeGraphicNibLoader

+ nibLoaderWithNibNamed:(NSString *)s
{
	return [[[self alloc] initWithNibNamed:s] autorelease];
}

+ nibLoader
{
	return [self nibLoaderWithNibNamed:@"GenomeGraphicView"];
}

- initWithNibNamed:(NSString *)s
{
	if((self = [super init]))
	{
		[NSBundle loadNibNamed:s owner:self];
		//NSLog(@"%@", self);
	}
	return self;
}

- view
{
	return view;
}

- insideView
{
	return insideView;
}

- genomeBox
{
	return genomeBox;
}

- genomeNameField
{
	return genomeNameField;
}

- mutationsField
{
	return mutationsField;
}

- populationField
{
	return populationField;
}

- (void)dealloc
{
	[view release];
	[super dealloc];
}


- description
{
	return [[super description] stringByAppendingString:[NSString stringWithFormat:@" view frame:%@  view bounds:%@  insideview frame:%@  insideview bounds:%@", NSStringFromRect([view frame]), NSStringFromRect([view bounds]), NSStringFromRect([insideView frame]), NSStringFromRect([insideView bounds])]];
}

@end

@implementation GenomeGraphic

// #define ENABLE_VIEW_CACHING


#if !defined(ENABLE_VIEW_CACHING)
+ nibLoader
{
	return [GenomeGraphicNibLoader nibLoader];
}

+ (void)recycleNibLoader:(GenomeGraphicNibLoader *)v
{
	// this can be a nop because v should be passed in autoreleased
}

+ (void)initCaches
{
	// no caching, so don't do anything
}

+ (void)clearCaches
{
	// no caching, so don't do anything
}

#else // defined(ENABLE_VIEW_CACHING)

static NSMutableArray *cachedLoaders = nil;

+ nibLoader
{
	NSView *obj = [cachedLoaders lastObject];
	if(obj)
	{
		[[obj retain] autorelease]; // keep it around a little longer
		[cachedLoaders removeLastObject];
	}
	else
	{
		obj = [GenomeGraphicNibLoader nibLoader];
	}
	return obj;
}

+ (void)recycleNibLoader:(GenomeGraphicNibLoader *)v
{
	[cachedLoaders addObject:v];
}

+ (void)initCaches
{
	cachedLoaders = [[NSMutableArray alloc] init];
}

+ (void)clearCaches
{
	[cachedLoaders release];
	cachedLoaders = nil;
}
#endif

+ genomeGraphicWithGenome:(Genome *)g view:(NSView *)v
{
	return [[[self alloc] initWithGenome:g view:v] autorelease];
}

// both of these functions should be rewritten, this way sucks.
// properly caching views should fix it.
+ (float)xSize
{
	static float size = -1.0;
	if(size < 0.0)
		size = [[[GenomeGraphicNibLoader nibLoader] view] frame].size.width;
	return size;
}

+ (float)ySize
{
	static float size = -1.0;
	if(size < 0.0)
		size = [[[GenomeGraphicNibLoader nibLoader] view] frame].size.height;
	return size;
}

+ (NSRect)insideFrame
{
	static NSRect frame = {{-1.0, -1.0}, {-1.0, -1.0}};
	if(frame.origin.x < 0.0)
		frame = [[[GenomeGraphicNibLoader nibLoader] insideView] frame];
	return frame;
}


- initWithGenome:(Genome *)g view:(NSView *)v
{
	if((self = [super init]))
	{
		genome = [g retain];
		treeView = v;
		//[NSBundle loadNibNamed:@"GenomeGraphicView" owner:self];
	}
	return self;
}

- (void)dealloc
{
	[loader release];
	//[view release];
	[children release];
	[genome release];
	
	[super dealloc];
}

- (void)setParent:(GenomeGraphic *)p
{
	parent = p;
}

- (GenomeGraphic *)parent
{
	return parent;
}

- genome
{
	return genome;
}

- (void)addChild:(GenomeGraphic *)c
{
	if(children == nil)
		children = [[NSMutableArray alloc] init];
	MyAssert(![children containsObject:c], @"");
	[children addObject:c];
}

- (void)removeChild:(GenomeGraphic *)c
{
	[children removeObjectIdenticalTo:c];
}

- children
{
	return children;
}

- (void)setXIndex:(unsigned)index
{
	xIndex = index;
}

- (unsigned)xIndex
{
	return xIndex;
}

- (unsigned)yIndex
{
	if(yIndex == 0)
		yIndex = parent ? [parent yIndex] + 1 : 0;
	
	return yIndex;
}

- (unsigned)row
{
	return [self yIndex];
}

- (void)setXPos:(float)x
{
	xPos = rint(x);
}

- (float)xPos
{
	return xPos;
}

/*- (void)displaceRight:(float)howMuch
{
	xPos += howMuch;
	[[children do] displaceRight:howMuch];
}

- (void)determineXCoordInMatrix:(NSArray *)matrix
{
	if(children)
	{
		NSEnumerator *enumerator;
		GenomeGraphic *obj;
		float xTotal = 0.0;
		
		enumerator = [children objectEnumerator];
		while((obj = [enumerator nextObject]))
		{
			[obj determineXCoordInMatrix:matrix];
			xTotal += [obj xPos];
		}

		xPos = xTotal / [children count];
		if(xIndex > 0)
		{
			float leftX = [[[matrix objectAtIndex:[genome mutations]] objectAtIndex:xIndex - 1] xPos];
			float diff = xPos - leftX;
			if(diff < bufferSpace)
			{
				[self displaceRight:bufferSpace - diff];
			}
		}
	}
	else if(xIndex > 0)
		xPos = [[[matrix objectAtIndex:[genome mutations]] objectAtIndex:xIndex - 1] xPos] + bufferSpace;
	else
		xPos = 5;
}*/

- (float)xSize
{
	return [view frame].size.width;
}

- (float)ySize
{
	return [view frame].size.height;
}

- (NSRect)viewRect
{
	NSPoint location = [self location];
	return NSMakeRect(location.x, location.y, [GenomeGraphic xSize], [GenomeGraphic ySize]);
}

- (void)insertView
{
	MyAssert(loader == nil, @"");
	loader = [[GenomeGraphic nibLoader] retain];
	view = [loader view];
	insideView = [loader insideView];

	NSRect myRect = [view frame];
	myRect.origin = [self location];
	/*NSEnumerator *enumerator = [[treeView subviews] objectEnumerator];
	id obj;
	while((obj = [enumerator nextObject]))
	{
		if(NSIntersectsRect(myRect, [obj frame]))
			NSLog(@"Error! Intersection of my rect %@ with object @% at %@", NSStringFromRect(myRect), obj, NSStringFromRect([obj frame]));
	}*/

	[[loader genomeBox] setGenome:genome];
	[[loader genomeNameField] setStringValue:[genome name]];
	[[loader mutationsField] setIntValue:[genome mutations]];
	[[loader populationField] setIntValue:[genome population]];
	
	[treeView addSubview:view];
	[view setFrameOrigin:[self location]];
}

- (void)removeView
{
	[view removeFromSuperview];
	[GenomeGraphic recycleNibLoader:[loader autorelease]];
	loader = nil;
	view = insideView = nil;
}

- (NSPoint)location
{
	return NSMakePoint(xPos, [self yIndex] * [GenomeGraphic ySize]);
}

- (NSPoint)topLineAttachLocation
{
	NSRect viewFrame = [GenomeGraphic insideFrame];
	NSPoint location = [self location];
	viewFrame.origin.y = [GenomeGraphic ySize] - (viewFrame.origin.y + viewFrame.size.height);
	viewFrame.origin.x += location.x;
	viewFrame.origin.y += location.y;
	
	NSPoint point = NSMakePoint(rint(viewFrame.origin.x + viewFrame.size.width/2.0) + 0.5, viewFrame.origin.y + 0.5);
	return point;
}

- (NSPoint)bottomLineAttachLocation
{
	NSRect viewFrame = [GenomeGraphic insideFrame];
	NSPoint location = [self location];
	viewFrame.origin.y = [GenomeGraphic ySize] - (viewFrame.origin.y + viewFrame.size.height);
	viewFrame.origin.x += location.x;
	viewFrame.origin.y += location.y;

	NSPoint point = NSMakePoint(rint(viewFrame.origin.x + viewFrame.size.width/2.0) + 0.5, viewFrame.origin.y + viewFrame.size.height + 0.5);
	return point;
}

- (NSRect)displayRect
{
	NSPoint myPoint = [self topLineAttachLocation];
	NSPoint pPoint = [parent bottomLineAttachLocation];
	return NSMakeRect(MIN(myPoint.x, pPoint.x), MIN(myPoint.y, pPoint.y), fabs(myPoint.x - pPoint.x) + 1, myPoint.y - pPoint.y);
}

- (void)drawLines
{
	if(parent)
	{
		[NSBezierPath strokeLineFromPoint:[self topLineAttachLocation] toPoint:[parent bottomLineAttachLocation]];
	}	
}

/*- (NSRect)displayRect
{
	NSRect myRect = NSMakeRect(xPos, [genome mutations] * graphicYSpace, graphicXSpace, graphicYSpace);
	NSRect parentRect = NSMakeRect([parent xPos], [parent row] * graphicYSpace + graphicYSize, 0.001, 0.001);
	NSRect returnValue = NSUnionRect(myRect, parentRect);
	return returnValue;
}

- (void)draw
{
	[NSBezierPath strokeRect:NSMakeRect(xPos + 5.0, [genome mutations] * graphicYSpace, graphicXSpace - 5.0, graphicYSize)];
	NSString *str = [[NSString alloc] initWithFormat:@"ID: %d", [genome genomeID]];
	[str drawInRect:NSMakeRect(xPos + 10, [genome mutations] * graphicYSpace + 5, graphicXSpace - 5, 12) withAttributes:nil];
	[str release];
	if(parent)
	{
		[NSBezierPath strokeLineFromPoint:NSMakePoint(xPos + graphicXSpace/2.0, [genome mutations] * graphicYSpace) toPoint:NSMakePoint([parent xPos] + graphicXSpace/2.0, ([genome mutations] - 1) * graphicYSpace + graphicYSize)];
	}
}

- (void)drawWithGraphicView:(NSView *)view
{
	NSCopyBits([view gState], [view bounds], [self location]);
}*/


@end
