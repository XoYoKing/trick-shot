//
//  LevelSelectViewController.m
//  Trick Shot
//
//  Created by Eric Dufresne on 2015-07-12.
//  Copyright (c) 2015 Eric Dufresne. All rights reserved.
//

#import "LevelSelectViewController.h"
#import "LevelSelectScene.h"
#import "IEDataManager.h"
#import "AppDelegate.h"

@interface LevelSelectViewController ()

@end

@implementation LevelSelectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    const int rows = 5;
    const int columns = 4;
    
    NSInteger levelCount = [IEDataManager sharedManager].localLevelCount;
    self.pageControl.numberOfPages = (NSInteger)(ceil((double)levelCount/(double)(rows*columns)));
    self.pageControl.currentPageIndicatorTintColor = [UIColor darkGrayColor];
    self.pageControl.pageIndicatorTintColor = [UIColor colorWithRed:0.666 green:0.666 blue:0.666 alpha:0.5];
    LevelSelectScene *scene = [[LevelSelectScene alloc] initWithSize:self.view.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    if (self.pageToShow<=0||self.pageToShow>self.pageControl.numberOfPages){
        scene.firstNumber = 1;
        scene.colorIndex = 0;
    }
    else{
        scene.colorIndex = self.pageToShow;
        scene.firstNumber = 1+20*self.pageToShow;
    }
    scene.rows = rows;
    scene.columns = columns;
    scene.presentingViewController = self;
    SKView *view = (SKView*)self.view;
    view.showsFPS = YES;
    [view presentScene:scene];
    // Do any additional setup after loading the view.
}
-(BOOL)prefersStatusBarHidden{
    return YES;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
+(UIColor*)colorWithR:(CGFloat)r G:(CGFloat)g B:(CGFloat)b{
    return [UIColor colorWithRed:r green:g blue:b alpha:1];
}
-(void)changingToIndex:(NSUInteger)index{
    AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    const float animationDuration = 0.3;
    if ([delegate hasDarkColorSchemeForIndex:index]){
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:animationDuration];
        self.pageControl.currentPageIndicatorTintColor = [UIColor darkGrayColor];
        self.pageControl.pageIndicatorTintColor = [UIColor colorWithRed:0.666 green:0.666 blue:0.666 alpha:0.5];
        [UIView commitAnimations];
    }
    else{
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:animationDuration];
        self.pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
        self.pageControl.pageIndicatorTintColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5];
        [UIView commitAnimations];
    }
}


@end
