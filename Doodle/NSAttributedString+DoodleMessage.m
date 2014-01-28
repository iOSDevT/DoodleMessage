//
//  NSAttributedString+DoodleMessage.m
//  DoodleMessage
//
//  Created by Qusic on 3/17/13.
//  Copyright (c) 2013 Qusic. All rights reserved.
//

#import "NSAttributedString+DoodleMessage.h"

@implementation NSAttributedString (DoodleMessage)

+ (NSAttributedString *)attributedString:(NSString *)string withColor:(UIColor *)color
{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithString:string];
    [attributedString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0,string.length)];
    return attributedString;
}

@end
