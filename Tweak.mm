#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CaptainHook.h>
#import "Doodle/DoodleViewController.h"

#pragma mark - Headers

#pragma mark Messages, biteSMS

@interface UIActionSheet ()
- (NSMutableArray *)buttons;
@end

@interface CKMessagePart : NSObject
@end

@interface CKMediaObject : NSObject
@end

@interface CKMediaObjectManager : NSObject
+ (id)sharedInstance;
- (CKMediaObject *)mediaObjectWithData:(NSData *)data UTIType:(NSString *)utiType filename:(NSString *)filename transcoderUserInfo:(id)transcoderUserInfo; // iOS 7
- (CKMediaObject *)newMediaObjectForData:(NSData *)data mimeType:(NSString *)mimeType exportedFilename:(NSString *)exportedFilename; // iOS 6
@end

@interface CKMediaObjectMessagePart : CKMessagePart
@property(readonly, nonatomic) CKMediaObject *mediaObject;
@property(copy, nonatomic) NSArray *composeImages;
- (id)initWithMediaObject:(CKMediaObject *)mediaObject;
@end

@interface CKTranscriptController : UIViewController
- (void)_addPart:(CKMessagePart *)messagePart;
@end

@interface CKTranscriptController (DoodleMessage) <DoodleViewControllerDelegate>
- (void)presentDoodleViewController;
@end

@interface CKMessagesController : UIViewController
@property(retain, nonatomic) CKTranscriptController *transcriptController;
@end

@interface SMSApplication : UIApplication <UIApplicationDelegate> {
    CKMessagesController *_messagesController;
}
@end

@interface BiteApp : UIApplication <UIApplicationDelegate> {
    CKMessagesController *_messagesController;
}
@end

#pragma mark WhatsApp

@interface ChatViewController : UIViewController
- (void)sendImage:(UIImage *)image;
@end

@interface ChatViewController (DoodleMessage) <DoodleViewControllerDelegate>
- (void)presentDoodleViewController;
@end

#pragma mark Facebook Messenger

@interface Photo : NSObject
@property(nonatomic,retain) UIImage *image;
@end

@interface PhotoAttachment : NSObject
@property(nonatomic,retain) Photo *photo;
@end

@interface MNComposeView : UIView {
    UIButton *_attachButton;
}
@end

@interface MNComposeViewController : UIViewController {
    MNComposeView *_composeView;
}
@property(nonatomic,retain) NSMutableArray *outgoingAttachments;
@property(assign,nonatomic) UIViewController *delegate;
- (void)_initComposeViewIfNeeded;
- (void)messageAttachmentPicker:(id)picker didPickMessageAttachments:(NSArray *)attachments;
- (void)composeViewDidPressSend:(id)arg1;
@end

@interface MNComposeViewController (DoodleMessage) <DoodleViewControllerDelegate>
@end

#pragma mark WeChat

@interface MMInputToolView : UIView
@property(retain, nonatomic) UIButton* attachmentButton;
@end

@interface BaseMsgContentViewController : UIViewController
@property(retain, nonatomic) MMInputToolView* toolView;
@end

@interface BaseMsgContentLogicController : NSObject
- (BaseMsgContentViewController *)getMsgContentViewController;
- (void)SendImageMessage:(UIImage *)image ImageInfo:(id)info;
@end

@interface BaseMsgContentLogicController (DoodleMessage) <DoodleViewControllerDelegate>
- (void)presentDoodleViewController;
@end

#pragma mark - Hooks

#pragma mark Messages, biteSMS

static BOOL DoodleMessageActionSheet;

CHDeclareClass(CKActionSheetManager);

CHOptimizedMethod(1, self, void ,CKActionSheetManager, setActionSheet, UIActionSheet *, actionSheet)
{
    if (DoodleMessageActionSheet && actionSheet != nil) {
        NSInteger i = [actionSheet addButtonWithTitle:@"Doodle"];
        NSMutableArray *buttons = [actionSheet buttons];
        [buttons exchangeObjectAtIndex:i withObjectAtIndex:i-1];
        actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
    }
    CHSuper(1, CKActionSheetManager, setActionSheet, actionSheet);
}

