//
//  IEButton.m
//  Trick Shot
//
//  Created by Eric Dufresne on 2015-07-10.
//  Copyright (c) 2015 Eric Dufresne. All rights reserved.
//

#import "IEButton.h"

@implementation IETextureButton
-(id)initWithDefaultTexture:(SKTexture*)texture selectedTexture:(SKTexture*)selected{
    if (self =  [super initWithTexture:texture]){
        self.defaultTexture = texture;
        self.selectedTexture = selected;
        self.userInteractionEnabled = YES;
        self.isSelected = NO;
        self.enlargesWhenPressed = YES;
        self.enlargePercentage = 1.1;
        self.size = self.texture.size;
    }
    return self;
}
+(instancetype)buttonWithDefaultTexture:(SKTexture*)texture selectedTexture:(SKTexture*)selected{
    return [[self alloc] initWithDefaultTexture:texture selectedTexture:selected];
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    self.isSelected = YES;
    [self runAction:[SKAction setTexture:self.selectedTexture]];
    if (self.enlargesWhenPressed)
        self.size = CGSizeMake(self.size.width*self.enlargePercentage, self.size.height*self.enlargePercentage);
    if (self.delegate&&[self.delegate respondsToSelector:@selector(buttonWasPressed:)])
        [self.delegate buttonWasPressed:self];
}
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    if (!CGRectContainsPoint(self.frame, location)){
        self.isSelected = NO;
        [self runAction:[SKAction setTexture:self.defaultTexture]];
        if (self.enlargesWhenPressed)
            self.size = CGSizeMake(self.size.width/self.enlargePercentage, self.size.height/self.enlargePercentage);
        if (self.delegate&&[self.delegate respondsToSelector:@selector(buttonWasReleased:)])
            [self.delegate buttonWasReleased:self];
    }
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    self.isSelected = NO;
    [self runAction:[SKAction setTexture:self.defaultTexture]];
    if (self.enlargesWhenPressed)
        self.size = CGSizeMake(self.size.width*self.enlargePercentage, self.size.height*self.enlargePercentage);
    if (self.delegate&&[self.delegate respondsToSelector:@selector(buttonWasPressed:)])
        [self.delegate buttonWasPressed:self];
}
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    self.isSelected = NO;
    [self runAction:[SKAction setTexture:self.defaultTexture]];
    if (self.enlargesWhenPressed)
        self.size = CGSizeMake(self.size.width*self.enlargePercentage, self.size.height*self.enlargePercentage);
    if (self.delegate&&[self.delegate respondsToSelector:@selector(buttonWasPressed:)])
        [self.delegate buttonWasPressed:self];
}
@end

@implementation IELabelButton
-(id)initWithFontNamed:(NSString *)fontName defaultColor:(UIColor *)color selectedColor:(UIColor *)selected{
    if (self = [super initWithFontNamed:fontName]){
        self.defaultColor = color;
        self.selectedColor = self.selectedColor;
        self.fontColor = self.defaultColor;
        self.userInteractionEnabled = YES;
        self.isSelected = NO;
        self.enlargesWhenPressed = YES;
        self.enlargePercentage = 1.1;
        self.fontSize = 30;
    }
    return self;
}
+(instancetype)buttonWithFontName:(NSString *)fontName defaultColor:(UIColor *)color selectedColor:(UIColor*)selected{
    return [[self alloc] initWithFontNamed:fontName defaultColor:color selectedColor:selected];
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    self.isSelected = YES;
    self.fontColor = self.selectedColor;
    if (self.enlargesWhenPressed)
        self.fontSize = self.fontSize*self.enlargePercentage;
    if (self.delegate&&[self.delegate respondsToSelector:@selector(buttonWasPressed:)])
        [self.delegate buttonWasPressed:self];
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    self.isSelected = NO;
    self.fontColor = self.defaultColor;
    if (self.enlargesWhenPressed)
        self.fontSize = self.fontSize/self.enlargePercentage;
    if (self.delegate&&[self.delegate respondsToSelector:@selector(buttonWasReleased:)])
        [self.delegate buttonWasReleased:self];
}
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    if (!CGRectContainsPoint(self.frame, location)){
        self.isSelected = NO;
        self.fontColor = self.defaultColor;
        if(self.enlargesWhenPressed)
            self.fontSize = self.fontSize/self.enlargePercentage;
        if (self.delegate&&[self.delegate respondsToSelector:@selector(buttonWasReleased:)])
            [self.delegate buttonWasReleased:self];
    }
}
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    self.isSelected = NO;
    self.fontColor = self.defaultColor;
    if (self.enlargesWhenPressed)
        self.fontSize = self.fontSize/self.enlargePercentage;
    if (self.delegate&&[self.delegate respondsToSelector:@selector(buttonWasReleased:)])
        [self.delegate buttonWasReleased:self];
}
@end

@implementation IEButtonMenu
-(id)initWithButtons:(NSArray*)buttons delegate:(id<IEButtonDelegate>)delegate{
    if (self = [super init]){
        self.buttons = buttons;
        for (id button in self.buttons){
            if ([button isKindOfClass:[IELabelButton class]]){
                IELabelButton *label = (IELabelButton*)button;
                label.delegate = self;
            }
            else if ([button isKindOfClass:[IETextureButton class]]){
                IETextureButton *texture = (IETextureButton*)button;
                texture.delegate = self;
            }
            else
                @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"initWithButtons: delegate: buttons argument contains id not of class IELabelButton or IETextureButton" userInfo:nil];
        }
        self.delegate = self;
        self.selectionCount = 0;
        self.position = CGPointZero;
    }
    return self;
}
+(instancetype)menuWithButtons:(NSArray*)buttons delegate:(id<IEButtonDelegate>)delegate{
    return [[self alloc] initWithButtons:buttons delegate:delegate];
}
#pragma mark - IEButtonOverride
-(void)buttonWasPressed:(id)button{
    self.selectionCount++;
    if (self.delegate&&[self.delegate respondsToSelector:@selector(buttonWasPressed:fromMenu:)])
        [self.delegate buttonWasPressed:button fromMenu:self];
}
-(void)buttonWasReleased:(id)button{
    self.selectionCount--;
    if(self.delegate&&[self.delegate respondsToSelector:@selector(buttonWasReleased:fromMenu:)])
        [self.delegate buttonWasReleased:button fromMenu:self];
}

@end

