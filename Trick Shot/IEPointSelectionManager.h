//
//  IEPointSelectionManager.h
//  Trick Shot
//
//  Created by Eric Dufresne on 2015-07-20.
//  Copyright (c) 2015 Eric Dufresne. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@class IEPointPair;

@protocol IEPointSelectionDelegate <NSObject>
@optional
-(void)selectedNewPoint:(CGPoint)point;
-(void)deselectedPoint;

-(void)didCreateConnection:(IEPointPair*)pair;
-(void)didRemoveConnection:(IEPointPair*)pair;
@end

@interface IEPointSelectionManager : NSObject
@property (weak, nonatomic) id<IEPointSelectionDelegate> delegate;
@property (assign, nonatomic) CGPoint selectedPoint;
@property (assign, nonatomic) BOOL hasSelection;
@property (strong, nonatomic) NSMutableArray *connections;

@property (assign, nonatomic) CGFloat maxDistance;
@property (assign, nonatomic) CGPoint firstTouch;
@property (assign, nonatomic) BOOL inTouch;
-(void)removePair:(IEPointPair*)pair;
-(void)addPair:(IEPointPair*)pair;
-(void)selectPoint:(CGPoint)point pressed:(BOOL)pressed;
-(IEPointPair*)connectionClosestToPoint:(CGPoint)point; //Returns nil if distance from point > maxDistance
-(BOOL)containsPair:(IEPointPair*)pair;
@end

@interface IEPointPair : NSObject
@property (assign, nonatomic) CGPoint first;
@property (assign, nonatomic) CGPoint second;
@property (strong, nonatomic) SKShapeNode *edgeShape;
@property (strong, nonatomic) SKSpriteNode *dot1;
@property (strong, nonatomic) SKSpriteNode *dot2;
-(id)initWithPoints:(CGPoint)first second:(CGPoint)second;
+(instancetype)pairWithPoints:(CGPoint)first second:(CGPoint)second;
-(BOOL)containsNode:(SKNode*)node;
-(BOOL)equalsPointPair:(IEPointPair*)pair;
@end


@interface IEStack : NSObject
-(id)initEmpty;
+(instancetype)emptyStack;

-(BOOL)isEmpty;
-(id)peek;
-(id)pop;
-(void)pushObject:(id)object;
@end
