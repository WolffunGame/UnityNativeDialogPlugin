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
    @try {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                                 message:message
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        // Customize alert appearance
        UIView *firstSubview = alertController.view.subviews.firstObject;
        UIView *alertContentView = firstSubview.subviews.firstObject;
        alertContentView.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.25 alpha:0.85];
        alertContentView.layer.cornerRadius = 15;
        
        // Change text colors
        if (title) {
            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
            [attributedTitle addAttribute:NSForegroundColorAttributeName
                                    value:[UIColor whiteColor]
                                    range:NSMakeRange(0, attributedTitle.length)];
            [attributedTitle addAttribute:NSFontAttributeName
                                    value:[UIFont boldSystemFontOfSize:20]
                                    range:NSMakeRange(0, attributedTitle.length)];
            [alertController setValue:attributedTitle forKey:@"attributedTitle"];
        }
        
        if (message) {
            NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:message];
            [attributedMessage addAttribute:NSForegroundColorAttributeName
                                      value:[UIColor whiteColor]
                                      range:NSMakeRange(0, attributedMessage.length)];
            [attributedMessage addAttribute:NSFontAttributeName
                                      value:[UIFont systemFontOfSize:16]
                                      range:NSMakeRange(0, attributedMessage.length)];
            [alertController setValue:attributedMessage forKey:@"attributedMessage"];
        }
        
        return alertController;
    } @catch (NSException *exception) {
        NSLog(@"Exception in createGameStyleAlert: %@", exception.reason);
        return nil;
    }
}

- (int) showSelectDialog:(NSString *)msg {
    return [self showSelectDialog:nil message:msg];
}

- (int) showSelectDialog:(NSString *)title message:(NSString*)msg {
    @try {
        ++_id;
        
        __block int currentID = _id;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                UIAlertController *alertController = [self createGameStyleAlert:title message:msg hasCancel:YES];
                if (!alertController) {
                    NSLog(@"Failed to create alert controller");
                    return;
                }
                
                // Create the actions with game-like styling
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:self->cancelLabel
                                                                       style:UIAlertActionStyleDefault
                                                                     handler:^(UIAlertAction * _Nonnull action) {
                    @try {
                        NSString *tag = [NSString stringWithFormat:@"%d", currentID];
                        UnitySendMessage("DialogManager", "OnCancel", tag.UTF8String);
                        [self->alerts removeObjectForKey:@(currentID)];
                    } @catch (NSException *exception) {
                        NSLog(@"Exception in cancel button handler: %@", exception.reason);
                    }
                }];
                
                UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:self->decideLabel
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * _Nonnull action) {
                    @try {
                        NSString *tag = [NSString stringWithFormat:@"%d", currentID];
                        UnitySendMessage("DialogManager", "OnSubmit", tag.UTF8String);
                        [self->alerts removeObjectForKey:@(currentID)];
                    } @catch (NSException *exception) {
                        NSLog(@"Exception in confirm button handler: %@", exception.reason);
                    }
                }];
                
                // Change text color of buttons to Clash Royale blue
                [cancelAction setValue:[UIColor colorWithRed:0.231 green:0.533 blue:0.765 alpha:1.0] forKey:@"titleTextColor"];
                [confirmAction setValue:[UIColor colorWithRed:0.231 green:0.533 blue:0.765 alpha:1.0] forKey:@"titleTextColor"];
                
                [alertController addAction:cancelAction];
                [alertController addAction:confirmAction];
                
                // Present the controller
                UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
                if (!rootViewController) {
                    NSLog(@"No root view controller found");
                    return;
                }
                
                [rootViewController presentViewController:alertController animated:YES completion:nil];
                self->alerts[@(currentID)] = alertController;
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                UIAlertController *alertController = [self createGameStyleAlert:title message:msg hasCancel:NO];
                if (!alertController) {
                    NSLog(@"Failed to create alert controller");
                    return;
                }
                
                // Create action button
                UIAlertAction *closeAction = [UIAlertAction actionWithTitle:self->closeLabel
                                                                      style:UIAlertActionStyleDefault
                                                                    handler:^(UIAlertAction * _Nonnull action) {
                    @try {
                        NSString *tag = [NSString stringWithFormat:@"%d", currentID];
                        UnitySendMessage("DialogManager", "OnSubmit", tag.UTF8String);
                        [self->alerts removeObjectForKey:@(currentID)];
                    } @catch (NSException *exception) {
                        NSLog(@"Exception in close button handler: %@", exception.reason);
                    }
                }];
                
                // Change text color of button to Clash Royale blue
                [closeAction setValue:[UIColor colorWithRed:0.231 green:0.533 blue:0.765 alpha:1.0] forKey:@"titleTextColor"];
                
                [alertController addAction:closeAction];
                
                // Present the controller
                UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
                if (!rootViewController) {
                    NSLog(@"No root view controller found");
                    return;
                }
                
                [rootViewController presentViewController:alertController animated:YES completion:nil];
                self->alerts[@(currentID)] = alertController;
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
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                UIAlertController *alertController = self->alerts[@(theID)];
                if (alertController) {
                    [alertController dismissViewControllerAnimated:YES completion:nil];
                    [self->alerts removeObjectForKey:@(theID)];
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