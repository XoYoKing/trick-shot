//
//  IEDataManager.m
//  Circle Test
//
//  Created by Eric Dufresne on 2015-07-03.
//  Copyright (c) 2015 Eric Dufresne. All rights reserved.
//

#import "IEDataManager.h"
#import "AppDelegate.h"
#define LEVEL_PER_TIER 20

@implementation IEDataManager

+(IEDataManager*)sharedManager{
    static IEDataManager *instance = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        instance = [[IEDataManager alloc] init];
    });
    return instance;
}
-(id)init{
    if (self = [super init]){
        self.hasRanBefore = [[NSUserDefaults standardUserDefaults] boolForKey:@"hasRanBefore"];
        self.highestUnlock = 100000;
        [[NSUserDefaults standardUserDefaults] setInteger:self.highestUnlock forKey:@"highestUnlock"];
        if (!self.hasRanBefore){
#warning Highest Unlock set for testing mode
            self.highestUnlock = 10000;
            self.highestTier = 1;
            [[NSUserDefaults standardUserDefaults] setInteger:self.highestUnlock forKey:@"highestUnlock"];
            [[NSUserDefaults standardUserDefaults] setInteger:self.highestTier forKey:@"highestTier"];
            self.hasRanBefore = YES;
            [[NSUserDefaults standardUserDefaults] setBool:self.hasRanBefore forKey:@"hasRanBefore"];
            self.localLevelCount = 200;
            //Steps for adding a new level.
            //1. Increase self.localLevelCount value by 1
            //2. Add implementation for initializeController:
            //3. Delete old version of app on test device
            //4. To Test: change view controller passed value
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSDate *date = [NSDate date];
                for (int k = 1;k<=self.localLevelCount;k++){
                    IEBounceLevelController *controller = [IEBounceLevelController controllerWithLevelNumber:k];
                    [self initializeController:controller];
                }
                float timeElapsed = [date timeIntervalSinceNow];
                NSLog(@"Level Loading Completed in: %f seconds", timeElapsed);
            });
        }
        else{
            self.localLevelCount = [IEBounceLevelController controllerCount];
            self.highestUnlock = [[NSUserDefaults standardUserDefaults] integerForKey:@"highestUnlock"];
            self.highestTier = [[NSUserDefaults standardUserDefaults] integerForKey:@"highestTier"];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.isLoaded = YES;
    }
    return self;
}
-(void)completedLevel:(NSUInteger)level withStars:(NSUInteger)stars{
    if (level>self.highestUnlock)
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"completedLevel: Argument %i has not been unlocked but completed method is being called. Highest Unlock %i", (int)level, (int)self.highestUnlock] userInfo:nil];
    else if (stars>3)
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"completedLevel: Argument %i must between 0 and 3", (int)stars] userInfo:nil];
    else if ([self starsForLevel:level]==0)
        [self advanceLevel];
    
    AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ProgressData" inManagedObjectContext:delegate.managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    [request setPredicate:[NSPredicate predicateWithFormat:@"(levelNumber = %i)", level]];
    NSError *error;
    NSArray *objects = [delegate.managedObjectContext executeFetchRequest:request error:&error];
    if (objects.count == 0){
        NSManagedObject *object = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:delegate.managedObjectContext];
        [object setValue:[NSNumber numberWithUnsignedInteger:stars] forKey:@"stars"];
        [object setValue:[NSNumber numberWithUnsignedInteger:level] forKey:@"levelNumber"];
        NSError *error2;
        [delegate.managedObjectContext save:&error2];
    }
    else if (objects.count == 1){
        NSManagedObject *object = objects[0];
        NSNumber *number = [object valueForKey:@"stars"];
        if (number.unsignedIntegerValue<stars){
            [object setValue:[NSNumber numberWithUnsignedInteger:stars] forKey:@"stars"];
            NSError *error2;
            [delegate.managedObjectContext save:&error2];
        }
    }
    else
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Multiple copies of data with the same level number for level %i. One copy must be deleded from core data", (int)level] userInfo:nil];
}
-(void)advanceLevel{
    self.highestUnlock++;
    if (self.highestUnlock>LEVEL_PER_TIER*self.highestTier){
        self.highestUnlock = LEVEL_PER_TIER*self.highestTier+10;
        self.highestTier++;
        [[NSUserDefaults standardUserDefaults] setInteger:self.highestTier forKey:@"highestTier"];
    }
    [[NSUserDefaults standardUserDefaults] setInteger:self.highestUnlock forKey:@"highestUnlock"];
}
-(NSUInteger)starsForLevel:(NSUInteger)level{
    if (level == 0)
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"No such level as Level: 0" userInfo:nil];
    else if (level>=self.highestUnlock)
        return 0;
    else{
        AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        NSManagedObjectContext *context = delegate.managedObjectContext;
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"ProgressData" inManagedObjectContext:context];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entity];
        [request setPredicate:[NSPredicate predicateWithFormat:@"(levelNumber = %i)", level]];
        NSError *error;
        NSArray *array = [context executeFetchRequest:request error:&error];
        if (array.count == 0)
            return 0;
        else if (array.count == 1){
            NSManagedObject *object = array[0];
            NSNumber *number = [object valueForKey:@"stars"];
            return number.unsignedIntegerValue;
        }
        else
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Multiple copies of data with the same level number for level %i. One copy must be deleded from core data", (int)level] userInfo:nil];
    }
}
-(NSUInteger)starCount{
    NSUInteger sum = 0;
    for (int k = 1;k<=self.localLevelCount;k++){
        sum+=[self starsForLevel:k];
    }
    return sum;
}
-(void)initializeController:(IEBounceLevelController*)controller{
    if (controller.levelNumber == 1){
        //Ball on Top Hole on Right
        controller.levelName = @"Getting Started pt 1";
        controller.ballAngle = M_PI+M_PI_4;
        controller.ballLocation = IEObjectLayoutTopRight;
        controller.holeLayout = IEObjectLayoutMiddleRight;
        controller.starQuantitys = IEStarQuantityCreate(3, 2, 1);
        
    }
    else if (controller.levelNumber == 2){
        //Different Locations
        controller.levelName = @"Getting Started pt 2";
        controller.ballAngle = M_PI*3/2;
        controller.ballLocation = IEObjectLayoutTop;
        controller.holeLayout = IEObjectLayoutRight;
        controller.starQuantitys = IEStarQuantityCreate(3, 2, 1);
    }
    else if (controller.levelNumber == 3){
        //Different Locations
        controller.levelName = @"A Little Harder";
        controller.ballAngle = M_PI+M_PI_4;
        controller.ballLocation = IEObjectLayoutTopRight;
        controller.holeLayout = IEObjectLayoutRight;
        controller.starQuantitys = IEStarQuantityCreate(3, 2, 1);
    }
    else if (controller.levelNumber == 4){
        // Ball facing away from ball
        controller.levelName = @"Boomerang";
        controller.ballAngle = 0;
        controller.ballLocation = IEObjectLayoutLeft;
        controller.holeLayout = IEObjectLayoutBottomLeft;
        controller.starQuantitys = IEStarQuantityCreate(3, 2, 1);
    }
    else if (controller.levelNumber == 5){
        // Same but different directions
        controller.levelName = @"Back Track";
        controller.ballAngle = M_PI_2+M_PI_4/2;
        controller.ballLocation = IEObjectLayoutDiagonalBottomRight;
        controller.holeLayout = IEObjectLayoutBottomRight;
        controller.starQuantitys = IEStarQuantityCreate(4, 2, 1);
    }
    else if (controller.levelNumber == 6){
        // Block in the middle
        controller.levelName = @"Around the Block";
        controller.ballAngle = M_PI_2;
        controller.ballLocation = IEObjectLayoutBottom;
        controller.holeLayout = IEObjectLayoutTop;
        controller.starQuantitys = IEStarQuantityCreate(6, 4, 2);
        IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.5) shapeName:IEShapeNameSquare textureName:IETextureTypeSolid];
        [controller addPair:pair];
    }
    else if (controller.levelNumber == 7){
        // Dead zone in middle
        controller.levelName = @"Dead Zone";
        controller.ballAngle = -M_PI/10;
        controller.ballLocation = IEObjectLayoutLeft;
        controller.holeLayout = IEObjectLayoutTop;
        IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.5) shapeName:IEShapeNameRectangleLongest textureName:IETextureTypeNoClick];
        pair.scale = 2;
        [controller addPair:pair];
        controller.starQuantitys = IEStarQuantityCreate(3, 2, 1);
    }
    else if (controller.levelNumber == 8){
        // Wall in middle bottom of level
        controller.levelName = @"Great Wall";
        controller.ballAngle = M_PI*3/2;
        controller.ballLocation = IEObjectLayoutDiagonalBottomleft;
        controller.holeLayout = IEObjectLayoutMiddleRight;
        IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.37) shapeName:IEShapeNameRectangleLongest textureName:IETextureTypeSolid];
        IEObjectPointPair *pair2 = [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.2) shapeName:IEShapeNameRectangleLongest textureName:IETextureTypeSolid];
        pair2.rotation = M_PI_2;
        pair.rotation = M_PI_2;
        [controller addPairs:@[pair, pair2]];
        controller.starQuantitys = IEStarQuantityCreate(6, 3, 2);
        
    }
    else if (controller.levelNumber == 9){
        // 4 circles around hole
        controller.levelName = @"5 Dice";
        controller.ballAngle = M_PI_2+M_PI_4*2/3;
        controller.ballLocation = IEObjectLayoutBottomRight;
        controller.holeLayout = IEObjectLayoutMiddle;
        NSMutableArray *objects = [NSMutableArray array];
        for (int k = 0;k<4;k++){
            IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointZero shapeName:IEShapeNameCircle textureName:IETextureTypeSolid];
            pair.scale = 0.75;
            if (k == 0)
                pair.shiftPoint = CGPointMake(0.3, 0.3);
            else if (k == 1)
                pair.shiftPoint = CGPointMake(0.3, 0.7);
            else if (k == 2)
                pair.shiftPoint = CGPointMake(0.7, 0.7);
            else
                pair.shiftPoint = CGPointMake(0.7, 0.3);
            [objects addObject:pair];
        }
        [controller addPairs:objects];
        controller.starQuantitys = IEStarQuantityCreate(4, 3, 2);
    }
    else if (controller.levelNumber == 10){
        //Dead zone covering majority of middle
        controller.levelName = @"Canyon";
        controller.ballAngle = M_PI;
        controller.ballLocation = IEObjectLayoutBottomLeft;
        controller.holeLayout = IEObjectLayoutTopRight;
        IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.5) shapeName:IEShapeNameRectangleLongest textureName:IETextureTypeNoClick];
        pair.rotation = M_PI_2;
        pair.scale = 5;
        [controller addPair:pair];
        controller.starQuantitys = IEStarQuantityCreate(7, 4, 2);
    }
    else if (controller.levelNumber == 11){
        // Dimaond in middle, ball must travel around
        controller.levelName = @"Round the Bases";
        controller.ballAngle = M_PI*3/2;
        controller.ballLocation = IEObjectLayoutBottomLeftMiddle;
        controller.holeLayout = IEObjectLayoutDiagonalTopLeft;
        IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointMake(0.3, 0.5) shapeName:IEShapeNameSquare textureName:IETextureTypeSolid];
        pair.scale = 3;
        pair.rotation = M_PI_4;
        [controller addPair:pair];
        controller.starQuantitys = IEStarQuantityCreate(6, 4, 3);
    }
    else if (controller.levelNumber == 12){
        //Two rectangles that create a doorway offset from the path of the ball
        controller.levelName = @"Doorway";
        controller.ballAngle = M_PI_2*3;
        controller.ballLocation = IEObjectLayoutDiagonalTopLeft;
        controller.holeLayout = IEObjectLayoutDiagonalBottomleft;
        IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointMake(1.1, 0.5) shapeName:IEShapeNameRectangleLongest textureName:IETextureTypeSolid];
        pair.scale = 0.6;
        IEObjectPointPair *pair2 = [IEObjectPointPair pairWithShift:CGPointMake(0.25, 0.5) shapeName:IEShapeNameRectangleLongest textureName:IETextureTypeSolid];
        pair2.scale = 0.6;
        [controller addPairs:@[pair, pair2]];
        controller.starQuantitys = IEStarQuantityCreate(5, 3, 2);
    }
    else if (controller.levelNumber == 13){
        controller.levelName = @"Doorway pt 2";
        controller.ballAngle = M_PI_2*3; 
        controller.ballLocation = IEObjectLayoutTopRight;
        controller.holeLayout = IEObjectLayoutDiagonalBottomleft;
        NSMutableArray *array = [NSMutableArray array];
        for (int k = 0;k<4;k++){
            IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointZero shapeName:IEShapeNameRectangleLongest textureName:IETextureTypeSolid];
            pair.scale = 0.6;
            if (k == 0)
                pair.shiftPoint = CGPointMake(1.1, 0.32);
            else if (k == 1)
                pair.shiftPoint = CGPointMake(0.25, 0.32);
            else if (k == 2)
                pair.shiftPoint = CGPointMake(-0.1, 0.7);
            else
                pair.shiftPoint = CGPointMake(0.75, 0.7);
            [array addObject: pair];
        }
        [controller addPairs:array];
        controller.starQuantitys = IEStarQuantityCreate(9, 7, 6);
    }
    else if (controller.levelNumber == 14){
        //Dead zone surrounding hole. Must deflect off of corners
        controller.levelName = @"Bubble";
        controller.ballAngle = M_PI*3/2;
        controller.ballLocation = IEObjectLayoutTopRight;
        controller.holeLayout = IEObjectLayoutMiddle;
        IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.5) shapeName:IEShapeNameCircle textureName:IETextureTypeNoClick];
        pair.scale = 8.5;
        IEObjectPointPair *corner = [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.38) shapeName:IEShapeNameCornerThin textureName:IETextureTypeSolid];
        corner.scale = 2;
        corner.rotation = M_PI_4;
        [controller addPairs:@[pair, corner]];
        NSMutableArray *array = [NSMutableArray array];
        for (int i = 0;i<=1;i++){
            for (int k = 0;k<=1;k++){
                CGPoint shiftPoint = CGPointMake(i, k);
                IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:shiftPoint shapeName:IEShapeNameCircle textureName:IETextureTypeNoClick];
                pair.scale = 3;
                [array addObject:pair];
            }
        }
        [controller addPairs:array];
        controller.starQuantitys = IEStarQuantityCreate(5, 4, 3);
    }
    else if (controller.levelNumber == 15){
        controller.levelName = @"Shoty Architecture";
        controller.ballAngle = M_PI*3/2;
        controller.ballLocation = IEObjectLayoutTop;
        controller.holeLayout = IEObjectLayoutBottomRight;
        NSMutableArray *array = [NSMutableArray array];
        for (int k = 0;k<3;k++){
            IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointZero shapeName:IEShapeNameRectangleThin textureName:IETextureTypeSolid];
            if (k == 0){
                pair.shiftPoint = CGPointMake(0, 0.25);
                pair.rotation = M_PI/8;
            }
            else if (k == 1){
                pair.shiftPoint = CGPointMake(1.2, 0.10);
                pair.rotation = -M_PI/8;
            }
            else{
                pair.shiftPoint = CGPointMake(0, 0.75);
                pair.rotation = -M_PI/16;
            }
            [array addObject:pair];
        }
        [controller addPairs:array];
        controller.starQuantitys = IEStarQuantityCreate(8, 6, 4);
    }
    else if (controller.levelNumber == 16){
        controller.levelName = @"Shoty Architecture Pt 2";
        controller.ballAngle = M_PI_2-M_PI/12;
        controller.ballLocation = IEObjectLayoutBottomLeft;
        controller.holeLayout = IEObjectLayoutTopRight;
        NSMutableArray *array = [NSMutableArray array];
        
        for (int k = 0;k<3;k++){
            IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointZero shapeName:IEShapeNameRectangleThin textureName:IETextureTypeSolid];
            pair.scale = 0.6;
            if (k == 0){
                pair.shiftPoint = CGPointMake(0.081, 0.197);
                pair.rotation = 5.934;
            }
            else if (k == 1){
                pair.shiftPoint = CGPointMake(0.597, 0.84);
                pair.rotation = 1.83;
            }
            else{
                pair.shiftPoint = CGPointMake(0.80, 0.36);
                pair.rotation = 2.97;
            }
            [array addObject:pair];
        }
        [controller addPairs:array];
        controller.starQuantitys = IEStarQuantityCreate(15, 9, 6);
    }
    else if (controller.levelNumber == 17){
        controller.levelName = @"Lava lamp";
        controller.ballAngle = M_PI+M_PI/12;
        controller.ballLocation = IEObjectLayoutTop;
        controller.holeLayout = IEObjectLayoutBottom;
        NSMutableArray *array = [NSMutableArray array];
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0,0.65),(0,1),(0.30,1)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(1,0.65),(1,1),(0.7,1)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(0,0),(0,0.35),(0.3,0)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(1,0),(1,0.35),(0.7,0)" texture:IETextureTypeSolid]]];
        
        for (int k = 0;k<5;k++){
            IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointZero shapeName:IEShapeNameCircle textureName:IETextureTypeSolid];
            if (k == 0)
                pair.shiftPoint = CGPointMake(0.334, 0.252);
            else if (k == 1)
                pair.shiftPoint = CGPointMake(0.652, 0.34);
            else if (k == 2)
                pair.shiftPoint = CGPointMake(0.24, 0.6);
            else if (k == 3){
                pair.shiftPoint = CGPointMake(0.8, 0.48);
                pair.scale = 0.25;
            }
            else{
                pair.scale = 0.5;
                pair.shiftPoint = CGPointMake(0.5, 0.8);
            }
            [array addObject:pair];
        }
        [controller addPairs:array];
    }
    else if (controller.levelNumber == 18){
        controller.levelName = @"Shrodingers Level";
        controller.ballAngle = M_PI*3/2;
        controller.ballLocation = IEObjectLayoutTop;
        controller.holeLayout = IEObjectLayoutMiddle;
        IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.5) shapeName:IEShapeNameSquareBoxOpen textureName:IETextureTypeSolid];
        pair.scale = 2;
        [controller addPair:pair];
        controller.starQuantitys = IEStarQuantityCreate(5, 4, 3);
    }
    else if (controller.levelNumber == 19){
        controller.levelName = @"The Great Divide";
        controller.ballLocation = IEObjectLayoutTop;
        controller.holeLayout = IEObjectLayoutBottom;
        controller.ballAngle = M_PI*3/2;
        
        IEObjectPointPair *rectangle = [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.44) shapeName:IEShapeNameRectangleLongest textureName:IETextureTypeSolid];
        IEObjectPointPair *square1 = [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.525) shapeName:IEShapeNameSquare textureName:IETextureTypeInstaDeath];
        IEObjectPointPair *square2 = [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.3576) shapeName:IEShapeNameSquare textureName:IETextureTypeInstaDeath];
        NSArray *array = @[rectangle, square1, square2];
        for (IEObjectPointPair *pair in array)
            pair.scale = 0.6;
        
        [controller addPairs:array];
    }
    else if (controller.levelNumber == 20){
        
        controller.levelName = @"Corridor";
        controller.ballLocation = IEObjectLayoutCustom;
        controller.holeLayout = IEObjectLayoutTopLeft;
        controller.ballRadius = 16;
        controller.ballAngle = M_PI_2;
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0.6,0),(0.6,0.4),(0.4,0.4),(0.4,0.6),(0,0.6),(0,0)" texture: IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(0.4,0.4),(0.4,0.6),(0.6,0.6),(0.6,0.4)" texture:IETextureTypeInstaDeath], [IECustomPath pathWithPointsFromString:@"(0.8,0),(0.8,0.6),(1,0.6),(1,0)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(0.4,0.75),(0.4,1),(1,1),(1,0.75)" texture:IETextureTypeInstaDeath]]];
        NSLog(@"Count: %i", (int)controller.customPaths.count);
        AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        [delegate storeShiftPoint:CGPointMake(0.7, 0.1) forIntegerKey:controller.levelNumber ball:YES];
        controller.starQuantitys = IEStarQuantityCreate(7, 5, 4);
    }
    else if (controller.levelNumber == 21){
        controller.levelName = @"Three Walls";
        controller.ballAngle = M_PI_2;
        controller.ballLocation = IEObjectLayoutBottomLeft;
        controller.holeLayout = IEObjectLayoutTopRight;
        for (int k = 0;k<3;k++){
            IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointZero shapeName:IEShapeNameRectangleThin textureName:IETextureTypeSolid];
            pair.rotation = M_PI_2;
            if (k == 0)
                pair.shiftPoint = CGPointMake(0.3, 0.3);
            else if (k == 1)
                pair.shiftPoint = CGPointMake(0.6, 0.7);
            else
                pair.shiftPoint = CGPointMake(0.9, 0.3);
            [controller addPair:pair];
        }
        controller.starQuantitys = IEStarQuantityCreate(5, 4, 2);
    }
    else if (controller.levelNumber == 22){
        controller.levelName = @"Bank Shot";
        controller.holeLayout = IEObjectLayoutTopLeftMiddle;
        controller.ballLocation = IEObjectLayoutBottomRight;
        controller.ballAngle = M_PI;
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0,0.46),(0,0.54),(0.3,0.54),(0.3,0.46)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(0,0.07),(0.35,0.07),(0.35,0),(1,0),(1,1),(0,1)" texture:IETextureTypeNoClick]]];
        
        controller.starQuantitys = IEStarQuantityCreate(3, 3, 2);
    }
    else if (controller.levelNumber == 23){
        controller.levelName = @"Single Edge";
        controller.ballAngle = M_PI*3/2;
        controller.holeLayout = IEObjectLayoutCustom;
        controller.ballLocation = IEObjectLayoutTopRight;
        AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        [delegate storeShiftPoint:CGPointMake(0.12, 0.8) forIntegerKey:23 ball:NO];
        
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0,0.18),(0,1),(1,1),(1,0.18)" texture:IETextureTypeNoClick], [IECustomPath pathWithPointsFromString:@"(0.3,0.78),(0.3,1),(0.4,1),(0.4,0.78)" texture:IETextureTypeSolid]]];
        for (int k = 0;k<=1;k++){
            IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointZero shapeName:IEShapeNameTriangleRight textureName:IETextureTypeSolid];
            if (k == 0){
                pair.rotation = M_PI;
                pair.shiftPoint = CGPointMake(0.5, 0.33);
            }
            else
                pair.shiftPoint = CGPointMake(0.123438, 0.33);
            [controller addPair:pair];
        }
        controller.starQuantitys = IEStarQuantityCreate(6, 5, 4);
    }
    else if (controller.levelNumber == 24){
        controller.levelName = @"Ball to Big? Nah";
        controller.ballLocation = IEObjectLayoutBottomRight;
        controller.ballAngle = 11/12*M_PI;
        controller.holeLayout = IEObjectLayoutMiddle;
        
        for (int k = 0;k<6;k++){
            IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointZero shapeName:IEShapeNameCircle textureName:IETextureTypeSolid];
            if (k == 0){
                pair.scale = 0.25;
                pair.shiftPoint = CGPointMake(0.460938, 0.301937);
            }
            else if (k == 1){
                pair.scale = 0.4;
                pair.shiftPoint = CGPointMake(0.315625, 0.360035);
            }
            else if (k == 2){
                pair.scale = 0.75;
                pair.shiftPoint = CGPointMake(0.275, 00.47676);
            }
            else if (k == 3){
                pair.scale = 1.1;
                pair.shiftPoint = CGPointMake(0.432813, 0.619718);
            }
            else if (k == 4){
                pair.scale = 1.5;
                pair.shiftPoint = CGPointMake(0.75, 0.58891);
            }
            else{
                pair.scale = 2;
                pair.shiftPoint = CGPointMake(0.767188, 0.360035);
            }
            if (!(k%2 == 0))
                pair.textureName = IETextureTypeInstaDeath;
            [controller addPair:pair];
        }
    }
    else if (controller.levelNumber == 25){
        controller.levelName = @"Cutting Corners";
        controller.ballLocation = IEObjectLayoutBottomRight;
        controller.holeLayout = IEObjectLayoutMiddle;
        controller.ballAngle = M_PI;
        
        [controller addPath:[IECustomPath pathWithPointsFromString:@"(0.23,0.17),(0.23,0.83),(0.77,0.83),(0.77,0.79),(0.31,0.79),(0.31,0.21),(0.83,0.21),(0.83,0.17)" texture:IETextureTypeSolid]];
        [controller addPath:[IECustomPath pathWithPointsFromString:@"(0.23,0.17),(0.23,0),(1,0),(1,0.5),(0.77,0.5),(0.77,0.83),(0.77,1),(0.23,1),(0.23,0.83),(0,0.83),(0,0.17)" texture:IETextureTypeNoClick]];
    }
    else if (controller.levelNumber == 26){
        controller.levelName = @"Divert or Die";
        controller.ballLocation = IEObjectLayoutBottom;
        controller.holeLayout = IEObjectLayoutTopLeft;
        controller.ballAngle = M_PI_2;
        [controller addPaths:@[/*[IECustomPath pathWithPointsFromString:@"(0.34,0.53),(0,0.53),(0,1),(1,1),(1,0.53),(0.66,0.53),(0.66,0.68),(0.44,0.68)" texture:IETextureTypeNoClick],*/ [IECustomPath pathWithPointsFromString:@"(0,0.53),(1,0.53),(1,0),(0,0)" texture:IETextureTypeNoClick]]];
        for (int k = 0;k<=1;k++){
            IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointZero shapeName:IEShapeNameSquare textureName:IETextureTypeSolid];
            pair.scale = 5;
            if (k == 0)
                pair.shiftPoint = CGPointMake(0, 0.216549);
            else
                pair.shiftPoint = CGPointMake(1, 0.216549);
            [controller addPair:pair];
        }
        for (int k = 0;k<4;k++){
            IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointZero shapeName:IEShapeNameCircle textureName:IETextureTypeInstaDeath];
            if (k == 0){
                pair.shiftPoint = CGPointMake(1.010938, 0.655810);
                pair.scale = 5;
            }
            else if (k == 1){
                pair.shiftPoint = CGPointMake(0.098438, 0.698944);
                pair.scale = 1;
            }
            else if (k == 2){
                pair.shiftPoint = CGPointMake(0.553125, 0.815141);
                pair.scale = 1;
            }
            else{
                pair.shiftPoint = CGPointMake(0.098438, 0.56740);
                pair.scale = 1;
            }
            [controller addPair:pair];
        }
        controller.starQuantitys = IEStarQuantityCreate(2, 1, 1);
    }
    else if (controller.levelNumber == 27){
        controller.levelName = @"Zig Zags";
        controller.ballLocation = IEObjectLayoutBottomLeft;
        controller.holeLayout = IEObjectLayoutTopRightMiddle;
        controller.ballAngle = M_PI/10;
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0,0.175), (0,0.325), (0.26,0.325),(0.26,0.175)" texture:IETextureTypeInstaDeath], [IECustomPath pathWithPointsFromString:@"(1,0.425), (0.74,0.425), (0.74,0.575),(1,0.575)" texture:IETextureTypeInstaDeath], [IECustomPath pathWithPointsFromString:@"(0,0.675),(0,0.825),(0.26,0.825),(0.26,0.675)" texture:IETextureTypeInstaDeath]]];
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0.26,0.325),(0.26,0.175),(0.5,0.25)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(0.74,0.425),(0.74,0.575),(0.5,0.5)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(0.26,0.825),(0.26,0.675),(0.5,0.75)" texture:IETextureTypeSolid]]];
        controller.starQuantitys = IEStarQuantityCreate(5, 3, 2);
    }
    else if (controller.levelNumber == 28){
        controller.levelName = @"Tunnel of Death";
        controller.ballLocation = IEObjectLayoutLeft;
        controller.holeLayout = IEObjectLayoutRight; 
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0,0.6),(0.4,0.5),(0.4,1),(0,1)" texture:IETextureTypeInstaDeath], [IECustomPath pathWithPointsFromString:@"(0,0.4),(0.4,0.3),(0.4,0),(0,0)" texture:IETextureTypeInstaDeath], [IECustomPath pathWithPointsFromString:@"(0.7,0.5),(1,0.6),(1,1),(0.7,1)" texture:IETextureTypeInstaDeath], [IECustomPath pathWithPointsFromString:@"(0.7,0.3),(1,0.4),(1,0),(0.7,0)" texture:IETextureTypeInstaDeath]]];
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0.4,0.5),(0.7,0.5),(0.7,1),(0.4,1)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(0.4,0.3),(0.7,0.3),(0.7,0),(0.4,0)" texture:IETextureTypeSolid]]];
        controller.starQuantitys = IEStarQuantityCreate(4, 3, 2);
    }
    else if (controller.levelNumber == 29){
        controller.levelName = @"Bubbles";
        controller.ballLocation = IEObjectLayoutBottomLeft;
        controller.ballAngle = M_PI_2-M_PI_4;
        controller.holeLayout = IEObjectLayoutTop;
        
        for (int k = 0;k<8;k++){
            IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointZero shapeName:IEShapeNameCircle textureName:IETextureTypeSolid];
            if (k==0){
                pair.shiftPoint = CGPointMake(0.212500, 0.211268);
                pair.scale = 0.5;
            }
            else if (k == 1){
                pair.shiftPoint = CGPointMake(0.626563, 0.310739);
                pair.scale = 0.5;
            }
            else if (k == 2){
                pair.shiftPoint = CGPointMake(0.139063, 0.316021);
                pair.scale = 0.75;
            }
            else if (k == 3){
                pair.shiftPoint = CGPointMake(0.54313, 0.398768);
                pair.scale = 0.75;
            }
            else if (k == 4){
                pair.shiftPoint = CGPointMake(0.610938, 0.522007);
                pair.scale = 1;
            }
            else if (k == 5){
                pair.shiftPoint = CGPointMake(0.115625, 0.443662);
                pair.scale = 1;
            }
            else if (k == 6){
                pair.shiftPoint = CGPointMake(0.779688, 0.648768);
                pair.scale = 1.25;
            }
            else{
                pair.shiftPoint = CGPointMake(0.184375, 0.593310);
                pair.scale = 1.25;
            }
            [controller addPair:pair];
        }
        for (int k = 0;k<2;k++){
            IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointZero shapeName:IEShapeNameCircle textureName:IETextureTypeInstaDeath];
            pair.scale = 1.75;
            if (k == 0)
                pair.shiftPoint = CGPointMake(0.309375, 0.757923);
            else
                pair.shiftPoint = CGPointMake(0.971875, 0.759683);
            [controller addPair:pair];
        }
        controller.starQuantitys = IEStarQuantityCreate(5, 4, 3);
    }
    else if (controller.levelNumber == 30){
        controller.levelName = @"Bubbles pt 2";
        controller.ballLocation = IEObjectLayoutBottomLeft;
        controller.ballAngle = M_PI_4;
        controller.holeLayout = IEObjectLayoutTop;
        for (int k = 0;k<4;k++){
            IEObjectPointPair *pair;
            if (k<2){
                pair = [IEObjectPointPair pairWithShift:CGPointZero shapeName:IEShapeNameCircle textureName:IETextureTypeSolid];
                if (k == 0)
                    pair.shiftPoint = CGPointMake(0.785938, 0.113556);
                else
                    pair.shiftPoint = CGPointMake(0.65, 0.607394);
            }
            else{
                pair = [IEObjectPointPair pairWithShift:CGPointZero shapeName:IEShapeNameCircle textureName:IETextureTypeInstaDeath];
                if (k == 2)
                    pair.shiftPoint = CGPointMake(0.110938, 0.305458);
                else
                    pair.shiftPoint = CGPointMake(-0.018750, 0.856514);
            }
            pair.scale = 3;
            [controller addPair:pair];
        }
        controller.starQuantitys = IEStarQuantityCreate(5, 4, 3);
    }
    else if (controller.levelNumber == 31){
        controller.levelName = @"Tight Fit";
        controller.ballLocation = IEObjectLayoutBottomRight;
        controller.holeLayout = IEObjectLayoutLeft;
        controller.ballRadius = controller.ballRadius*2.5;
        controller.ballAngle = M_PI_2;
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0.45,0),(0.55,0),(0.55,0.4),(0.45,0.4)" texture:IETextureTypeInstaDeath], [IECustomPath pathWithPointsFromString:@"(0.45,1),(0.55,1),(0.55,0.6),(0.45,0.6)" texture:IETextureTypeInstaDeath]]];
        controller.starQuantitys = IEStarQuantityCreate(2, 2, 1);
    }
    else if (controller.levelNumber == 32){
        controller.levelName = @"Concave";
        controller.ballLocation = IEObjectLayoutTop;
        controller.holeLayout = IEObjectLayoutMiddleBottom;
        controller.ballAngle = M_PI*3/2;
        IEObjectPointPair *square = [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.334) shapeName:IEShapeNameSquare textureName:IETextureTypeInstaDeath];
        IEObjectPointPair *arc = [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.163) shapeName:IEShapeNameArcHalf textureName:IETextureTypeSolid];
        arc.scale = 2;
        arc.rotation = M_PI;
        [controller addPairs:@[square, arc]];
        controller.starQuantitys = IEStarQuantityCreate(4, 3, 2);
    }
    else if (controller.levelNumber == 33){
        controller.levelName = @"Concave Pt 2";
        controller.ballLocation = IEObjectLayoutBottom;
        controller.holeLayout = IEObjectLayoutMiddleTop;
        controller.ballAngle = M_PI_2;
        
        IEObjectPointPair *bigArc = [IEObjectPointPair pairWithShift:CGPointMake(0.50, 0.804578) shapeName:IEShapeNameArcHalf textureName:IETextureTypeSolid];
        bigArc.scale = 1.5;
        IEObjectPointPair *littleArc = [IEObjectPointPair pairWithShift:CGPointMake(0.50, 0.435) shapeName:IEShapeNameArcHalf textureName:IETextureTypeInstaDeath];
        littleArc.rotation = M_PI;
        littleArc.scale = 0.8;
        for (int k = 0;k<2;k++){
            IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointZero shapeName:IEShapeNameArcThird textureName:IETextureTypeSolid];
            if (k == 0){
                pair.shiftPoint = CGPointMake(0.10, 0.21);
                pair.rotation = M_PI-M_PI_4;
            }
            else{
                pair.shiftPoint = CGPointMake(0.90, 0.21);
                pair.rotation = M_PI+M_PI_4;
            }
            [controller addPair:pair];
        }
        [controller addPairs:@[bigArc, littleArc]];
    }
    else if (controller.levelNumber == 34){
        controller.levelName = @"Zipper";
        controller.ballLocation = IEObjectLayoutBottomLeft;
        controller.holeLayout = IEObjectLayoutTopRight;
        controller.ballAngle = M_PI_2;
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0,1),(0,0.9),(0.25,0.9),(0.25,1)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(0.25,1),(0.25,0.9),(0.5,0.9),(0.5,1)" texture:IETextureTypeInstaDeath], [IECustomPath pathWithPointsFromString:@"(0.5,1),(0.5,0.9),(0.75,0.9),(0.75,1)" texture:IETextureTypeSolid]]];
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0.25,0),(0.5,0),(0.5,0.1),(0.25,0.1)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(0.5,0),(0.75,0),(0.75,0.1),(0.5,0.1)" texture:IETextureTypeInstaDeath], [IECustomPath pathWithPointsFromString:@"(0.75,0),(1,0),(1,0.1),(0.75,0.1)" texture:IETextureTypeSolid]]];
        [controller addPath:[IECustomPath pathWithPointsFromString:@"(0.25,0.1),(0.25,0.9),(0.75,0.9),(0.75,1),(1,1),(1,0.1)" texture:IETextureTypeNoClick]];
        controller.starQuantitys = IEStarQuantityCreate(5, 5, 4);
    }
    else if (controller.levelNumber == 35){
        controller.levelName = @"Straight Shot";
        controller.ballLocation = IEObjectLayoutBottomRightMiddle;
        controller.holeLayout = IEObjectLayoutTop;
        controller.ballAngle = M_PI;
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0,1),(0.38,1),(0.38,0.6),(0,0.6)" texture:IETextureTypeInstaDeath], [IECustomPath pathWithPointsFromString:@"(0.62,1),(1,1),(1,0.6),(0.62,0.6)" texture:IETextureTypeInstaDeath],[IECustomPath pathWithPointsFromString:@"(0,0.5),(1,0.5),(1,0.6),(0.62,0.6),(0.62,1),(0.38,1),(0.38,0.6),(0,0.6)" texture:IETextureTypeNoClick]]];
        controller.starQuantitys = IEStarQuantityCreate(2, 2, 1);
    }
    else if (controller.levelNumber == 36){
        controller.levelName = @"Swirl";
        controller.ballLocation = IEObjectLayoutCustom;
        controller.holeLayout = IEObjectLayoutCustom;
        controller.ballAngle = M_PI*3/2;
        [controller addPath:[IECustomPath pathWithPointsFromString:@"(0, 1),(0.05, 1), (0.05, 0.025), (0.95, 0.025), (0.95, 0.975), (0.35, 0.975), (0.35, 0.225), (0.65, 0.225), (0.65, 0.725), (0.7, 0.725), (0.7, 0.2), (0.3, 0.2), (0.3, 1), (1, 1), (1, 0),(0,0)" texture: IETextureTypeSolid]];
        AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        [delegate storeShiftPoint:CGPointMake(0.5,0.4) forIntegerKey:controller.levelNumber ball:NO];
        [delegate storeShiftPoint:CGPointMake(0.18, 0.9) forIntegerKey:controller.levelNumber ball:YES];
        controller.starQuantitys = IEStarQuantityCreate(6, 5, 4);
    }
    else if (controller.levelNumber == 37){
        controller.levelName = @"Rainbow";
        controller.holeLayout = IEObjectLayoutCustom;
        controller.ballLocation = IEObjectLayoutBottom;
        controller.ballAngle = M_PI_2-M_PI/6;
        IEObjectPointPair *bigArc = [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.83) shapeName:IEShapeNameArcHalf textureName:IETextureTypeSolid];
        bigArc.scale = 2;
        IEObjectPointPair *smallArc = [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.70) shapeName:IEShapeNameArcHalf textureName:IETextureTypeSolid];
        smallArc.scale = 0.8;
        IEObjectPointPair *death = [IEObjectPointPair pairWithShift:CGPointMake(0.86, 0.47) shapeName:IEShapeNameRectangle textureName:IETextureTypeInstaDeath];
        death.rotation = -M_PI_4;
        [controller addPairs:@[bigArc, smallArc, death]];
        AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        [delegate storeShiftPoint:CGPointMake(0.9, 0.6) forIntegerKey:controller.levelNumber ball:NO];
        controller.starQuantitys = IEStarQuantityCreate(7, 5, 3);
    }
    else if (controller.levelNumber == 38){
        controller.levelName = @"Around the Bend";
        controller.holeLayout = IEObjectLayoutLeft;
        controller.ballLocation = IEObjectLayoutMiddleBottom;
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@", (0, 1), (1, 1), (1, 0.8), (0, 0.8)" texture: IETextureTypeNoClick],
                               [IECustomPath pathWithPointsFromString:@", (0, 0.3), (1, 0.3), (1, 0), (0, 0)" texture: IETextureTypeNoClick],
                               [IECustomPath pathWithPointsFromString:@", (0.7, 0), (1, 0.3), (1, 0)" texture: IETextureTypeSolid],
                               [IECustomPath pathWithPointsFromString:@", (0, 0.3), (0, 0.4), (0.4, 0.4), (0.4, 0.7), (0.6, 0.7), (0.6, 0.3)" texture: IETextureTypeInstaDeath]]];
        IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.9744) shapeName:IEShapeNameArcHalf textureName:IETextureTypeSolid];
        pair.scale = 1.5;
        [controller addPair:pair];
        controller.starQuantitys = IEStarQuantityCreate(6, 5, 4);
    }
    else if (controller.levelNumber == 39){
        controller.levelName = @"Macaroni";
        controller.ballLocation = IEObjectLayoutBottomLeft;
        controller.holeLayout = IEObjectLayoutTopLeft;
        controller.ballAngle = M_PI_4;
        for (int k = 0;k<6;k++){
            IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointZero shapeName:IEShapeNameArcQuarter textureName:IETextureTypeSolid];
            if (k == 0){
                pair.rotation = 0;
                pair.shiftPoint = CGPointMake(0.948438, 0.9568);
            }
            else if (k == 1){
                pair.rotation = M_PI;
                pair.shiftPoint = CGPointMake(0.167188, 0.235916);
            }
            else if (k == 2){
                pair.rotation = M_PI_2;
                pair.shiftPoint = CGPointMake(0.445313, 0.6346);
            }
            else if (k == 3){
                pair.rotation = M_PI*3/2;
                pair.shiftPoint = CGPointMake(0.882813, 0.389085);
            }
            else if (k == 4){
                pair.rotation = 1.169;
                pair.shiftPoint = CGPointMake(0.1, 0.522);
            }
            else{
                pair.rotation = 1.57;
                pair.shiftPoint = CGPointMake(0.557, 0);
            }
            [controller addPair:pair];
            controller.starQuantitys = IEStarQuantityCreate(6, 5, 4);
        }
    }
    else if (controller.levelNumber == 40){
        controller.levelName = @"Pyramid Scheme";
        controller.ballLocation = IEObjectLayoutLeft;
        controller.ballAngle = M_PI/6;
        controller.holeLayout = IEObjectLayoutBottom;
        for (int k = 0;k<6;k++){
            IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointZero shapeName:IEShapeNameTriangleEquilateral textureName:IETextureTypeSolid];
            if (k == 0)
                pair.shiftPoint = CGPointMake(0.5, 0.70);
            else if (k == 1)
                pair.shiftPoint = CGPointMake(0.68, 0.48);
            else if (k == 2)
                pair.shiftPoint = CGPointMake(0.32, 0.48);
            else if (k == 3)
                pair.shiftPoint = CGPointMake(0.5, 0.22);
            else if (k == 4)
                pair.shiftPoint = CGPointMake(0.86, 0.22);
            else
                pair.shiftPoint = CGPointMake(0.14,0.22);
            [controller addPair:pair];
        }
        for (int k = 0;k<2;k++){
            IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointZero shapeName:IEShapeNameTriangleEquilateral textureName:IETextureTypeInstaDeath];
            if (k == 0)
                pair.shiftPoint = CGPointMake(0.68,0.03);
            else
                pair.shiftPoint = CGPointMake(0.32, 0.03);
            [controller addPair:pair];
        }
        controller.starQuantitys = IEStarQuantityCreate(11, 10, 9);
    }
    else if (controller.levelNumber == 41){
        controller.levelName = @"Aim and Fire";
        controller.holeLayout = IEObjectLayoutBottom;
        IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.7, 0.5)];
        [controller addPowerup:powerup];
        [controller addPath:[IECustomPath pathWithPointsFromString:@"(0,0),(0,1),(1,1),(1,0)" texture:IETextureTypeNoClick]];
        controller.starQuantitys = IEStarQuantityCreate(1, 0, 0);
    }
    else if (controller.levelNumber == 42){
        controller.levelName = @"Shoot and Bounce";
        controller.ballLocation = IEObjectLayoutBottomLeft;
        controller.holeLayout = IEObjectLayoutLeft;
        controller.ballAngle = M_PI/2-M_PI/11;
        [controller addPaths:@[
                              [IECustomPath pathWithPointsFromString:@"(0,0),(1,0),(1,1),(0,1)" texture:IETextureTypeNoClick],
                              [IECustomPath pathWithPointsFromString:@"(0.85,0),(1,0.10),(1,0)" texture:IETextureTypeSolid],
                              [IECustomPath pathWithPointsFromString:@"(0,0.80),(0,1),(0.35,1)" texture:IETextureTypeSolid],
                              [IECustomPath pathWithPointsFromString:@"(0,0.2),(0,0.25),(0.6,0.25),(0.6,0.75),(0.3,0.75),(0.3,0.8),(0.7,0.8),(0.7,0.2)" texture:IETextureTypeSolid]]];
        [controller addPowerups:@[[IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.2, 0.05)], [IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.85, 0.9)]]];
        NSLog(@"powerup count: %i", (int)controller.powerups.count);
        controller.starQuantitys = IEStarQuantityCreate(4, 3, 2);
    }
    else if (controller.levelNumber == 43){
        controller.levelName = @"Ricochet";
        [controller addPowerup:[IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.5, 0.25)]];
        [controller addPair:[IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.5) shapeName:IEShapeNameRectangle textureName:IETextureTypeInstaDeath]];
        controller.ballLocation = IEObjectLayoutBottomLeftMiddle;
        controller.holeLayout = IEObjectLayoutMiddleTop;
        controller.starQuantitys = IEStarQuantityCreate(4,3,3);
    }
    else if (controller.levelNumber == 44){
        controller.levelName = @"Ricochet Pt 2";
        controller.ballLocation = IEObjectLayoutBottomRight;
        controller.holeLayout = IEObjectLayoutMiddleLeft;
        [controller addPowerup: [IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.9, 0.1)]];
        IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointMake(0.3, 0.4) shapeName:IEShapeNameRectangle textureName: IETextureTypeInstaDeath];
        pair.rotation = -M_PI_4;
        [controller addPair:pair];
        [controller addPath:[IECustomPath pathWithPointsFromString:@"(0,0),(0,0.8),(0.2,0.8),(0.2,1),(1,1),(1,0)" texture:IETextureTypeNoClick]];
    }
    else if (controller.levelNumber == 45){
        controller.levelName = @"Shooting with Angles";
        controller.ballLocation = IEObjectLayoutBottomLeft;
        controller.holeLayout = IEObjectLayoutBottomRightMiddle;
        [controller addPaths:@[
                              [IECustomPath pathWithPointsFromString:@", (0.4, 0), (0.45, 0), (0.45, 0.20), (0.4, 0.20)" texture: IETextureTypeInstaDeath],
                              [IECustomPath pathWithPointsFromString:@"(0.4, 0.80), (0.4, 1), (0.35, 1), (0.35, 0.80)" texture: IETextureTypeInstaDeath],
                              [IECustomPath pathWithPointsFromString: @"(1,1),(1,0.97),(0.4,0.97),(0.4,1)" texture:IETextureTypeInstaDeath],
                              [IECustomPath pathWithPointsFromString:@", (0, 0), (0, 0.8), (0.4, 0.8), (0.4, 0.97), (1, 0.97), (1, 0), (0.8, 0), (0.8, 0.2), (0.4, 0.2), (0.4, 0)" texture: IETextureTypeNoClick]
                              ]];
        [controller addPowerup:[IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.2, 0.05)]];
        controller.starQuantitys = IEStarQuantityCreate(2, 2, 1);
    }
    else if (controller.levelNumber == 46){
        controller.levelName = @"Shooting with Angles pt 2";
        controller.ballLocation = IEObjectLayoutBottomLeft;
        controller.holeLayout = IEObjectLayoutTop;
        controller.ballAngle = M_PI_2;
        IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.35) shapeName:IEShapeNameRectangleLong textureName:IETextureTypeSolid];
        pair.rotation = -M_PI_4;
        IEObjectPointPair *pair2 = [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.6) shapeName:IEShapeNameRectangleLong textureName:IETextureTypeSolid];
        pair2.rotation = -M_PI_4;
        pair.scale = 0.8;
        pair2.scale = 0.8;
        [controller addPairs:@[pair, pair2]];
        
        [controller addPowerups:@[[IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.05, 0.1)], [IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.95, 0.5 )]]];
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0,0),(1,0),(1,0.25),(0,0.25)" texture:IETextureTypeNoClick], [IECustomPath pathWithPointsFromString:@"(0,1),(1,1),(1,0.75),(0,0.75)" texture:IETextureTypeNoClick], [IECustomPath pathWithPointsFromString:@"(0.37, 1), (0.43,1),(0.43,0.75),(0.37,0.75)" texture:IETextureTypeInstaDeath]]];
        controller.starQuantitys = IEStarQuantityCreate(5, 4, 3);
    }
    else if (controller.levelNumber == 47){
        controller.levelName = @"Single Key";
        [controller addPowerup:[IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointMake(0.5, 0.05)]];
        controller.starQuantitys = IEStarQuantityCreate(5, 4, 3);
    }
    else if (controller.levelNumber == 48){
        controller.levelName = @"Single Key pt 2";
        controller.ballAngle = M_PI*3/2;
        controller.ballLocation = IEObjectLayoutTop;
        controller.holeLayout = IEObjectLayoutMiddle;
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0.4,0),(0.4,0.15),(0.6,0)" texture:IETextureTypeSolid]]];
        [controller addPowerup:[IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointMake(0.6, 0.12)]];
        controller.starQuantitys = IEStarQuantityCreate(8, 6, 4);
    }
    else if (controller.levelNumber == 49){
        controller.levelName = @"Obstructed";
        controller.ballAngle = M_PI*3/2;
        controller.ballLocation = IEObjectLayoutMiddleLeft;
        controller.holeLayout = IEObjectLayoutMiddle;
        for (int k = 0;k<4;k++){
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointZero];
            if (k == 0)
                powerup.shiftPoint = CGPointMake(0.25, 0.25);
            else if (k == 1)
                powerup.shiftPoint = CGPointMake(0.75, 0.25);
            else if (k == 2)
                powerup.shiftPoint = CGPointMake(0.75, 0.75);
            else
                powerup.shiftPoint = CGPointMake(0.25, 0.75);
            [controller addPowerup:powerup];
        }
    }
    else if (controller.levelNumber == 50){
        controller.levelName = @"Double Double";
        controller.holeLayout = IEObjectLayoutMiddle;
        controller.ballLocation = IEObjectLayoutMiddleLeft;
        controller.ballAngle = M_PI;
        for (int i = 0;i<4;i++){
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointZero];
            if (i == 0)
                powerup.shiftPoint = CGPointMake(0.5, 0.05);
            else if (i == 1)
                powerup.shiftPoint = CGPointMake(0.5, 0.95);
            else if (i == 2)
                powerup = [IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.1, 0.5)];
            else if (i == 3)
                powerup = [IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.9, 0.5)];
            else
                powerup.shiftPoint = CGPointMake(0.9, 0.5);
            [controller addPowerup:powerup];
        }
        controller.starQuantitys = IEStarQuantityCreate(3, 3, 3);
    }
    else if (controller.levelNumber == 51){
        controller.levelName = @"U Turn";
        controller.ballLocation = IEObjectLayoutCustom;
        controller.holeLayout = IEObjectLayoutTopLeftMiddle;
        [controller addPath:[IECustomPath pathWithPointsFromString:@"(0,0.53),(0,0.55),(0.5,0.55),(0.5,0.3),(0.47,0.3),(0.47,0.53)" texture:IETextureTypeSolid]];
        [controller addPowerup:[IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointMake(0.15, 0.45)]];
        [controller addPowerup:[IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.75, 0.75)]];
        AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        [delegate storeShiftPoint:CGPointMake(0.75, 0.6) forIntegerKey:controller.levelNumber ball:YES];
        controller.starQuantitys = IEStarQuantityCreate(10, 9, 8);
    }
    else if (controller.levelNumber == 52){
        controller.levelName = @"Deadly Unlock";
        controller.ballLocation = IEObjectLayoutTop;
        [controller addPowerups:@[[IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointMake(0.5, 0.5)], [IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.5, 0.8)]]];
        [controller addPairs:@[[IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.65) shapeName:IEShapeNameCircle textureName:IETextureTypeInstaDeath], [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.35) shapeName:IEShapeNameCircle textureName:IETextureTypeInstaDeath]]];
        controller.starQuantitys = IEStarQuantityCreate(6, 4, 2);
    }
    else if (controller.levelNumber == 53){
        controller.levelName = @"Fork in the Road";
        controller.holeLayout = IEObjectLayoutDiagonalTopRight;
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0.55,0),(0.45,0),(0.45,0.4),(0.55,0.4)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(0.55,1),(0.45,1),(0.45,0.6),(0.55,0.6)" texture:IETextureTypeSolid]]];
        [controller addPowerup:[IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointMake(0.75, 0.25)]];
        controller.starQuantitys = IEStarQuantityCreate(8, 7, 6);
    }
    else if (controller.levelNumber == 54){
        controller.levelName = @"+";
        controller.ballLocation = IEObjectLayoutBottomLeft;
        controller.holeLayout = IEObjectLayoutBottomRight;
        controller.starQuantitys = IEStarQuantityCreate(8, 7, 6);
        for (int k = 0;k<2;k++){
            IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.5) shapeName:IEShapeNameRectangleLong textureName:IETextureTypeSolid];
            pair.scale = 0.8;
            if (k == 0)
                pair.rotation = M_PI_2;
            [controller addPair:pair];
        }
        for (int k = 0;k<4;k++){
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointZero];
            CGFloat distanceFromCenter = 0.35;
            if (k == 0)
                powerup.shiftPoint = CGPointMake(0.5-distanceFromCenter, 0.5);
            else if (k == 1)
                powerup.shiftPoint = CGPointMake(0.5+distanceFromCenter, 0.5);
            else if (k == 2)
                powerup.shiftPoint = CGPointMake(0.5, 0.5-distanceFromCenter);
            else
                powerup.shiftPoint = CGPointMake(0.5, distanceFromCenter+0.5);
            [controller addPowerup:powerup];
        }
    }
    else if (controller.levelNumber == 55){
        controller.levelName = @"Back Fire";
        controller.ballLocation = IEObjectLayoutBottomLeft;
        controller.holeLayout = IEObjectLayoutTop;
        for (int k = 0;k<2;k++){
            CGFloat distanceFromCenter = 0.2;
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointZero];
            if (k == 0)
                powerup.shiftPoint = CGPointMake(0.5-distanceFromCenter, 0.5);
            else
                powerup.shiftPoint = CGPointMake(0.5+distanceFromCenter, 0.5);
            [controller addPowerup:powerup];
        }
        for (int k = 0;k<2;k++){
            CGFloat distanceFromCenter = 0.1;
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointZero];
            if (k == 0)
                powerup.shiftPoint = CGPointMake(0.5-distanceFromCenter, 0.5);
            else
                powerup.shiftPoint = CGPointMake(0.5+distanceFromCenter, 0.5);
            [controller addPowerup:powerup];
        }
        IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.5) shapeName:IEShapeNameRectangleLong textureName:IETextureTypeSolid];
        pair.rotation = M_PI_2;
        pair.scale = 0.6;
        [controller addPair:pair];
    }
    else if (controller.levelNumber == 56){
        controller.levelName = @"Sniper";
        controller.holeLayout = IEObjectLayoutTopRight;
        controller.ballLocation = IEObjectLayoutBottomLeft;
        controller.ballAngle = M_PI/20;
        controller.starQuantitys = IEStarQuantityCreate(20, 18, 16);
        for (int k = 0;k<2;k++){
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointZero];
            if (k == 0)
                powerup.shiftPoint = CGPointMake(0.5, 0.5);
            else
                powerup.shiftPoint = CGPointMake(0.1, 0.1);
            [controller addPowerup:powerup];
        }
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(1,0.8),(0.807,0.852),(0.842,0.887),(1.132,0.809)" texture:IETextureTypeInstaDeath], [IECustomPath pathWithPointsFromString:@"(0.6,1),(0.706,0.894),(0.741,0.929),(0.635,1.035)" texture:IETextureTypeInstaDeath]]];
    }
    else if (controller.levelNumber == 57){
        controller.levelName = @"Lucky Bounce";
        controller.holeLayout = IEObjectLayoutTop;
        controller.ballLocation = IEObjectLayoutTopLeftMiddle;
        controller.ballAngle = M_PI*3/2;
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0,0.3),(0.8,0.3),(1,0.45),(1,0),(0,0)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(0,0.45),(1,0.45),(1,0),(0,0)" texture:IETextureTypeNoClick]]];
        for (int k = 0;k<4;k++){
            CGPoint shift = CGPointMake(0.1*(k+1), 0.35);
            IEPowerup *powerup;
            if(k == 0)
                powerup = [IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:shift];
            else
                powerup = [IEPowerup powerupWithType:IEPowerupKey shiftPoint:shift];
            [controller addPowerup: powerup];
        }
        controller.starQuantitys = IEStarQuantityCreate(1, 1, 1);
    }
    else if (controller.levelNumber == 58){
        controller.levelName = @"No Edges Allowed";
        controller.holeLayout = IEObjectLayoutMiddle;
        controller.ballLocation = IEObjectLayoutBottom;
        controller.starQuantitys = IEStarQuantityCreate(20, 18, 16);
        controller.ballAngle = M_PI_2;
        [controller addPath:[IECustomPath fullScreenPathWithTexture:IETextureTypeNoClick]];
        for (int k = 0;k<2;k++){
            IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointMake(0.3, 0.5) shapeName:IEShapeNameRectangleThin textureName:IETextureTypeSolid];
            pair.rotation = M_PI_2;
            if (k == 0)
                pair.shiftPoint = CGPointMake(0.7, 0.5);
            [controller addPair:pair];
        }
        CGFloat distanceFromEdge = 0.15;
        for (int k = 0;k<6;k++){
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointZero];
            if (k == 0)
                powerup.shiftPoint = CGPointMake(distanceFromEdge, 0.5);
            else if (k == 1)
                powerup.shiftPoint = CGPointMake(distanceFromEdge, 0.2);
            else if (k == 2)
                powerup.shiftPoint = CGPointMake(distanceFromEdge, 0.8);
            else if (k == 3)
                powerup.shiftPoint = CGPointMake(1-distanceFromEdge, 0.5);
            else if (k == 4)
                powerup.shiftPoint = CGPointMake(1-distanceFromEdge, 0.2);
            else if (k == 5)
                powerup.shiftPoint = CGPointMake(1- distanceFromEdge, 0.8);
            [controller addPowerup:powerup];
        }
        CGFloat distanceFromMiddle = 0.2;
        for (int k = 0;k<2;k++){
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.5, 0.5+distanceFromMiddle)];
            if (k == 0)
                powerup.shiftPoint = CGPointMake(0.5, 0.5-distanceFromMiddle);
            [controller addPowerup:powerup];
        }
    }
    else if (controller.levelNumber == 59){
        controller.levelName = @"Hot Zone";
        controller.holeLayout = IEObjectLayoutMiddleTop;
        controller.ballLocation = IEObjectLayoutMiddleBottom;
        controller.ballAngle = M_PI_2;
        [controller addPaths:@[
                               [IECustomPath pathWithPointsFromString:@"(0.05,0.53),(0.05,0.47),(0.20,0.47),(0.20,0.53)" texture:IETextureTypeInstaDeath],
                               [IECustomPath pathWithPointsFromString:@"(0.95,0.53),(0.95,0.47),(0.80,0.47),(0.80,0.53)" texture:IETextureTypeInstaDeath],
                               [IECustomPath pathWithPointsFromString:@"(0.45,0.97),(0.55,0.97),(0.55,0.85),(0.45,0.85)" texture:IETextureTypeInstaDeath],
                               [IECustomPath pathWithPointsFromString:@"(0.45,0.03),(0.55,0.03),(0.55,0.15),(0.45,0.15)" texture:IETextureTypeInstaDeath]]];
        [controller addPaths:[IECustomPath pathsForScreenEdgeWithYThickness:0.03 texture:IETextureTypeInstaDeath]];
        controller.starQuantitys = IEStarQuantityCreate(10, 8, 4);
        CGFloat keyDistance = 0.2;
        CGFloat aimDistance = 0.1;
        for (int k = 0;k<4;k++){
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointZero];
            if (k == 0)
                powerup.shiftPoint = CGPointMake(aimDistance, aimDistance);
            else if (k == 1)
                powerup.shiftPoint = CGPointMake(aimDistance, 1-aimDistance);
            else if (k == 2)
                powerup.shiftPoint = CGPointMake(1-aimDistance, 1-aimDistance);
            else
                powerup.shiftPoint = CGPointMake(1-aimDistance, aimDistance);
            [controller addPowerup:powerup];
        }
        for(int k = 0;k<4;k++){
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointZero];
            if (k == 0)
                powerup.shiftPoint = CGPointMake(keyDistance, keyDistance);
            else if (k == 1)
                powerup.shiftPoint = CGPointMake(keyDistance, 1-keyDistance);
            else if (k == 2)
                powerup.shiftPoint = CGPointMake(1-keyDistance, 1-keyDistance);
            else
                powerup.shiftPoint = CGPointMake(1-keyDistance, keyDistance);
            [controller addPowerup:powerup];
        }
    }
    else if (controller.levelNumber == 60){
        controller.levelName = @"The Ultimate Bounce Shot";
        controller.ballLocation = IEObjectLayoutDiagonalBottomleft;
        controller.holeLayout = IEObjectLayoutTop;
        controller.starQuantitys = IEStarQuantityCreate(15, 14, 13);
        [controller addPaths:@[
                               [IECustomPath pathWithPointsFromString:@"(0,0),(0,0.15),(0.25,0)" texture:IETextureTypeSolid],//Bottom Right
                               [IECustomPath pathWithPointsFromString:@"(0.25,0),(0.5,0.15),(0.75,0)" texture:IETextureTypeSolid],//Bottom Middle
                               [IECustomPath pathWithPointsFromString:@"(0.75,0),(1,0.15),(1,0)" texture:IETextureTypeSolid],
                               [IECustomPath pathWithPointsFromString:@"(0,0.4),(0.2,0.5),(0,0.6)" texture:IETextureTypeSolid],
                               [IECustomPath pathWithPointsFromString:@"(1,0.5),(0.8,0.60),(1,0.7)" texture:IETextureTypeSolid],
                               [IECustomPath pathWithPointsFromString:@"(0,0.65),(0.2,0.75),(0,0.75)" texture:IETextureTypeSolid],
                               [IECustomPath pathWithPointsFromString:@"(0,0.75),(0.2,0.75),(0,0.85)" texture:IETextureTypeInstaDeath]
                               ]];
        [controller addPowerups:@[
                                  [IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointMake(0.1, 0.25)],
                                  [IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointMake(0.9, 0.25)],
                                  [IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.65, 0.45)],
                                  [IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.65, 0.55)],
                                  [IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointMake(0.9, 0.75)],
                                  [IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.9, 0.9)],
                                  [IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointMake(0.1, 0.9)]
                                  ]];
        
    }
    else if (controller.levelNumber == 61){
        controller.levelName = @"Gravity 101";
        controller.ballLocation = IEObjectLayoutTopLeftMiddle;
        controller.holeLayout = IEObjectLayoutBottom;
        [controller addPath:[IECustomPath fullScreenPathWithTexture:IETextureTypeNoClick]];
        [controller addPowerup:[IEPowerup powerupWithType:IEPowerupGravity shiftPoint:CGPointMake(0.5, 0.75)]];
    }
    else if (controller.levelNumber == 62){
        controller.levelName = @"Free Fall";
        controller.ballLocation = IEObjectLayoutTopLeft;
        controller.holeLayout = IEObjectLayoutBottomRight;
        controller.ballAngle = M_PI*3/2;
        [controller addPowerup:[IEPowerup powerupWithType:IEPowerupGravity shiftPoint:CGPointMake(0.05, 0.9)]];
    }
    else if (controller.levelNumber == 63){
        controller.levelName = @"Keep on Rollin";
        controller.ballLocation = IEObjectLayoutTopLeft;
        controller.holeLayout = IEObjectLayoutTopRight;
        controller.ballAngle = M_PI*3/2;
        [controller addPowerup:[IEPowerup powerupWithType:IEPowerupGravity shiftPoint:CGPointMake(0.05, 0.9)]];
        IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupGravity shiftPoint:CGPointMake(0.05, 0.1)];
        powerup.zRotation = M_PI;
        [controller addPowerup:powerup];
        [controller addPath:[IECustomPath pathWithPointsFromString:@"(0,0),(1,0),(1,0.2)" texture:IETextureTypeSolid]];
    }
    else if (controller.levelNumber == 64){
        controller.levelName = @"Double Fall";
        controller.ballLocation = IEObjectLayoutTop;
        controller.holeLayout = IEObjectLayoutTopLeft;
        for (int k = 0;k<2;k++){
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupGravity shiftPoint:CGPointMake(0.95, 0.95)];
            if (k == 0){
                powerup.shiftPoint = CGPointMake(0.05, 0.05);
                powerup.zRotation = M_PI;
            }
            [controller addPowerup:powerup];
        }
        CGFloat distanceFromEdge = 0.3;
        CGFloat distanceFromMiddle = 0.2;
        for (int k = 0;k<4;k++){
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointZero];
            if (k == 0)
                powerup.shiftPoint = CGPointMake(distanceFromEdge, 0.5-distanceFromMiddle);
            else if (k == 1)
                powerup.shiftPoint = CGPointMake(distanceFromEdge, 0.5+distanceFromMiddle);
            else if (k == 2)
                powerup.shiftPoint = CGPointMake(1-distanceFromEdge, 0.5-distanceFromMiddle);
            else
                powerup.shiftPoint = CGPointMake(1-distanceFromEdge, 0.5+distanceFromMiddle);
            [controller addPowerup:powerup];
        }
        [controller addPath:[IECustomPath pathWithPointsFromString:@"(0,0),(0.03,0),(1,0.03),(1,0)" texture:IETextureTypeInstaDeath]];
    }
    else if (controller.levelNumber == 65){
        controller.levelName = @"Aqueduct";
        controller.ballLocation = IEObjectLayoutTop;
        controller.holeLayout = IEObjectLayoutTopLeft;
        for (int k = 0;k<2;k++){
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupGravity shiftPoint:CGPointMake(0.95, 0.95)];
            if (k == 0){
                powerup.shiftPoint = CGPointMake(0.05, 0.05);
                powerup.zRotation = M_PI;
            }
            [controller addPowerup:powerup];
        }
        CGFloat distanceFromEdge = 0.3;
        CGFloat distanceFromMiddle = 0.2;
        for (int k = 0;k<6;k++){
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointZero];
            if (k == 0)
                powerup.shiftPoint = CGPointMake(distanceFromEdge, 0.5-distanceFromMiddle);
            else if (k == 1)
                powerup.shiftPoint = CGPointMake(distanceFromEdge, 0.5+distanceFromMiddle);
            else if (k == 2)
                powerup.shiftPoint = CGPointMake(1-distanceFromEdge, 0.5-distanceFromMiddle);
            else if (k == 3)
                powerup.shiftPoint = CGPointMake(1-distanceFromEdge, 0.5+distanceFromMiddle);
            else if (k == 4)
                powerup.shiftPoint = CGPointMake(0.05, 0.5);
            else
                powerup.shiftPoint = CGPointMake(0.95, 0.5);
            [controller addPowerup:powerup];
        }
    }
    else if (controller.levelNumber == 66){
        controller.levelName = @"Orbit";
        controller.ballLocation = IEObjectLayoutMiddleBottom;
        controller.holeLayout = IEObjectLayoutMiddle;
        for (int k = 0;k<4;k++){
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointMake(0.25, 0.25)];
            if (k == 0)
                powerup.shiftPoint = CGPointMake(0.25, 0.75);
            else if (k == 1)
                powerup.shiftPoint = CGPointMake(0.75, 0.75);
            else if (k == 2)
                powerup.shiftPoint = CGPointMake(0.75, 0.25);
            [controller addPowerup:powerup];
        }
        for (int k = 0;k<4;k++){
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupGravity shiftPoint:CGPointZero];
            if (k == 0){
                powerup.shiftPoint = CGPointMake(0.5, 0.03);
                powerup.zRotation = M_PI;
            }
            else if (k == 1){
                powerup.shiftPoint = CGPointMake(0.5, 0.97);
                powerup.zRotation = -M_PI_2;
            }
            else if (k == 2)
                powerup.shiftPoint = CGPointMake(0.05, 0.5);
            else{
                powerup.shiftPoint = CGPointMake(0.95, 0.5);
                powerup.zRotation = M_PI;
            }
            [controller addPowerup:powerup];
        }
    }
    else if (controller.levelNumber == 67){
        controller.levelName = @"Halfpipe";
        controller.holeLayout = IEObjectLayoutTopRightMiddle;
        controller.ballLocation = IEObjectLayoutMiddleBottom;
        controller.ballAngle = M_PI_2;
        [controller addPowerup:[IEPowerup powerupWithType:IEPowerupGravity shiftPoint:CGPointMake(0.05, 0.95)]];
        IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupGravity shiftPoint:CGPointMake(0.5, 0.1)];
        powerup.zRotation = M_PI;
        [controller addPowerup:powerup];
        [controller addPath:[IECustomPath pathWithPointsFromString:@"(0.75,0.4),(0.75,1),(0.8,1),(0.8,0.4)" texture:IETextureTypeInstaDeath]];
        IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.15) shapeName:IEShapeNameArcHalf textureName:IETextureTypeSolid];
        pair.scale = 1.75;
        pair.rotation = M_PI;
        [controller addPair:pair];
    }
    else if (controller.levelNumber == 68){
        controller.levelName = @"Funnel";
        controller.ballLocation = IEObjectLayoutBottomLeft;
        controller.holeLayout = IEObjectLayoutTop;
        controller.starQuantitys = IEStarQuantityCreate(5, 4, 4);
        [controller addPath:[IECustomPath pathWithPointsFromString:@"(0,0.6),(0.47,0.8),(0.47,1),(0,1)" texture:IETextureTypeSolid]];
        [controller addPath:[IECustomPath pathWithPointsFromString:@"(1,0.6),(0.53,0.8),(0.53,1),(1,1)" texture:IETextureTypeSolid]];
        for (int k = 0;k<3;k++){
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupGravity shiftPoint:CGPointZero];
            powerup.zRotation = M_PI;
            if (k == 0)
                powerup.shiftPoint = CGPointMake(0.5, 0.03);
            else if (k == 1)
                powerup.shiftPoint = CGPointMake(0.05, 0.25);
            else
                powerup.shiftPoint = CGPointMake(0.95, 0.25);
            [controller addPowerup:powerup];
        }
    }
    else if (controller.levelNumber == 69){
        controller.levelName = @"Lob Shot";
        controller.ballLocation = IEObjectLayoutBottomLeftMiddle;
        controller.ballAngle = M_PI_2;
        controller.holeLayout = IEObjectLayoutRight;
        [controller addPowerups:@[[IEPowerup powerupWithType:IEPowerupGravity shiftPoint:CGPointMake(0.05, 0.5)], [IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.05, 0.1)]]];
        [controller addPath:[IECustomPath fullScreenPathWithTexture:IETextureTypeNoClick]];
    }
    else if (controller.levelNumber == 70){
        controller.levelName = @"Cliffhanger";
        controller.ballLocation = IEObjectLayoutBottomLeftMiddle;
        controller.ballAngle = M_PI_2;
        controller.holeLayout = IEObjectLayoutCustom;
        [controller addPowerups:@[[IEPowerup powerupWithType:IEPowerupGravity shiftPoint:CGPointMake(0.05, 0.5)], [IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.05, 0.1)]]];
        [controller addPath:[IECustomPath pathWithPointsFromString:@"(0,0),(0,1),(0.3,1),(0.3,0)" texture:IETextureTypeNoClick]];
        AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        [delegate storeShiftPoint:CGPointMake(0.95, 0.625) forIntegerKey:controller.levelNumber ball:NO];
    }
    else if (controller.levelNumber == 71){
        controller.levelName = @"Projectile Motion";
        controller.ballLocation = IEObjectLayoutBottomRight;
        controller.ballAngle = M_PI;
        controller.holeLayout = IEObjectLayoutTopLeftMiddle;
        for (int k = 0;k<2;k++){
            IEObjectPointPair *pair = [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.25) shapeName:IEShapeNameSquare textureName:IETextureTypeInstaDeath];
            if (k == 1)
                pair.shiftPoint = CGPointMake(0.5, 0.75);
            [controller addPair:pair];
        }
        [controller addPowerups:@[[IEPowerup powerupWithType:IEPowerupGravity shiftPoint:CGPointMake(0.1, 0.03)], [IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.02, 0.03)], [IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.95, 0.5)]]];
        [controller addPath:[IECustomPath pathWithPointsFromString:@"(0,0),(0,0.1),(0.5,0.1),(0.5,1),(1,1),(1,0)" texture:IETextureTypeNoClick]];
    }
    else if (controller.levelNumber == 72){
        controller.levelName = @"Waterfall";
        controller.ballLocation = IEObjectLayoutTopLeftMiddle;
        controller.holeLayout = IEObjectLayoutBottom;
        controller.ballAngle = M_PI_2*3;
        [controller addPowerup:[IEPowerup powerupWithType:IEPowerupGravity shiftPoint:CGPointMake(0.03, 0.5)]];
        [controller addPath:[IECustomPath pathWithPointsFromString:@"(0,0),(0,1),(0.1,1),(0.1,0)" texture:IETextureTypeNoClick]];
        [controller addPowerup:[IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.03, 0.3)]];
        for (float x = 0.25;x<=0.75;x+=0.25){
            for (float y = 0.25;y<=0.75;y+=0.25){
                IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointMake(x, y)];
                [controller addPowerup:powerup];
            }
        }
    }
    else if (controller.levelNumber == 73){
        controller.levelName = @"Rocket Pocket";
        controller.ballLocation = IEObjectLayoutBottomLeft;
        controller.holeLayout = IEObjectLayoutBottomRight;
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0,0),(1,0),(1,0.1),(0,0.1)" texture:IETextureTypeNoClick], [IECustomPath pathWithPointsFromString:@"(0,1),(1,1),(1,0.9),(0,0.9)" texture:IETextureTypeNoClick], [IECustomPath pathWithPointsFromString:@"(0,0.9),(0,0.1),(0.15,0.1),(0.15,0.9)" texture:IETextureTypeNoClick], [IECustomPath pathWithPointsFromString:@"(1,0.9),(1,0.1),(0.85,0.1),(0.85,0.9)" texture:IETextureTypeNoClick]]];
        [controller addPowerup:[IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.5, 0.05)]];
        for (int k = 0;k<2;k++){
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupGravity shiftPoint:CGPointMake(0.5, 0.95)];
            if (k == 0){
                powerup.shiftPoint = CGPointMake(0.45, 0.05);
                powerup.zRotation = M_PI;
            }
            [controller addPowerup:powerup];
        }
        for (int k = 0;k<5;k++){
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointZero];
            if (k == 0)
                powerup.shiftPoint = CGPointMake(0.25, 0.35);
            else if (k == 1)
                powerup.shiftPoint = CGPointMake(0.5, 0.45);
            else if (k == 2)
                powerup.shiftPoint = CGPointMake(0.25, 0.75);
            else if (k == 3)
                powerup.shiftPoint = CGPointMake(0.55, 0.75);
            else
                powerup.shiftPoint = CGPointMake(0.35, 0.85);
            [controller addPowerup:powerup];
        }
    }
    else if (controller.levelNumber == 74){
        controller.levelName = @"Trapped";
        controller.ballLocation = IEObjectLayoutTopLeft;
        controller.holeLayout = IEObjectLayoutMiddle;
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0,0.8),(0,0.6),(0.4,0.6)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(1,0.8),(1,0.6),(0.6,0.6)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(0.5,0),(1,0),(1,0.25),(0.85,0.25)" texture:IETextureTypeSolid]]];
        for (int k = 0;k<5;k++){
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointZero];
            if (k == 0)
                powerup.shiftPoint = CGPointMake(0.5, 0.9);
            else if (k == 1)
                powerup.shiftPoint = CGPointMake(0.4, 0.7);
            else if (k == 2)
                powerup.shiftPoint = CGPointMake(0.6, 0.7);
            else
                powerup.shiftPoint = CGPointMake(0.6, 0.125);
            [controller addPowerup:powerup];
        }
        [controller addPowerups:@[[IEPowerup powerupWithType:IEPowerupGravity shiftPoint:CGPointMake(0.5, 0.95)], [IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.5, 0.05)], [IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.9, 0.3)]]];
    }
    else if (controller.levelNumber == 75){
        controller.levelName = @"Turkey Shoot";
        controller.ballLocation = IEObjectLayoutBottomLeft;
        controller.holeLayout = IEObjectLayoutTopLeft;
        controller.ballAngle = M_PI;
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0.95,1),(1,1),(1,0),(0.95,0)" texture:IETextureTypeInstaDeath], [IECustomPath pathWithPointsFromString:@"(0.7,0.4),(0.7,0.6),(0,0.6),(0,0.4)" texture:IETextureTypeInstaDeath], [IECustomPath pathWithPointsFromString:@"(0,0),(1,0),(1,0.05),(0,0.05)" texture:IETextureTypeNoClick]]];
        IEPowerup *gravity = [IEPowerup powerupWithType:IEPowerupGravity shiftPoint:CGPointMake(0.1, 0.05)];
        gravity.zRotation = -M_PI_2;
        IEPowerup *aimAndFire = [IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.05, 0.05)];
        [controller addPowerups:@[gravity, aimAndFire]];
    }
    else if (controller.levelNumber == 76){
        controller.levelName = @"Baby Steps";
        controller.holeLayout = IEObjectLayoutBottomRight;
        controller.ballLocation = IEObjectLayoutTopRightMiddle;
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0,0),(0,0.5),(0.1,0.5),(0.1,0)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(0.2,0),(0.2,0.4),(0.3,0.4),(0.3,0)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(0.4,0),(0.4,0.3),(0.5,0.3),(0.5,0)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(0.6,0),(0.6,0.2),(0.7,0.2),(0,0.2)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(0.8,0),(0.8,0.1),(0.9,0.1),(0.9,0)" texture:IETextureTypeSolid]]];
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0.1,0),(0.1,0.4),(0.2,0.4),(0.2,0)" texture:IETextureTypeInstaDeath], [IECustomPath pathWithPointsFromString:@"(0.3,0),(0.3,0.3),(0.4,0.3),(0.4,0)" texture:IETextureTypeInstaDeath], [IECustomPath pathWithPointsFromString:@"(0.5,0),(0.5,0.2),(0.6,0.2),(0.6,0)" texture:IETextureTypeInstaDeath], [IECustomPath pathWithPointsFromString:@"(0.7,0),(0.7,0.1),(0.8,0.1),(0.8,0)" texture:IETextureTypeInstaDeath]]];
        [controller addPath:[IECustomPath pathWithPointsFromString:@"(0,0.75),(0.9,0.1),(0.9,0.2),(0,0.85)" texture:IETextureTypeNoClick]];
        [controller addPowerup:[IEPowerup powerupWithType:IEPowerupGravity shiftPoint:CGPointMake(0.5,0.95)]];
        for (int k = 0;k<4;k++){
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointZero];
            if (k == 0)
                powerup.shiftPoint = CGPointMake(0.15, 0.5);
            else if (k == 1)
                powerup.shiftPoint = CGPointMake(0.35, 0.4);
            else if (k == 2)
                powerup.shiftPoint = CGPointMake(0.55, 0.3);
            else
                powerup.shiftPoint = CGPointMake(0.75, 0.2);
            [controller addPowerup:powerup];
        }
    }
    else if (controller.levelNumber == 77){
        controller.levelName = @"Sine Wave";
        controller.ballLocation = IEObjectLayoutDiagonalTopRight;
        controller.holeLayout = IEObjectLayoutRight;
        controller.ballAngle = M_PI;
        for (int k = 0;k<3;k++)
            [controller addPowerup:[IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointMake(0.35+k*0.15, 0.5)]];
        for (int k = 0;k<4;k++){
            CGFloat x = 0.23+(0.1275+0.015)*k;
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupGravity shiftPoint:CGPointZero];
            if (k == 0)
                powerup.shiftPoint = CGPointMake(x, 0.1);
            else if (k == 1 || k == 3)
                powerup.shiftPoint = CGPointMake(x, 0.8);
            else
                powerup.shiftPoint = CGPointMake(x, 0.2);
            [controller addPowerup:powerup];
        }
        const CGFloat thickness = 0.03;
        const CGFloat padding = 0.1275;
        const CGFloat total = thickness + padding;
        for (int k = 0;k<4;k++){
            CGFloat left = 0.2+total*k;
            NSString *pointString = [NSString stringWithFormat:@"(%f,0.3),(%f,0.7),(%f,0.7),(%f,0.3)", left, left,  left+thickness, left+thickness];
            IECustomPath *path = [IECustomPath pathWithPointsFromString:pointString texture:IETextureTypeSolid];
            [controller addPath:path];
        }
    }
    else if (controller.levelNumber == 78){
        controller.levelName = @"Deadly Borders";
        controller.ballLocation = IEObjectLayoutCustom;
        controller.holeLayout = IEObjectLayoutDiagonalTopRight;
        AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        [delegate storeShiftPoint:CGPointMake(0.25, 0.15) forIntegerKey:controller.levelNumber ball:YES];
        
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0,0.55),(0,1),(0.47,1),(0.06,0.9)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(1,0.55),(1,1),(0.53,1),(0.94,0.9)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(1,0.45),(0,1),(0.53,0),(0.94,0.1)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(0.47,0.5),(0.5,0.6),(0.53,0.5),(0.5,0.4)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(0,0.45),(0,0),(0.47,0),(0.06,0.1)" texture:IETextureTypeSolid]]];
        for (int k = 0;k<4;k++){
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupGravity shiftPoint:CGPointZero];
            if (k == 0){
                powerup.shiftPoint = CGPointMake(0.25,0.75);
                powerup.zRotation = M_PI;
            }
            else if (k == 1){
                powerup.shiftPoint = CGPointMake(0.75, 0.5);
                powerup.zRotation = M_PI_2;
            }
            else if (k == 2)
                powerup.shiftPoint = CGPointMake(0.5,0.25);
            else{
                powerup.shiftPoint = CGPointMake(0.25, 0.5);
                powerup.zRotation = -M_PI_2;
            }
            [controller addPowerup:powerup];
        }
        for (int k = 0;k<2;k++){
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupKey shiftPoint:CGPointZero];
            if (k == 0)
                powerup.shiftPoint = CGPointMake(0.25, 0.25);
            else
                powerup.shiftPoint = CGPointMake(0.75, 0.25);
            [controller addPowerup:powerup];
        }
        [controller addPowerup:[IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.25, 0.75)]];
    }
    else if (controller.levelNumber == 79){
        controller.levelName = @"Death Row";
        controller.ballLocation = IEObjectLayoutCustom;
        controller.holeLayout = IEObjectLayoutCustom;
        AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        [delegate storeShiftPoint:CGPointMake(0.35, 0.1) forIntegerKey:controller.levelNumber ball:YES];
        [delegate storeShiftPoint:CGPointMake(0.65, 0.1) forIntegerKey:controller.levelNumber ball:NO];
        [controller addPairs:@[[IECustomPath pathWithPointsFromString:@"(0.48,0),(0.48,0.8),(0.52,0.8),(0.52,0)" texture:IETextureTypeInstaDeath], [IECustomPath pathWithPointsFromString:@"(0,0),(0,1),(0.2,1),(0.2,0)" texture:IETextureTypeInstaDeath], [IECustomPath pathWithPointsFromString:@"(1,1),(1,0),(0.78,0),(0.78,1)" texture:IETextureTypeInstaDeath]]];
        for (int k = 0;k<8;k++){
            CGFloat x;
            CGFloat y;
            CGFloat rotation;
            if (k%2 == 0)
                rotation = 0;
            else
                rotation = M_PI;
            if(k<4)
                y = 0.2+0.2*k;
            else
                y = 0.7-0.2*(k-4);
            if(k<4&&k%2==0)
                x = 0.27;
            else if (k<4&&k%2==1)
                x = 0.41;
            else if (k>4&&k%2==0)
                x = 0.73;
            else
                x = 0.60;
            IEPowerup *powerup = [IEPowerup powerupWithType:IEPowerupGravity shiftPoint:CGPointMake(x, y)];
            powerup.zRotation = rotation;
            [controller addPowerup:powerup];
        }
    }
    else if (controller.levelNumber == 80){
        controller.levelName = @"Shape Shifter";
        controller.ballLocation = IEObjectLayoutDiagonalTopLeft;
        controller.holeLayout = IEObjectLayoutBottomRight;
        controller.ballAngle = M_PI_2;
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0,0.5),(0,0.55),(1,0.55),(1,0.5)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(0,0.3),(0,0.35),(1,0.35),(1,0.3)" texture:IETextureTypeInstaDeath]]];
        [controller addPowerups:@[[IEPowerup powerupWithType:IEPowerupGhost shiftPoint:CGPointMake(0.5, 0.75)], [IEPowerup powerupWithType:IEPowerupImmune shiftPoint:CGPointMake(0.25, 0.425)]]];
    }
    else if (controller.levelNumber == 81){
        
    }
    else if (controller.levelNumber == 199){
        controller.levelName = @"Physics Test";
        controller.holeLayout = IEObjectLayoutCustom;
        AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        [delegate storeShiftPoint:CGPointMake(2, 2) forIntegerKey:controller.levelNumber ball:NO];
        controller.starQuantitys = IEStarQuantityCreate(100, 100, 100);
        [controller addPowerup:[IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.25, 0.5)]];
        [controller addPowerup:[IEPowerup powerupWithType:IEPowerupGhost shiftPoint:CGPointMake(0.5, 0.5)]];
        [controller addPowerup:[IEPowerup powerupWithType:IEPowerupAimAndFire shiftPoint:CGPointMake(0.75, 0.5)]];
        [controller addPairs:@[[IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.1) shapeName:IEShapeNameCircle textureName:IETextureTypeInstaDeath], [IEObjectPointPair pairWithShift:CGPointMake(0.5, 0.9) shapeName:IEShapeNameCircle textureName:IETextureTypeNoClick], [IEObjectPointPair pairWithShift:CGPointMake(0.9, 0.5) shapeName:IEShapeNameCircle textureName:IETextureTypeSolid]]];
    }
    else if (controller.levelNumber == 200){
        controller.levelName = @"Tight Fit pt 2";
        controller.ballLocation = IEObjectLayoutBottom;
        controller.holeLayout = IEObjectLayoutMiddleTop;
        controller.ballAngle = M_PI_2;
        controller.ballRadius = controller.ballRadius*2.5;
        controller.starQuantitys = IEStarQuantityCreate(4, 4, 4);
        [controller addPaths:@[[IECustomPath pathWithPointsFromString:@"(0,0.48),(0,0.52),(0.4,0.52),(0.4,0.48)" texture:IETextureTypeInstaDeath
                                    ], [IECustomPath pathWithPointsFromString:@"(1,0.48),(1,0.52),(0.6,0.52),(0.6,0.48)" texture:IETextureTypeInstaDeath], [IECustomPath pathWithPointsFromString:@"(0,0.52),(0,1),(0.3,1),(0.3,0.52)" texture:IETextureTypeSolid], [IECustomPath pathWithPointsFromString:@"(1,0.52),(1,1),(0.7,1),(0.7,0.52)" texture:IETextureTypeSolid]]];
    }
    [controller saveLocally];
}
@end
