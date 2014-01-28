//
//  DoodleStroke.h
//  DoodleMessage
//
//  Created by Qusic on 3/18/13.
//  Copyright (c) 2013 Qusic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, StrokeType) {
    Draw = 0,
    Highlight = 1,
    Fill = 2,
    Erase = 3
};

@interface DoodleStroke : NSObject

@property(retain) UIBezierPath *path;
@property(assign) StrokeType type;
@property(retain) UIColor *color;

@end
