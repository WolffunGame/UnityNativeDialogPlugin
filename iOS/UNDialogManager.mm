//
//  UNDialogManager.m
//  UnityDialogPlugin
//
//  Created by ibu on 12/10/09.
//  Copyright (c) 2012年 kayac. All rights reserved.
//

#import "UNDialogManager.h"

#define MakeStringCopy( _x_ ) ( _x_ != NULL && [_x_ isKindOfClass:[NSString class]] ) ? strdup( [_x_ UTF8String] ) : NULL

extern void UnitySendMessage(const char *, const char *, const char *);

extern "C" {
    int _showSelectDialog(const char *msg) {
        return [[UNDialogManager sharedManager]
                showSelectDialog:[NSString stringWithUTF8String:msg]];
    }
    
    int _showSelectTitleDialog(const char *title, const char *msg) {
        return [[UNDialogManager sharedManager]
                showSelectDialog:[NSString stringWithUTF8String:title]
                message:[NSString stringWithUTF8String:msg]];
    }
    
    int _showSubmitDialog(const char *msg) {
        return [[UNDialogManager sharedManager]
                showSubmitDialog:[NSString stringWithUTF8String:msg]];
    }
    
    int _showSubmitTitleDialog(const char *title, const char *msg) {
        return [[UNDialogManager sharedManager]
                showSubmitDialog:[NSString stringWithUTF8String:title]
                message:[NSString stringWithUTF8String:msg]];
    }
    
    void _dissmissDialog(const int theID){
        [[UNDialogManager sharedManager] dissmissDialog:theID];
    }

    void _setLabel(const char *decide, const char *cancel, const char *close) {
        [[UNDialogManager sharedManager] 
            setLabelTitleWithDecide:[NSString stringWithUTF8String:decide]
                             cancel:[NSString stringWithUTF8String:cancel]
                              close:[NSString stringWithUTF8String:close]];
    }
}



@implementation UNDialogManager

static UNDialogManager * shardDialogManager;

// Color constants
static UIColor *const kBackgroundColor = nil;
static UIColor *const kButtonColor = nil;
static UIColor *const kTextColor = nil;

+ (void)initialize {
    if (self == [UNDialogManager class]) {
        kBackgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.25 alpha:0.95];
        kButtonColor = [UIColor colorWithRed:0.231 green:0.533 blue:0.765 alpha:1.0]; // Clash Royale blue
        kTextColor = [UIColor whiteColor];
    }
}

+ (UNDialogManager*) sharedManager {
    @synchronized(self) {
        if(shardDialogManager == nil) {
            shardDialogManager = [[self alloc] init];
        }
    }
    return shardDialogManager;
}

- (id) init {
    self = [super init];
    if (self) {
        alerts = [NSMutableDictionary dictionary];
        decideLabel = @"YES";
        cancelLabel = @"NO";
        closeLabel = @"CLOSE";
    }
    return self;
}

// Create custom styled game-like alerts for iOS
- (UIAlertController *)createGameStyleAlert:(NSString *)title message:(NSString *)message hasCancel:(BOOL)hasCancel {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    // Customize alert appearance - iOS 13+ way of styling
    // This works by applying a custom view controller presentation style
    if (@available(iOS 13.0, *)) {
        alertController.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    }
    
    // Set up appearance
    UIView *firstSubview = alertController.view.subviews.firstObject;
    UIView *alertContentView = firstSubview.subviews.firstObject;
    alertContentView.backgroundColor = kBackgroundColor;
    alertContentView.layer.cornerRadius = 15;
    alertContentView.layer.masksToBounds = YES;
    
    // Add border to make it stand out
    alertContentView.layer.borderWidth = 1.5;
    alertContentView.layer.borderColor = [UIColor colorWithWhite:0.3 alpha:0.8].CGColor;
    
    // Add subtle shadow
    alertController.view.layer.shadowColor = [UIColor blackColor].CGColor;
    alertController.view.layer.shadowOffset = CGSizeMake(0, 4);
    alertController.view.layer.shadowRadius = 10;
    alertController.view.layer.shadowOpacity = 0.3;
    
    // Change text colors
    NSMutableAttributedString *attributedTitle = nil;
    if (title && title.length > 0) {
        attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
        [attributedTitle addAttribute:NSForegroundColorAttributeName
                                value:kTextColor
                                range:NSMakeRange(0, attributedTitle.length)];
        [attributedTitle addAttribute:NSFontAttributeName
                                value:[UIFont boldSystemFontOfSize:20]
                                range:NSMakeRange(0, attributedTitle.length)];
    }
    
    NSMutableAttributedString *attributedMessage = nil;
    if (message && message.length > 0) {
        attributedMessage = [[NSMutableAttributedString alloc] initWithString:message];
        [attributedMessage addAttribute:NSForegroundColorAttributeName
                                  value:kTextColor
                                  range:NSMakeRange(0, attributedMessage.length)];
        [attributedMessage addAttribute:NSFontAttributeName
                                  value:[UIFont systemFontOfSize:16]
                                  range:NSMakeRange(0, attributedMessage.length)];
    }
    
    if (attributedTitle) {
        [alertController setValue:attributedTitle forKey:@"attributedTitle"];
    }
    
    if (attributedMessage) {
        [alertController setValue:attributedMessage forKey:@"attributedMessage"];
    }
    
    return alertController;
}

