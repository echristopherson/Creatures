//
//  FamilyTreeWindowController.h
//  Creatures
//
//  Created by Michael Ash on Fri Mar 15 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>


@class FamilyTreeView;

@interface FamilyTreeWindowController : NSWindowController {
	IBOutlet FamilyTreeView *treeView;
}

+ controller;
+ (void)reset;
- (FamilyTreeView *)treeView;

@end
