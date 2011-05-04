//
//  GenomeWindowController.m
//  Creatures
//
//  Created by mikeash on Wed Oct 31 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "GenomeWindowController.h"
#import "Genome.h"
#import "GenomeAssemblerController.h"
#import "CreatureController.h"
#import "CreaturesView.h"
#import "PixmapUtils.h"

@interface NSView (RecursivelyDisableSubviews)

- (void)recursivelyDisableSubviews;

@end

@implementation NSView (RecursivelyDisableSubviews)

- (void)recursivelyDisableSubviews
{
	if([self respondsToSelector:@selector(setEnabled:)])
		[(id)self setEnabled:NO];
	else if([self respondsToSelector:@selector(setEditable:)])
		[(id)self setEditable:NO];
	NSEnumerator *enumerator = [[self subviews] objectEnumerator];
	NSView *view;
	while((view = [enumerator nextObject]))
		[view recursivelyDisableSubviews];
}

@end

@implementation GenomeWindowController

- initWithGenome:g
{
	if((self = [super initWithWindowNibName:@"GenomeWindow"]))
	{
		[self retain]; // releases when window closes
		genome = g;
		[[self window] setDelegate:self];
		[[self window] setTitle:[NSString stringWithFormat:@"%@ %@", [[self window] title], [genome name]]];
		[colorWell setColor:ColorForPixel24([genome color])];
		[self update];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(genomeDestroyed:) name:GenomeDestroyedNotification object:genome];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeColor:) name:NSColorPanelColorDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:[self window] selector:@selector(performClose:) name:CreatureNewArenaCreatedNotification object:nil];
	}
	return self;
}

- initWithWindowNibName:name
{
	MyErrorLog(@"method should never be called");
	[self release];
	return nil;
}

- (BOOL)windowShouldClose:sender
{
	if([showCOGButton state] == NSOnState)
		[[[Genome creatureController] view] removeTemporaryPainter:self];
	
	[genome windowClosing];
	[self autorelease];
	return YES;
}

- (void)setGenome:g
{
	genome = g;
}

- (void)update
{
	[populationCurrentField setIntValue:[genome population]];
	[populationTotalField setIntValue:[genome totalPopulation]];
	[populationPeakField setIntValue:[genome peakPopulation]];
	[mutationsField setIntValue:[genome mutations]];
	if([genome lastDeathStep] == 0)
		[lifetimeField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%d - present", @"Format string indicating a genome's lifetime when the genome is not extinct"), [genome firstAppearanceStep]]];
	else
		[lifetimeField setStringValue:[NSString stringWithFormat:@"%d - %d", [genome firstAppearanceStep], [genome lastDeathStep]]];

	[commentTextView setString:[genome comment]];
	if(![genome parent])
		[parentButton setEnabled:false];
}

- (void)showParent:sender
{
	[[genome parent] openWindow];
}

- (void)showDisassembly:sender
{
	id disassembly;
	if([genome originalCode])
		disassembly = [genome originalCode];
	else
		disassembly = [[genome representative] disassembly];
	id controller = [[GenomeAssemblerController alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"# Genome %@  --  mutations %d\n\n%@", @"Genome assembler window title format string"), [genome name], [genome mutations], disassembly]];
	[controller showWindow:self];
	[controller release]; // the controller is self-contained from here	
}

- (void)showCOG:sender
{
	CreaturesView *view = [[Genome creatureController] view];
	if([sender state] == NSOnState)
		[view addTemporaryPainter:self];
	else
		[view removeTemporaryPainter:self];
	[view setNeedsPixmapUpdate];
	[view setNeedsDisplay:YES];
}

- (void)setColor:(NSColorWell *)sender
{
	float h,s,b,a;
	[[[sender color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getHue:&h saturation:&s brightness:&b alpha:&a];
	NSColor *color = [NSColor colorWithDeviceHue:h saturation:1.0 brightness:1.0 alpha:1.0];
	[sender setColor:color];
	[genome setColor:Pixel24ForColor(color)];
	CreaturesView *view = [[Genome creatureController] view];
	[view setNeedsPixmapUpdate];
	[view setNeedsDisplay:YES];
}

// draw COG
- (void)drawOnPixmap:(PixelUnion *)pixmap width:(int)pixWidth
{
	int ySize = [[[Genome creatureController] arena] ySize];
	int COGx = lrint([genome centerOfGravityX]);
	int COGy = ySize - lrint([genome centerOfGravityY]) - 1;

	MyAssert(COGx >= 0 && COGx < pixWidth && COGy >= 0 && COGy < ySize, @"bad center of gravity (%d, %d", COGx, COGy);
	
	int startx = MAX(0, COGx - 2);
	int starty = MAX(0, COGy - 2);
	int endx = MIN(pixWidth - 1, COGx + 2);
	int endy = MIN(ySize - 1, COGy + 2);
	Pixel24 color = [genome color];
	PixelUnion fillColor = {{255, color.r, color.g, color.b}};

	DrawHLine(pixmap, pixWidth, startx, COGy, endx, fillColor);
	DrawVLine(pixmap, pixWidth, COGx, starty, endy, fillColor);
}

- (void)textDidChange:(NSNotification *)notification
{
	[genome setComment:[commentTextView string]];
}

- (void)genomeDestroyed:(NSNotification *)notification
{
	[[[self window] contentView] recursivelyDisableSubviews];
	[[self window] setTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ --DESTROYED--", @"Genome info window title when genome has been destroyed"), [[self window] title]]];
	genome = nil;
}

- (void)changeColor:sender
{
	[commentTextView setTextColor:nil];
	[commentTextView performSelector:@selector(setTextColor:) withObject:nil afterDelay:0];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:GenomeDestroyedNotification object:genome];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSColorPanelColorDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:CreatureNewArenaCreatedNotification object:nil];
	[super dealloc];
}

@end
