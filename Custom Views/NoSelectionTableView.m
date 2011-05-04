//
//  NoSelectionTableView.m
//  Creatures
//
//  Created by Michael Ash on Thu Jul 10 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NoSelectionTableView.h"


@implementation NoSelectionTableView

- (void)selectRow:(int)row byExtendingSelection:(BOOL)extend
{
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
	if([[self dataSource] respondsToSelector:@selector(tableView:draggedImage:endedAt:operation:)])
		[[self dataSource] tableView:self draggedImage:anImage endedAt:aPoint operation:operation];
	if([[self superclass] instancesRespondToSelector:_cmd])
		[super draggedImage:anImage endedAt:aPoint operation:operation];
}

@end
