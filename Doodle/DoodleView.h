//
//  DoodleView.h
//  DoodleMessage
//
//  Created by Qusic on 3/17/13.
//  Copyright (c) 2013 Qusic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DoodleStroke.h"

@interface DoodleView : UIView

@property(assign) StrokeType strokeType;
@property(assign) NSInteger strokeColor;
@property(assign) NSInteger strokeWidth;
@property(retain) UIImageView *backgroundView;

- (void)undo;
- (void)redo;
- (void)clear;

+ (NSArray *)builtinColors;
+ (NSArray *)builtinWidths;

@end
