//
//  AppDelegate.m
//  Circle Test
//
//  Created by Eric Dufresne on 2015-06-25.
//  Copyright (c) 2015 Eric Dufresne. All rights reserved.
//

#import "AppDelegate.h"
#import "IEDataManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate
-(BOOL)hasDarkColorSchemeForIndex:(NSUInteger)index{
    if (index<=4)
        return YES;
    else
        return NO;
}
-(BOOL)storeShiftPoint:(CGPoint)shiftPoint forIntegerKey:(NSInteger)integer ball:(BOOL)isBall{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (isBall){
        NSNumber *number = [NSNumber numberWithFloat:shiftPoint.x];
        [defaults setObject:number forKey:[NSString stringWithFormat:@"Ball%iX", (int)integer]];
        number = [NSNumber numberWithFloat:shiftPoint.y];
        [defaults setObject:number forKey:[NSString stringWithFormat:@"Ball%iY", (int)integer]];
    }
    else{
        NSNumber *number = [NSNumber numberWithFloat:shiftPoint.x];
        [defaults setObject:number forKey:[NSString stringWithFormat:@"Hole%iX", (int)integer]];
        number = [NSNumber numberWithFloat:shiftPoint.y];
        [defaults setObject:number forKey:[NSString stringWithFormat:@"Hole%iY", (int)integer]];
    }
    [defaults synchronize];
    
    return YES;
}
-(CGPoint)getShiftPointForIntegerKey:(NSInteger)key ball:(BOOL)isBall{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (isBall){
        NSNumber *x = (NSNumber*)[defaults objectForKey:[NSString stringWithFormat:@"Ball%iX", (int)key]];
        NSNumber *y = (NSNumber*)[defaults objectForKey:[NSString stringWithFormat:@"Ball%iY", (int)key]];
        if (!x||!y)
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Data not found" userInfo:nil];
        return CGPointMake(x.floatValue, y.floatValue);
    }
    else{
        NSNumber *x = (NSNumber*)[defaults objectForKey:[NSString stringWithFormat:@"Hole%iX", (int)key]];
        NSNumber *y = (NSNumber*)[defaults objectForKey:[NSString stringWithFormat:@"Hole%iY", (int)key]];
        if (!y||!x)
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Y NOt Found" userInfo:nil];
        return CGPointMake(x.floatValue, y.floatValue);
    }
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    srand((unsigned int)time(NULL));
    IEDataManager *manager = [IEDataManager sharedManager];
#pragma unused(manager)
    
    self.arrayOfColors = @[
                           [UIColor colorWithRed:0.000f green:0.953f blue:0.992f alpha:1.00f],
                           [UIColor colorWithRed:0.000f green:1.000f blue:0.682f alpha:1.00f],
                           [UIColor colorWithRed:0.000f green:0.996f blue:0.388f alpha:1.00f],
                           [UIColor colorWithRed:0.494f green:0.996f blue:0.365f alpha:1.00f],
                           [UIColor colorWithRed:0.945f green:0.996f blue:0.373f alpha:1.00f],
                           [UIColor colorWithRed:1.000f green:0.639f blue:0.278f alpha:1.00f],
                           [UIColor colorWithRed:1.000f green:0.212f blue:0.208f alpha:1.00f],
                           [UIColor colorWithRed:0.988f green:0.443f blue:0.659f alpha:1.00f],
                           [UIColor colorWithRed:0.851f green:0.745f blue:0.784f alpha:1.00f],
                           [UIColor colorWithRed:0.294f green:0.294f blue:0.294f alpha:1.00f]
                           ];
    self.pageToShow = 0;
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"BounceLevelController" inManagedObjectContext:self.managedObjectContext]];
    request.propertiesToFetch = @[@"levelNumber"];
    NSError *error;
    NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];
    for (NSManagedObject *object in objects){
        [self.managedObjectContext deleteObject:object];
    }
    NSSet *set = [self.managedObjectContext deletedObjects];
    NSLog(@"%i levels deleted", (int)set.count);
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"hasRanBefore"];
    [self saveContext];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "IndieEndGames.Circle_Test" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Circle_Test" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Circle_Test.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
