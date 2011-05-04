//
//  GenomeListController.m
//  Creatures
//
//  Created by mikeash on Sun Oct 28 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "GenomeListController.h"
#import "Genome.h"
#import "GenomeLibrary.h"
#import "CreatureController.h"
#import "GenomeAssemblerController.h"
//#import "TableHeaderCellWithContextMenu.h"
#import "RegistrationSplashController.h"
#import "EnterRegistrationController.h"


@implementation GenomeListController

+ (void)initialize
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *visibleDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithBool:YES], @"SaveInLibrary",
		[NSNumber numberWithBool:YES], @"Name",
		[NSNumber numberWithBool:YES], @"Population",
		[NSNumber numberWithBool:YES], @"Total",
		[NSNumber numberWithBool:NO], @"Parent",
		[NSNumber numberWithBool:YES], @"Mutations",
		[NSNumber numberWithBool:NO], @"Comment",
		[NSNumber numberWithBool:NO], @"FirstAppeared",
		[NSNumber numberWithBool:NO], @"LastAppeared",
		[NSNumber numberWithBool:NO], @"PeakPopulation",
		[NSNumber numberWithBool:NO], @"ErasedChildGenomes",
		[NSNumber numberWithBool:NO], @"ErasedGenomeCreatures",
		nil];
	NSDictionary *sizesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithFloat:30], @"SaveInLibrary",
		[NSNumber numberWithFloat:80], @"Name",
		[NSNumber numberWithFloat:109], @"Population",
		[NSNumber numberWithFloat:96], @"Total",
		[NSNumber numberWithFloat:80], @"Parent",
		[NSNumber numberWithFloat:57], @"Mutations",
		[NSNumber numberWithFloat:120], @"Comment",
		[NSNumber numberWithFloat:82], @"FirstAppeared",
		[NSNumber numberWithFloat:90], @"LastAppeared",
		[NSNumber numberWithFloat:90], @"PeakPopulation",
		[NSNumber numberWithFloat:122], @"ErasedChildGenomes",
		[NSNumber numberWithFloat:140], @"ErasedGenomeCreatures",
		nil];
	NSDictionary *orderArray = [NSArray arrayWithObjects:@"SaveInLibrary", @"Name", @"Population", @"Total", @"Mutations", nil];
	NSDictionary *appDefaults = [NSDictionary
        dictionaryWithObjectsAndKeys:
		visibleDictionary, @"GenomeListColumnVisibility",
		sizesDictionary, @"GenomeListColumnSizes",
		orderArray, @"GenomeListColumnOrder",
		nil];

	[defaults registerDefaults:appDefaults];
}	

static GenomeListController *globalController = nil;

+ (void)showListWindow
{
	if(globalController == nil)
		globalController = [[self alloc] init];

	[globalController showWindow:self];
}

- (int)compareGenomes:g1 :g2
{
	return [(NSNumber *)[g1 dataForIdentifier:sortIdentifier] compare:[g2 dataForIdentifier:sortIdentifier]];
}

static int sortFunction(id g1, id g2, void *object)
{
	int result = [(id)object compareGenomes:g1 :g2];
	if(((GenomeListController *)object)->ascending)
		return result;
	else
	{
		if(result == NSOrderedAscending)
			return NSOrderedDescending;
		else if(result == NSOrderedDescending)
			return NSOrderedAscending;
		else
			return result;
	}
}

- (void)sortList
{
	if(sortIdentifier != nil)
		[listContents sortUsingFunction:sortFunction context:self];
}

- (BOOL)matchesFilter:obj
{
	if([obj mutations] == 0)
		return YES;
	
	if(filterUnique)
	{
		if([obj totalPopulation] <= 1)
			return NO;
	}
	if(filterExtinct)
	{
		if([obj population] < 1)
			return NO;
	}

	return YES;
}

- (void)redoListContents
{
	NSEnumerator *enumerator = [[Genome genomeList] objectEnumerator];
	id obj;
	if(listContents == nil)
		listContents = [[NSMutableArray alloc] init];
	[listContents removeAllObjects];

	while((obj = [enumerator nextObject]))
	{
		if([self matchesFilter:obj])
			[listContents addObject:obj];
	}

	[self sortList];
}

