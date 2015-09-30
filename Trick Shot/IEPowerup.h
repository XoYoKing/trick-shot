//
//  IEPowerup.h
//  Trick Shot
//
//  Created by Eric Dufresne on 2015-08-18.
//  Copyright (c) 2015 Eric Dufresne. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef enum : NSUInteger{
    IEPowerupImmune,
    IEPowerupSmaller,
    IEPowerupAimAndFire,
    IEPowerupGhost,
    IEPowerupGravity,
    IEPowerupNegateHits,
    IEPowerupTilt,
    IEPowerupKey
}IEPowerupType;

@interface IEPowerup : SKSpriteNode <NSCoding>
@property (assign, nonatomic) IEPowerupType powerupType;
@property (strong, nonatomic) SKTextureAtlas *powerupAtlas;
@property (assign, nonatomic) CGPoint shiftPoint;
-(id)initWithPowerupType:(IEPowerupType)type shiftPoint:(CGPoint)point;
+(instancetype)powerupWithType:(IEPowerupType)type shiftPoint:(CGPoint)point;
@end
