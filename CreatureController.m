//
//  CreatureController.m
//  Creatures
//
//  Created by Michael Ash on Sat Jun 08 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "CreatureController.h"
#import "CreaturesView.h"
#import "Genome.h"
#import "FamilyTreeWindowController.h"
#import "FamilyTreeView.h"
#import "ComputingCreature.h"
#import "DrawingTool.h"
#import "GenomeDragAcceptTextField.h"
#import "SimpleWebController.h"
#import "GenomeListController.h"
#import "EnterRegistrationController.h"
#import "RegistrationSplashController.h"
#import "MAKeyedArchiver.h"
#import "MAKeyedUnarchiver.h"


NSString * const CreatureNewArenaCreatedNotification = @"CreatureNewArenaCreatedNotification";


@interface CreatureController (Private)

- (void)resizeDrawingPanel;
- (void)initDefaultArena;
- (void)saveFilename:(NSString *)filename;
- (BOOL)openFilename:(NSString *)filename;
- (void)setupStepTimer;
- (void)removeUnregisteredMenuItems;

@end

@implementation CreatureController (Private)

- (void)saveMethodCompare
{
	
	clock_t startTime, endTime;
	
	{
		NSLog(@"Saving with MAKeyedArchiver...");
		startTime = clock();
		NSMutableData *fileData = [NSMutableData data];
		id pool = [NSAutoreleasePool new];
		MAKeyedArchiver *archiver = [[[MAKeyedArchiver alloc] initForWritingWithMutableData:fileData] autorelease];
		[archiver encodeObject:arena forKey:@"arenaObject"];
		[archiver finishEncoding];
		[pool release];
		endTime = clock();
		NSLog(@"done. Total time was %f. Data size is %d", (float)(endTime - startTime)/CLOCKS_PER_SEC, [fileData length]);
	}

	{
		NSLog(@"Saving with NSKeyedArchiver...");
		startTime = clock();
		NSMutableData *fileData = [NSMutableData data];
		id pool = [NSAutoreleasePool new];
		NSKeyedArchiver *archiver = [[[NSKeyedArchiver alloc] initForWritingWithMutableData:fileData] autorelease];
		[archiver encodeObject:arena forKey:@"arenaObject"];
		[archiver finishEncoding];
		[pool release];
		endTime = clock();
		NSLog(@"done. Total time was %f. Data size is %d", (float)(endTime - startTime)/CLOCKS_PER_SEC, [fileData length]);
	}	
}

- (void)resizeDrawingPanel
{
	NSRect windowFrame = [drawingPanel frame];
	NSEnumerator *enumerator = [[[drawingPanel contentView] subviews] objectEnumerator];
	NSView *subview;

	float maxX = 0, maxY = 0, minX = 10000, minY = 10000;
	while((subview = [enumerator nextObject]))
	{
		NSRect frame = [subview frame];
		if(frame.size.width + frame.origin.x > maxX)
			maxX = frame.size.width + frame.origin.x;
		if(frame.origin.x < minX)
			minX = frame.origin.x;
		if(frame.size.height + frame.origin.y > maxY)
			maxY = frame.size.height + frame.origin.y;
		if(frame.origin.y < minY)
			minY = frame.origin.y;
	}
	NSSize maxSize = NSMakeSize(maxX - minX, maxY - minY);
	float extraHeight = windowFrame.size.height - [[drawingPanel contentView] frame].size.height;
	maxSize.height += extraHeight;
	windowFrame.origin.y += windowFrame.size.height - maxSize.height;
	windowFrame.size = maxSize;
	[drawingPanel setFrame:windowFrame display:YES animate:YES];
}

- (void)initDefaultArena
{
	arena = [[Arena alloc] initWithX:[[NSUserDefaults standardUserDefaults] integerForKey:@"DefaultArenaWidth"] Y:[[NSUserDefaults standardUserDefaults] integerForKey:@"DefaultArenaHeight"]];
	[Arena setArena:arena];
	[view setArena:arena];

	[genomeField setGenome:[Genome defaultGenome]];

	step = 0;
	[self update];
	[view setNeedsDisplay:YES];
	[self setDisplayInterval:[NSNumber numberWithFloat:1.0]];
	[FamilyTreeWindowController reset];
}

