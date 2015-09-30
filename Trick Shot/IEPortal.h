//
//  IEPortal.h
//  Trick Shot
//
//  Created by Eric Dufresne on 2015-08-17.
//  Copyright (c) 2015 Eric Dufresne. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef enum : NSUInteger{
    IEPortalDirectionBottom,
    IEPortalDirectionTop,
    IEPortalDirectionLeft,
    IEPortalDirectionRight
}IEPortalDirection;

@interface IEPortal : SKSpriteNode
@property (strong, nonatomic) IEPortal *linkedPortal;
@property (assign, nonatomic) IEPortalDirection direction;
@property (assign, nonatomic) CGFloat shift;
-(id)initWithDirection:(IEPortalDirection)direction;
+(instancetype)portalWithDirection:(IEPortalDirection)direction;
+(void)linkPortals:(IEPortal*)portal withPortal:(IEPortal*)other;
-(CGVector)adjustVelocity:(CGVector)velocity;
-(BOOL)portalsFaceEachOther;
@end
