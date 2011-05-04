//
//  SquareTool.m
//  Creatures
//
//  Created by Michael Ash on Sat Jan 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "SquareTool.h"
#import "ComputingCreature.h"
#import "Genome.h"
#import "CreatureController.h"
#import "CreaturesView.h"
#import "Barrier.h"
#import "PixmapUtils.h"
#import "GenomeDragAcceptTextField.h"


@implementation SquareTool

- (void)awakeFromNib
{
	[super awakeFromNib];
	NSImage *squareToolImage = [NSImage imageNamed:@"square_tool.tiff"];
	MyAssert(squareToolImage != nil, @"Couldn't load square_tool.tiff!");

	[GUIObject setImage:squareToolImage];
	[GUIObject setImagePosition:NSImageOnly];
}

- (void)unregisterTrackingRect
{
	[[controller view] removeTrackingRect:trackingRectTag];
	tracking = 0;
}

- (void)registerTrackingRect
{
	if(tracking)
	{
		[self unregisterTrackingRect];
	}
	
	trackingRectTag = [[controller view] addTrackingRect:[[controller view] visibleRect] owner:self userData:nil assumeInside:NO];
	tracking = 1;

}

- (void)visibleRectChanged:(NSNotification *)notification
{
	[self registerTrackingRect];
}

- (IBAction)selected:sender
{
	[self registerTrackingRect];

	NSClipView *enclosingClipView = [[[controller view] enclosingScrollView] contentView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(visibleRectChanged:) name:NSViewFrameDidChangeNotification object:enclosingClipView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(visibleRectChanged:) name:NSViewBoundsDidChangeNotification object:enclosingClipView];
}

- (IBAction)deselected:sender
{
	[self unregisterTrackingRect];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)clickedInView:(ToolInteractionView *)view at:(int)px :(int)py
{
	if(view == [controller view])
	{
		int radius = rint([radiusSlider doubleValue]);
		int x, y;
		int percent = rint([coverageSlider doubleValue]);
		int selectedTag = [[creatureTypeMatrix selectedCell] tag];
		int foodValue = 0;
		id arena = [controller arena];
		int arenaXSize = [arena xSize];
		int arenaYSize = [arena ySize];
		if(selectedTag == 1)
			foodValue = [foodValueField intValue];

		for(y = py - radius; y <= py + radius; y++)
		{
			for(x = px - radius; x <= px + radius; x++)
			{
				if(x >= 0 && y >= 0 && x < arenaXSize && y < arenaYSize && (random() % 100) < percent)
				{
					if(selectedTag == 1)
					{
						Creature *creature = [arena creatureFor:x :y];
						if([overwriteCheckbox state] == NSOnState)
						{
							[creature die];
							creature = nil;
						}
						if(creature == nil)
							[arena setFoodValue:foodValue at:x :y];
					}
					else if(selectedTag == 2)
					{
						ComputingCreature *c;
						[arena setFoodValue:0 at:x :y];
						[[arena creatureFor:x :y] die];
						c = [[ComputingCreature alloc] initWithArena:arena location:x :y];
						if(c == nil)
							continue;
						[c setVM:[[genomeField genome] representative]];
						//[c setDefaultData];
						//[c setData:nil size:0];
						[c setColor:[[genomeField genome] color]];
						[c setDirection:random()%4];
						[c setGenome:[genomeField genome]];
						[[genomeField genome] addCreature:c];
						[c release];
					}
					else if(selectedTag == 3)
					{
						[arena setFoodValue:0 at:x :y];
						[[arena creatureFor:x :y] die];
						[[[Barrier alloc] initWithArena:arena location:x :y] release];
					}
					else
					{
						MyErrorLog(@"bad selected tag");
						return;
					}
				}
			}
		}
		[[controller view] setNeedsPixmapUpdate];
		[[controller view] setNeedsDisplay:YES];
		[[[controller view] window] setDocumentEdited:YES];
	}
}

- (void)draggedInView:(ToolInteractionView *)view at:(int)x :(int)y
{
	[self clickedInView:view at:x :y];
}

- (void)movedInView:(ToolInteractionView *)view at:(int)x :(int)y
{
	if(view == [controller view])
	{
		curx = x;
		cury = y;
		[[controller view] setNeedsPixmapUpdate];
		[[controller view] setNeedsDisplay:YES];
	}
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	[[controller view] addTemporaryPainter:self];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	[[controller view] removeTemporaryPainter:self];
	[[controller view] setNeedsPixmapUpdate];
	[[controller view] setNeedsDisplay:YES];
	curx = -1;
	cury = -1;
}

- (int)settingsTab
{
	return 1;
}

- (void)drawOnPixmap:(PixelUnion *)pixmap width:(int)pixWidth
{
	if(curx < 0 || cury < 0)
		return;
	
	PixelUnion pixel = {{255, 255, 255, 255}};
	switch([[creatureTypeMatrix selectedCell] tag])
	{
		case 1:
			pixel.components.r = 0;
			pixel.components.g = [foodValueField intValue];
			pixel.components.b = 0;
			break;
		case 2:
		{
			Pixel24 c = [[genomeField genome] color];
			pixel.components.r = c.r;
			pixel.components.g = c.g;
			pixel.components.b = c.b;
			break;
		}
		case 3:
			pixel.components.r = 127;
			pixel.components.g = 0;
			pixel.components.b = 127;
			break;
	}
	int ulx, uly, lrx, lry;
	int radius = [radiusSlider intValue];
	ulx = MAX(curx - radius, 0);
	uly = MAX(([[controller arena] ySize] - cury - 1) - radius, 0);
	lrx = MIN(curx + radius, [[controller arena] xSize] - 1);
	lry = MIN(([[controller arena] ySize] - cury - 1) + radius, [[controller arena] ySize] - 1);
	FillRectangle(pixmap, pixWidth, ulx, uly, lrx, lry, pixel);
}

@end
