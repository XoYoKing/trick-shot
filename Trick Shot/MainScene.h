//
//  MainScene.h
//  Circle Test
//
//  Created by Eric Dufresne on 2015-06-26.
//  Copyright (c) 2015 Eric Dufresne. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "IEPointSelectionManager.h"
#import "IEBounceLevelController.h"
#import "IEButton.h"
typedef enum : NSUInteger{
    GameStatePlacingItems,
    GameStateBallMoving,
    GameStateLost, 
    GameStateWon,
    GameStateWaitingForTouch,
    GameStateTiltControls,
}GameState;
typedef enum : NSUInteger{
    MenuStateHidden,
    MenuStateShowing
}MenuState;
typedef enum : NSUInteger{
    TouchStateSingle,
    TouchStateNone,
    TouchStateInvalid,
}TouchState;
@interface MainScene : SKScene <IEPointSelectionDelegate, SKPhysicsContactDelegate, IEButtonDelegate>
@property (strong, nonatomic) IEBounceLevelController *controller;
@property (assign, nonatomic) GameState gameState;
@property (assign, nonatomic) MenuState menuState;
@property (assign, nonatomic) TouchState touchState;
@property (assign, nonatomic) NSInteger colorIndex;
@end