//
//  ViewController.m
//  Circle Test
//
//  Created by Eric Dufresne on 2015-06-25.
//  Copyright (c) 2015 Eric Dufresne. All rights reserved.
//

#import "ViewController.h"
#import "MenuScene.h"
#import "IEBounceLevelController.h"
#import "LevelSelectViewController.h"
#import "AppDelegate.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    SKView *view = (SKView*)self.view;
    view.showsFPS = YES;
    //view.showsPhysics = YES;
    MenuScene *scene = [[MenuScene alloc] initWithSize:self.view.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    [view presentScene:scene];
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(BOOL)prefersStatusBarHidden{
    return YES;
}
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"levelSelectSegue"]){
        LevelSelectViewController *vc = segue.destinationViewController;
        AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        vc.pageToShow = delegate.pageToShow;
    }
}

@end
