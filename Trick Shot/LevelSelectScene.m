//
//  LevelSelectScene.m
//  
//
//  Created by Eric Dufresne on 2015-07-06.
//
//

#import "LevelSelectScene.h"
#import "IEDataManager.h"
#import "MainScene.h"
#import "ViewController.h"
#import "AppDelegate.h"
#define DIM_FACTOR 6
#define STAR_DIM_FACTOR 4

@interface LevelSelectScene (){
    SKTexture *roundedBoxTexture;
}
@property BOOL contentCreated;
@property (strong, nonatomic) UISwipeGestureRecognizer *leftSwipe;
@property (strong, nonatomic) UISwipeGestureRecognizer *rightSwipe;
@end

@implementation LevelSelectScene
-(void)didMoveToView:(SKView *)view{
    if (!self.contentCreated){
        self.contentCreated = YES;
        [self createSceneContent];
    }
}

-(void)createSceneContent{
    AppDelegate *delegate= (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.backgroundColor = [delegate.arrayOfColors objectAtIndex:self.colorIndex];
    self.leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeLeft)];
    self.rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeRight)];
    self.leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    self.rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    self.leftSwipe.cancelsTouchesInView = YES;
    self.rightSwipe.cancelsTouchesInView = YES;
    [self.view addGestureRecognizer:self.rightSwipe];
    [self.view addGestureRecognizer:self.leftSwipe];
    
    CGSize size = CGSizeMake(self.size.width/DIM_FACTOR/STAR_DIM_FACTOR, self.size.width/DIM_FACTOR/STAR_DIM_FACTOR);
    SKSpriteNode *starSprite = [SKSpriteNode spriteNodeWithTexture:[SKTexture textureWithImageNamed:@"star.png"]];
    starSprite.size = size;
    starSprite.position = CGPointMake(CGRectGetMidX(self.frame)-5, self.size.height-starSprite.size.height/2-5);
    [self addChild:starSprite];
    SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Roboto-Thin"];
    label.fontSize = 14;
    label.fontColor = [UIColor colorWithRed:0.965f green:0.729f blue:0.227f alpha:1.00f];
    label.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    label.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    NSInteger sum = 0;
    for (NSInteger k = self.firstNumber;k<self.firstNumber+self.columns*self.rows;k++){
        sum+= [[IEDataManager sharedManager] starsForLevel:k];
    }
    label.text = [NSString stringWithFormat:@"%i/%i", (int)sum, (int)(self.rows*self.columns*3)];
    [self addChild:label];
    label.position = CGPointMake(starSprite.position.x+label.frame.size.width/2+5, starSprite.position.y);
    const CGFloat bufferTopBottom = self.size.height/15;
    CGFloat bufferX = self.size.width/self.columns;
    CGFloat bufferY = (self.size.height-2*bufferTopBottom)/self.rows;
    
    NSUInteger currentNumber = self.firstNumber;
    BOOL stop = NO;
    for (int k = 0;k<self.rows;k++){
        for (int i = 0;i<self.columns;i++){
            if(currentNumber>[[IEDataManager sharedManager] localLevelCount]){
                stop = YES;
                break;
            }
            CGPoint location = CGPointMake(bufferX/2+bufferX*i, self.size.height-bufferTopBottom-bufferY/2-bufferY*k);
            SKSpriteNode *sprite = [[SKSpriteNode alloc] initWithColor:[SKColor whiteColor] size:CGSizeMake(self.size.width/DIM_FACTOR, self.size.width/DIM_FACTOR)];
            sprite.position = location;
            SKShapeNode *shape = [SKShapeNode node];
            shape.path = CGPathCreateWithRoundedRect(CGRectMake(-self.size.width/DIM_FACTOR, -self.size.width/DIM_FACTOR, self.size.width/DIM_FACTOR*2, self.size.width/DIM_FACTOR*2), 12, 12, NULL);
            if (![delegate hasDarkColorSchemeForIndex:self.colorIndex]){
                shape.fillColor = [SKColor whiteColor];
                shape.strokeColor = [SKColor whiteColor];
            }
            else{
                shape.fillColor = [SKColor darkGrayColor];
                shape.strokeColor = [SKColor darkGrayColor];
            }
            SKTexture *texture = [self.view textureFromNode:shape];
            sprite.texture = texture;
            sprite.name = @"Button";
            [self addChild:sprite];
            
            SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Roboto-Thin"];
            label.fontColor = self.backgroundColor;
            label.fontSize = 25;
            label.text = [NSString stringWithFormat:@"%i", (int)currentNumber];
            [label setHorizontalAlignmentMode:SKLabelHorizontalAlignmentModeCenter];
            [label setVerticalAlignmentMode:SKLabelVerticalAlignmentModeCenter];
            label.name = @"buttonLabel";
            label.position = CGPointZero;
            [sprite addChild:label];
            NSInteger stars = [[IEDataManager sharedManager] starsForLevel:currentNumber];
            
            if ([IEDataManager sharedManager].highestUnlock<currentNumber){
                SKShapeNode *black = [SKShapeNode node];
                black.path = shape.path;
                black.fillColor = [SKColor blackColor];
                black.strokeColor = [SKColor blackColor];
                texture = [self.view textureFromNode:black];
                SKSpriteNode *blackMask = [SKSpriteNode spriteNodeWithTexture:texture];
                blackMask.alpha = 0.5;
                blackMask.position = CGPointZero;
                blackMask.size = sprite.size;
                SKSpriteNode *lock = [SKSpriteNode spriteNodeWithTexture:[SKTexture textureWithImageNamed:@"lockicon.png"]];
                lock.size = CGSizeMake(sprite.size.width/2, sprite.size.width/2);
                lock.position = CGPointZero;
                [blackMask addChild:lock];
                [sprite addChild:blackMask];
            }
            currentNumber++;
            if (stars == 1){
                SKSpriteNode *star = [SKSpriteNode spriteNodeWithTexture:[SKTexture textureWithImageNamed:@"star.png"]];
                star.size = CGSizeMake(sprite.size.width/STAR_DIM_FACTOR, sprite.size.height/STAR_DIM_FACTOR);
                star.position = CGPointMake(0, -sprite.size.height/2-star.size.height/2);
                [sprite addChild:star];
            }
            else if (stars == 2){
                SKSpriteNode *star1 = [SKSpriteNode spriteNodeWithTexture:[SKTexture textureWithImageNamed:@"star.png"]];
                star1.size = CGSizeMake(sprite.size.width/STAR_DIM_FACTOR, sprite.size.height/STAR_DIM_FACTOR);
                star1.position = CGPointMake(-sprite.size.width/6, -sprite.size.height/2-star1.size.height/2);
                
                SKSpriteNode *star2 = [SKSpriteNode spriteNodeWithTexture:[SKTexture textureWithImageNamed:@"star.png"]];
                star2.size = CGSizeMake(sprite.size.width/STAR_DIM_FACTOR, sprite.size.height/STAR_DIM_FACTOR);
                star2.position = CGPointMake(+sprite.size.width/6, -sprite.size.height/2-star2.size.height/2);
                
                [sprite addChild:star1];
                [sprite addChild:star2];
            }
            else if (stars == 3){
                for (int k = 0;k<stars;k++){
                    SKSpriteNode *star = [SKSpriteNode spriteNodeWithTexture:[SKTexture textureWithImageNamed:@"star.png"]];
                    star.size = CGSizeMake(sprite.size.width/STAR_DIM_FACTOR, sprite.size.height/STAR_DIM_FACTOR);
                    if (k == 0)
                        star.position = CGPointMake(0, -star.size.height/2-sprite.size.height/2);
                    else if (k == 1)
                        star.position = CGPointMake(-star.size.width-sprite.size.width/11, -star.size.height/2-sprite.size.height/2);
                    else
                        star.position = CGPointMake(+star.size.width+sprite.size.width/11, -star.size.height/2-sprite.size.height/2);
                    [sprite addChild:star];
                }
            }
        }
        if (stop)
            break;
    }
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    self.selectedNode = node;
}
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    if (self.selectedNode){
        UITouch *touch = [touches anyObject];
        CGPoint location = [touch locationInNode:self];
        if (!CGRectContainsPoint(self.selectedNode.frame, location))
            self.selectedNode = nil;
    }
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    if (self.selectedNode){
        NSInteger levelNumber = -1;
        if ([node.name isEqualToString:@"Button"]){
            SKLabelNode *label = (SKLabelNode*)[node childNodeWithName:@"buttonLabel"];
            levelNumber = label.text.integerValue;
        }
        else if ([node.parent.name isEqualToString:@"Button"]){
            SKLabelNode *label = (SKLabelNode*)node;
            levelNumber = label.text.integerValue;
        }
        if (levelNumber>0){
            [self.view removeGestureRecognizer:self.leftSwipe];
            [self.view removeGestureRecognizer:self.rightSwipe];
            MainScene *scene = [[MainScene alloc] initWithSize:self.size];
            scene.colorIndex = self.colorIndex;
            ViewController *viewController = (ViewController*)self.view.window.rootViewController;
            SKView *view = (SKView*)viewController.view;
            
            scene.scaleMode = SKSceneScaleModeAspectFill;
            IEBounceLevelController *controller = [IEBounceLevelController controllerWithLevelNumber:levelNumber];
            scene.controller = controller;
            [view presentScene:scene];
            [viewController dismissViewControllerAnimated:NO completion:nil];
        }
    }
}
-(void)didSwipeRight{
    if (!(self.firstNumber == 1)){
        self.presentingViewController.pageControl.currentPage--;
        [self.presentingViewController changingToIndex:self.presentingViewController.pageControl.currentPage];
        LevelSelectScene *scene = [[LevelSelectScene alloc] initWithSize:self.view.bounds.size];
        scene.colorIndex=self.colorIndex-1;
        scene.scaleMode = SKSceneScaleModeAspectFill;
        scene.rows = self.rows;
        scene.columns = self.columns;
        scene.firstNumber = self.firstNumber-self.rows*self.columns;
        scene.presentingViewController = self.presentingViewController;
        [self.view presentScene:scene transition:[SKTransition pushWithDirection:SKTransitionDirectionRight duration:0.25]];
    }
}
-(void)didSwipeLeft{
    if (self.firstNumber+self.rows*self.columns-1<[IEDataManager sharedManager].localLevelCount){
        self.presentingViewController.pageControl.currentPage++;
        [self.presentingViewController changingToIndex:self.presentingViewController.pageControl.currentPage];
        LevelSelectScene *scene = [[LevelSelectScene alloc] initWithSize:self.view.bounds.size];
        scene.colorIndex = self.colorIndex+1;
        scene.scaleMode = SKSceneScaleModeAspectFill;
        scene.rows = self.rows;
        scene.columns = self.columns;
        scene.firstNumber = self.firstNumber+self.rows*self.columns;
        scene.presentingViewController = self.presentingViewController;
        [self.view presentScene:scene transition:[SKTransition pushWithDirection:SKTransitionDirectionLeft duration:0.25]];
    }
    
}
#pragma mark - Helper Methods
+(UIColor*)colorWithR:(CGFloat)r G:(CGFloat)g B:(CGFloat)b{
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1];
}
@end
