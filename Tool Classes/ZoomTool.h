//
//  ZoomTool.h
//  Creatures
//
//  Created by Michael Ash on Mon Aug 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DrawingTool.h"


@interface ZoomTool : DrawingTool {
	NSCursor *zoomInCursor;
	NSCursor *zoomOutCursor;
}

@end
