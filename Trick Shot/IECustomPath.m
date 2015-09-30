//
//  IECustomPath.m
//  New Level Editor
//
//  Created by Eric Dufresne on 2015-08-11.
//  Copyright (c) 2015 Eric Dufresne. All rights reserved.
//

#import "IECustomPath.h"

@interface IECustomPath ()
@property (strong, nonatomic) NSMutableArray *pointDictionaries;
@property (strong, nonatomic) NSString *fullPointString;
@end

@implementation IECustomPath
-(id)initWithPointsFromString:(NSString *)string texture:(NSString *)texture{
    if (self = [super init]){
        self.textureName = texture;
        if (string!=nil)
            self.fullPointString = string;
        else
            self.fullPointString = @"";
        NSString *trim = [[string componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789(),."]invertedSet]]componentsJoinedByString:@""];
        NSArray *array = [trim componentsSeparatedByString:@")"];
        NSMutableArray *trimmedStrings = [NSMutableArray array];
        for (NSString *string in array){
            NSString *trim = [string stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@",("]];
            [trimmedStrings addObject:trim];
        }
        self.pointDictionaries = [NSMutableArray array];
        for (int k = 0;k<trimmedStrings.count-1;k++){
            NSString *string = [trimmedStrings objectAtIndex:k];
            NSArray *twoStrings = [string componentsSeparatedByString:@","];
            NSString *xString = [twoStrings objectAtIndex:0];
            NSString *yString = [twoStrings objectAtIndex:1];
            NSNumber *x = [NSNumber numberWithFloat:xString.floatValue];
            NSNumber *y = [NSNumber numberWithFloat:yString.floatValue];
            NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:x, @"positionX", y, @"positionY", nil];
            [self.pointDictionaries addObject:dictionary];
        }
    }
    return self;
}
+(instancetype)fullScreenPathWithTexture:(NSString*)texture{
    return [[self alloc] initWithPointsFromString:@"(0,0),(0,1),(1,1),(1,0)" texture:texture];
}
+(instancetype)pathWithPointsFromString:(NSString *)string texture:(NSString *)texture{
    return [[self alloc]initWithPointsFromString:string texture:texture];
}
+(NSArray*)pathsForScreenEdgeWithYThickness:(CGFloat)thickness texture:(NSString *)texture{
    CGFloat xThickness = 5*thickness/3;
    NSMutableArray *array = [NSMutableArray array];
    [array addObject:[IECustomPath pathWithPointsFromString:[NSString stringWithFormat:@"(0,0),(0,1),(%f,1),(%f,0)", xThickness, xThickness] texture:texture]];
    [array addObject:[IECustomPath pathWithPointsFromString:[NSString stringWithFormat:@"(1,1),(1,0),(%f,0),(%f,1)", 1-xThickness, 1-xThickness] texture:texture]];
    [array addObject:[IECustomPath pathWithPointsFromString:[NSString stringWithFormat:@"(%f,1),(%f,1),(%f,%f),(%f,%f)", xThickness, 1-xThickness, 1-xThickness, 1-thickness, xThickness, 1-thickness] texture:texture]];
    [array addObject:[IECustomPath pathWithPointsFromString:[NSString stringWithFormat:@"(%f,0),(%f,0),(%f,%f),(%f,%f)", xThickness, 1-xThickness, 1-xThickness, thickness, xThickness, thickness] texture:texture]];
    return (NSArray*)array;
}
-(void)addPoint:(CGPoint)point{
    self.fullPointString = [self.fullPointString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
    self.fullPointString = [NSString stringWithFormat:@"%@, (%f, %f)", self.fullPointString, point.x, point.y];
    NSNumber *x = [NSNumber numberWithFloat:point.x];
    NSNumber *y = [NSNumber numberWithFloat:point.y];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:x, @"positionX", y, @"positionY", nil];
    [self.pointDictionaries addObject:dictionary];
}
-(void)addPointsFromString:(NSString *)string{
    self.fullPointString = [self.fullPointString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
    NSString *trim = [[string componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789(),."]invertedSet]]componentsJoinedByString:@""];
    self.fullPointString = [NSString stringWithFormat:@"%@, %@", self.fullPointString, trim];
    NSArray *array = [trim componentsSeparatedByString:@")"];
    NSMutableArray *trimmedStrings = [NSMutableArray array];
    for (NSString *string in array){
        NSString *trim = [string stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@",("]];
        [trimmedStrings addObject:trim];
    }
    for (int k = 0;k<trimmedStrings.count-1;k++){
        NSString *string = [trimmedStrings objectAtIndex:k];
        NSArray *twoStrings = [string componentsSeparatedByString:@","];
        NSString *xString = [twoStrings objectAtIndex:0];
        NSString *yString = [twoStrings objectAtIndex:1];
        [self addPoint:CGPointMake(xString.floatValue, yString.floatValue)];
    }
}
-(UIBezierPath*)pathInView:(SKView *)view{
    return [self pathInView:view scale:1];
}
-(UIBezierPath*)pathInView:(SKView *)view scale:(CGFloat)scale{
    if (view == nil)
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Creating path not allowed with nil view" userInfo:nil];
    NSLog(@"Frame Dimensions: %f, %f", view.frame.size.width, view.frame.size.height);
    UIBezierPath *path = [UIBezierPath bezierPath];
    for (int k = 0;k<self.pointDictionaries.count;k++){
        NSDictionary *dictionary = [self.pointDictionaries objectAtIndex:k];
        NSNumber *x = [dictionary objectForKey:@"positionX"];
        NSNumber *y = [dictionary objectForKey:@"positionY"];
        CGPoint point = CGPointMake(x.floatValue*view.frame.size.width*scale, y.floatValue*view.frame.size.height*scale);
        if (k == 0)
            [path moveToPoint:point];
        else
            [path addLineToPoint:point];
    }
    [path closePath];
    return path;
}
-(NSString*)description{
    return [NSString stringWithFormat:@"[IECustomPath pathWithPointsFromString:@\"%@\" texture: %@];", self.fullPointString, self.textureName];
}
#pragma mark - NSCoding Protocol
-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.textureName forKey:@"textureName"];
    [aCoder encodeObject:self.pointDictionaries forKey:@"pointDictionaries"];
    [aCoder encodeObject:self.fullPointString forKey:@"fullPointString"];
}
-(id)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super init]){
        self.textureName = [aDecoder decodeObjectForKey:@"textureName"];
        self.pointDictionaries = [aDecoder decodeObjectForKey:@"pointDictionaries"];
        self.fullPointString = [aDecoder decodeObjectForKey:@"fullPointString"];
    }
    return self;
}
@end