- (int) showSelectDialog:(NSString *)msg {
    return [self showSelectDialog:nil message:msg];
}

- (int) showSelectDialog:(NSString *)title message:(NSString*)msg {
    ++_id;
    
    UIAlertController *alertController = [self createGameStyleAlert:title message:msg hasCancel:YES];
    
    // Add visual separator between buttons and message
    UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, alertController.view.bounds.size.width, 1)];
    separatorView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    [alertController.view addSubview:separatorView];
    
    // Create the actions with game-like styling
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelLabel
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
        @try {
            NSString *tag = [NSString stringWithFormat:@"%d", _id];
            UnitySendMessage("DialogManager", "OnCancel", tag.UTF8String);
            [alerts removeObjectForKey:@(_id)];
        } @catch (NSException *exception) {
            NSLog(@"Exception in dialog cancel: %@", exception.reason);
        }
    }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:decideLabel
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
        @try {
            NSString *tag = [NSString stringWithFormat:@"%d", _id];
            UnitySendMessage("DialogManager", "OnSubmit", tag.UTF8String);
            [alerts removeObjectForKey:@(_id)];
        } @catch (NSException *exception) {
            NSLog(@"Exception in dialog confirm: %@", exception.reason);
        }
    }];
    
    // Change text color of buttons to Clash Royale blue
    [cancelAction setValue:kButtonColor forKey:@"titleTextColor"];
    [confirmAction setValue:kButtonColor forKey:@"titleTextColor"];
    
    // Bold the text on buttons
    [cancelAction setValue:[UIFont boldSystemFontOfSize:17] forKey:@"titleTextFont"];
    [confirmAction setValue:[UIFont boldSystemFontOfSize:17] forKey:@"titleTextFont"];
    
    [alertController addAction:cancelAction];
    [alertController addAction:confirmAction];
    
    // Present the controller
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:alertController animated:YES completion:nil];
    
    alerts[@(_id)] = alertController;
    return _id;
}

- (int) showSubmitDialog:(NSString *)msg {
    return [self showSubmitDialog:nil message:msg];
}

- (int) showSubmitDialog:(NSString *)title message:(NSString*)msg {
    ++_id;
    
    UIAlertController *alertController = [self createGameStyleAlert:title message:msg hasCancel:NO];
    
    // Add visual separator between buttons and message
    UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, alertController.view.bounds.size.width, 1)];
    separatorView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    [alertController.view addSubview:separatorView];
    
    // Create the action with game-like styling
    UIAlertAction *closeAction = [UIAlertAction actionWithTitle:closeLabel
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
        @try {
            NSString *tag = [NSString stringWithFormat:@"%d", _id];
            UnitySendMessage("DialogManager", "OnSubmit", tag.UTF8String);
            [alerts removeObjectForKey:@(_id)];
        } @catch (NSException *exception) {
            NSLog(@"Exception in dialog action: %@", exception.reason);
        }
    }];
    
    // Change text color of button to Clash Royale blue
    [closeAction setValue:kButtonColor forKey:@"titleTextColor"];
    
    // Bold the text on button
    [closeAction setValue:[UIFont boldSystemFontOfSize:17] forKey:@"titleTextFont"];
    
    [alertController addAction:closeAction];
    
    // Center the action button
    if (@available(iOS 9.0, *)) {
        alertController.preferredAction = closeAction;
    }
    
    // Present the controller with animation
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    // Add a subtle animation
    alertController.view.alpha = 0.0;
    [rootViewController presentViewController:alertController animated:NO completion:^{
        [UIView animateWithDuration:0.3 animations:^{
            alertController.view.alpha = 1.0;
        }];
    }];
    
    alerts[@(_id)] = alertController;
    return _id;
}

- (void) dissmissDialog:(int)theID {
    UIAlertController *alertController = alerts[@(theID)];
    if (alertController) {
        [alertController dismissViewControllerAnimated:YES completion:nil];
        [alerts removeObjectForKey:@(theID)];
    }
}

- (void) setLabelTitleWithDecide:(NSString*)decide cancel:(NSString*)cancel close:(NSString*) close {
    decideLabel = [decide copy];
    cancelLabel = [cancel copy];
    closeLabel = [close copy];
}

@end