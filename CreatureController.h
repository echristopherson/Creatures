//
//  CreatureController.h
//  Creatures
//
//  Created by Michael Ash on Sat Jun 08 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>


extern NSString * const CreatureNewArenaCreatedNotification;

@class CreaturesView, Arena, GenomeDragAcceptTextField;

@interface CreatureController : NSObject {
	IBOutlet CreaturesView *view;
	IBOutlet NSScrollView *scrollView;
	IBOutlet id runButton, runMenuItem;
	IBOutlet id stepBox, populationBox;
	IBOutlet NSPanel *newArenaPanel;
	IBOutlet NSPanel *removeOldGenomesPanel;
	IBOutlet NSTextField *removeOldGenomesField;
	IBOutlet NSWindow *mainWindow;

	IBOutlet NSPanel *controlPanel;
	
	IBOutlet NSPanel *drawingPanel;
	IBOutlet NSMatrix *toolSelectMatrix;

	IBOutlet NSPanel *toolOptionsPanel;
	IBOutlet NSTabView *toolOptionsTabView;
	IBOutlet GenomeDragAcceptTextField *genomeField;

	IBOutlet NSButtonCell *handToolButton;
	IBOutlet NSButtonCell *circleToolButton;
	IBOutlet NSButtonCell *squareToolButton;
	IBOutlet NSButtonCell *pencilToolButton;
	IBOutlet NSButtonCell *selectToolButton;
	IBOutlet NSButtonCell *inspectToolButton;

	NSView *activeSettingsView;

	IBOutlet NSWindow *arenaSettingsWindow;
	IBOutlet NSTextField *mutationRateField;
	IBOutlet NSTextField *birthMutationRateField;
	IBOutlet NSTextField *foodGrowthIntervalField;
	IBOutlet NSTextField *spawnEnergyField;
	IBOutlet NSMatrix *allowedSpawnBehaviorRadio;
	IBOutlet NSMatrix *edgeBehaviorRadio;
	IBOutlet NSButton *biasFoodCheckbox;
	IBOutlet NSTextField *biasFoodProportionField;
	IBOutlet NSTextField *biasFoodAmountField;
	IBOutlet NSButton *stopThresholdPopulationCheckbox;
	IBOutlet NSTextField *stopThresholdPopulationField;

	IBOutlet NSMenuItem *purchaseMenuItem;
	IBOutlet NSMenuItem *enterSerialMenuItem;
	IBOutlet NSMenuItem *registrationInfoMenuItem;

	NSMutableDictionary *toolDictionary;

	Arena *arena;

	unsigned step;

	id genomeList;

	BOOL hasBeenSaved;
	BOOL askingForSave;

	id stepTimer, saveTimer;

	unsigned displayIntervalBase;
	int displayInterval;
}

- (void)setTool:tool forButton:button;

/*- (void)mouseDownAtPoint:(NSPoint)p;
- (void)mouseMovedToPoint:(NSPoint)p;
- (void)mouseUpAtPoint:(NSPoint)p;*/

- (IBAction)toggleRun:(id)sender;
- (IBAction)removeOldGenomes:sender;
- (IBAction)setDisplayInterval:sender;
- (void)setGenomeList:list;
- (IBAction)openGenomeWindow:sender;
- (IBAction)openFamilyTreeWindow:sender;
- (void)runningUpdate;
- (void)update;
- (IBAction)update:sender;
- (void)newArenaOK:sender;
- (void)newArenaCancel:sender;
- (IBAction)new:sender;
- (IBAction)saveAs:sender;
- (IBAction)save:sender;
- (void)timedSave;
- (IBAction)open:sender;
- (IBAction)openWebPage:sender;
- (IBAction)showHelp:sender;
- (IBAction)purchase:sender;
- (IBAction)doRegister:sender;
- (IBAction)registrationInfo:sender;

- (IBAction)toolChanged:sender;

- (IBAction)openArenaSettingsWindow:sender;
- (IBAction)mutationRateChanged:sender;
- (IBAction)birthMutationRateChanged:sender;
- (IBAction)foodGrowthIntervalChanged:sender;
- (IBAction)spawnEnergyChanged:sender;
- (IBAction)allowedSpawnBehaviorChanged:sender;
- (IBAction)edgeBehaviorChanged:sender;
- (IBAction)biasFoodCheckboxClicked:sender;
- (IBAction)biasFoodProportionChanged:sender;
- (IBAction)biasFoodAmountChanged:sender;
- (IBAction)stopThresholdPopulationCheckboxClicked:sender;
- (IBAction)stopThresholdPopulationChanged:sender;

- (CreaturesView *)view;
- arena;
- selectedTool;

@end