- init
{
	if((self = [super initWithWindowNibName:@"Genome"]))
	{
		[[self window] setExcludedFromWindowsMenu:YES];
		[self redoListContents];
		[Genome setListController:self];
		[self setFilterUnique:filterUniqueBox];
		[self setFilterExtinct:filterExtinctBox];
		[self setUpdateAutomatically:updateAutomaticallyBox];

		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewColumnDidMove:) name:NSTableViewColumnDidMoveNotification object:table];
  //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewColumnDidResize:) name:NSTableViewColumnDidResizeNotification object:table];

		[table setDoubleAction:[table action]];
		[table setAction:nil];

		NSButtonCell *checkboxCell = [[NSButtonCell alloc] init];
		[checkboxCell setTitle:@" "];
		[checkboxCell setButtonType:NSSwitchButton];
		[checkboxCell setEditable:YES];
		[checkboxCell setControlSize:NSSmallControlSize];
		[checkboxCell setRefusesFirstResponder:NO];
		NSTableColumn *saveColumn = [table tableColumnWithIdentifier:@"SaveInLibrary"];
		[saveColumn setDataCell:checkboxCell];
		[checkboxCell release];

		tableHeaderContextMenu = [[NSMenu alloc] initWithTitle:@"Genome Table Context Menu"];
		[[table headerView] setMenu:tableHeaderContextMenu];
		//[table setMenu:tableHeaderContextMenu];
		visibleTableColumns = [[NSMutableSet alloc] init];
		hiddenTableColumns = [[NSMutableSet alloc] init];

		NSDictionary *visibleDictionary = [[NSUserDefaults standardUserDefaults] objectForKey:@"GenomeListColumnVisibility"];
		NSDictionary *sizesDictionary = [[NSUserDefaults standardUserDefaults] objectForKey:@"GenomeListColumnSizes"];
		NSArray *orderArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"GenomeListColumnOrder"];

		NSArray *tableColumns = [table tableColumns];
		NSEnumerator *enumerator = [tableColumns objectEnumerator];
		id obj;

		[table setDelegate:nil]; // keep our changes from generating notifications to ourselves

		while((obj = [enumerator nextObject]))
		{
			int menuIndex = 0;
			while(menuIndex < [tableHeaderContextMenu numberOfItems] && [[[obj headerCell] title] localizedCompare:[[tableHeaderContextMenu itemAtIndex:menuIndex] title]] == NSOrderedDescending)
				menuIndex++;
			id <NSMenuItem> item = [tableHeaderContextMenu insertItemWithTitle:[[obj headerCell] title] action:@selector(contextMenuSelected:) keyEquivalent:@"" atIndex:menuIndex];
			[item setTarget:self];
			[item setRepresentedObject:obj];
			if([[visibleDictionary objectForKey:[obj identifier]] boolValue])
				[item setState:NSOnState];
			else
				[item setState:NSOffState];

			//NSLog(@"setting width of %@ to %f", [obj identifier], [[sizesDictionary objectForKey:[obj identifier]] floatValue]);
			[obj setWidth:[[sizesDictionary objectForKey:[obj identifier]] floatValue]];

			if([[visibleDictionary objectForKey:[obj identifier]] boolValue])
			{
				[visibleTableColumns addObject:obj];
			}
			else
			{
				[hiddenTableColumns addObject:obj];
				[table removeTableColumn:obj];
			}

			//[[obj headerCell] setMenu:tableHeaderContextMenu];
		}
		enumerator = [orderArray objectEnumerator];
		int i = 0;
		while((obj = [enumerator nextObject]))
		{
			[table moveColumn:[table columnWithIdentifier:obj] toColumn:i];
			i++;
		}

		[table setDelegate:self]; // reset the delegate to ourself		

		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(genomeDestroyed:) name:GenomeDestroyedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update:) name:CreatureNewArenaCreatedNotification object:nil];
	}
	return self;
}

- initWithWindowNibName:name
{
	MyErrorLog(@"method should never be called");
	[self release];
	return nil;
}

- (void)registerClick:sender
{
	if([table clickedRow] == -1)
		;
	else
	{
		Genome *genome;
		genome = [listContents objectAtIndex:[table clickedRow]];
		[genome openWindow];
	}
}

- (void)setFilterUnique:sender
{
	filterUnique = [sender intValue];
	[self update];
}

- (void)setFilterExtinct:sender
{
	filterExtinct = [sender intValue];
	[self update];
}

- (void)setUpdateAutomatically:sender
{
	if([sender intValue])
	{
		[[Genome creatureController] setGenomeList:self];
	}
	else
	{
		[[Genome creatureController] setGenomeList:nil];
	}
}

/*- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)rowIndex
{
	[tableView performSelector:@selector(deselectAll:) withObject:self afterDelay:0.0];
	return YES;
}*/

