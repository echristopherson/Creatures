#import <Cocoa/Cocoa.h>
#import "ToolInteractionView.h"
#import "Arena.h"


@class CreatureController;

@interface CreaturesView : ToolInteractionView
{
	IBOutlet NSScrollView *scrollView;
	
	int originX, originY;
	Arena *arena;
	int lastUpdatedStep;

	NSMutableArray *temporaryPainters;

	PixelUnion *pixmap;
}

- (void)setArena:a;
- (void)addTemporaryPainter:obj;
- (void)removeTemporaryPainter:obj;
- (void)setNeedsPixmapUpdate;

@end
