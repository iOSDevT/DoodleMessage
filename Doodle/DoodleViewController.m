//
//  DoodleViewController.m
//  DoodleMessage
//
//  Created by Qusic on 3/17/13.
//  Copyright (c) 2013 Qusic. All rights reserved.
//

#import "DoodleViewController.h"
#import "DoodleView.h"
#import "DoodleImageCropViewController.h"
#import "NSAttributedString+DoodleMessage.h"
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/MobileCoreServices.h>

#define PreferencesPlist @"/var/mobile/Library/Preferences/me.qusic.doodlemessage.plist"
#define LastStrokeTypeKey @"LastStrokeType"
#define LastStrokeColorKey @"LastStrokeColor"
#define LastStrokeWidthKey @"LastStrokeWidth"

@interface DoodleViewController () <UIPickerViewDataSource, UIPickerViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, DoodleImageCropViewControllerDelegate>

@property(assign) id<DoodleViewControllerDelegate> delegate;

@property(retain) DoodleView *doodleView;
@property(retain) UIImageView *backgroundView;

@property(retain) UIPickerView *pickerView;
@property(retain) UIActionSheet *configView;
@property(retain) UIPopoverController *configPopover;

@property(retain) UIActionSheet *clearActionSheet;
@property(retain) UIActionSheet *photoActionSheet;
@property(retain) UIActionSheet *moreActionSheet;

@property(retain) UIImagePickerController *photoPicker;
@property(retain) UIPopoverController *photoPickerPopover;

@end

@implementation DoodleViewController

