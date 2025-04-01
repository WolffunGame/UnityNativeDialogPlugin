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
        @try {
            if (msg == NULL) {
                NSLog(@"Error: message is NULL in _showSelectDialog");
                return -1;
            }
            return [[UNDialogManager sharedManager]
                    showSelectDialog:[NSString stringWithUTF8String:msg]];
        } @catch (NSException *exception) {
            NSLog(@"Exception in _showSelectDialog: %@", exception.reason);
            return -1;
        }
    }
    
    int _showSelectTitleDialog(const char *title, const char *msg) {
        @try {
            if (msg == NULL) {
                NSLog(@"Error: message is NULL in _showSelectTitleDialog");
                return -1;
            }
            NSString *titleStr = (title != NULL) ? [NSString stringWithUTF8String:title] : nil;
            return [[UNDialogManager sharedManager]
                    showSelectDialog:titleStr
                    message:[NSString stringWithUTF8String:msg]];
        } @catch (NSException *exception) {
            NSLog(@"Exception in _showSelectTitleDialog: %@", exception.reason);
            return -1;
        }
    }
    
    int _showSubmitDialog(const char *msg) {
        @try {
            if (msg == NULL) {
                NSLog(@"Error: message is NULL in _showSubmitDialog");
                return -1;
            }
            return [[UNDialogManager sharedManager]
                    showSubmitDialog:[NSString stringWithUTF8String:msg]];
        } @catch (NSException *exception) {
            NSLog(@"Exception in _showSubmitDialog: %@", exception.reason);
            return -1;
        }
    }
    
    int _showSubmitTitleDialog(const char *title, const char *msg) {
        @try {
            if (msg == NULL) {
                NSLog(@"Error: message is NULL in _showSubmitTitleDialog");
                return -1;
            }
            NSString *titleStr = (title != NULL) ? [NSString stringWithUTF8String:title] : nil;
            return [[UNDialogManager sharedManager]
                    showSubmitDialog:titleStr
                    message:[NSString stringWithUTF8String:msg]];
        } @catch (NSException *exception) {
            NSLog(@"Exception in _showSubmitTitleDialog: %@", exception.reason);
            return -1;
        }
    }
    
    void _dissmissDialog(const int theID){
        @try {
            [[UNDialogManager sharedManager] dissmissDialog:theID];
        } @catch (NSException *exception) {
            NSLog(@"Exception in _dissmissDialog: %@", exception.reason);
        }
    }

    void _setLabel(const char *decide, const char *cancel, const char *close) {
        @try {
            NSString *decideStr = (decide != NULL) ? [NSString stringWithUTF8String:decide] : @"YES";
            NSString *cancelStr = (cancel != NULL) ? [NSString stringWithUTF8String:cancel] : @"NO";
            NSString *closeStr = (close != NULL) ? [NSString stringWithUTF8String:close] : @"CLOSE";
            
            [[UNDialogManager sharedManager] 
                setLabelTitleWithDecide:decideStr
                                 cancel:cancelStr
                                  close:closeStr];
        } @catch (NSException *exception) {
            NSLog(@"Exception in _setLabel: %@", exception.reason);
        }
    }
}

@implementation UNDialogManager

static UNDialogManager * shardDialogManager;

// Color definitions
#define BACKGROUND_COLOR [UIColor colorWithRed:0.125 green:0.184 blue:0.278 alpha:0.9]
#define BUTTON_COLOR [UIColor colorWithRed:0.231 green:0.533 blue:0.765 alpha:1.0]
#define TITLE_COLOR [UIColor whiteColor]
#define MESSAGE_COLOR [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]
#define BUTTON_TEXT_COLOR [UIColor whiteColor]
#define BORDER_COLOR [UIColor colorWithRed:0.29 green:0.58 blue:0.83 alpha:1.0]

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

