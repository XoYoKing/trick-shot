//
//  MenuScene.m
//  Circle Test
//
//  Created by Eric Dufresne on 2015-06-30.
//  Copyright (c) 2015 Eric Dufresne. All rights reserved.
//

#import "MenuScene.h"
#import "MainScene.h"
#import "LevelSelectScene.h"
#import "ViewController.h"
#import "AppDelegate.h"

@interface MenuScene (){
    NSTimer *timer;
}
@property BOOL contentCreated;
@property (assign, nonatomic) NSUInteger currentIndex;
@end
@implementation MenuScene
static const uint32_t contactCategory = 0x1 << 0;

-(void)didMoveToView:(SKView *)view{
    if (!self.contentCreated){
        self.contentCreated = YES;
        [self createSceneContent];
    }
}
-(void)createSceneContent{
    // 4,
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
    self.physicsBody.restitution = 1;
    self.physicsBody.categoryBitMask = contactCategory;
    self.physicsBody.collisionBitMask = 0xFFFFFF;
    self.physicsBody.contactTestBitMask = contactCategory;
    self.physicsBody.friction = 0;
    self.physicsWorld.gravity = CGVectorMake(0, 0);
    
    AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    int index = arc4random()%delegate.arrayOfColors.count;
    self.backgroundColor = [delegate.arrayOfColors objectAtIndex:index];
    UIColor *baseColor;
    UIColor *selectedColor;
    if (index <=4){
        baseColor = [SKColor darkGrayColor];
        selectedColor = [SKColor lightGrayColor];
    }
    else{
        baseColor = [SKColor whiteColor];
        selectedColor = [SKColor lightGrayColor];
    }
    
    SKLabelNode *labelNode = [SKLabelNode labelNodeWithFontNamed:@"Roboto-Thin"];
    labelNode.fontColor = baseColor;
    labelNode.fontSize = 50;
    labelNode.text = @"Trick Shot";
    labelNode.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame)+100);
    labelNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:labelNode.frame.size center:CGPointMake(0, labelNode.frame.size.height/2)];
    labelNode.physicsBody.friction = 0;
    labelNode.physicsBody.restitution = 1;
    labelNode.physicsBody.categoryBitMask = contactCategory;
    labelNode.physicsBody.contactTestBitMask = contactCategory;
    labelNode.physicsBody.collisionBitMask = 0xFFFFFF;
    labelNode.physicsBody.dynamic = NO;
    [self addChild:labelNode];
    
    
    IELabelButton *playNode = [IELabelButton buttonWithFontName:@"Roboto-Thin" defaultColor:baseColor selectedColor:selectedColor];
    playNode.delegate = self;
    playNode.fontSize = 26;
    playNode.text = @"Play";
    playNode.position = CGPointMake(CGRectGetMidX(self.frame), labelNode.position.y-100);
    playNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:playNode.frame.size center:CGPointMake(0, playNode.frame.size.height/2)];
    playNode.physicsBody.friction = 0;
    playNode.name = @"play";
    playNode.physicsBody.restitution = 1;
    playNode.physicsBody.categoryBitMask = contactCategory;
    playNode.physicsBody.contactTestBitMask = contactCategory;
    playNode.physicsBody.collisionBitMask = 0xFFFFFF;
    playNode.physicsBody.dynamic = NO;
    [self addChild:playNode];
    
    IELabelButton *leaderboardsNode = [IELabelButton buttonWithFontName:@"Roboto-Thin" defaultColor:baseColor selectedColor:selectedColor];
    leaderboardsNode.delegate = self;
    leaderboardsNode.fontSize = 26;
    leaderboardsNode.text = @"Leaderboards";
    leaderboardsNode.name = @"leaderboards";
    leaderboardsNode.position = CGPointMake(CGRectGetMidX(self.frame), playNode.position.y-50);
    leaderboardsNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:leaderboardsNode.frame.size center:CGPointMake(0, leaderboardsNode.frame.size.height/2)];
    leaderboardsNode.physicsBody.friction = 0;
    leaderboardsNode.physicsBody.restitution = 1;
    leaderboardsNode.physicsBody.categoryBitMask = contactCategory;
    leaderboardsNode.physicsBody.contactTestBitMask = contactCategory;
    leaderboardsNode.physicsBody.collisionBitMask = 0xFFFFFF;
    leaderboardsNode.physicsBody.dynamic = NO;
    [self addChild:leaderboardsNode];
    
    IELabelButton *rateNode = [IELabelButton buttonWithFontName:@"Roboto-Thin" defaultColor:baseColor selectedColor:selectedColor];
    rateNode.delegate = self;
    rateNode.fontSize = 20;
    rateNode.text = @"Rate";
    rateNode.name = @"rate";
    rateNode.position = CGPointMake(CGRectGetMinX(leaderboardsNode.frame)+rateNode.frame.size.width/2, leaderboardsNode.position.y-50);
    rateNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:rateNode.frame.size center:CGPointMake(0, rateNode.frame.size.height/2)];
    rateNode.physicsBody.friction = 0;
    rateNode.physicsBody.restitution = 1;
    rateNode.physicsBody.categoryBitMask = contactCategory;
    rateNode.physicsBody.contactTestBitMask = contactCategory;
    rateNode.physicsBody.collisionBitMask = 0xFFFFFF;
    rateNode.physicsBody.dynamic = NO;
    [self addChild:rateNode];
    
    IELabelButton *removeAdsNode = [IELabelButton buttonWithFontName:@"Roboto-Thin" defaultColor:baseColor selectedColor:selectedColor];
    removeAdsNode.delegate = self;
    removeAdsNode.fontSize = 20;
    removeAdsNode.text = @"Remove Ads";
    removeAdsNode.name = @"removeAds";
    removeAdsNode.position = CGPointMake(CGRectGetMaxX(leaderboardsNode.frame)-removeAdsNode.frame.size.width/2, rateNode.position.y);
    removeAdsNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:removeAdsNode.frame.size center:CGPointMake(0, removeAdsNode.frame.size.height/2)];
    removeAdsNode.physicsBody.friction = 0;
    removeAdsNode.physicsBody.restitution = 1;
    removeAdsNode.physicsBody.categoryBitMask = contactCategory;
    removeAdsNode.physicsBody.contactTestBitMask = contactCategory;
    removeAdsNode.physicsBody.collisionBitMask = 0xFFFFFF;
    removeAdsNode.physicsBody.dynamic = NO;
    [self addChild:removeAdsNode];
    
    
    SKShapeNode *shape = [SKShapeNode shapeNodeWithCircleOfRadius:256];
    shape.fillColor = [SKColor whiteColor];
    shape.strokeColor = baseColor;
    shape.lineWidth = 20;
    shape.antialiased = YES;
    SKTexture *texture = [self.view textureFromNode:shape];
    
    SKSpriteNode *ball = [SKSpriteNode spriteNodeWithTexture:texture];
    ball.size = CGSizeMake(32, 32);
    ball.position = CGPointMake(CGRectGetMidX(self.frame), ball.size.height/2+25);
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:16];
    ball.physicsBody.friction = 0;
    ball.physicsBody.restitution = 1;
    ball.physicsBody.linearDamping = 0;
    ball.physicsBody.angularDamping = 0;
    ball.physicsBody.contactTestBitMask = contactCategory;
    ball.physicsBody.collisionBitMask = 0xFFFFFF;
    ball.physicsBody.contactTestBitMask = contactCategory;
    ball.name = @"ball";
    [self addChild:ball];
    
    [ball.physicsBody applyImpulse:getVectorWithResultantVelocity(5)];
}
-(void)tick{
    static int index = 0;
    index++;
    AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    if (index==delegate.arrayOfColors.count)
        index = 0;
    self.backgroundColor = [delegate.arrayOfColors objectAtIndex:index];
}
#pragma mark - Touch Events
-(void)buttonWasReleased:(id)button{
    IELabelButton *released = (IELabelButton*)button;
    if([released.name isEqualToString:@"play"]){
        ViewController *viewController = (ViewController*)self.view.window.rootViewController;
        [viewController performSegueWithIdentifier:@"levelSelectSegue" sender:viewController];
    }
    else if ([released.name isEqualToString:@"leaderboards"]){
        NSLog(@"Leaderboards");
    }
    else if ([released.name isEqualToString:@"rate"]){
        NSLog(@"Rate");
    }
    else if ([released.name isEqualToString:@"removeAds"]){
        NSLog(@"RemoveAds");
    }
}
-(void)didBeginContact:(SKPhysicsContact *)contact{
    NSLog(@"Play Noise");
}
#pragma mark - Helper and C style methods
+(UIColor*)colorWithR:(CGFloat)r G:(CGFloat)g b:(CGFloat)b{
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1];
}
static inline CGVector getVectorWithResultantVelocity(float velocity){
    CGFloat x = getRandomNumber(velocity, -velocity);
    CGFloat y = sqrtf(pow(velocity, 2)-pow(x,2));
    return CGVectorMake(x, y);
}
static inline CGFloat getRandomNumber(float high, float low){
    float random = (float)rand()/(float)RAND_MAX;
    return low+random*(high-low);
}
@end
