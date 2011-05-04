//
//  GenomeListController.h
//  Creatures
//
//  Created by mikeash on Sun Oct 28 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>


@interface GenomeListController : NSWindowController {
	IBOutlet NSTableView *table;
	IBOutlet NSButton *filterUniqueBox, *filterExtinctBox;
	IBOutlet NSButton *updateAutomaticallyBox;

	NSMutableSet *visibleTableColumns;
	NSMutableSet *hiddenTableColumns;

	NSMenu *tableHeaderContextMenu;
	
	id creaturesView;
	
	NSMutableArray *listContents;
	int filterUnique, filterExtinct;
	id sortIdentifier;
	BOOL ascending;
	id updateTimer;
}

+ (void)showListWindow;
- (void)registerClick:sender;
- (void)setFilterUnique:sender;
- (void)setFilterExtinct:sender;
- (void)setUpdateAutomatically:sender;
- (void)update;
- (void)update:sender;
- (void)newClicked:sender;

@end
