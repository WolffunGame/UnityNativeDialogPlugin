//
//  UNDialogManager.m
//  UnityDialogPlugin - Clash Royale Style
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
            NSString *decideStr = (decide != NULL) ? [NSString stringWithUTF8String:decide] : @"Try again";
            NSString *cancelStr = (cancel != NULL) ? [NSString stringWithUTF8String:cancel] : @"Cancel";
            NSString *closeStr = (close != NULL) ? [NSString stringWithUTF8String:close] : @"Try again";
            
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

// Clash Royale style color definitions
#define CR_BACKGROUND_COLOR [UIColor colorWithRed:0.25 green:0.20 blue:0.18 alpha:0.95]
#define CR_BUTTON_COLOR [UIColor colorWithRed:0.2 green:0.45 blue:0.8 alpha:1.0]
#define CR_TITLE_COLOR [UIColor whiteColor]
#define CR_MESSAGE_COLOR [UIColor colorWithWhite:0.9 alpha:1.0]
#define CR_BUTTON_TEXT_COLOR [UIColor colorWithRed:0.3 green:0.6 blue:1.0 alpha:1.0]
#define CR_BORDER_COLOR [UIColor colorWithRed:0.4 green:0.33 blue:0.27 alpha:1.0]
#define CR_SEPARATOR_COLOR [UIColor colorWithRed:0.3 green:0.25 blue:0.2 alpha:1.0]

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
        decideLabel = @"Try again";
        cancelLabel = @"Cancel";
        closeLabel = @"Try again";
    }
    return self;
}

// Create a custom view for Clash Royale style dialog
- (UIView *)createClashRoyaleStyleDialogWithTitle:(NSString *)title message:(NSString *)message buttonText:(NSString *)buttonText {
    @try {
        CGFloat dialogWidth = 280.0;
        CGFloat topPadding = 25.0;
        CGFloat sidePadding = 20.0;
        CGFloat titleFontSize = 22.0;
        CGFloat messageFontSize = 16.0;
        CGFloat buttonHeight = 50.0;
        CGFloat cornerRadius = 8.0;
        
        // Create the main container
        UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, dialogWidth, 10)]; // Height will be adjusted
        containerView.backgroundColor = CR_BACKGROUND_COLOR;
        containerView.layer.cornerRadius = cornerRadius;
        containerView.clipsToBounds = YES;
        containerView.layer.borderWidth = 1.0;
        containerView.layer.borderColor = CR_BORDER_COLOR.CGColor;
        
        CGFloat currentY = topPadding;
        
        // Add the title
        if (title && title.length > 0) {
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(sidePadding, currentY, dialogWidth - (sidePadding * 2), 30)];
            titleLabel.text = title;
            titleLabel.textColor = CR_TITLE_COLOR;
            titleLabel.font = [UIFont boldSystemFontOfSize:titleFontSize];
            titleLabel.textAlignment = NSTextAlignmentCenter;
            [containerView addSubview:titleLabel];
            
            [titleLabel sizeToFit];
            titleLabel.frame = CGRectMake((dialogWidth - titleLabel.frame.size.width) / 2,
                                        currentY,
                                        titleLabel.frame.size.width,
                                        titleLabel.frame.size.height);
            
            currentY = CGRectGetMaxY(titleLabel.frame) + 12;
        }
        
        // Add the message
        if (message && message.length > 0) {
            UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(sidePadding, currentY, dialogWidth - (sidePadding * 2), 20)];
            messageLabel.text = message;
            messageLabel.textColor = CR_MESSAGE_COLOR;
            messageLabel.font = [UIFont systemFontOfSize:messageFontSize];
            messageLabel.textAlignment = NSTextAlignmentCenter;
            messageLabel.numberOfLines = 0;
            messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
            [containerView addSubview:messageLabel];
            
            CGSize maxSize = CGSizeMake(dialogWidth - (sidePadding * 2), 200);
            CGRect textRect = [message boundingRectWithSize:maxSize
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:@{NSFontAttributeName: messageLabel.font}
                                                   context:nil];
            
            messageLabel.frame = CGRectMake(sidePadding, currentY, dialogWidth - (sidePadding * 2), textRect.size.height);
            
            currentY = CGRectGetMaxY(messageLabel.frame) + 20;
        }
        
        // Add separator line
        UIView *separatorLine = [[UIView alloc] initWithFrame:CGRectMake(0, currentY, dialogWidth, 1)];
        separatorLine.backgroundColor = CR_SEPARATOR_COLOR;
        [containerView addSubview:separatorLine];
        
        currentY += 1;
        
        // Add button
        UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        actionButton.frame = CGRectMake(0, currentY, dialogWidth, buttonHeight);
        [actionButton setTitle:buttonText forState:UIControlStateNormal];
        [actionButton setTitleColor:CR_BUTTON_TEXT_COLOR forState:UIControlStateNormal];
        [actionButton setTitleColor:[CR_BUTTON_TEXT_COLOR colorWithAlphaComponent:0.7] forState:UIControlStateHighlighted];
        actionButton.titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
        actionButton.tag = 1;  // Tag for identifying the button in action
        [containerView addSubview:actionButton];
        
        currentY += buttonHeight;
        
        // Adjust container height
        CGRect frame = containerView.frame;
        frame.size.height = currentY;
        containerView.frame = frame;
        
        return containerView;
    } @catch (NSException *exception) {
        NSLog(@"Exception in createClashRoyaleStyleDialog: %@", exception.reason);
        return nil;
    }
}

