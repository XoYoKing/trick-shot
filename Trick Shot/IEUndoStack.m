//
//  IEUndoStack.m
//  Trick Shot
//
//  Created by Eric Dufresne on 2015-07-23.
//  Copyright (c) 2015 Eric Dufresne. All rights reserved.
//

#import "IEUndoStack.h"

@interface IEUndoStack ()
@property (strong, nonatomic) IEStackArray *undos;
@property (strong, nonatomic) IEStackArray *redos;
@end
@implementation IEUndoStack
-(id)init{
    if (self = [super init]){
        self.undos = [IEStackArray emptyStack];
        self.redos = [IEStackArray emptyStack];
    }
    return self;
}
-(void)addToStack:(id)object{
    while (!self.redos.isEmpty)
        [self.redos pop];
    
    [self.undos pushObject:object];
}
-(id)undo{
    if (!self.hasUndos)
        return nil;
    
    id temp = [self.undos pop];
    [self.redos pushObject:temp];
    return temp;
}
-(id)redo{
    if (!self.hasRedos)
        return nil;
    id temp = [self.redos pop];
    [self.undos pushObject:temp];
    return temp;
}
-(BOOL)hasRedos{
    return !self.redos.isEmpty;
}
-(BOOL)hasUndos{
    return !self.undos.isEmpty;
}
@end
@interface IEStackArray ()
@property (strong, nonatomic) NSMutableArray *objects;
@end
@implementation IEStackArray
-(id)init{
    if (self = [super init]){
        self.objects = [[NSMutableArray alloc] init];
    }
    return self;
}
+(instancetype)emptyStack{
    return [[self alloc] init];
}
-(id)pop{
    if (self.isEmpty)
        return nil;
    id temp = [self.objects objectAtIndex:self.objects.count-1];
    [self.objects removeObject:temp];
    return temp;
}
-(id)peek{
    if (self.isEmpty)
        return nil;
    return [self.objects objectAtIndex:self.objects.count-1];
}
-(void)pushObject:(id)object{
    [self.objects addObject:object];
}
-(BOOL)isEmpty{
    return self.objects.count == 0;
}
@end