CHOptimizedMethod(2, self, void, CKActionSheetManager, dismissActionSheet, UIActionSheet *, actionSheet, withButtonIndex, NSUInteger, buttonIndex)
{
    if (DoodleMessageActionSheet && buttonIndex == 3) {
        CKTranscriptController * const transcriptController = CHIvar([[UIApplication sharedApplication]delegate], _messagesController, CKMessagesController * const).transcriptController;
        [transcriptController presentDoodleViewController];
    } else {
        CHSuper(2, CKActionSheetManager, dismissActionSheet, actionSheet, withButtonIndex, buttonIndex);
    }
    DoodleMessageActionSheet = NO;
}

CHDeclareClass(CKTranscriptController)

CHOptimizedMethod(1, self, void, CKTranscriptController, addMedia, id, arg)
{
    DoodleMessageActionSheet = YES;
    CHSuper(1, CKTranscriptController, addMedia, arg);
}

CHMethod(0, void, CKTranscriptController, presentDoodleViewController)
{
    DoodleViewController *doodleViewController = [[DoodleViewController alloc]initWithDelegate:self];
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:doodleViewController];
    [self presentViewController:navigationController animated:YES completion:NULL];
}

CHMethod(2, void, CKTranscriptController, doodle, DoodleViewController *, doodleViewController, didFinishWithImage, UIImage *, image)
{
    [self dismissViewControllerAnimated:YES completion:^{
        if (image != nil) {
            CKMediaObjectManager *objectManager = [NSClassFromString(@"CKMediaObjectManager")sharedInstance];
            CKMediaObject *mediaObject = iOS7() ? [objectManager mediaObjectWithData:UIImagePNGRepresentation(image) UTIType:@"public.png" filename:nil transcoderUserInfo:nil] : [objectManager newMediaObjectForData:UIImagePNGRepresentation(image) mimeType:@"image/png" exportedFilename:nil];
            CKMediaObjectMessagePart *messagePart = [[NSClassFromString(@"CKMediaObjectMessagePart") alloc]initWithMediaObject:mediaObject];
            [self _addPart:messagePart];
        }
    }];
}

#pragma mark WhatsApp

CHDeclareClass(ChatViewController)

CHOptimizedMethod(1, self, void, ChatViewController, setButtonSendMedia, UIButton *, button)
{
    UIGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(sendMediaButtonLongPressed_DoodleMessage:)];
    [button addGestureRecognizer:gestureRecognizer];
    CHSuper(1, ChatViewController, setButtonSendMedia, button);
}

CHMethod(1, void, ChatViewController, sendMediaButtonLongPressed_DoodleMessage, UIGestureRecognizer *, gestureRecognizer)
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self presentDoodleViewController];
    }
}

CHMethod(0, void, ChatViewController, presentDoodleViewController)
{
    DoodleViewController *doodleViewController = [[DoodleViewController alloc]initWithDelegate:self];
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:doodleViewController];
    [self presentViewController:navigationController animated:YES completion:NULL];
}

CHMethod(2, void, ChatViewController, doodle, DoodleViewController *, doodleViewController, didFinishWithImage, UIImage *, image)
{
    [self dismissViewControllerAnimated:YES completion:^{
        if (image != nil) {
            [self sendImage:image];
        }
    }];
}

#pragma mark Facebook Messenger

CHDeclareClass(MNComposeViewController)

CHOptimizedMethod(0, self, void, MNComposeViewController, _initComposeViewIfNeeded)
{
    CHSuper(0, MNComposeViewController, _initComposeViewIfNeeded);
    UIButton * const attachButton = CHIvar(CHIvar(self, _composeView, MNComposeView * const), _attachButton, UIButton * const);
    if (attachButton.gestureRecognizers.count == 0) {
        UIGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(attachButtonLongPressed_DoodleMessage:)];
        [attachButton addGestureRecognizer:gestureRecognizer];
    }
}

CHMethod(1, void, MNComposeViewController, attachButtonLongPressed_DoodleMessage, UIGestureRecognizer *, gestureRecognizer)
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        DoodleViewController *doodleViewController = [[DoodleViewController alloc]initWithDelegate:self];
        UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:doodleViewController];
        [self.delegate presentViewController:navigationController animated:YES completion:NULL];
    }
}

