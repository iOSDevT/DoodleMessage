//
//  DoodleViewController.h
//  DoodleMessage
//
//  Created by Qusic on 3/17/13.
//  Copyright (c) 2013 Qusic. All rights reserved.
//

#import <UIKit/UIKit.h>

#define iOS7() (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0)

@protocol DoodleViewControllerDelegate;

@interface DoodleViewController : UIViewController

- (id)initWithDelegate:(id<DoodleViewControllerDelegate>)delegate;

@end

@protocol DoodleViewControllerDelegate <NSObject>

@required
- (void)doodle:(DoodleViewController *)doodleViewController didFinishWithImage:(UIImage *)image;

@end
