//
//  CreatureInspectorWindowController.m
//  Creatures
//
//  Created by Michael Ash on Thu Oct 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "CreatureInspectorWindowController.h"
#import "ComputingCreature.h"
#import "VirtualMachine.h"
#import "Genome.h"
#import "CreatureController.h"


@interface CreatureInspectorWindowController (Private)

- (void)showWindowWithCreature:(ComputingCreature *)creature;

@end

@implementation CreatureInspectorWindowController (Private)

- (void)showWindowWithCreature:(ComputingCreature *)creature
{
	[self window];
	
	VirtualMachine *vm = [creature vm];

	[mutationsField setIntValue:[creature mutations]];
	[energyField setFloatValue:[creature energy]];
	[ageField setIntValue:[creature age]];
	[messageField setIntValue:[creature message]];
	[pcField setIntValue:[vm PC]];

	[disassemblyTextView setString:[vm disassembly]];

	memcpy(r, [vm registers], sizeof(int) * VM_NUM_REGS);

	creatureGenome = [creature genome];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(genomeDestroyed:) name:GenomeDestroyedNotification object:creatureGenome];

	[self showWindow:self];
}

@end

@implementation CreatureInspectorWindowController

+ (void)showWindowWithCreature:(ComputingCreature *)creature
{
	id controller = [[self alloc] init];
	[controller showWindowWithCreature:creature];
	[controller autorelease];
}

- (void)genomeDestroyed:genome
{
	creatureGenome = nil;
	[showGenomeButton setEnabled:NO];
}

- (void)showGenome:sender
{
	[creatureGenome openWindow];
}

- init
{
	if((self = [super initWithWindowNibName:@"Disassembly"]))
	{
		[self retain];
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

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:[self window] name:CreatureNewArenaCreatedNotification object:nil];
	[super dealloc];
}

- (BOOL)windowShouldClose:sender
{
	[self autorelease];
	return YES;
}


- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return VM_NUM_REGS;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	MyAssert(row >= 0 && row < VM_NUM_REGS, @"Bad row value in tableView request");
	
	if([[tableColumn identifier] isEqualToString:@"name"])
		return [NSString stringWithFormat:@"r%d", row];
	else if([[tableColumn identifier] isEqualToString:@"contents"])
		return [NSNumber numberWithInt:r[row]];
	else
		MyErrorLog(@"Unknown identifier %@", [tableColumn identifier]);
	return @"You should never see this";
}


@end
