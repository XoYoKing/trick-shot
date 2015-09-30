//
//  IEDataManager.h
//  Circle Test
//
//  Created by Eric Dufresne on 2015-07-03.
//  Copyright (c) 2015 Eric Dufresne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IEBounceLevelController.h"

@interface IEDataManager : NSObject
@property (assign, nonatomic) NSUInteger highestUnlock;
@property (assign, nonatomic) NSUInteger highestTier;
@property (assign, nonatomic) BOOL hasRanBefore;
@property (assign, nonatomic) BOOL isLoaded;
@property (assign, nonatomic) NSUInteger localLevelCount;
+(IEDataManager*)sharedManager;
-(void)completedLevel:(NSUInteger)level withStars:(NSUInteger)stars;
-(NSUInteger)starsForLevel:(NSUInteger)level;
-(NSUInteger)starCount;
@end