CHMethod(2, void, MNComposeViewController, doodle, DoodleViewController *, doodleViewController, didFinishWithImage, UIImage *, image)
{
    [self dismissViewControllerAnimated:YES completion:^{
        if (image != nil) {
            Photo *photo = [[NSClassFromString(@"Photo")alloc]init];
            photo.image = image;
            PhotoAttachment *attachment = [[NSClassFromString(@"PhotoAttachment")alloc]init];
            attachment.photo = photo;

            NSMutableArray *attachments = self.outgoingAttachments;
            if (attachments == nil) {
                attachments = [NSMutableArray array];
            }
            [attachments addObject:attachment];
            [self messageAttachmentPicker:nil didPickMessageAttachments:attachments];
            [self composeViewDidPressSend:nil];
        }
    }];
}

#pragma mark WeChat

CHDeclareClass(BaseMsgContentLogicController)

CHOptimizedMethod(0, self, void, BaseMsgContentLogicController, initViewController)
{
    CHSuper(0, BaseMsgContentLogicController, initViewController);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
        UIGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(attachmentButtonLongPressed_DoodleMessage:)];
        [self.getMsgContentViewController.toolView.attachmentButton addGestureRecognizer:gestureRecognizer];
    });
}

CHMethod(1, void, BaseMsgContentLogicController, attachmentButtonLongPressed_DoodleMessage, UIGestureRecognizer *, gestureRecognizer)
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self presentDoodleViewController];
    }
}

CHMethod(0, void, BaseMsgContentLogicController, presentDoodleViewController)
{
    DoodleViewController *doodleViewController = [[DoodleViewController alloc]initWithDelegate:self];
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:doodleViewController];
    [self.getMsgContentViewController presentViewController:navigationController animated:YES completion:NULL];
}

CHMethod(2, void, BaseMsgContentLogicController, doodle, DoodleViewController *, doodleViewController, didFinishWithImage, UIImage *, image)
{
    [self.getMsgContentViewController dismissViewControllerAnimated:YES completion:^{
        if (image != nil) {
            [self SendImageMessage:image ImageInfo:nil];
        }
    }];
}

#pragma mark - Constructor

CHConstructor
{
    @autoreleasepool {
        //Messages, biteSMS
        CHLoadLateClass(CKActionSheetManager);
        CHHook(1, CKActionSheetManager, setActionSheet);
        CHHook(2, CKActionSheetManager, dismissActionSheet, withButtonIndex);
        CHLoadLateClass(CKTranscriptController);
        CHHook(1, CKTranscriptController, addMedia);
        CHHook(0, CKTranscriptController, presentDoodleViewController);
        CHHook(2, CKTranscriptController, doodle, didFinishWithImage);

        NSString *application = [NSBundle mainBundle].bundleIdentifier;
        if ([application isEqualToString:@"net.whatsapp.WhatsApp"]) {
            //WhatsApp
            CHLoadLateClass(ChatViewController);
            CHHook(1, ChatViewController, setButtonSendMedia);
            CHHook(1, ChatViewController, sendMediaButtonLongPressed_DoodleMessage);
            CHHook(0, ChatViewController, presentDoodleViewController);
            CHHook(2, ChatViewController, doodle, didFinishWithImage);
        } else if ([application isEqualToString:@"com.facebook.Messenger"]) {
            //Facebook Messenger
            CHLoadLateClass(MNComposeViewController);
            CHHook(0, MNComposeViewController, _initComposeViewIfNeeded);
            CHHook(1, MNComposeViewController, attachButtonLongPressed_DoodleMessage);
            CHHook(2, MNComposeViewController, doodle, didFinishWithImage);
        } else if ([application isEqualToString:@"com.tencent.xin"]) {
            //WeChat
            CHLoadLateClass(BaseMsgContentLogicController);
            CHHook(0, BaseMsgContentLogicController, initViewController);
            CHHook(1, BaseMsgContentLogicController, attachmentButtonLongPressed_DoodleMessage);
            CHHook(0, BaseMsgContentLogicController, presentDoodleViewController);
            CHHook(2, BaseMsgContentLogicController, doodle, didFinishWithImage);
        }
    }
}
