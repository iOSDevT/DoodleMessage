//
//  DoodleImageCropViewController.h
//  DoodleMessage
//
//  Created by Qusic on 3/24/13.
//  Copyright (c) 2013 Qusic. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DoodleImageCropViewControllerDelegate;

@interface DoodleImageCropViewController : UIViewController

- (id)initWithDelegate:(id<DoodleImageCropViewControllerDelegate>)delegate image:(UIImage *)image;

@end

@protocol DoodleImageCropViewControllerDelegate <NSObject>

@required
- (void)doodleImageCrop:(DoodleImageCropViewController *)doodleImageCropViewController didFinishWithImage:(UIImage *)image;

@end