- (void)saveFilename:(NSString *)filename
{
	NS_DURING
		NSMutableData *fileData = [NSMutableData data];
		MAKeyedArchiver *archiver = [[[MAKeyedArchiver alloc] initForWritingWithMutableData:fileData] autorelease];
		[archiver encodeObject:arena forKey:@"arenaObject"];
		[archiver finishEncoding];
		[fileData writeToFile:filename atomically:YES];
	NS_HANDLER
		NSRunCriticalAlertPanel(NSLocalizedString(@"The file could not be saved!", @""), NSLocalizedString(@"The following error occured: %@", @""), NSLocalizedString(@"OK", @"default button title"), nil, nil, [localException reason]);
		return;
	NS_ENDHANDLER
	[[view window] setTitleWithRepresentedFilename:filename];
	[[view window] setDocumentEdited:NO];
	hasBeenSaved = YES;
	[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:[[view window] representedFilename]]];
}

- (BOOL)openFilename:(NSString *)filename
{
	const int maxReadableVersion = 1;
	
	// returns YES if succeeded, NO if failed
	if([self askForSave] == NO)
		return NO;

	[self stopRun:self];
	[arena release];
	[Genome destroyListContents];

	NSString *errorString = nil;
	BOOL isCorrupt = NO;
	NS_DURING
		NSData *fileData = [NSData dataWithContentsOfFile:filename];
		MAKeyedUnarchiver *unarchiver = [[[MAKeyedUnarchiver alloc] initForReadingWithData:fileData] autorelease];
		if([unarchiver decodeIntForKey:@"compatible file version"] > maxReadableVersion)
			errorString = NSLocalizedString(@"the file was created with a newer version of Creatures and can't be read.", @"");
		else
			arena = [[unarchiver decodeObjectForKey:@"arenaObject"] retain];
		[unarchiver finishDecoding];
	NS_HANDLER
		arena = nil;
		NS_DURING
			NSData *fileData = [NSData dataWithContentsOfFile:filename];
			NSKeyedUnarchiver *unarchiver = [[[NSKeyedUnarchiver alloc] initForReadingWithData:fileData] autorelease];
			arena = [[unarchiver decodeObjectForKey:@"arenaObject"] retain];
			[unarchiver finishDecoding];
		NS_HANDLER
			arena = nil;
			isCorrupt = YES;
		NS_ENDHANDLER
	NS_ENDHANDLER

	if(arena == nil)
	{
		[self initDefaultArena];
		NSString *messageString;
		if(errorString)
			messageString = [NSString stringWithFormat:NSLocalizedString(@"The following error occured: %@", @"")];
		else if(isCorrupt)
			messageString = [NSString stringWithFormat:NSLocalizedString(@"File is corrupt or of the wrong format.", @"unarchiver error")];
		else
			messageString = NSLocalizedString(@"An unspecified error occured.", @"");

		NSRunCriticalAlertPanel([NSString stringWithFormat:NSLocalizedString(@"The file %@ could not be opened!", @""), [filename lastPathComponent]], @"%@", NSLocalizedString(@"OK", @"default button title"), nil, nil, messageString);
		return NO;
	}

	[Arena setArena:arena];
	[view setArena:arena];
	[[view window] setTitleWithRepresentedFilename:filename];
	step = [arena stepNumber];
	[self update];
	[[view window] setDocumentEdited:NO];
	[[view window] makeKeyAndOrderFront:self];
	[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:filename]];
	[genomeField setGenome:[Genome defaultGenome]];
	if([arenaSettingsWindow isVisible])
		[self openArenaSettingsWindow:self]; // reset the values it contains
	hasBeenSaved = YES;

	[FamilyTreeWindowController reset];
	
	return YES;
}

