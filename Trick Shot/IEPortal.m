//
//  IEPortal.m
//  Trick Shot
//
//  Created by Eric Dufresne on 2015-08-17.
//  Copyright (c) 2015 Eric Dufresne. All rights reserved.
//

#import "IEPortal.h"

@implementation IEPortal
-(id)initWithDirection:(IEPortalDirection)direction{
    if (self = [super initWithTexture:[SKTexture textureWithImageNamed:@"portal.png"]]){
        self.direction = direction;
    }
    return self;
}
+(instancetype)portalWithDirection:(IEPortalDirection)direction{
    return [[self alloc] initWithDirection:direction];
}
+(void)linkPortals:(IEPortal*)portal withPortal:(IEPortal*)other{
    portal.linkedPortal = other;
    other.linkedPortal = portal;
}
-(CGVector)adjustVelocity:(CGVector)velocity{
    if (self.linkedPortal == nil)
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Portals are not linked. Cannot call adjustVelocity:" userInfo:nil];
    bool same = self.portalsFaceEachOther;
    if (same)
        return velocity;
    else if (self.linkedPortal.direction == self.direction){
        if (self.direction == IEPortalDirectionBottom)
            return CGVectorMake(velocity.dx, fabs(velocity.dy));
        else if (self.direction == IEPortalDirectionTop)
            return CGVectorMake(velocity.dx, -fabs(velocity.dy));
        else if (self.direction == IEPortalDirectionLeft)
            return CGVectorMake(fabs(velocity.dx), velocity.dy);
        else if (self.direction == IEPortalDirectionRight)
            return CGVectorMake(-fabs(velocity.dx), velocity.dy);
    }
    else if (self.linkedPortal.direction == IEPortalDirectionBottom)
        return CGVectorMake(-velocity.dy, fabs(velocity.dx));
    else if (self.linkedPortal.direction == IEPortalDirectionTop)
        return CGVectorMake(-velocity.dy, -fabs(velocity.dx));
    else if (self.linkedPortal.direction == IEPortalDirectionLeft)
        return CGVectorMake(fabs(velocity.dy), -velocity.dx);
    else if (self.linkedPortal.direction == IEPortalDirectionRight)
        return CGVectorMake(-fabs(velocity.dy), -velocity.dx);
    return CGVectorMake(0, 0);
}
-(BOOL)portalsFaceEachOther{
    if (self.linkedPortal == nil)
        @throw [NSException exceptionWithName:NSInvalidArgumentException  reason:@"Portals are not linked. Cannot call portalsFaceEachOther" userInfo:nil];
    if (self.direction == IEPortalDirectionLeft)
        return self.linkedPortal.direction == IEPortalDirectionRight;
    else if (self.direction == IEPortalDirectionRight)
        return self.linkedPortal.direction == IEPortalDirectionLeft;
    else if (self.direction == IEPortalDirectionBottom)
        return self.linkedPortal.direction == IEPortalDirectionTop;
    else if (self.direction == IEPortalDirectionTop)
        return self.linkedPortal.direction == IEPortalDirectionBottom;
    else
        return false;
}
@end
