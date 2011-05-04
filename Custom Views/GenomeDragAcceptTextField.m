//
//  GenomeDragAcceptTextField.m
//  Creatures
//
//  Created by Michael Ash on Thu Jun 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "GenomeDragAcceptTextField.h"
#import "Genome.h"


@implementation GenomeDragAcceptTextField

- (void)awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(genomeDestroyed:) name:GenomeDestroyedNotification object:nil];
}

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
	[self registerForDraggedTypes:[NSArray arrayWithObject:GenomeDragDataType]];
}

- (void)setGenome:(Genome *)g
{
	genome = g;
	[self setStringValue:[genome name]];
}

- (Genome *)genome
{
	return genome;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
	pboard = [sender draggingPasteboard];
	if([[pboard types] containsObject:GenomeDragDataType])
	{
		return NSDragOperationCopy;
	}
	return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
	pboard = [sender draggingPasteboard];
	if([[pboard types] containsObject:GenomeDragDataType])
	{
		[self setGenome:*((Genome **)[[pboard dataForType:GenomeDragDataType] bytes])];
		return YES;
	}
	else
		return NO;
}

- (void)genomeDestroyed:(NSNotification *)notification
{
	Genome *destroyedGenome = [notification object];
	if(destroyedGenome == genome)
	{
		[self setGenome:[Genome defaultGenome]];
	}
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

@end