// Helper method to customize UIAlertController with a game-like style
- (void)customizeAlertController:(UIAlertController *)alertController titleText:(NSString *)title messageText:(NSString *)message {
    @try {
        if (!alertController) return;
        
        // Access the alert's view to customize it
        if (@available(iOS 13.0, *)) {
            // For iOS 13 and later, we need to use this approach
            UIView *alertView = alertController.view;
            
            // Apply background appearance
            alertView.backgroundColor = BACKGROUND_COLOR;
            alertView.layer.cornerRadius = 15;
            alertView.layer.borderWidth = 2.0;
            alertView.layer.borderColor = BORDER_COLOR.CGColor;
            
            // Style the title and message labels
            if (title) {
                NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
                [attributedTitle addAttribute:NSForegroundColorAttributeName value:TITLE_COLOR range:NSMakeRange(0, attributedTitle.length)];
                [attributedTitle addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:20] range:NSMakeRange(0, attributedTitle.length)];
                [alertController setValue:attributedTitle forKey:@"attributedTitle"];
            }
            
            if (message) {
                NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:message];
                [attributedMessage addAttribute:NSForegroundColorAttributeName value:MESSAGE_COLOR range:NSMakeRange(0, attributedMessage.length)];
                [attributedMessage addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16] range:NSMakeRange(0, attributedMessage.length)];
                [alertController setValue:attributedMessage forKey:@"attributedMessage"];
            }
            
            // Find and style all action buttons
            for (UIAlertAction *action in alertController.actions) {
                [action setValue:BUTTON_TEXT_COLOR forKey:@"titleTextColor"];
                
                // Try to make buttons more prominent if possible
                if ([alertController valueForKey:@"alertController"] && [[alertController valueForKey:@"alertController"] respondsToSelector:NSSelectorFromString(@"setPreferredAction:")]) {
                    [[alertController valueForKey:@"alertController"] performSelector:NSSelectorFromString(@"setPreferredAction:") withObject:action];
                }
            }
        } else {
            // Fallback for older iOS versions
            if (title) {
                NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
                [attributedTitle addAttribute:NSForegroundColorAttributeName value:TITLE_COLOR range:NSMakeRange(0, attributedTitle.length)];
                [attributedTitle addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:20] range:NSMakeRange(0, attributedTitle.length)];
                [alertController setValue:attributedTitle forKey:@"attributedTitle"];
            }
            
            if (message) {
                NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:message];
                [attributedMessage addAttribute:NSForegroundColorAttributeName value:MESSAGE_COLOR range:NSMakeRange(0, attributedMessage.length)];
                [attributedMessage addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16] range:NSMakeRange(0, attributedMessage.length)];
                [alertController setValue:attributedMessage forKey:@"attributedMessage"];
            }
            
            for (UIAlertAction *action in alertController.actions) {
                [action setValue:BUTTON_COLOR forKey:@"titleTextColor"];
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"Exception in customizeAlertController: %@", exception.reason);
    }
}

// Create styled action for alerts with proper styling
- (UIAlertAction *)createStyledAction:(NSString *)title handler:(void (^)(UIAlertAction *))handler {
    UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:handler];
    [action setValue:BUTTON_COLOR forKey:@"titleTextColor"];
    return action;
}

- (int) showSelectDialog:(NSString *)msg {
    return [self showSelectDialog:nil message:msg];
}

- (int) showSelectDialog:(NSString *)title message:(NSString*)msg {
    @try {
        ++_id;
        
        __block int currentID = _id;
        __weak UNDialogManager *weakSelf = self;  // Use weak reference to avoid retain cycle
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                UNDialogManager *strongSelf = weakSelf;
                if (!strongSelf) return;  // Safety check
                
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title 
                                                                                         message:msg 
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                
                // Create the actions with styling
                UIAlertAction *cancelAction = [strongSelf createStyledAction:strongSelf->cancelLabel handler:^(UIAlertAction * _Nonnull action) {
                    @try {
                        UNDialogManager *innerStrongSelf = weakSelf;
                        if (!innerStrongSelf) return;
                        
                        NSString *tag = [NSString stringWithFormat:@"%d", currentID];
                        UnitySendMessage("DialogManager", "OnCancel", tag.UTF8String);
                        [innerStrongSelf->alerts removeObjectForKey:@(currentID)];
                    } @catch (NSException *exception) {
                        NSLog(@"Exception in cancel action handler: %@", exception.reason);
                    }
                }];
                
                UIAlertAction *confirmAction = [strongSelf createStyledAction:strongSelf->decideLabel handler:^(UIAlertAction * _Nonnull action) {
                    @try {
                        UNDialogManager *innerStrongSelf = weakSelf;
                        if (!innerStrongSelf) return;
                        
                        NSString *tag = [NSString stringWithFormat:@"%d", currentID];
                        UnitySendMessage("DialogManager", "OnSubmit", tag.UTF8String);
                        [innerStrongSelf->alerts removeObjectForKey:@(currentID)];
                    } @catch (NSException *exception) {
                        NSLog(@"Exception in confirm action handler: %@", exception.reason);
                    }
                }];
                
                [alertController addAction:cancelAction];
                [alertController addAction:confirmAction];
                
                // Apply custom styling
                [strongSelf customizeAlertController:alertController titleText:title messageText:msg];
                
                // Present the controller
                UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
                if (!rootViewController) {
                    NSLog(@"No root view controller found");
                    return;
                }
                
                [rootViewController presentViewController:alertController animated:YES completion:nil];
                strongSelf->alerts[@(currentID)] = alertController;
            } @catch (NSException *exception) {
                NSLog(@"Exception in showSelectDialog UI thread: %@", exception.reason);
            }
        });
        
        return _id;
    } @catch (NSException *exception) {
        NSLog(@"Exception in showSelectDialog: %@", exception.reason);
        return -1;
    }
}

