//
//  IEPowerup.m
//  Trick Shot
//
//  Created by Eric Dufresne on 2015-08-18.
//  Copyright (c) 2015 Eric Dufresne. All rights reserved.
//

#import "IEPowerup.h"

@implementation IEPowerup
-(id)initWithPowerupType:(IEPowerupType)type shiftPoint:(CGPoint)point{
    if (self = [super init]){
        self.powerupAtlas = [SKTextureAtlas atlasNamed:@"icon.atlas"];
        self.powerupType = type;
        self.shiftPoint = point;
        if (self.powerupType == IEPowerupAimAndFire)
            self.texture = [self.powerupAtlas textureNamed:@"icon_aim"];
        else if (self.powerupType == IEPowerupGhost)
            self.texture = [self.powerupAtlas textureNamed:@"icon_ghost"];
        else if (self.powerupType == IEPowerupGravity)
            self.texture = [self.powerupAtlas textureNamed:@"icon_gravity"];
        else if (self.powerupType == IEPowerupImmune)
            self.texture = [self.powerupAtlas textureNamed:@"icon_invincible"];
        else if (self.powerupType == IEPowerupNegateHits)
            self.texture = [self.powerupAtlas textureNamed:@"icon_negate"];
        else if (self.powerupType == IEPowerupSmaller)
            self.texture = [self.powerupAtlas textureNamed:@"icon_shrink"];
        else if (self.powerupType == IEPowerupTilt)
            self.texture = [self.powerupAtlas textureNamed:@"icon_tilt"];
        else if (self.powerupType == IEPowerupKey)
            self.texture = [self.powerupAtlas textureNamed:@"icon_key"];
    }
    return self;
}
+(instancetype)powerupWithType:(IEPowerupType)type shiftPoint:(CGPoint)point{
    return [[self alloc] initWithPowerupType:type shiftPoint:point];
}
#pragma mark - NSCoding Protocol
-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:self.powerupType] forKey:@"powerupType"];
    [aCoder encodeObject:[NSValue valueWithCGPoint:self.shiftPoint] forKey:@"shiftPoint"];
    [aCoder encodeObject:[NSNumber numberWithFloat:self.zRotation] forKey:@"rotation"];
}
-(id)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super init]){
        self.powerupAtlas = [SKTextureAtlas atlasNamed:@"icon.atlas"];
        NSValue *value = [aDecoder decodeObjectForKey:@"shiftPoint"];
        self.shiftPoint = value.CGPointValue;
        NSNumber *number = [aDecoder decodeObjectForKey:@"powerupType"];
        self.powerupType = number.unsignedIntegerValue;
        number = [aDecoder decodeObjectForKey:@"rotation"];
        self.zRotation = number.floatValue;
        if (self.powerupType == IEPowerupAimAndFire)
            self.texture = [self.powerupAtlas textureNamed:@"icon_aim"];
        else if (self.powerupType == IEPowerupGhost)
            self.texture = [self.powerupAtlas textureNamed:@"icon_ghost"];
        else if (self.powerupType == IEPowerupGravity)
            self.texture = [self.powerupAtlas textureNamed:@"icon_gravity"];
        else if (self.powerupType == IEPowerupImmune)
            self.texture = [self.powerupAtlas textureNamed:@"icon_invincible"];
        else if (self.powerupType == IEPowerupNegateHits)
            self.texture = [self.powerupAtlas textureNamed:@"icon_negate"];
        else if (self.powerupType == IEPowerupSmaller)
            self.texture = [self.powerupAtlas textureNamed:@"icon_shrink"];
        else if (self.powerupType == IEPowerupTilt)
            self.texture = [self.powerupAtlas textureNamed:@"icon_tilt"];
        else if (self.powerupType == IEPowerupKey)
            self.texture = [self.powerupAtlas textureNamed:@"icon_key"];
    }
    return self;
}
@end