// Helper to present a custom dialog
- (void)presentClashRoyaleDialog:(UIView *)dialogView withID:(int)dialogID {
    @try {
        // Create a transparent overlay
        UIView *overlayView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        overlayView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
        
        // Center the dialog
        dialogView.center = CGPointMake(CGRectGetMidX(overlayView.bounds), CGRectGetMidY(overlayView.bounds));
        [overlayView addSubview:dialogView];
        
        // Create a custom alert and store it with the dialog ID
        UIViewController *alertVC = [[UIViewController alloc] init];
        alertVC.view = overlayView;
        alertVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
        alertVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        // Find the button and add tap action
        UIButton *actionButton = [dialogView viewWithTag:1];
        __weak UNDialogManager *weakSelf = self;
        [actionButton addTarget:self action:@selector(dialogButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        // Store the reference and ID for callback
        [alertVC.view setTag:dialogID];
        alerts[@(dialogID)] = alertVC;
        
        // Present the alert
        UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        [rootViewController presentViewController:alertVC animated:YES completion:nil];
    } @catch (NSException *exception) {
        NSLog(@"Exception in presentClashRoyaleDialog: %@", exception.reason);
    }
}

// Button action handler
- (void)dialogButtonTapped:(UIButton *)sender {
    @try {
        UIView *dialogView = sender.superview;
        while (dialogView && ![dialogView isKindOfClass:[UIViewController class]]) {
            dialogView = dialogView.superview;
        }
        
        if (dialogView) {
            int dialogID = (int)dialogView.tag;
            UIViewController *alertVC = alerts[@(dialogID)];
            
            if (alertVC) {
                [alertVC dismissViewControllerAnimated:YES completion:^{
                    NSString *tag = [NSString stringWithFormat:@"%d", dialogID];
                    UnitySendMessage("DialogManager", "OnSubmit", tag.UTF8String);
                    [self->alerts removeObjectForKey:@(dialogID)];
                }];
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"Exception in dialogButtonTapped: %@", exception.reason);
    }
}

- (int) showSelectDialog:(NSString *)msg {
    return [self showSelectDialog:nil message:msg];
}

- (int) showSelectDialog:(NSString *)title message:(NSString*)msg {
    @try {
        ++_id;
        
        __block int currentID = _id;
        __weak UNDialogManager *weakSelf = self;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                UNDialogManager *strongSelf = weakSelf;
                if (!strongSelf) return;
                
                UIView *dialogView = [strongSelf createClashRoyaleStyleDialogWithTitle:title 
                                                                  message:msg 
                                                                  buttonText:strongSelf->decideLabel];
                if (!dialogView) {
                    NSLog(@"Failed to create dialog view");
                    return;
                }
                
                [strongSelf presentClashRoyaleDialog:dialogView withID:currentID];
                
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
        __weak UNDialogManager *weakSelf = self;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                UNDialogManager *strongSelf = weakSelf;
                if (!strongSelf) return;
                
                UIView *dialogView = [strongSelf createClashRoyaleStyleDialogWithTitle:title 
                                                                  message:msg 
                                                                  buttonText:strongSelf->closeLabel];
                if (!dialogView) {
                    NSLog(@"Failed to create dialog view");
                    return;
                }
                
                [strongSelf presentClashRoyaleDialog:dialogView withID:currentID];
                
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
                
                UIViewController *alertVC = strongSelf->alerts[@(theID)];
                if (alertVC) {
                    [alertVC dismissViewControllerAnimated:YES completion:nil];
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