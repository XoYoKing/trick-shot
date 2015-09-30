//
//  IEBounceLevelController.m
//  Circle Test
//
//  Created by Eric Dufresne on 2015-06-30.
//  Copyright (c) 2015 Eric Dufresne. All rights reserved.
//

#import "IEBounceLevelController.h"
#import "AppDelegate.h"
NSString *const IEShapeNameSquare = @"square";
NSString *const IEShapeNameRectangle = @"rectangle_short";
NSString *const IEShapeNameRectangleLong = @"rectangle_long";
NSString *const IEShapeNameRectangleLongest = @"rectangle_longest";
NSString *const IEShapeNameTriangleRight = @"triangle_right";
NSString *const IEShapeNameTriangleEquilateral = @"triangle_equilateral";
NSString *const IEShapeNameTrianglePointy = @"triangle_pointy";
NSString *const IEShapeNameCircle = @"circle";
NSString *const IEShapeNameCornerThin = @"corner_thin";
NSString *const IEShapeNameCornerThick = @"corner_thick";
NSString *const IEShapeNameRectangleThin = @"rectangle_thin";
NSString *const IEShapeNameSquareBox = @"box_square";
NSString *const IEShapeNameRectangleBox = @"box_rectangle";
NSString *const IEShapeNameSquareBoxOpen = @"box_square_open";

NSString *const IETextureTypeSolid = @"solid";
NSString *const IETextureTypeFriction = @"friction";
NSString *const IETextureTypeNoClick = @"noClick";
NSString *const IETextureTypeCharged = @"charge";
NSString *const IETextureTypeInstaDeath = @"instaDeath";

NSString *const IEShapeNameArcHalf = @"IEShapeNameArcHalf";
NSString *const IEShapeNameArcQuarter = @"IEShapeNameArcQuarter";
NSString *const IEShapeNameArcThird = @"IEShapeNameArcThird";

IEStarQuantity IEStarQuantityCreate(NSUInteger min, NSUInteger twoStars, NSUInteger threeStars){
    IEStarQuantity quantity;
    quantity.min = min;
    quantity.twoStars = twoStars;
    quantity.threeStars = threeStars;
    return quantity;
}

@implementation IEObjectPointPair
-(id)initWithShift:(CGPoint)loc shapeName:(NSString *)name textureName:(NSString *)textureName{
    if (self = [super init]){
        self.shapeName = name;
        self.textureName = textureName;
        self.shiftPoint = loc;
        self.scale = 1;
    }
    return self;
}
+(instancetype)pairWithShift:(CGPoint)loc shapeName:(NSString *)name textureName:(NSString *)textureName{
    return [[self alloc] initWithShift:loc shapeName:name textureName:textureName];
}
-(void)encodeWithCoder:(NSCoder *)aCoder{
    NSValue *value = [NSValue valueWithCGPoint:self.shiftPoint];
    [aCoder encodeObject:value forKey:@"location"];
    [aCoder encodeObject:self.shapeName forKey:@"shapeName"];
    [aCoder encodeObject:self.textureName forKey:@"textureName"];
    [aCoder encodeObject:[NSNumber numberWithFloat:self.rotation] forKey:@"rotation"];
    [aCoder encodeObject:[NSNumber numberWithFloat:self.scale] forKey:@"scale"];
}
-(id)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super init]){
        NSValue *value = [aDecoder decodeObjectForKey:@"location"];
        self.shiftPoint = value.CGPointValue;
        self.shapeName = [aDecoder decodeObjectForKey:@"shapeName"];
        self.textureName = [aDecoder decodeObjectForKey:@"textureName"];
        NSNumber *x = [aDecoder decodeObjectForKey:@"scale"];
        self.scale = x.floatValue;
        x = [aDecoder decodeObjectForKey:@"rotation"];
        self.rotation = x.floatValue;
    }
    return self;
}
-(NSString*)description{
    return [NSString stringWithFormat:@"Location: (%.2f, %.2f), Shape: %@, Texture: %@", self.shiftPoint.x, self.shiftPoint.y, self.shapeName, self.textureName];
}
@end

