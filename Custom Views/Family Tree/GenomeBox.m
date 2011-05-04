//
//  GenomeBox.m
//  Creatures
//
//  Created by Michael Ash on Wed Jul 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "GenomeBox.h"
#import "Genome.h"


@implementation GenomeBox

- (void)setGenome:(Genome *)g
{
	genome = g;
}

- (Genome *)genome
{
	return genome;
}

- (void)mouseDown:(NSEvent *)theEvent
{
	if([theEvent clickCount] == 1)
	{
		NSImage *myImage = [[NSImage alloc] initWithData:[self dataWithPDFInsideRect:[self bounds]]];

		NSPoint clickLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		NSSize dragOffset = NSMakeSize(clickLocation.x, clickLocation.y);
		NSPasteboard *pboard;

		pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
		[pboard declareTypes:[NSArray arrayWithObject:GenomeDragDataType] owner:self];
		[pboard setData:[NSData dataWithBytes:(const void *)&genome length:sizeof(genome)] forType:GenomeDragDataType];
			
		[Genome disableCulling];
		[self dragImage:myImage at:NSMakePoint(0, 0) offset:dragOffset
			event:theEvent pasteboard:pboard source:self slideBack:YES];
		[myImage release];
		
	}
	else if([theEvent clickCount] == 2)
	{
		[genome openWindow];
	}
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
	[Genome enableCulling];
}

@end
