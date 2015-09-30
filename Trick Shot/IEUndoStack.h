//
//  IEUndoStack.h
//  Trick Shot
//
//  Created by Eric Dufresne on 2015-07-23.
//  Copyright (c) 2015 Eric Dufresne. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IEUndoStack : NSObject
-(id)undo; 
-(id)redo;
-(void)addToStack:(id)object;
-(BOOL)hasUndos;
-(BOOL)hasRedos;
@end
@interface IEStackArray : NSObject
+(instancetype)emptyStack;
-(id)pop;
-(id)peek;
-(void)pushObject:(id)object;
-(BOOL)isEmpty;
@end