- (void)foo:tableColumn
{
	[[tableColumn headerCell] setHighlighted:YES];
	[[tableColumn headerCell] setEnabled:YES];
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectTableColumn:(NSTableColumn *)tableColumn
{
	NSTableColumn *oldColumn = [tableView tableColumnWithIdentifier:sortIdentifier];
	[tableView setIndicatorImage:nil inTableColumn:oldColumn];
	//[[oldColumn headerCell] setHighlighted:NO];
	
	id identifier = [tableColumn identifier];
	if([identifier isEqual:sortIdentifier])
		ascending = !ascending;
	else
	{
		sortIdentifier = identifier;
		ascending = YES;
	}
	if(ascending)
		[tableView setIndicatorImage:[NSImage imageNamed:@"NSAscendingSortIndicator"] inTableColumn:tableColumn];
	else
		[tableView setIndicatorImage:[NSImage imageNamed:@"NSDescendingSortIndicator"] inTableColumn:tableColumn];
	if([tableView highlightedTableColumn] != tableColumn)
		[tableView setHighlightedTableColumn:tableColumn];

	[self update];

	//[self performSelector:@selector(foo:) withObject:tableColumn afterDelay:0];
	
	return NO;
}

- (void)writeColumnOrderDefaults
{
	NSMutableArray *identifiers = [NSMutableArray array];
	NSEnumerator *enumerator = [[table tableColumns] objectEnumerator];
	id obj;
	while((obj = [enumerator nextObject]))
		[identifiers addObject:[obj identifier]];
	[[NSUserDefaults standardUserDefaults] setObject:identifiers forKey:@"GenomeListColumnOrder"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}	

- (void)tableViewColumnDidMove:(NSNotification *)notification
{
	[self writeColumnOrderDefaults];
}

- (void)tableViewColumnDidResize:(NSNotification *)notification
{
	NSMutableDictionary *sizes = [NSMutableDictionary dictionary];

	NSEnumerator *enumerator = [[table tableColumns] objectEnumerator];
	id column;
	while((column = [enumerator nextObject]))
		[sizes setObject:[NSNumber numberWithFloat:[column width]] forKey:[column identifier]];

	[[NSUserDefaults standardUserDefaults] setObject:sizes forKey:@"GenomeListColumnSizes"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)contextMenuSelected:sender
{
	if([sender state] == NSOnState)
	{
		[sender setState:NSOffState];
		[hiddenTableColumns addObject:[sender representedObject]];
		[visibleTableColumns removeObject:[sender representedObject]];
		[table removeTableColumn:[sender representedObject]];
	}
	else
	{
		[sender setState:NSOnState];
		[table addTableColumn:[sender representedObject]];
		[visibleTableColumns addObject:[sender representedObject]];
		[hiddenTableColumns removeObject:[sender representedObject]];
	}
	NSMutableDictionary *visibleDictionary = [NSMutableDictionary dictionary];
	NSEnumerator *enumerator = [visibleTableColumns objectEnumerator];
	id obj;
	while((obj = [enumerator nextObject]))
		[visibleDictionary setObject:[NSNumber numberWithBool:YES] forKey:[obj identifier]];
	enumerator = [hiddenTableColumns objectEnumerator];
	while((obj = [enumerator nextObject]))
		[visibleDictionary setObject:[NSNumber numberWithBool:NO] forKey:[obj identifier]];
	[[NSUserDefaults standardUserDefaults] setObject:visibleDictionary forKey:@"GenomeListColumnVisibility"];

	[self writeColumnOrderDefaults];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if(listContents == nil)
		[self redoListContents];

	return [listContents count];
}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
    row:(int)rowIndex
{
	if(listContents == nil)
		[self redoListContents];

    id theRecord, theValue;
	
    NSParameterAssert(rowIndex >= 0 && rowIndex < [listContents count]);
    theRecord = [listContents objectAtIndex:rowIndex];
    theValue = [theRecord dataForIdentifier:[aTableColumn identifier]];
    return theValue;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex
{
	if([[tableColumn identifier] isEqualToString:@"SaveInLibrary"])
	{
		Genome *genome = [listContents objectAtIndex:rowIndex];
		GenomeLibrary *library = [GenomeLibrary library];
		// double negation ensures we can properly test for equality
		if(![anObject boolValue] != ![library containsGenome:genome])
		{
			if([anObject boolValue])
				[library addGenome:genome];
			else
				[library removeGenome:genome];
		}
	}
	else
		MyErrorLog(@"Unknown identifier %@", [tableColumn identifier]);
}

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard
{
	Genome *genome = [listContents objectAtIndex:[[rows lastObject] intValue]];
	[pboard declareTypes:[NSArray arrayWithObject:GenomeDragDataType] owner:self];
	[pboard setData:[NSData dataWithBytes:(const void *)&genome length:sizeof(genome)] forType:GenomeDragDataType];
	[Genome disableCulling];
	return YES;
}

- (void)tableView:(NSTableView *)tableView draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
	[Genome enableCulling];
}

- (void)update
{
	[self update:nil];
	//if(updateTimer == nil)
	//	updateTimer = [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(update:) userInfo:nil repeats:NO];
}

- (void)update:sender
{
	NS_DURING
		//[table noteNumberOfRowsChanged];
		//[self redoListContents];
		[listContents release];
		listContents = nil;
		[table reloadData];
		updateTimer = nil;
		[Genome updateOpenWindows];
	NS_HANDLER
		LogUncaughtException(localException);
	NS_ENDHANDLER
}

- (void)newClicked:sender
{
	id controller = [[GenomeAssemblerController alloc] init];
	[controller showWindow:self];
	[controller release]; // the controller is self-contained from here
}


- (void)genomeDestroyed:(NSNotification *)notification
{
	[self update];
}

- (BOOL)windowShouldClose:(id)sender
{
	[self release];
	globalController = nil;
	return YES;
}



- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[Genome creatureController] setGenomeList:nil];
	[Genome setListController:nil];
	[listContents release];
	[visibleTableColumns release];
	[hiddenTableColumns release];
	[tableHeaderContextMenu release];
	
	[super dealloc];
}

@end