- (void)setupStepTimer
{
	NSTimeInterval interval = 0;
	if(displayInterval < 0)
		interval = (1 << (-displayInterval - 1))/30.0; // -1 is 1/30th of a sec, -2 is 1/15th, etc.

	[stepTimer invalidate];
	stepTimer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(step) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:stepTimer forMode:NSModalPanelRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:stepTimer forMode:NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:stepTimer forMode:NSEventTrackingRunLoopMode];
}

- (void)removeUnregisteredMenuItems
{
	[[purchaseMenuItem menu] insertItem:registrationInfoMenuItem atIndex:[[purchaseMenuItem menu] indexOfItem:purchaseMenuItem]];
	[[purchaseMenuItem menu] removeItem:purchaseMenuItem];
	purchaseMenuItem = nil;
	[[enterSerialMenuItem menu] removeItem:enterSerialMenuItem];
	enterSerialMenuItem = nil;
}

@end

@implementation CreatureController

+ (void)initialize
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = [NSDictionary
        dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:300], @"DefaultArenaWidth",
		[NSNumber numberWithInt:200], @"DefaultArenaHeight",
		nil];
	[defaults registerDefaults:appDefaults];

	[Creature initialize];
	[ComputingCreature initialize];
}

- (void)awakeFromNib
{
	/*NSRect bounds = [view bounds];
	bounds.size.height /= 3;
	bounds.size.width /= 3;
	[view setBounds:bounds];*/

	displayInterval = 0.1;

	[self initDefaultArena];
	
	[self resizeDrawingPanel];
	
	[Genome setCreatureController:self];
	[toolOptionsTabView selectTabViewItemAtIndex:0];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appActivated:) name:NSApplicationDidBecomeActiveNotification object:NSApp];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDeactivated:) name:NSApplicationDidResignActiveNotification object:NSApp];

	[controlPanel setExcludedFromWindowsMenu:YES];
	[controlPanel setBecomesKeyOnlyIfNeeded:YES];
	//[controlPanel setFloatingPanel:NO];
	[drawingPanel setExcludedFromWindowsMenu:YES];
	[drawingPanel setBecomesKeyOnlyIfNeeded:YES];
	[arenaSettingsWindow setExcludedFromWindowsMenu:YES];

	[registrationInfoMenuItem retain];
	[[registrationInfoMenuItem menu] removeItem:registrationInfoMenuItem];
}

- (void)setTool:tool forButton:button
{
	if(toolDictionary == nil)
		toolDictionary = [[NSMutableDictionary alloc] init];

	[toolDictionary setObject:tool forKey:[NSValue valueWithNonretainedObject:button]];
}


/*- (void)mouseDownAtPoint:(NSPoint)p
{
	[[toolDictionary objectForKey:[NSValue valueWithNonretainedObject:[toolSelectMatrix selectedCell]]] clickedInView:(NSView *)view at:p.x :p.y];
}

- (void)mouseMovedToPoint:(NSPoint)p
{
	[[toolDictionary objectForKey:[NSValue valueWithNonretainedObject:[toolSelectMatrix selectedCell]]] movedInView:(ToolInteractionView *)view at:p.x :p.y];
}

- (void)mouseUpAtPoint:(NSPoint)p
{
	[[toolDictionary objectForKey:[NSValue valueWithNonretainedObject:[toolSelectMatrix selectedCell]]] releasedInView:(ToolInteractionView *)view at:p.x :p.y];
}*/

- (void)stopRun:sender
{
	if(stepTimer != nil)
		[self toggleRun:sender];
}

- (void)step
{
	NS_DURING
		step++;
		[arena step];
		if([arena useStopThresholdPopulation] && [arena population] < [arena stopThresholdPopulation])
		[self stopRun:nil];

		[[view window] setDocumentEdited:YES];

		if(displayInterval < 0 || (step - displayIntervalBase) % (1 << displayInterval) == 0)
			[self runningUpdate];
	NS_HANDLER
		LogUncaughtException(localException);
	NS_ENDHANDLER
}

