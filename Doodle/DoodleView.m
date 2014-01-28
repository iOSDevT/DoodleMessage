//
//  DoodleView.m
//  DoodleMessage
//
//  Created by Qusic on 3/17/13.
//  Copyright (c) 2013 Qusic. All rights reserved.
//

#import "DoodleView.h"
#import "DoodleStroke.h"

@interface DoodleView ()

@property(retain) NSMutableArray *strokes;
@property(retain) NSMutableArray *history;
@property(retain) DoodleStroke *currentStroke;

@end

@implementation DoodleView

@synthesize strokeType = _strokeType;
@synthesize strokeColor = _strokeColor;
@synthesize strokeWidth = _strokeWidth;
@synthesize backgroundView = _backgroundView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _strokes = [NSMutableArray array];
        _history = [NSMutableArray array];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    for (DoodleStroke *stroke in _strokes) {
        switch (stroke.type) {
            case Draw:
                [stroke.color setStroke];
                [[UIColor clearColor]setFill];
                [stroke.path strokeWithBlendMode:kCGBlendModeNormal alpha:1.0];
                break;
            case Highlight:
                [stroke.color setStroke];
                [[UIColor clearColor]setFill];
                [stroke.path strokeWithBlendMode:kCGBlendModeNormal alpha:0.5];
                break;
            case Fill:
                [stroke.color setFill];
                [[UIColor clearColor]setStroke];
                [stroke.path fillWithBlendMode:kCGBlendModeNormal alpha:1.0];
                break;
            case Erase:
                [[UIColor colorWithPatternImage:_backgroundView.image] ?: _backgroundView.backgroundColor setStroke];
                [[UIColor clearColor]setFill];
                [stroke.path strokeWithBlendMode:kCGBlendModeNormal alpha:1.0];
                break;
            default:
                break;
        }
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UIBezierPath *currentPath = [[UIBezierPath alloc]init];
    currentPath.lineWidth = [[[self class]builtinWidths][_strokeWidth]integerValue];
    currentPath.lineCapStyle = kCGLineCapRound;
    [currentPath moveToPoint:[[touches allObjects][0]locationInView:self]];
    _currentStroke = [[DoodleStroke alloc]init];
    _currentStroke.path = currentPath;
    _currentStroke.type = _strokeType;
    _currentStroke.color = [[self class]builtinColors][_strokeColor];
    [_strokes addObject:_currentStroke];
    _history = [NSMutableArray array];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [_currentStroke.path addLineToPoint:[[touches allObjects][0]locationInView:self]];
    [self setNeedsDisplay];
}

- (void)undo
{
    if(_strokes.count > 0) {
        [_history addObject:_strokes.lastObject];
        [_strokes removeLastObject];
        [self setNeedsDisplay];
    }
}

- (void)redo
{
    if(_history.count > 0) {
        [_strokes addObject:_history.lastObject];
        [_history removeLastObject];
        [self setNeedsDisplay];
    }
}

- (void)clear
{
    _strokes = [NSMutableArray array];
    _history = [NSMutableArray array];
    [self setNeedsDisplay];
}

+ (NSArray *)builtinColors
{
    NSMutableArray *colors = [NSMutableArray array];
    for (CGFloat white = 0.0; white <= 1.0; white += 0.2) {
        [colors addObject:[UIColor colorWithWhite:white alpha:1.0]];
    }
    for (CGFloat hue = 0.0; hue < 1.0; hue += 0.05) {
        [colors addObject:[UIColor colorWithHue:hue saturation:1.0 brightness:1.0 alpha:1.0]];
        [colors addObject:[UIColor colorWithHue:hue saturation:1.0 brightness:0.5 alpha:1.0]];
        [colors addObject:[UIColor colorWithHue:hue saturation:0.5 brightness:1.0 alpha:1.0]];
    }
    return colors;
}

+ (NSArray *)builtinWidths
{
    NSMutableArray *widths = [NSMutableArray array];
    for (NSInteger width = 5; width <= 50; width += 5) {
        [widths addObject:[NSNumber numberWithInteger:width]];
    }
    return widths;
}

@end
