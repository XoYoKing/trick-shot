//
//  IEBounceLevelController.h
//  Circle Test
//
//  Created by Eric Dufresne on 2015-06-30.
//  Copyright (c) 2015 Eric Dufresne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>
#import "IECustomPath.h"
#import "IEPowerup.h"

//Layout Location enumeration for finish
typedef enum : NSUInteger{
    IEObjectLayoutTopRight,
    IEObjectLayoutTopLeft,
    IEObjectLayoutBottomRight,
    IEObjectLayoutBottomLeft,
    
    IEObjectLayoutTop,
    IEObjectLayoutLeft,
    IEObjectLayoutRight,
    IEObjectLayoutBottom,
    IEObjectLayoutMiddle,
    
    IEObjectLayoutMiddleLeft,
    IEObjectLayoutMiddleRight,
    IEObjectLayoutMiddleTop,
    IEObjectLayoutMiddleBottom,
    
    IEObjectLayoutDiagonalTopLeft,
    IEObjectLayoutDiagonalTopRight,
    IEObjectLayoutDiagonalBottomleft,
    IEObjectLayoutDiagonalBottomRight,
    
    IEObjectLayoutBottomLeftMiddle,
    IEObjectLayoutBottomRightMiddle,
    IEObjectLayoutTopRightMiddle,
    IEObjectLayoutTopLeftMiddle,
    
    IEObjectLayoutCustom
} IEObjectLayout;

typedef struct{
    NSUInteger min;
    NSUInteger twoStars;
    NSUInteger threeStars;
    
}IEStarQuantity;

IEStarQuantity IEStarQuantityCreate(NSUInteger min, NSUInteger twoStars, NSUInteger threeStars);


FOUNDATION_EXPORT NSString *const IEShapeNameSquare;
FOUNDATION_EXPORT NSString *const IEShapeNameRectangle;
FOUNDATION_EXPORT NSString *const IEShapeNameRectangleLong;
FOUNDATION_EXPORT NSString *const IEShapeNameRectangleLongest;
FOUNDATION_EXPORT NSString *const IEShapeNameRectangleThin;
FOUNDATION_EXPORT NSString *const IEShapeNameTriangleRight;
FOUNDATION_EXPORT NSString *const IEShapeNameTriangleEquilateral;
FOUNDATION_EXPORT NSString *const IEShapeNameTrianglePointy;
FOUNDATION_EXPORT NSString *const IEShapeNameCircle;
FOUNDATION_EXPORT NSString *const IEShapeNameCornerThin;
FOUNDATION_EXPORT NSString *const IEShapeNameCornerThick;

FOUNDATION_EXPORT NSString *const IEShapeNameSquareBox;
FOUNDATION_EXPORT NSString *const IEShapeNameRectangleBox;
FOUNDATION_EXPORT NSString *const IEShapeNameSquareBoxOpen;

FOUNDATION_EXPORT NSString *const IETextureTypeSolid;
FOUNDATION_EXPORT NSString *const IETextureTypeFriction;
FOUNDATION_EXPORT NSString *const IETextureTypeNoClick;
FOUNDATION_EXPORT NSString *const IETextureTypeCharged;
FOUNDATION_EXPORT NSString *const IETextureTypeInstaDeath;

FOUNDATION_EXPORT NSString *const IEShapeNameArcHalf;
FOUNDATION_EXPORT NSString *const IEShapeNameArcQuarter;
FOUNDATION_EXPORT NSString *const IEShapeNameArcThird;


/*
 IEObjectPointPair
 class is an easily binary convertable class that has all the properties necessary for an obstacle in a level. */
@interface IEObjectPointPair : NSObject <NSCoding>

/*The name of the shape. This determines the type of obstacle. Ex. circle, square, rectangle_long, triangle_right */
@property (strong, nonatomic) NSString *shapeName;

/*The name of the texture that overlaps the obstacle. This will change the friction and restitution properties of the obstacle */
@property (strong, nonatomic) NSString *textureName;

