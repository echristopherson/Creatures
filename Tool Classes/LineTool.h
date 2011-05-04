//
//  LineTool.h
//  Creatures
//
//  Created by Michael Ash on Wed Jan 08 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DrawingTool.h"


@interface LineTool : DrawingTool {
	BOOL inProgress;
	int startx, starty;
	int curx, cury;
}

@end