- (IBAction)toggleRun:(id)sender
{
	if(stepTimer == nil)
	{
		[self setupStepTimer];
		//saveTimer = [NSTimer scheduledTimerWithTimeInterval:600 target:self selector:@selector(timedSave) userInfo:nil repeats:YES];
		[runButton setTitle:NSLocalizedString(@"Stop", @"Run/Stop button title")];
		[runMenuItem setTitle:NSLocalizedString(@"Stop", @"Run/Stop button title")];
	}
	else
	{
		[stepTimer invalidate];
		[saveTimer invalidate];
		stepTimer = nil;
		saveTimer = nil;
		[self runningUpdate];
		[runButton setTitle:NSLocalizedString(@"Run", @"Run/Stop button title")];
		[runMenuItem setTitle:NSLocalizedString(@"Run", @"Run/Stop button title")];
	}
}

- (IBAction)removeOldGenomes:sender
{
	int modalResultCode = [NSApp runModalForWindow:removeOldGenomesPanel];
	if(modalResultCode == 0)
	{
		[removeOldGenomesPanel orderOut:nil];
		return;
	}
	
	int howMany = [removeOldGenomesField intValue];
	[Genome removeOldGenomes:howMany];
	[removeOldGenomesPanel orderOut:nil];
}

- (IBAction)setDisplayInterval:sender
{
	displayInterval = lrint([sender floatValue]);
	//NSLog(@"got display interval = %u", displayInterval);
	if(displayInterval > 5)
		displayInterval = 0x7FFFFFFF; // "never update"

	displayIntervalBase = step;
	
	if(stepTimer != nil)
		[self setupStepTimer];
}

- (IBAction)openGenomeWindow:sender
{
	[GenomeListController showListWindow];
}

- (IBAction)openFamilyTreeWindow:sender
{
	id controller = [FamilyTreeWindowController controller];
	[[controller window] setExcludedFromWindowsMenu:YES];
	[controller showWindow:nil];
	[[controller treeView] setController:self]; // this has to be last, otherwise the nib hasn't loaded yet
	[[controller treeView] centerFirstGenome:self];
}

- (void)setGenomeList:list
{
	genomeList = list;
}

- (void)update
{
	[view setNeedsDisplay:YES];
	[stepBox setIntValue:step];
	[populationBox setIntValue:[arena population]];
	//if(genomeList && [[genomeWindowController window] isVisible])
	[genomeList update];
}

- (void)runningUpdate
{
	/*[view lockFocus];
	[arena update];
	[view unlockFocus];
	[[view window] flushWindow];*/
	[view setNeedsDisplay:YES];
	[stepBox setIntValue:step];
	[populationBox setIntValue:[arena population]];
	//if(genomeList && [[genomeWindowController window] isVisible])
	//	[genomeList update];
}

- (IBAction)update:sender
{
	[self runningUpdate];
}

- (IBAction)saveAs:sender
{
	NSSavePanel *sp;
	int runResult;

	/* create or get the shared instance of NSSavePanel */
	sp = [NSSavePanel savePanel];

	/* set up new attributes */
	//[sp setAccessoryView:newView];
	[sp setRequiredFileType:@"creatures"];

	/* display the NSSavePanel */
	NSString *oldFilename;
	if(hasBeenSaved)
		oldFilename = [[view window] representedFilename];
	else
		oldFilename = @"";
	runResult = [sp runModalForDirectory:nil file:oldFilename];

	/* if successful, save file under designated name */
	if (runResult == NSOKButton) {
		/*NS_DURING
			[NSKeyedArchiver archiveRootObject:arena toFile:[sp filename]];
		NS_HANDLER
			NSRunCriticalAlertPanel(@"The file could not be saved!", @"The following error occured: %@", @"OK", nil, nil, [localException reason]);
			return;
		NS_ENDHANDLER*/
		[self saveFilename:[sp filename]];
	}

}