/* This property has an x and y shift factor. 0 being no shift and 1 being a full shift to other side of the screen. Ex. If one were to place an object in the middle the vector would be (0.5,0.5) */
@property (assign, nonatomic) CGPoint shiftPoint;

/* Property that determines the size of the obstacle. Default = 1 */
@property (assign, nonatomic) CGFloat scale;

/* Property that determines how many radians the obstacle is rotated on spawn */
@property (assign, nonatomic) CGFloat rotation;

/* Methods for initialization, one being an instance and other being a class method */
-(id)initWithShift:(CGPoint)loc shapeName:(NSString*)name textureName:(NSString*)textureName;
+(instancetype)pairWithShift:(CGPoint)loc shapeName:(NSString*)name textureName:(NSString*)textureName;
@end

/*
 IEBounceLevelController
 class will be used to create the data for a level and store the information in core data. The level number property is the property in which this data can be found and will be accessed upon level selection 
    */
@interface IEBounceLevelController : NSObject

/* Struct that has variables for each star amount 1,2 and 3. */
@property (assign, nonatomic) IEStarQuantity starQuantitys;

/* Level number, is the only property that must be assigned. This is the identifier for this object and the class does not allow duplicates in core data */
@property (assign, nonatomic) NSUInteger levelNumber;

/* Level Name (optional), is used as a display name for the level */
@property (strong, nonatomic) NSString *levelName;

/* Properties for the balls location in the parent view, the radius (size) of the ball, and the angle in which the ball will be shot at the start of the game. */
@property (assign, nonatomic) IEObjectLayout ballLocation; // Default is Layout:Left

@property (assign, nonatomic) CGFloat ballRadius; // Default is 16

@property (assign, nonatomic) CGFloat ballAngle; // Default is 0 deg

/* Properties for charged objects */
@property (assign, nonatomic) CGFloat fieldStrength; // Default is 1

/* Hole layout property is where the equally sized hole must be placed in order to win a game. Cannot equal the ball location */

@property (assign, nonatomic) IEObjectLayout holeLayout; // Default is Layout:Right;


/* Array with all of the object pairs for the levels obstacles. These can be added or removed at any time */
@property (strong, nonatomic) NSMutableArray *obstacles;

@property (strong, nonatomic) NSMutableArray *customPaths;

@property (strong, nonatomic) NSMutableArray *powerups;

/* Method that encodes the object into an NSManagedObject (encodes obstacles array into binary) and saves it into core data. Checks for duplicates and throws NSInternalInconsistencyException */
-(void)saveLocally;

/*Adds a strong typed pair to the obstacles array after archiving it*/
-(void)addPair:(IEObjectPointPair*)pair;

/* Adds all of the pairs in an array as obstacles */
-(void)addPairs:(NSArray*)pairs;

-(void)addPath:(IECustomPath*)path;

-(void)addPaths:(NSArray*)paths;

-(void)addPowerup:(IEPowerup*)powerup;

-(void)addPowerups:(NSArray*)powerups;

/*Gets unarchived pair from the obstacles array */
-(IEObjectPointPair*)getPairAtIndex:(NSUInteger)index;

/*Returns all unarchived pairs from the array */
-(NSArray*)decodedPairs;

-(NSArray*)decodedPaths;

-(NSArray*)decodedPowerups;

/*Returns YES if the level number passed already exists in the core data store */
+(BOOL)levelNumberIsSaved:(NSUInteger)levelNumber;

/*Returns the level controller for the corresponding number. If there is not one stored in Core Data a new one is initialized */
+(instancetype)controllerWithLevelNumber:(NSUInteger)number;

/*Returns the level contorller count. Does this by seeing the highest number that levelNumberIsSaved returns YES. Disjointed level orders can cause this to give a smaller value then expected. All levels must be consecutive */
+(NSUInteger)controllerCount;
@end