- (id)initWithDelegate:(id<DoodleViewControllerDelegate>)delegate
{
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    self.title = @"Doodle";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
    self.toolbarItems = @[[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(configAction:)],
                          [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL],
                          [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self action:@selector(undoAction:)],
                          [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL],
                          [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(redoAction:)],
                          [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL],
                          [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(clearAction:)],
                          [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL],
                          [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(photoAction:)],
                          [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL],
                          [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(moreAction:)]
                          ];
    self.navigationController.toolbarHidden = NO;
    
    UIView *mainView = [[UIView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    mainView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UIImageView *backgroundView = [[UIImageView alloc]initWithFrame:mainView.frame];
    backgroundView.backgroundColor = [UIColor whiteColor];
    backgroundView.contentMode = UIViewContentModeTopLeft;
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _backgroundView = backgroundView;
    DoodleView *doodleView = [[DoodleView alloc]initWithFrame:mainView.frame];
    doodleView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    doodleView.backgroundView = _backgroundView;
    _doodleView = doodleView;
    [mainView addSubview:_backgroundView];
    [mainView addSubview:_doodleView];
    self.view = mainView;
    
    UIPickerView *pickerView = [[UIPickerView alloc]initWithFrame:CGRectMake(0, 40, 0, 0)];
    pickerView.delegate = self;
    pickerView.dataSource = self;
    pickerView.showsSelectionIndicator = YES;
    _pickerView = pickerView;
    
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:@"Done"]];
    segmentedControl.momentary = YES;
    segmentedControl.frame = CGRectMake(260, 7.0f, 50.0f, 30.0f);
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    segmentedControl.tintColor = [UIColor blackColor];
    [segmentedControl addTarget:self action:@selector(dismissConfigView) forControlEvents:UIControlEventValueChanged];
    
    UIActionSheet *configView = [[UIActionSheet alloc]initWithTitle:nil delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    configView.actionSheetStyle = UIActionSheetStyleAutomatic;
    [configView addSubview:pickerView];
    [configView addSubview:segmentedControl];
    configView.bounds = CGRectMake(0, 0, 320, 485);
    _configView = configView;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIViewController *popoverContentViewController = [[UIViewController alloc]init];
        popoverContentViewController.view = _configView;
        popoverContentViewController.contentSizeForViewInPopover = CGSizeMake(320, 256);
        _configPopover = [[UIPopoverController alloc]initWithContentViewController:popoverContentViewController];
    }
    
    UIActionSheet *clearActionSheet = [[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Clear" otherButtonTitles:nil];
    clearActionSheet.tag = 0;
    _clearActionSheet = clearActionSheet;
    UIActionSheet *photoActionSheet = [[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo to Insert", @"Insert Existing Photo", @"Remove Photo", nil];
    photoActionSheet.tag = 1;
    _photoActionSheet = photoActionSheet;
    UIActionSheet *moreActionSheet = [[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"@QusicS on Twitter", @"Donate", nil];
    moreActionSheet.tag = 2;
    _moreActionSheet = moreActionSheet;
    
    UIImagePickerController *pickerController = [[UIImagePickerController alloc]init];
    pickerController.delegate = self;
    pickerController.mediaTypes = @[(NSString *)kUTTypeImage];
    pickerController.allowsEditing = NO;
    _photoPicker = pickerController;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _photoPickerPopover = [[UIPopoverController alloc]initWithContentViewController:_photoPicker];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:PreferencesPlist];
    StrokeType lastStrokeType = [[preferences objectForKey:LastStrokeTypeKey]integerValue];
    NSInteger lastStrokeColor = [[preferences objectForKey:LastStrokeColorKey]integerValue];
    NSInteger lastStrokeWidth = [[preferences objectForKey:LastStrokeWidthKey]integerValue];
    _doodleView.strokeType = lastStrokeType;
    _doodleView.strokeColor = lastStrokeColor;
    _doodleView.strokeWidth = lastStrokeWidth;
    [_pickerView selectRow:lastStrokeType inComponent:0 animated:NO];
    [_pickerView selectRow:lastStrokeColor inComponent:1 animated:NO];
    [_pickerView selectRow:lastStrokeWidth inComponent:2 animated:NO];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    NSMutableDictionary *preferences = [NSMutableDictionary dictionary];
    [preferences addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:PreferencesPlist]];
    [preferences setObject:[NSNumber numberWithInteger:_doodleView.strokeType] forKey:LastStrokeTypeKey];
    [preferences setObject:[NSNumber numberWithInteger:_doodleView.strokeColor] forKey:LastStrokeColorKey];
    [preferences setObject:[NSNumber numberWithInteger:_doodleView.strokeWidth] forKey:LastStrokeWidthKey];
    [preferences writeToFile:PreferencesPlist atomically:YES];
}

- (void)cancelAction:(UIBarButtonItem *)buttonItem
{
    [self finishWithImage:nil];
}

- (void)doneAction:(UIBarButtonItem *)buttonItem
{
    [self finishWithImage:[self getDoodleImage]];
}

- (UIImage *)getDoodleImage
{
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, YES, 0.0);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)finishWithImage:(UIImage *)image
{
    [self.delegate doodle:self didFinishWithImage:image];
}

- (void)configAction:(UIBarButtonItem *)buttonItem
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [_configView showFromBarButtonItem:buttonItem animated:YES];
        [UIView animateWithDuration:0.25 animations:^{
            CGRect bounds = _configView.bounds;
            bounds.size.height = 485;
            _configView.bounds = bounds;
        }];
    } else {
        [_configPopover presentPopoverFromBarButtonItem:buttonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void)dismissConfigView
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [_configView dismissWithClickedButtonIndex:0 animated:YES];
    } else {
        [_configPopover dismissPopoverAnimated:YES];
    }
}

- (void)undoAction:(UIBarButtonItem *)buttonItem
{
    [_doodleView undo];
}

- (void)redoAction:(UIBarButtonItem *)buttonItem
{
    [_doodleView redo];
}

- (void)clearAction:(UIBarButtonItem *)buttonItem
{
    [_clearActionSheet showFromBarButtonItem:buttonItem animated:YES];
}

- (void)photoAction:(UIBarButtonItem *)buttonItem
{
    [_photoActionSheet showFromBarButtonItem:buttonItem animated:YES];
}

