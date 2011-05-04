//
//  DrawingTool.h
//  Creatures
//
//  Created by Michael Ash on Sat Jan 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*
 Generalized Tool class for the drawing palette. Others should subclass from this.
 */

@class CreatureController;
@class ToolInteractionView;

@interface DrawingTool : NSObject {
	IBOutlet CreatureController *controller;
	IBOutlet id GUIObject; // what this instance is represented by
	IBOutlet NSView *settingsView;
}

- (NSView *)settingsView;

@end

@interface DrawingTool (OptionalSubclassMethods)

- (IBAction)selected:sender;
- (IBAction)deselected:sender;
- (void)clickedInView:(ToolInteractionView *)view at:(int)x :(int)y;
- (void)doubleClickedInView:(ToolInteractionView *)view at:(int)x :(int)y;
- (void)draggedInView:(ToolInteractionView *)view at:(int)x :(int)y;
- (void)draggedInView:(ToolInteractionView *)view withDeltas:(int)dx :(int)dy;
- (void)releasedInView:(ToolInteractionView *)view at:(int)x :(int)y;
- (void)movedInView:(ToolInteractionView *)view at:(int)x :(int)y;
- (void)view:(ToolInteractionView *)view keyPressedInArena:(NSString *)key;
- (void)view:(ToolInteractionView *)view modifiersChangedTo:(unsigned int)modifierFlags;

/*

 - (void)clickedInView:(NSView *)view at:(int)x :(int)y;
 - (void)doubleclickedInView:(NSView *)view at:(int)x :(int)y;
 - (void)draggedInView:(ToolInteractionView *)view at:(int)x :(int)y;
 - (void)draggedInView:(ToolInteractionView *)view withDeltas:(int)dx :(int)dy;
 - (void)releasedInView:(ToolInteractionView *)view at:(int)x :(int)y;
 - (void)movedInView:(ToolInteractionView *)view at:(int)x :(int)y;
 - (void)view:(ToolInteractionView *) keyPressedInArena:(NSString *)key;
 - (void)view:(ToolInteractionView *)view modifiersChangedTo:(unsigned int)modifierFlags;
 
 */
@end
