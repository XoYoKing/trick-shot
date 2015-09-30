//
//  IECustomPath.h
//  New Level Editor
//
//  Created by Eric Dufresne on 2015-08-11.
//  Copyright (c) 2015 Eric Dufresne. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface IECustomPath : NSObject <NSCoding>
@property (strong, nonatomic) NSString *textureName;
-(id)initWithPointsFromString:(NSString*)string texture:(NSString*)texture;
+(instancetype)pathWithPointsFromString:(NSString*)string texture:(NSString*)texture;
+(instancetype)fullScreenPathWithTexture:(NSString*)texture;
+(NSArray*)pathsForScreenEdgeWithYThickness:(CGFloat)thickness texture:(NSString*)texture;
-(void)addPoint:(CGPoint)point;
-(void)addPointsFromString:(NSString*)string;
-(UIBezierPath*)pathInView:(SKView*)view;
-(UIBezierPath*)pathInView:(SKView*)view scale:(CGFloat)scale;
@end
