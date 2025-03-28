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

+ (UNDialogManager*) sharedManager {
    @synchronized(self) {
        if(shardDialogManager == nil) {
            shardDialogManager = [[self alloc]init];
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
    
    // Customize alert appearance
    UIView *firstSubview = alertController.view.subviews.firstObject;
    UIView *alertContentView = firstSubview.subviews.firstObject;
    alertContentView.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.25 alpha:0.85];
    alertContentView.layer.cornerRadius = 15;
    
    // Change text colors
    NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title ? title : @""];
    [attributedTitle addAttribute:NSForegroundColorAttributeName
                            value:[UIColor whiteColor]
                            range:NSMakeRange(0, attributedTitle.length)];
    [attributedTitle addAttribute:NSFontAttributeName
                            value:[UIFont boldSystemFontOfSize:20]
                            range:NSMakeRange(0, attributedTitle.length)];
    
    NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:message ? message : @""];
    [attributedMessage addAttribute:NSForegroundColorAttributeName
                              value:[UIColor whiteColor]
                              range:NSMakeRange(0, attributedMessage.length)];
    [attributedMessage addAttribute:NSFontAttributeName
                              value:[UIFont systemFontOfSize:16]
                              range:NSMakeRange(0, attributedMessage.length)];
    
    [alertController setValue:attributedTitle forKey:@"attributedTitle"];
    [alertController setValue:attributedMessage forKey:@"attributedMessage"];
    
    return alertController;
}

- (int) showSelectDialog:(NSString *)msg {
    return [self showSelectDialog:nil message:msg];
}

- (int) showSelectDialog:(NSString *)title message:(NSString*)msg {
    ++_id;
    
    UIAlertController *alertController = [self createGameStyleAlert:title message:msg hasCancel:YES];
    
    // Create the actions with game-like styling
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelLabel
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
        NSString *tag = [NSString stringWithFormat:@"%d", _id];
        UnitySendMessage("DialogManager", "OnCancel", tag.UTF8String);
        [alerts removeObjectForKey:@(_id)];
    }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:decideLabel
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
        NSString *tag = [NSString stringWithFormat:@"%d", _id];
        UnitySendMessage("DialogManager", "OnSubmit", tag.UTF8String);
        [alerts removeObjectForKey:@(_id)];
    }];
    
    // Change text color of buttons to Clash Royale blue
    [cancelAction setValue:[UIColor colorWithRed:0.231 green:0.533 blue:0.765 alpha:1.0] forKey:@"titleTextColor"];
    [confirmAction setValue:[UIColor colorWithRed:0.231 green:0.533 blue:0.765 alpha:1.0] forKey:@"titleTextColor"];
    
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
    
    // Create the action with game-like styling
    UIAlertAction *closeAction = [UIAlertAction actionWithTitle:closeLabel
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
        NSString *tag = [NSString stringWithFormat:@"%d", _id];
        UnitySendMessage("DialogManager", "OnSubmit", tag.UTF8String);
        [alerts removeObjectForKey:@(_id)];
    }];
    
    // Change text color of button to Clash Royale blue
    [closeAction setValue:[UIColor colorWithRed:0.231 green:0.533 blue:0.765 alpha:1.0] forKey:@"titleTextColor"];
    
    [alertController addAction:closeAction];
    
    // Present the controller
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:alertController animated:YES completion:nil];
    
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