@implementation IEBounceLevelController
-(id)init{
    if (self = [super init]){
        self.ballRadius = 16;
        self.ballAngle = 0;
        self.ballLocation = IEObjectLayoutLeft;
        self.holeLayout = IEObjectLayoutRight;
        self.levelName = @"No Name";
        self.obstacles = [[NSMutableArray alloc]init];
        self.customPaths = [[NSMutableArray alloc] init];
        self.powerups = [[NSMutableArray alloc] init];
        self.starQuantitys = IEStarQuantityCreate(10, 9, 8);
    }
    return self;
}
-(void)saveLocally{
    AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = delegate.managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"BounceLevelController" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    [request setPredicate:[NSPredicate predicateWithFormat:@"(levelNumber = %i)", (int)self.levelNumber]];
    NSError *error;
    NSArray *array = [context executeFetchRequest:request error:&error];
    if (array.count == 0){
        NSManagedObject *newObject = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
        [newObject setValue:[NSNumber numberWithUnsignedInteger:self.levelNumber] forKey:@"levelNumber"];
        [newObject setValue:self.levelName forKey:@"levelName"];
        [newObject setValue:[NSNumber numberWithUnsignedInteger:self.holeLayout] forKey:@"holeLocation"];
        [newObject setValue:[NSNumber numberWithUnsignedInteger:self.ballLocation] forKey:@"ballLocation"];
        [newObject setValue:[NSNumber numberWithFloat:self.ballRadius] forKey:@"ballRadius"];
        [newObject setValue:[NSNumber numberWithFloat:self.ballAngle] forKey:@"ballAngle"];
        [newObject setValue:[self dataFromStarQuantity] forKey:@"starQuantity"];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.obstacles];
        [newObject setValue:data forKey:@"obstacles"];
        NSData *data2 = [NSKeyedArchiver archivedDataWithRootObject:self.customPaths];
        [newObject setValue:data2 forKey:@"customPaths"];
        NSData *data3 = [NSKeyedArchiver archivedDataWithRootObject:self.powerups];
        [newObject setValue:data3 forKey:@"powerups"];
        NSError *error2;
        [context save:&error2];
    }
    else if (array.count == 1){
        NSManagedObject *object = [array objectAtIndex:0];
        [object setValue:[NSNumber numberWithUnsignedInteger:self.levelNumber] forKey:@"levelNumber"];
        [object setValue:self.levelName forKey:@"levelName"];
        [object setValue:[NSNumber numberWithUnsignedInteger:self.ballLocation] forKey:@"ballLocation"];
        [object setValue:[NSNumber numberWithFloat:self.ballRadius] forKey:@"ballRadius"];
        [object setValue:[NSNumber numberWithFloat:self.ballAngle] forKey:@"ballAngle"];
        [object setValue:[self dataFromStarQuantity] forKey:@"starQuantity"];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.obstacles];
        [object setValue:data forKey:@"obstacles"];
        NSData *data2 = [NSKeyedArchiver archivedDataWithRootObject:self.customPaths];
        [object setValue:data2 forKey:@"customObstacles"];
        NSData *data3 = [NSKeyedArchiver archivedDataWithRootObject:self.powerups];
        [object setValue:data3 forKey:@"powerups"];
        NSError *error2;
        [context save:&error2];
    }
    else
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Two or more copies of the same level data stored locally with levelNumber: %i", (int)self.levelNumber] userInfo:nil];
}
-(void)addPair:(IEObjectPointPair*)pair{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:pair];
    [self.obstacles addObject:data];
}
-(void)addPairs:(NSArray *)pairs{
    for (IEObjectPointPair *pair in pairs){
        [self addPair:pair];
    }
}
-(void)addPath:(IECustomPath *)path{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:path];
    [self.customPaths addObject:data];
}
-(void)addPaths:(NSArray *)paths{
    for (IECustomPath *path in paths){
        [self addPath:path];
    }
}
-(void)addPowerup:(IEPowerup *)powerup{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:powerup];
    [self.powerups addObject:data];
}
-(void)addPowerups:(NSArray *)powerups{
    for (int k = 0;k<powerups.count;k++){
        IEPowerup *powerup = [powerups objectAtIndex:k];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:powerup];
        [self.powerups addObject:data];
    }
}
-(IEObjectPointPair*)getPairAtIndex:(NSUInteger)index{
    if (index>=self.obstacles.count)
        @throw [NSException exceptionWithName:NSRangeException reason:[NSString stringWithFormat:@"Index: %i is out of bounces for obstacles array in controller with count: %i", (int)index, (int)self.obstacles.count] userInfo:nil];
    NSData *data = [self.obstacles objectAtIndex:index];
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}
-(NSArray*)decodedPairs{
    NSMutableArray *array = [NSMutableArray array];
    for (NSData *data in self.obstacles){
        IEObjectPointPair *pair = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        [array addObject: pair];
    }
    return (NSArray*)array;
}
-(NSArray*)decodedPaths{
    NSMutableArray *array = [NSMutableArray array];
    for (NSData *data in self.customPaths){
        IECustomPath *path = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        [array addObject:path];
    }
    return (NSArray*)array;
}
-(NSArray*)decodedPowerups{
    NSMutableArray *array = [NSMutableArray array];
    for (NSData *data in self.powerups){
        IEPowerup *powerup = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        [array addObject:powerup];
    }
    return (NSArray*)array;
}

