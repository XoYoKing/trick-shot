//
//  AppDelegate.h
//  Circle Test
//
//  Created by Eric Dufresne on 2015-06-25.
//  Copyright (c) 2015 Eric Dufresne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@property (strong, nonatomic) NSArray *arrayOfColors;
@property (assign, nonatomic) BOOL testMode;

@property (assign, nonatomic) NSInteger pageToShow;
-(BOOL)hasDarkColorSchemeForIndex:(NSUInteger)index;
-(BOOL)storeShiftPoint:(CGPoint)shiftPoint forIntegerKey:(NSInteger)integer ball:(BOOL)isBall;
-(CGPoint)getShiftPointForIntegerKey:(NSInteger)key ball:(BOOL)isBall;
@end