- (BOOL)askForSave
{
	if(askingForSave)
		return NO;

	// returns NO if the user cancelled and whatever process is happening should stop
	if([[view window] isDocumentEdited])
	{
		askingForSave = YES;
		int returnCode = NSRunAlertPanel(NSLocalizedString(@"Do you want to save the current Creatures world?", @""), NSLocalizedString(@"Any unsaved changes will be lost. %d creatures will die unremembered.", @""), NSLocalizedString(@"Save", @"button title"), NSLocalizedString(@"Don't Save", @"button title"), NSLocalizedString(@"Cancel", @"button title"), [arena population]);
		askingForSave = NO;
		if (returnCode == NSAlertAlternateReturn)		/* "Don't Save" */
		{
			return YES;
		}
		else if (returnCode == NSAlertDefaultReturn)		/* "Save" */
		{
			[self save:self];
			return YES;
		}
		else if (returnCode == NSAlertOtherReturn)	/* "Cancel" */
		{
			return NO;
		}
	}

	return YES;
}

- (void)newArenaOK:sender
{
	[NSApp stopModalWithCode:1];
}

- (void)newArenaCancel:sender
{
	[NSApp stopModalWithCode:0];
}

- (void)new:sender
{
	//Genome *genome;
	int modalResultCode;
	NSTextField *widthBox, *heightBox;
	int width, height;
	
	if([self askForSave] == NO)
		return;
	
	widthBox = [[newArenaPanel contentView] viewWithTag:1];
	heightBox = [[newArenaPanel contentView] viewWithTag:2];
	[widthBox setIntValue:
		[[NSUserDefaults standardUserDefaults] integerForKey:@"DefaultArenaWidth"]];
	[heightBox setIntValue:
		[[NSUserDefaults standardUserDefaults] integerForKey:@"DefaultArenaHeight"]];

	BOOL isOK = NO;
	BOOL saveToDefaults;
	do
	{
		saveToDefaults = YES;
		modalResultCode = [NSApp runModalForWindow:newArenaPanel];
		if(modalResultCode == 0)
		{
			[newArenaPanel orderOut:nil];
			return;
		}
		
		if([widthBox intValue] < 100 || [heightBox intValue] < 50)
		{
			if([widthBox intValue] < 100)
				[widthBox setIntValue:100];
			if([heightBox intValue] < 50)
				[heightBox setIntValue:50];
			NSRunAlertPanel(NSLocalizedString(@"You cannot create an arena smaller than 100x50.", @""),
							NSLocalizedString(@"Please make your arena at least as large as 100x50.", @""),
							NSLocalizedString(@"OK", @"default button title"),
							nil, nil);
		}
		else if([widthBox intValue] * [heightBox intValue] > 10000000)
		{
			int result = NSRunAlertPanel(
				   NSLocalizedString(@"Are you sure you want to make an arena of this size?", @""),
				   NSLocalizedString(@"Large arenas will use a great deal of memory and may run slowly. This arena will use %dMB of memory, or more.", @""),
				   NSLocalizedString(@"No", @"button title"),
				   NSLocalizedString(@"Yes", @"button title"),
				   nil,
				   [widthBox intValue] * [heightBox intValue] * 9 / (1024*1024));
			if(result == NSAlertDefaultReturn)
				isOK = NO;
			else
			{
				isOK = YES;
				saveToDefaults = NO; // let it be created but don't save the numbers to the defaults;
						 // that way if there's a problem, the program won't use these numbers next time
			}
		}
		else
			isOK = YES;
	} while(!isOK);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CreatureNewArenaCreatedNotification object:self];
	[arena release];
	arena = nil;
	[Genome destroyListContents];

	width = [widthBox intValue];
	height = [heightBox intValue];
	if(saveToDefaults)
	{
		[[NSUserDefaults standardUserDefaults] setInteger:width forKey:@"DefaultArenaWidth"];
		[[NSUserDefaults standardUserDefaults] setInteger:height forKey:@"DefaultArenaHeight"];
	}
	[newArenaPanel orderOut:nil];
	
	arena = [[Arena alloc] initWithX:width Y:height];
	[Arena setArena:arena];
	[view setArena:arena];
	[[view window] setDocumentEdited:NO];
	[[view window] setRepresentedFilename:@""];
	[[view window] setTitle:NSLocalizedString(@"Creatures New Window", @"new window title")];
	hasBeenSaved = NO;
	if([arenaSettingsWindow isVisible])
		[self openArenaSettingsWindow:self]; // reset the values it contains

	[FamilyTreeWindowController reset];

	/* CREATE GENOME 0 */
	[genomeField setGenome:[Genome defaultGenome]];
	
	[view setNeedsDisplay:YES];
	step = 0;
	[self update];
}