+(BOOL)levelNumberIsSaved:(NSUInteger)levelNumber{
    AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = delegate.managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"BounceLevelController" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    [request setPredicate:[NSPredicate predicateWithFormat:@"(levelNumber = %i)", (int)levelNumber]];
    NSError *error;
    NSArray *array = [context executeFetchRequest:request error:&error];
    if (array.count == 0)
        return NO;
    else if (array.count == 1)
        return YES;
    else
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Two or more copies of the same level data stored locally with levelNumber: %i", (int)levelNumber] userInfo:nil];
}
+(instancetype)controllerWithLevelNumber:(NSUInteger)number{
    AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = delegate.managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"BounceLevelController" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    [request setPredicate:[NSPredicate predicateWithFormat:@"(levelNumber = %i)", (int)number]];
    NSError *error;
    NSArray *array = [context executeFetchRequest:request error:&error];
    if (array.count == 0){
        IEBounceLevelController *controller = [[IEBounceLevelController alloc] init];
        controller.levelNumber = number;
        return controller;
    }
    else if (array.count == 1){
        NSManagedObject *object = [array objectAtIndex:0];
        IEBounceLevelController *controller = [[IEBounceLevelController alloc] init];
        NSNumber *number = [object valueForKey:@"levelNumber"];
        controller.levelNumber = number.unsignedIntegerValue;
        controller.levelName = [object valueForKey:@"levelName"];
        number = [object valueForKey:@"ballRadius"];
        controller.ballRadius = number.floatValue;
        number = [object valueForKey:@"ballAngle"];
        controller.ballAngle = number.floatValue;
        controller.obstacles = [object valueForKey:@"obstacles"];
        number = [object valueForKey:@"holeLocation"];
        controller.holeLayout = number.unsignedIntegerValue;
        NSNumber *x = [object valueForKey:@"ballLocation"];
        controller.ballLocation = x.unsignedIntegerValue;
        NSData *data = [object valueForKey:@"obstacles"];
        controller.obstacles = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        NSData *data2 = [object valueForKey:@"starQuantity"];
        controller.starQuantitys = [IEBounceLevelController starQuantityFromData:data2];
        data2 = [object valueForKey:@"customPaths"];
        controller.customPaths = [NSKeyedUnarchiver unarchiveObjectWithData:data2];
        data2 = [object valueForKey:@"powerups"];
        controller.powerups = [NSKeyedUnarchiver unarchiveObjectWithData:data2];
        return controller;
    }
    else
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Two or more copies of the same level data stored locally with levelNumber: %i", (int)number] userInfo:nil];
}
-(NSString*)description{
    NSString *info = [NSString stringWithFormat:@"Level Number: %i\nLevel Name: %@", (int)self.levelNumber, self.levelName];
    NSString *enumString = @"";
    switch (self.ballLocation) {
        case IEObjectLayoutBottomLeft:
            enumString = @"Bottom Left";
            break;
        case IEObjectLayoutBottom:
            enumString = @"Bottom";
            break;
        case IEObjectLayoutBottomRight:
            enumString = @"BottomRight";
            break;
        case IEObjectLayoutDiagonalBottomleft:
            enumString = @"Bottom Left";
            break;
        case IEObjectLayoutDiagonalBottomRight:
            enumString = @"Diagonal Bottom Right";
            break;
        case IEObjectLayoutDiagonalTopLeft:
            enumString = @"Diagonal Top Left";
            break;
        case IEObjectLayoutDiagonalTopRight:
            enumString = @"Digaonal Top Right";
            break;
        case IEObjectLayoutLeft:
            enumString = @"Left";
            break;
        case IEObjectLayoutMiddle:
            enumString = @"Middle";
            break;
        case IEObjectLayoutMiddleBottom:
            enumString = @"Middle Bottom";
            break;
        case IEObjectLayoutMiddleLeft:
            enumString = @"Middle Left";
            break;
        case IEObjectLayoutMiddleRight:
            enumString = @"Middle Right";
            break;
        case IEObjectLayoutMiddleTop:
            enumString = @"Middle Top";
            break;
        case IEObjectLayoutRight:
            enumString = @"Right";
            break;
        case IEObjectLayoutTop:
            enumString = @"Top";
            break;
        case IEObjectLayoutTopLeft:
            enumString = @"Top Left";
            break;
        case IEObjectLayoutTopRight:
            enumString = @"Top Right";
            break;
        default:
            break;
    }
    NSString *ballInfo = [NSString stringWithFormat:@"Ball Location: %@\nBall Radius: %.2f\nBall Angle: %.2f deg", enumString, self.ballRadius, self.ballAngle];
    NSString *obstacleInfo = @"Obstacles: {";
    for (NSData* data in self.obstacles){
        IEObjectPointPair *obstacle = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        obstacleInfo = [NSString stringWithFormat:@"%@\n%@", obstacleInfo, obstacle];
    }
    obstacleInfo = [NSString stringWithFormat:@"%@}", obstacleInfo];
    
    return [NSString stringWithFormat:@"%@\n%@\n%@", info, ballInfo, obstacleInfo];
}
+(NSUInteger)controllerCount{
    int count = 0;
    while (true){
        if([IEBounceLevelController levelNumberIsSaved:count+1])
            count++;
        else
            return count;
    }
}
-(NSData*)dataFromStarQuantity{
    NSNumber *min = [NSNumber numberWithUnsignedInteger:self.starQuantitys.min];
    NSNumber *two = [NSNumber numberWithUnsignedInteger:self.starQuantitys.twoStars];
    NSNumber *three = [NSNumber numberWithUnsignedInteger:self.starQuantitys.threeStars];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:min, @"min", two, @"twoStars", three, @"threeStars", nil];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
    return data;
}
+(IEStarQuantity)starQuantityFromData:(NSData*)data{
    NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSNumber *min = [dictionary objectForKey:@"min"];
    NSNumber *two = [dictionary objectForKey:@"twoStars"];
    NSNumber *three = [dictionary objectForKey:@"threeStars"];
    IEStarQuantity quantity = IEStarQuantityCreate(min.unsignedIntegerValue, two.unsignedIntegerValue, three.unsignedIntegerValue);
    return quantity;
}
@end
