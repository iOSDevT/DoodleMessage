//
//  NSAttributedString+DoodleMessage.h
//  DoodleMessage
//
//  Created by Qusic on 3/17/13.
//  Copyright (c) 2013 Qusic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSAttributedString (DoodleMessage)

+ (NSAttributedString *)attributedString:(NSString *)string withColor:(UIColor *)color;

@end