- (IBAction)save:sender
{
	if(!hasBeenSaved)
		[self saveAs:sender];
	else
	{
		[self saveFilename:[[view window] representedFilename]];
	}
}

- (void)timedSave
{
	if(hasBeenSaved)
		[self save:self];
}

- (IBAction)open:sender
{
    int result;
    NSArray *fileTypes = [NSArray arrayWithObject:@"creatures"];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];

	if([self askForSave] == NO)
		return;

    result = [oPanel runModalForDirectory:NSHomeDirectory() file:nil types:fileTypes];
    if (result == NSOKButton && [oPanel filename] != nil)
	{
		[[view window] setDocumentEdited:NO];
		[self openFilename:[oPanel filename]];
	}
}

- (IBAction)openWebPage:sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.mikeash.com/software/creatures/"]];
}

- (IBAction)showHelp:sender
{
	NSString *helpFilePath = [[NSBundle mainBundle] pathForResource:@"help" ofType:@"html"];
	[SimpleWebController openURL:[NSURL fileURLWithPath:helpFilePath] withIdentifier:NSLocalizedString(@"Help File", @"Help window title")];
}

- (IBAction)purchase:sender
{
}

- (IBAction)doRegister:sender
{
}

- (IBAction)registrationInfo:sender
{
	NSString *name = @"Open Source Creatures", *copies = @"Unlimited";
	NSRunAlertPanel(NSLocalizedString(@"This copy of Creatures is registered to:", @""),
					[NSString stringWithFormat:NSLocalizedString(@"Name: %@\nCopies: %@\n\nThanks for registering!", @"Registration info box string"), name, copies],
					NSLocalizedString(@"OK", @"default button title"), nil, nil);
}


- (IBAction)toolChanged:sender
{
	id tool = [toolDictionary objectForKey:[NSValue valueWithNonretainedObject:[toolSelectMatrix selectedCell]]];
	NSEnumerator *enumerator = [toolDictionary objectEnumerator];
	id obj;
	
	NSView *newView = [tool settingsView];
	[activeSettingsView removeFromSuperview];
	[[drawingPanel contentView] addSubview:newView];
	NSPoint newOrigin = [toolSelectMatrix frame].origin;
	newOrigin.y -= [newView frame].size.height;
	[newView setFrameOrigin:newOrigin];
	activeSettingsView = newView;

	[self resizeDrawingPanel];
	
	while((obj = [enumerator nextObject]))
	{
		if(obj != tool && [obj respondsToSelector:@selector(deselected:)])
			[obj deselected:nil];
	}
	if([tool respondsToSelector:@selector(selected:)])
		[tool selected:nil];
}


