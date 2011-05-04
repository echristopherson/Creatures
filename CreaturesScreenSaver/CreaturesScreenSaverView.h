//
//  CreaturesScreenSaverView.h
//  CreaturesScreenSaver
//
//  Created by Michael Ash on Sat Aug 09 2003.
//  Copyright (c) 2003, __MyCompanyName__. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>


@class CreatureController, CreaturesView;

@interface CreaturesScreenSaverView : ScreenSaverView 
{
	CreatureController *controller;
	CreaturesView *view;
}

@end
