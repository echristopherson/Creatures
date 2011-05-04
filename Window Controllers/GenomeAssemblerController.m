//
//  GenomeAssemblerController.m
//  Creatures
//
//  Created by Michael Ash on Tue Jun 03 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "GenomeAssemblerController.h"
#import "VirtualMachineAssembler.h"
#import "VirtualMachineError.h"
#import "VirtualMachine.h"
#import "Genome.h"
#import "PixmapUtils.h"
#import "CreatureController.h"


@implementation GenomeAssemblerController

- init
{
	if((self = [super initWithWindowNibName:@"GenomeAssembler"]))
	{
		[[self window] setDelegate:self];
		[self retain]; // releases on window close
		[[NSNotificationCenter defaultCenter] addObserver:[self window] selector:@selector(performClose:) name:CreatureNewArenaCreatedNotification object:nil];
	}
	return self;
}

- initWithString:(NSString *)s
{
	if((self = [self init]))
	{
		[textView setString:s];
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
	[self autorelease];
	return YES;
}

- (IBAction)assembleClicked:sender
{
	[assembler release];
	assembler = [[VirtualMachineAssembler alloc] initWithString:[textView string]];
	[assembler scan];
	
	[errors release];
	errors = [[assembler errors] copy];

	if([errors count] == 0)
	{
		[errorDrawer close];
		[saveButton setEnabled:YES];
	}
	else
	{
		[errorDrawer open];
		[errorTable reloadData];
		[saveButton setEnabled:NO];
	}
}

- (IBAction)saveClicked:sender
{
	id vm = [[VirtualMachine alloc] initWithData:[assembler assembledData] pad:0];
	Genome *genome = [[Genome alloc] initWithVM:vm];
	[genome setOriginalCode:[textView string]];
	Pixel24 blue = {0, 0, 255};
	[genome setColor:blue];
	[[self window] performClose:self];
	[genome openWindow];
	[genome release];
}

- (IBAction)errorTableClicked:sender
{
	if([errorTable clickedRow] < 0 || [errorTable clickedRow] >= [errors count])
		return;
	
	id error = [errors objectAtIndex:[errorTable clickedRow]];
	id lines = [[textView string] componentsSeparatedByString:@"\n"];
	int i;
	int begin = 0;
	for(i = 0; i < [error line] - 1; i++)
		begin += [(NSString *)[lines objectAtIndex:i] length] + 1; // +1 for the missing \n
	int line = [error line];
	if(line > [lines count])
		line = [lines count];
	NSRange lineRange = NSMakeRange(begin, [(NSString *)[lines objectAtIndex:line - 1] length] + 1);
	if(lineRange.location + lineRange.length >= [[textView string] length])
		lineRange.length = [[textView string] length] - lineRange.location - 1;
	[textView scrollRangeToVisible:lineRange];
	[textView setSelectedRange:lineRange];
	[[self window] makeFirstResponder:textView];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [errors count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	VirtualMachineError *error = [errors objectAtIndex:rowIndex];
	return [NSString stringWithFormat:NSLocalizedString(@"line %d: %@", @"Assembler error table format string"), [error line], [error message]];
}

- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
	[saveButton setEnabled:NO];
	return YES;
}


- (void)dealloc
{
	[errors release];
	[assembler release];
	[[NSNotificationCenter defaultCenter] removeObserver:[self window] name:CreatureNewArenaCreatedNotification object:nil];
	[super dealloc];
}

@end