- (IBAction)openArenaSettingsWindow:sender
{
	int tag = 0;
	[mutationRateField setDoubleValue:[arena mutationRate]];
	[birthMutationRateField setDoubleValue:[arena birthMutationRate]];
	[foodGrowthIntervalField setDoubleValue:[arena foodGrowthRate]];
	[spawnEnergyField setIntValue:[arena spawnEnergy]];
	[stopThresholdPopulationField setIntValue:[arena stopThresholdPopulation]];
	
	[allowedSpawnBehaviorRadio selectCellWithTag:[arena spawnMask]];
	switch([arena edgeBehavior])
	{
		case kEdgeWrap:
			tag = 1;
			break;
		case kEdgeBlock:
			tag = 2;
			break;
		case kEdgeKill:
			tag = 3;
			break;
	}
	[edgeBehaviorRadio selectCellWithTag:tag];

	[biasFoodProportionField setDoubleValue:([arena biasFoodGrowthProportion]*100.0)];
	[biasFoodAmountField setIntValue:[arena biasFoodGrowthAmount]];
	if([arena biasFoodGrowth])
	{
		[biasFoodCheckbox setState:NSOnState];
		[biasFoodProportionField setEnabled:YES];
		[biasFoodAmountField setEnabled:YES];
	}
	else
	{
		[biasFoodCheckbox setState:NSOffState];
		[biasFoodProportionField setEnabled:NO];
		[biasFoodAmountField setEnabled:NO];
	}

	if([arena useStopThresholdPopulation])
	{
		[stopThresholdPopulationCheckbox setState:NSOnState];
		[stopThresholdPopulationField setEnabled:YES];
	}
	else
	{
		[stopThresholdPopulationCheckbox setState:NSOffState];
		[stopThresholdPopulationField setEnabled:NO];
	}
	
	[arenaSettingsWindow makeKeyAndOrderFront:self];
}

- (IBAction)mutationRateChanged:sender
{
	if([arena mutationRate] != [sender doubleValue])
		[[view window] setDocumentEdited:YES];
	[arena setMutationRate:[sender doubleValue]];
}

- (IBAction)birthMutationRateChanged:sender
{
	if([arena birthMutationRate] != [sender doubleValue])
		[[view window] setDocumentEdited:YES];
	[arena setBirthMutationRate:[sender doubleValue]];
}

- (IBAction)foodGrowthIntervalChanged:sender
{
	if([arena foodGrowthRate] != [sender doubleValue])
		[[view window] setDocumentEdited:YES];
	[arena setFoodGrowthRate:[sender doubleValue]];
}

- (IBAction)spawnEnergyChanged:sender
{
	if([arena spawnEnergy] != [sender intValue])
		[[view window] setDocumentEdited:YES];
	[arena setSpawnEnergy:[sender intValue]];
}

- (IBAction)allowedSpawnBehaviorChanged:sender
{
	[arena setSpawnMask:[[sender selectedCell] tag]];
}

- (IBAction)edgeBehaviorChanged:sender
{
	eEdgeType type = kEdgeWrap; // arbitrary choice to shut up warnings
	switch([[sender selectedCell] tag])
	{
		case 1:
			type = kEdgeWrap;
			break;
		case 2:
			type = kEdgeBlock;
			break;
		case 3:
			type = kEdgeKill;
			break;
		default:
			MyErrorLog(@"Bad type recieved: %d", [[sender selectedCell] tag]);
			break;
	}
	if([arena edgeBehavior] != type)
		[[view window] setDocumentEdited:YES];
	[arena setEdgeBehavior:type];
}

- (IBAction)biasFoodCheckboxClicked:sender
{
	if([sender state] == NSOnState)
	{
		[arena setBiasFoodGrowth:YES];
		[biasFoodProportionField setEnabled:YES];
		[biasFoodAmountField setEnabled:YES];
	}
	else
	{
		[arena setBiasFoodGrowth:NO];
		[biasFoodProportionField setEnabled:NO];
		[biasFoodAmountField setEnabled:NO];
	}
	[[view window] setDocumentEdited:YES];
}

- (IBAction)biasFoodProportionChanged:sender
{
	if([arena biasFoodGrowthProportion] != [sender doubleValue]/100.0)
		[[view window] setDocumentEdited:YES];
	[arena setBiasFoodGrowthProportion:([sender doubleValue]/100.0)];
}

- (IBAction)biasFoodAmountChanged:sender
{
	if([arena biasFoodGrowthAmount] != [sender intValue])
		[[view window] setDocumentEdited:YES];
	[arena setBiasFoodGrowthAmount:[sender intValue]];
}

- (IBAction)stopThresholdPopulationCheckboxClicked:sender
{
	if([sender state] == NSOnState)
	{
		[arena setUseStopThresholdPopulation:YES];
		[stopThresholdPopulationField setEnabled:YES];
	}
	else
	{
		[arena setUseStopThresholdPopulation:NO];
		[stopThresholdPopulationField setEnabled:NO];
	}
	[[view window] setDocumentEdited:YES];
}

