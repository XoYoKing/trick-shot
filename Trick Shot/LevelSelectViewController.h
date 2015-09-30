//
//  LevelSelectViewController.h
//  Trick Shot
//
//  Created by Eric Dufresne on 2015-07-12.
//  Copyright (c) 2015 Eric Dufresne. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LevelSelectViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (assign, nonatomic) NSInteger pageToShow;
-(void)changingToIndex:(NSUInteger)index;
@end
