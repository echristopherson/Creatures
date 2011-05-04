//
//  LineTool.m
//  Creatures
//
//  Created by Michael Ash on Wed Jan 08 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "LineTool.h"
#import "PixmapUtils.h"
#import "CreatureController.h"
#import "CreaturesView.h"
#import "Creature.h"
#import "Barrier.h"
#import "ToolInteractionView.h"


@implementation LineTool

- (void)awakeFromNib
{
	[super awakeFromNib];
	NSImage *lineToolImage = [NSImage imageNamed:@"line_tool.tiff"];
	MyAssert(lineToolImage != nil, @"Couldn't load line_tool.tiff!");

	[GUIObject setImage:lineToolImage];
	[GUIObject setImagePosition:NSImageOnly];
}

- (void)clickedInView:(ToolInteractionView *)view at:(int)x :(int)y
{
	if(view == [controller view])
	{
		startx = x;
		starty = y;
		inProgress = YES;
		[[controller view] addTemporaryPainter:self];
	}
}

- (void)draggedInView:(ToolInteractionView *)view at:(int)x :(int)y
{
	if(view == [controller view])
	{
		if(inProgress == NO)
		{
			startx = x;
			starty = y;
			inProgress = YES;
			[[controller view] addTemporaryPainter:self];
		}
		curx = x;
		cury = y;
		[[controller view] setNeedsPixmapUpdate];
		[[controller view] setNeedsDisplay:YES];
	}
}

- (void)drawOnPixmap:(PixelUnion *)pixmap width:(int)pixWidth
{
	int fromx, fromy;
	int tox, toy;

	PixelUnion pixel = {{255, 255, 255, 255}};
	pixel.components.r = 127;
	pixel.components.g = 0;
	pixel.components.b = 127;
	tox = MAX(curx, 0);
	tox = MIN(tox, [[controller arena] xSize] - 1);
	toy = MAX(cury, 0);
	toy = MIN(toy, [[controller arena] ySize] - 1);

	if(startx > tox)
	{
		fromx = tox;
		tox = startx;
	}
	else
		fromx = startx;

	if(starty < toy)
	{
		fromy = toy;
		toy = starty;
	}
	else
		fromy = starty;
	
	if(abs(curx - startx) > abs(cury - starty))
		DrawHLine(pixmap, pixWidth, fromx, [[controller arena] ySize] - starty - 1, tox, pixel);
	else
		DrawVLine(pixmap, pixWidth, startx, [[controller arena] ySize] - fromy - 1, [[controller arena] ySize] - toy - 1, pixel);
}

- (void)releasedInView:(ToolInteractionView *)view at:(int)x :(int)y
{
	if(view == [controller view])
	{
		int dx, dy;
		int length;
		[[controller view] removeTemporaryPainter:self];
		if(abs(x - startx) > abs(y - starty))
		{
			x = MAX(x, 0);
			x = MIN(x, [[controller arena] xSize] - 1);
			dy = 0;
			dx = (x - startx < 0) ? -1 : 1;
			length = abs(x - startx) + 1;
		}
		else
		{
			y = MAX(y, 0);
			y = MIN(y, [[controller arena] ySize] - 1);
			dx = 0;
			dy = (y - starty < 0) ? -1 : 1;
			length = abs(y - starty) + 1;
		}

		id arena = [controller arena];
		x = startx;
		y = starty;
		while(length--)
		{
			[[arena creatureFor:x :y] die];
			[arena setFoodValue:0 at:x :y];
			[[[Barrier alloc] initWithArena:arena location:x :y] release];
			x += dx;
			y += dy;
		}
		[[controller view] setNeedsPixmapUpdate];
		[[controller view] setNeedsDisplay:YES];
		[[[controller view] window] setDocumentEdited:YES];
	}
}
	
@end
