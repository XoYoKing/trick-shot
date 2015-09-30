//
//  LevelSelectScene.h
//  
//
//  Created by Eric Dufresne on 2015-07-06.
//
//

#import <SpriteKit/SpriteKit.h>
#import "LevelSelectViewController.h"

@interface LevelSelectScene : SKScene
@property (strong, nonatomic) LevelSelectViewController *presentingViewController;
@property (assign, nonatomic) SKNode *selectedNode;
@property (assign, nonatomic) NSUInteger colorIndex;
@property NSUInteger rows;
@property NSUInteger columns;
@property NSUInteger firstNumber;
@end