- (void)moreAction:(UIBarButtonItem *)buttonItem
{
    [_moreActionSheet showFromBarButtonItem:buttonItem animated:YES];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 3;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    NSInteger number = 0;
    switch (component) {
        case 0:
            number = 4;
            break;
        case 1:
            number = [DoodleView builtinColors].count;
            break;
        case 2:
            number = [DoodleView builtinWidths].count;
            break;
        default:
            break;
    }
    return number;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    CGFloat width = 0.f;
    switch (component) {
        case 0:
            width = 120.f;
            break;
        case 1:
            width = iOS7() ? 103.f : 98.f;
            break;
        case 2:
            width = 43.f;
            break;
        default:
            break;
    }
    return width;
}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSAttributedString *attributedString = nil;
    switch (component) {
        case 0:
            switch (row) {
                case 0:
                    attributedString = [NSAttributedString attributedString:@"Draw" withColor:[UIColor blackColor]];
                    break;
                case 1:
                    attributedString = [NSAttributedString attributedString:@"Highlight" withColor:[UIColor blackColor]];
                    break;
                case 2:
                    attributedString = [NSAttributedString attributedString:@"Fill" withColor:[UIColor blackColor]];
                    break;
                case 3:
                    attributedString = [NSAttributedString attributedString:@"Erase" withColor:[UIColor blackColor]];
                    break;
                default:
                    break;
            }
            break;
        case 1:
            attributedString = [NSAttributedString attributedString:@"████" withColor:[DoodleView builtinColors][row]];
            break;
        case 2:
            attributedString = [NSAttributedString attributedString:[[DoodleView builtinWidths][row]stringValue] withColor:[UIColor blackColor]];
            break;
        default:
            break;
    }
    return attributedString;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    switch (component) {
        case 0:
            _doodleView.strokeType = row;
            break;
        case 1:
            _doodleView.strokeColor = row;
            break;
        case 2:
            _doodleView.strokeWidth = row;
            break;
        default:
            break;
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case 0:
            switch (buttonIndex) {
                case 0:
                    [_doodleView clear];
                    break;
                default:
                    break;
            }
            break;
        case 1:
            switch (buttonIndex) {
                case 0:
                    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                        _photoPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                            [self presentViewController:_photoPicker animated:YES completion:NULL];
                        } else {
                            [_photoPickerPopover presentPopoverFromBarButtonItem:self.toolbarItems[8] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                        }
                    }
                    break;
                case 1:
                    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
                        _photoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                            [self presentViewController:_photoPicker animated:YES completion:NULL];
                        } else {
                            [_photoPickerPopover presentPopoverFromBarButtonItem:self.toolbarItems[8] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                        }
                    }
                    break;
                case 2:
                    [_doodleView clear];
                    _backgroundView.image = nil;
                    break;
                default:
                    break;
            }
            break;
        case 2:
            switch (buttonIndex) {
                case 0:
                    [self finishWithImage:nil];
                    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"http://twitter.com/QusicS"]];
                    break;
                case 1:
                    [self finishWithImage:nil];
                    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=PJ93RW7TLKZZ4"]];
                    break;
                default:
                    break;
            }
            break;
        default:
            break;
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    DoodleImageCropViewController *imageCropViewController = [[DoodleImageCropViewController alloc]initWithDelegate:self image:[info objectForKey:UIImagePickerControllerOriginalImage]];
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:imageCropViewController];
    navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self presentViewController:navigationController animated:YES completion:NULL];
        }];
    } else {
        [_photoPickerPopover dismissPopoverAnimated:YES];
        [self presentViewController:navigationController animated:YES completion:NULL];
    }
}

- (void)doodleImageCrop:(DoodleImageCropViewController *)doodleImageCropViewController didFinishWithImage:(UIImage *)image
{
    if (image != nil) {
        [_doodleView clear];
        _backgroundView.image = image;
    }
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [_doodleView setNeedsDisplay];
    [_backgroundView setNeedsDisplay];
}

@end