- (int) showSubmitDialog:(NSString *)msg {
    return [self showSubmitDialog:nil message:msg];
}

- (int) showSubmitDialog:(NSString *)title message:(NSString*)msg {
    @try {
        ++_id;
        
        __block int currentID = _id;
        __weak UNDialogManager *weakSelf = self;  // Use weak reference to avoid retain cycle
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                UNDialogManager *strongSelf = weakSelf;
                if (!strongSelf) return;  // Safety check
                
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title 
                                                                                         message:msg 
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                
                // Create action with styling
                UIAlertAction *closeAction = [strongSelf createStyledAction:strongSelf->closeLabel handler:^(UIAlertAction * _Nonnull action) {
                    @try {
                        UNDialogManager *innerStrongSelf = weakSelf;
                        if (!innerStrongSelf) return;
                        
                        NSString *tag = [NSString stringWithFormat:@"%d", currentID];
                        UnitySendMessage("DialogManager", "OnSubmit", tag.UTF8String);
                        [innerStrongSelf->alerts removeObjectForKey:@(currentID)];
                    } @catch (NSException *exception) {
                        NSLog(@"Exception in close action handler: %@", exception.reason);
                    }
                }];
                
                [alertController addAction:closeAction];
                
                // Apply custom styling
                [strongSelf customizeAlertController:alertController titleText:title messageText:msg];
                
                // Present the controller
                UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
                if (!rootViewController) {
                    NSLog(@"No root view controller found");
                    return;
                }
                
                [rootViewController presentViewController:alertController animated:YES completion:nil];
                strongSelf->alerts[@(currentID)] = alertController;
            } @catch (NSException *exception) {
                NSLog(@"Exception in showSubmitDialog UI thread: %@", exception.reason);
            }
        });
        
        return _id;
    } @catch (NSException *exception) {
        NSLog(@"Exception in showSubmitDialog: %@", exception.reason);
        return -1;
    }
}

- (void) dissmissDialog:(int)theID {
    @try {
        __weak UNDialogManager *weakSelf = self;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                UNDialogManager *strongSelf = weakSelf;
                if (!strongSelf) return;
                
                UIAlertController *alertController = strongSelf->alerts[@(theID)];
                if (alertController) {
                    [alertController dismissViewControllerAnimated:YES completion:nil];
                    [strongSelf->alerts removeObjectForKey:@(theID)];
                }
            } @catch (NSException *exception) {
                NSLog(@"Exception in dissmissDialog UI thread: %@", exception.reason);
            }
        });
    } @catch (NSException *exception) {
        NSLog(@"Exception in dissmissDialog: %@", exception.reason);
    }
}

- (void) setLabelTitleWithDecide:(NSString*)decide cancel:(NSString*)cancel close:(NSString*) close {
    @try {
        if (decide) {
            decideLabel = [decide copy];
        }
        if (cancel) {
            cancelLabel = [cancel copy];
        }
        if (close) {
            closeLabel = [close copy];
        }
    } @catch (NSException *exception) {
        NSLog(@"Exception in setLabelTitleWithDecide: %@", exception.reason);
    }
}

@end