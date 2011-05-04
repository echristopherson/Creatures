
#import <Carbon/Carbon.h>
#import <QuickTime/QuickTime.h>
#import "CreaturesView.h"
#import "CreatureController.h"
#import "ComputingCreature.h"
#import "Arena.h"
#import "PixmapUtils.h"
#import "DrawingTool.h"
#import "NSViewAdditions.h"


@implementation CreaturesView

- (id)initWithFrame:(NSRect)frame
{
	if((self = [super initWithFrame:frame]))
	{
		temporaryPainters = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)awakeFromNib
{
	/*if ([[self superclass] instancesRespondToSelector:@selector(awakeFromNib)]) {
        [super awakeFromNib];
    }*/
	[[self window] setAcceptsMouseMovedEvents:YES];
}

- (void)setArena:a
{
	//float xProportion, yProportion;
	//NSSize idealFrameSize;
	NSSize screenSize;
	
	arena = a;
	pixWidth = [arena xSize];
	pixHeight = [arena ySize];
	if(pixmap)
		free(pixmap);
	pixmap = malloc(pixWidth * pixHeight * sizeof(*pixmap));
	ClearPixmap(pixmap, pixWidth, pixHeight);
	lastUpdatedStep = -1;
	//[self setBounds:NSMakeRect(0, 0, xSize, ySize)];
	originX = 0;
	originY = 0;
	screenSize = [[NSScreen mainScreen] frame].size;
	if(pixWidth < screenSize.width / 3 && pixHeight < screenSize.height / 3)
	{
		zoomFactor = 2;
	}
	else
	{
		zoomFactor = 1;
	}
	//[self setFrame:NSMakeRect(0,0,pixWidth,pixHeight)];
	[self setFrame:NSMakeRect(0, 0, pixWidth * zoomFactor, pixHeight * zoomFactor)];
	//[self setBounds:NSMakeRect(0, 0, pixWidth, pixHeight)];

	if(![[self window] isZoomed])
		[[self window] zoom:nil];
	/*xProportion = [scrollView contentSize].width / (float)pixWidth;
	yProportion = [scrollView contentSize].height / (float)pixHeight;
	zoomFactor = MIN(xProportion, yProportion);
	if(zoomFactor > 2)
		zoomFactor = 2;

	[self setFrame:NSMakeRect(0, 0, pixWidth * zoomFactor, pixHeight * zoomFactor)];
	[self setBounds:NSMakeRect(0, 0, pixWidth, pixHeight)];
	idealFrameSize = [NSScrollView frameSizeForContentSize:[self frame].size hasHorizontalScroller:YES hasVerticalScroller:YES borderType:[scrollView borderType]];
	[[self window] setContentSize:idealFrameSize];*/

	//[self setBounds:NSMakeRect(0, 0, [self bounds].size.width / zoomFactor, [self bounds].size.height / zoomFactor)];
}

- (void)dealloc
{
	if(pixmap)
		free(pixmap);
	[temporaryPainters release];
	
	[super dealloc];
}

- (void)addTemporaryPainter:obj
{
	[temporaryPainters addObject:obj];
}

- (void)removeTemporaryPainter:obj
{
	[temporaryPainters removeObject:obj];
}

- (void)setNeedsPixmapUpdate
{
	lastUpdatedStep = -1;
}

- (void)drawTemporaryPainters
{
	NSEnumerator *enumerator = [temporaryPainters objectEnumerator];
	id obj;
	while((obj = [enumerator nextObject]))
		[obj drawOnPixmap:pixmap width:pixWidth];
}	

- (void)updatePixmapIfNeeded
{
	if(lastUpdatedStep < [arena stepNumber])
	{
		lastUpdatedStep = [arena stepNumber];
		[arena drawOnPixmap:pixmap width:pixWidth];
		[self drawTemporaryPainters];
	}
}

- (void)drawPixmap:(PixelUnion *)map
{
	SetGWorld([self qdPort], nil);
	// set background & foreground
	BackColor( whiteColor );
	ForeColor( blackColor );

	Rect srcRect = {0, 0, pixHeight, pixWidth};
	Rect destRect = {0, 0, [self frame].size.height, [self frame].size.width};
	GWorldPtr myGWorld;
	OSStatus err = QTNewGWorldFromPtr(&myGWorld, k32ARGBPixelFormat, &srcRect, nil, nil, nil, map, pixWidth * 4);
	MyAssert(err == 0, @"Got error %d calling QTNewGWorldFromPtr()", err);

	// make a masking region equal to our visible rect
	NSRect visibleRect = [self visibleRect];
	RgnHandle rgn = NewRgn();
	SetRectRgn(rgn, visibleRect.origin.x, visibleRect.origin.y,
			visibleRect.origin.x + visibleRect.size.width,
			visibleRect.origin.y + visibleRect.size.height);
	
	// now copy
	CopyBits( GetPortBitMapForCopyBits( myGWorld ),
		   GetPortBitMapForCopyBits( [self qdPort] ),
		   &srcRect, &destRect, srcCopy, rgn );

	// kill the region handle
	DisposeRgn(rgn);

	DisposeGWorld(myGWorld);
	QDFlushPortBuffer([self qdPort], NULL);
}

- (void)drawRect:(NSRect)rect
{
	if(arena)
	{
		/*NSBitmapImageRep *imageRep;
		unsigned char *foodPixmap = [arena foodData];
		imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: (unsigned char **)&foodPixmap
														pixelsWide: pixWidth
														pixelsHigh: pixHeight
													 bitsPerSample: 8
												   samplesPerPixel: 1
														  hasAlpha: NO
														  isPlanar: NO
													colorSpaceName: NSCalibratedWhiteColorSpace
													   bytesPerRow: 0
													  bitsPerPixel: 0];
		[imageRep colorizeByMappingGray:0.5
				toColor:[NSColor colorWithDeviceRed:0 green:0.5 blue:0 alpha:1]
				blackMapping:[NSColor blackColor] whiteMapping:[NSColor whiteColor]];
		[arena drawOnPixmap:(PixelUnion *)[imageRep bitmapData] width:pixWidth];
		[imageRep draw];
		[imageRep release];*/
		if([arena continuousUpdates])
		{
			PixelUnion *arenamap = [arena pixmap];
			if(![temporaryPainters count])
			{
				[self drawPixmap:arenamap];
				/*NSBitmapImageRep *imageRep;
				imageRep = [[NSBitmapImageRep alloc]
								initWithBitmapDataPlanes: (unsigned char **)&arenamap
																pixelsWide: pixWidth
																pixelsHigh: pixHeight
															bitsPerSample: 8
														samplesPerPixel: 4
																hasAlpha: YES
																isPlanar: NO
															colorSpaceName: NSDeviceRGBColorSpace
															bytesPerRow: 0
															bitsPerPixel: 0];
				[imageRep draw];
				[imageRep release];*/
			}
			else
			{
				memcpy(pixmap, arenamap, pixWidth * pixHeight * sizeof(*pixmap));
				[self drawTemporaryPainters];
				[self drawPixmap:pixmap];
				/*NSBitmapImageRep *imageRep;
				imageRep = [[NSBitmapImageRep alloc]
								initWithBitmapDataPlanes: (unsigned char **)&pixmap
																	  pixelsWide: pixWidth
																	  pixelsHigh: pixHeight
																bitsPerSample: 8
														   samplesPerPixel: 4
																		hasAlpha: YES
																		isPlanar: NO
															   colorSpaceName: NSDeviceRGBColorSpace
																  bytesPerRow: 0
																 bitsPerPixel: 0];
				[imageRep draw];
				[imageRep release];*/
			}
		}
		else
		{
			[self drawPixmap:pixmap];
			/*NSBitmapImageRep *imageRep;
			[self updatePixmapIfNeeded];
			imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: (unsigned char **)&pixmap
															pixelsWide: pixWidth
															pixelsHigh: pixHeight
														 bitsPerSample: 8
													   samplesPerPixel: 4
															  hasAlpha: YES
															  isPlanar: NO
														colorSpaceName: NSDeviceRGBColorSpace
														   bytesPerRow: 0
														  bitsPerPixel: 0];
			[imageRep draw];
			[imageRep release];*/
			//NSDrawBitmap(NSMakeRect(0, 0, pixWidth, pixHeight), pixWidth, pixHeight, 8, 4, 32, pixWidth * 4, NO, YES, NSDeviceRGBColorSpace, &pixmap);
		}
	}
	//[arena draw];
}

- (void)zoomIn:sender
{
	NSPoint center;
	if(zoomFactor > 16)
		return;
	zoomFactor *= 2;
	center = [self centerVisiblePoint];
	[self setFrame:NSMakeRect(0, 0, pixWidth * zoomFactor, pixHeight * zoomFactor)];
	[self centerPointInView:center];
	[self setNeedsDisplay:YES];
}

- (void)zoomOut:sender
{
	//NSSize newWindowSize;
	if(pixWidth * zoomFactor / 2 < 100 || pixHeight * zoomFactor / 2 < 100)
		return;

	zoomFactor /= 2;
	[self setFrame:NSMakeRect(0, 0, pixWidth * zoomFactor, pixHeight * zoomFactor)];
	//[self setBounds:NSMakeRect(0, 0, pixWidth, pixHeight)];
	[self setNeedsDisplay:YES];
	
	NSSize contentSize = [[[self window] contentView] frame].size;
	NSSize maxSize = [NSScrollView frameSizeForContentSize:[self frame].size hasHorizontalScroller:YES hasVerticalScroller:YES borderType:[scrollView borderType]];
	NSPoint scrollViewOrigin = [scrollView frame].origin;
	maxSize.width += scrollViewOrigin.x;
	maxSize.height += scrollViewOrigin.y;

	BOOL shouldResize = NO;
	if(contentSize.width > maxSize.width)
	{
		contentSize.width = maxSize.width;
		shouldResize = YES;
	}
	if(contentSize.height > maxSize.height)
	{
		contentSize.height = maxSize.height;
		shouldResize = YES;
	}

	if(shouldResize)
	{
		NSPoint windowOrigin = [[self window] frame].origin;
		[[self window] setContentSize:contentSize];
		[[self window] setFrameOrigin:windowOrigin];
	}
}

- (BOOL)isOpaque
{
	return YES;
}

- (BOOL)acceptsFirstResponder;
{
	return YES;
}

@end
