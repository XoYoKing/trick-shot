//
//  IEButton.h
//  Trick Shot
//
//  Created by Eric Dufresne on 2015-07-10.
//  Copyright (c) 2015 Eric Dufresne. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@class IEButtonMenu;

@protocol IEButtonDelegate <NSObject>
@optional
-(void)buttonWasPressed:(id)button;
-(void)buttonWasReleased:(id)button;
-(void)buttonWasPressed:(id)button fromMenu:(IEButtonMenu*)menu;
-(void)buttonWasReleased:(id)button fromMenu:(IEButtonMenu*)menu;
@end

@interface IETextureButton : SKSpriteNode <IEButtonDelegate>
@property (weak, nonatomic) id<IEButtonDelegate> delegate;
@property (strong, nonatomic) SKTexture *selectedTexture;
@property (strong, nonatomic) SKTexture *defaultTexture;
@property (assign, nonatomic) BOOL isSelected;
@property (assign, nonatomic) BOOL enlargesWhenPressed;
@property (assign, nonatomic) CGFloat enlargePercentage;
-(id)initWithDefaultTexture:(SKTexture*)texture selectedTexture:(SKTexture*)selected;
+(instancetype)buttonWithDefaultTexture:(SKTexture*)texture selectedTexture:(SKTexture*)selected;
@end

@interface IELabelButton : SKLabelNode
@property (weak, nonatomic) id<IEButtonDelegate> delegate;
@property (assign, nonatomic) UIColor *defaultColor;
@property (strong, nonatomic) UIColor *selectedColor;
@property (assign, nonatomic) BOOL isSelected;
@property (assign, nonatomic) BOOL enlargesWhenPressed;
@property (assign, nonatomic) CGFloat enlargePercentage;
-(id)initWithFontNamed:(NSString *)fontName defaultColor:(UIColor*)color selectedColor:(UIColor*)selected;
+(instancetype)buttonWithFontName:(NSString*)fontName defaultColor:(UIColor*)color selectedColor:(UIColor*)selected;
@end

@interface IEButtonMenu : SKNode <IEButtonDelegate>
@property (weak, nonatomic) id<IEButtonDelegate> delegate;
@property (strong, nonatomic) NSArray *buttons;
@property (assign, nonatomic) NSInteger selectionCount;
-(id)initWithButtons:(NSArray*)buttons delegate:(id<IEButtonDelegate>)delegate;
+(instancetype)menuWithButtons:(NSArray*)buttons delegate:(id<IEButtonDelegate>)delegate;
@end


