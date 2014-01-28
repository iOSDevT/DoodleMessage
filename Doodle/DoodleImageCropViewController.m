//
//  DoodleImageCropViewController.m
//  DoodleMessage
//
//  Created by Qusic on 3/24/13.
//  Copyright (c) 2013 Qusic. All rights reserved.
//

#import "DoodleImageCropViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface DoodleImageCropViewController () <UIScrollViewDelegate>

@property(assign) id<DoodleImageCropViewControllerDelegate> delegate;
@property(retain) UIImage *image;
@property(retain) UIScrollView *mainView;
@property(retain) UIImageView *imageView;

@end

@implementation DoodleImageCropViewController

- (id)initWithDelegate:(id<DoodleImageCropViewControllerDelegate>)delegate image:(UIImage *)image
{
    self = [super init];
    if (self) {
        _delegate = delegate;
        _image = image;
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    self.title = @"Move and Scale";
    self.toolbarItems = @[[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)],
                          [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL],
                          [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)]
                          ];
    self.navigationController.toolbarHidden = NO;
    
    //Image Orientation Fix
    UIGraphicsBeginImageContextWithOptions(_image.size, YES, _image.scale);
    [_image drawAtPoint:CGPointZero];
    UIImage *fixedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    _image = fixedImage;
    
    UIImageView *imageView = [[UIImageView alloc]initWithImage:_image];
    imageView.image = _image;
    imageView.userInteractionEnabled = YES;
    imageView.multipleTouchEnabled = YES;
    _imageView = imageView;
    UIScrollView *mainView = [[UIScrollView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    mainView.delegate = self;
    mainView.backgroundColor = [UIColor whiteColor];
    mainView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    mainView.contentSize = _imageView.frame.size;
    mainView.alwaysBounceHorizontal = YES;
    mainView.alwaysBounceVertical = YES;
    mainView.minimumZoomScale = 0.1;
    mainView.maximumZoomScale = 10.0;
    mainView.zoomScale = [UIScreen mainScreen].bounds.size.width / _image.size.width;
    [mainView addSubview:_imageView];
    _mainView = mainView;
    self.view = _mainView;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _imageView;
}

- (void)cancelAction:(UIBarButtonItem *)buttonItem
{
    [self finishWithImage:nil];
}

- (void)doneAction:(UIBarButtonItem *)buttonItem
{
    [self finishWithImage:[self getCroppedImage]];
}

- (UIImage *)getCroppedImage
{
    //Crop
    CGFloat scale = 1.0 / _mainView.zoomScale;
    CGRect cropRect = CGRectMake(_mainView.contentOffset.x * scale,
                                 _mainView.contentOffset.y * scale,
                                 _mainView.bounds.size.width * scale,
                                 _mainView.bounds.size.height * scale);
    CGImageRef cgImage = CGImageCreateWithImageInRect([_image CGImage], cropRect);
    UIImage *croppedImage = [[UIImage alloc]initWithCGImage:cgImage scale:_image.scale * scale orientation:_image.imageOrientation];
    CGImageRelease(cgImage);
    
    //Resize
    UIGraphicsBeginImageContextWithOptions(croppedImage.size, YES, 0.0);
    [croppedImage drawAtPoint:CGPointZero];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //Fill Blank
    CGRect imageRect = _mainView.bounds;
    UIGraphicsBeginImageContextWithOptions(imageRect.size, YES, 0.0);
    [[UIColor whiteColor]set];
    UIRectFill(imageRect);
    [resizedImage drawAtPoint:CGPointZero];
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return finalImage;
}

- (void)finishWithImage:(UIImage *)image
{
    [self.delegate doodleImageCrop:self didFinishWithImage:image];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [_imageView setNeedsDisplay];
}

@end