- (IBAction)stopThresholdPopulationChanged:sender
{
	if([arena stopThresholdPopulation] != [sender intValue])
		[[view window] setDocumentEdited:YES];
	[arena setStopThresholdPopulation:[sender intValue]];
}


- (CreaturesView *)view
{
	return view;
}

- arena
{
	return arena;
}

- selectedTool
{
	return [toolDictionary objectForKey:[NSValue valueWithNonretainedObject:[toolSelectMatrix selectedCell]]];
}



// thanks to oreilly for this one
- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender
						defaultFrame:(NSRect)defaultFrame
{
	if(sender == mainWindow)
	{
		NSSize goodSize = [self windowWillResize:sender toSize:defaultFrame.size];
		NSRect returnRect = {[sender frame].origin, goodSize};
		float dx, dy;
		dx = NSMaxX(returnRect) - NSMaxX(defaultFrame);
		dy = NSMaxY(returnRect) - NSMaxY(defaultFrame);
		if(dx > 0)
			returnRect.origin.x -= dx;
		if(dy > 0)
			returnRect.origin.y -= dy;
		return returnRect;
	}
	else
		return defaultFrame;
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize
{
	if(sender == mainWindow)
	{
		NSSize viewSize = [view frame].size;
		//viewSize.width -= 1;
		viewSize.height -= 1;
		NSSize maxSize = [NSScrollView frameSizeForContentSize:viewSize hasHorizontalScroller:YES hasVerticalScroller:YES borderType:[scrollView borderType]];
		NSPoint scrollViewOrigin = [scrollView frame].origin;
		maxSize.width += scrollViewOrigin.x;
		maxSize.height += scrollViewOrigin.y;
		NSSize newSize = proposedFrameSize;
		maxSize = [NSWindow frameRectForContentRect:NSMakeRect(0, 0, maxSize.width, maxSize.height) styleMask:[sender styleMask]].size;
		if(newSize.width > maxSize.width)
			newSize.width = maxSize.width;
		if(newSize.height > maxSize.height)
			newSize.height = maxSize.height;
		return newSize;
	}
	else
		return proposedFrameSize;
}

- (void)controlTextDidChange:(NSNotification *)notification
{
	[[notification object] sendAction:[[notification object] action] to:[[notification object] target]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	NSNumber *drawingPanelXNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"DrawPanelOriginX"];
	NSNumber *drawingPanelYNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"DrawPanelOriginY"];
	if(drawingPanelXNumber && drawingPanelYNumber)
	{
		[drawingPanel setFrameTopLeftPoint:NSMakePoint([drawingPanelXNumber floatValue], [drawingPanelYNumber floatValue])];
	}
	[self removeUnregisteredMenuItems];
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	return [self openFilename:filename];
}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	if([self askForSave] == NO)
		return NSTerminateCancel;
	else
	{
		NSRect drawFrame = [drawingPanel frame];
		NSPoint drawOrigin = NSMakePoint(drawFrame.origin.x, drawFrame.origin.y + drawFrame.size.height);
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:[NSNumber numberWithFloat:drawOrigin.x] forKey:@"DrawPanelOriginX"];
		[defaults setObject:[NSNumber numberWithFloat:drawOrigin.y] forKey:@"DrawPanelOriginY"];
		[defaults synchronize];
		return NSTerminateNow;
	}
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return NO;
}

- (BOOL)windowShouldClose:sender
{
	BOOL userAgrees = [self askForSave];
	if(userAgrees)
		[NSApp terminate:self];
	return userAgrees;
}

- (void)appActivated:(NSNotification *)notification
{
	//[controlPanel setFloatingPanel:YES];
	//[drawingPanel setFloatingPanel:YES];
}

- (void)appDeactivated:(NSNotification *)notification
{
	//[controlPanel setFloatingPanel:NO];
	//[drawingPanel setFloatingPanel:NO];
}

@end
