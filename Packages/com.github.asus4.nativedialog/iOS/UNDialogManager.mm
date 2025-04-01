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
        CGFloat dialogWidth = 300.0;  // Increased width for better look
        CGFloat topPadding = 28.0;    // Increased top padding
        CGFloat sidePadding = 20.0;
        CGFloat titleFontSize = 24.0;  // Larger title font
        CGFloat messageFontSize = 15.0; // Slightly smaller message font
        CGFloat buttonHeight = 52.0;   // Taller button
        CGFloat cornerRadius = 12.0;   // More rounded corners
        CGFloat dialogMinHeight = 200.0; // Minimum height for the dialog
        
        // Create the main container
        UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, dialogWidth, dialogMinHeight)];
        containerView.backgroundColor = CR_BACKGROUND_COLOR;
        containerView.layer.cornerRadius = cornerRadius;
        containerView.clipsToBounds = YES;
        containerView.layer.borderWidth = 1.0;
        containerView.layer.borderColor = CR_BORDER_COLOR.CGColor;
        
        CGFloat currentY = topPadding;
        
        // Add the title
        if (title && title.length > 0) {
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(sidePadding, currentY, dialogWidth - (sidePadding * 2), 35)];
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
            
            currentY = CGRectGetMaxY(titleLabel.frame) + 16; // More space after title
        }
        
        // Add the message
        if (message && message.length > 0) {
            // Use attributed string for line height adjustment
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.lineSpacing = 4.0; // Add space between lines
            paragraphStyle.alignment = NSTextAlignmentCenter;
            
            NSDictionary *attributes = @{
                NSFontAttributeName: [UIFont systemFontOfSize:messageFontSize],
                NSForegroundColorAttributeName: CR_MESSAGE_COLOR,
                NSParagraphStyleAttributeName: paragraphStyle
            };
            
            NSAttributedString *attributedMessage = [[NSAttributedString alloc] initWithString:message attributes:attributes];
            
            UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(sidePadding, currentY, dialogWidth - (sidePadding * 2), 20)];
            messageLabel.attributedText = attributedMessage;
            messageLabel.textAlignment = NSTextAlignmentCenter;
            messageLabel.numberOfLines = 0;
            messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
            [containerView addSubview:messageLabel];
            
            CGSize maxSize = CGSizeMake(dialogWidth - (sidePadding * 2), 200);
            CGRect textRect = [attributedMessage boundingRectWithSize:maxSize
                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                    context:nil];
            
            messageLabel.frame = CGRectMake(sidePadding, currentY, dialogWidth - (sidePadding * 2), ceilf(textRect.size.height));
            
            currentY = CGRectGetMaxY(messageLabel.frame) + 24; // More space after message
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
        actionButton.titleLabel.font = [UIFont boldSystemFontOfSize:18.0]; // Larger button font
        actionButton.tag = 1;  // Tag for identifying the button in action
        
        // Add ripple effect when touching the button
        UIView *highlightView = [[UIView alloc] initWithFrame:actionButton.bounds];
        highlightView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
        highlightView.alpha = 0.0;
        highlightView.tag = 2;
        [actionButton addSubview:highlightView];
        
        // Add touch events for highlight effect
        [actionButton addTarget:self action:@selector(buttonTouchDown:) forControlEvents:UIControlEventTouchDown];
        [actionButton addTarget:self action:@selector(buttonTouchUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
        
        [containerView addSubview:actionButton];
        
        currentY += buttonHeight;
        
        // Adjust container height (ensure minimum height)
        CGRect frame = containerView.frame;
        frame.size.height = MAX(currentY, dialogMinHeight);
        containerView.frame = frame;
        
        return containerView;
    } @catch (NSException *exception) {
        NSLog(@"Exception in createClashRoyaleStyleDialog: %@", exception.reason);
        return nil;
    }
}

// Button touch down effect
- (void)buttonTouchDown:(UIButton *)sender {
    UIView *highlightView = [sender viewWithTag:2];
    if (highlightView) {
        [UIView animateWithDuration:0.1 animations:^{
            highlightView.alpha = 1.0;
        }];
    }
}

// Button touch up effect
- (void)buttonTouchUp:(UIButton *)sender {
    UIView *highlightView = [sender viewWithTag:2];
    if (highlightView) {
        [UIView animateWithDuration:0.2 animations:^{
            highlightView.alpha = 0.0;
        }];
    }
}

// Helper to present a custom dialog
- (void)presentClashRoyaleDialog:(UIView *)dialogView withID:(int)dialogID {
    @try {
        // Create a transparent overlay
        UIView *overlayView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        overlayView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
        overlayView.tag = dialogID; // Store the dialog ID in the view tag
        
        // Add subtle shadow to dialog
        dialogView.layer.shadowColor = [UIColor blackColor].CGColor;
        dialogView.layer.shadowOffset = CGSizeMake(0, 3);
        dialogView.layer.shadowOpacity = 0.3;
        dialogView.layer.shadowRadius = 10;
        
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
        
        // Use a weak reference to self to avoid retain cycle
        __weak UNDialogManager *weakSelf = self;
        __block int blockDialogID = dialogID;
        
        // Add tap action to the button
        [actionButton addTarget:self action:@selector(dialogButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        // Store the dialog ID in the button's layer
        objc_setAssociatedObject(actionButton, "dialogID", @(dialogID), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        // Store the reference and ID for callback
        alerts[@(dialogID)] = alertVC;
        
        // Present the alert with animation
        UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        
        // Add animation for showing dialog
        dialogView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        dialogView.alpha = 0;
        
        [rootViewController presentViewController:alertVC animated:YES completion:^{
            // Animate the dialog appearance
            [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.8 options:UIViewAnimationOptionCurveEaseOut animations:^{
                dialogView.transform = CGAffineTransformIdentity;
                dialogView.alpha = 1.0;
            } completion:nil];
        }];
    } @catch (NSException *exception) {
        NSLog(@"Exception in presentClashRoyaleDialog: %@", exception.reason);
    }
}

// Button action handler
- (void)dialogButtonTapped:(UIButton *)sender {
    @try {
        // Get the dialog ID from the associated object
        NSNumber *dialogIDNumber = objc_getAssociatedObject(sender, "dialogID");
        if (!dialogIDNumber) {
            NSLog(@"No dialog ID associated with button");
            return;
        }
        
        int dialogID = [dialogIDNumber intValue];
        UIViewController *alertVC = alerts[@(dialogID)];
        
        if (alertVC) {
            // Create animation for dismissal
            UIView *dialogView = [sender superview];
            
            [UIView animateWithDuration:0.2 animations:^{
                dialogView.transform = CGAffineTransformMakeScale(0.9, 0.9);
                dialogView.alpha = 0;
                alertVC.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
            } completion:^(BOOL finished) {
                [alertVC dismissViewControllerAnimated:NO completion:^{
                    // Important: Send message back to Unity AFTER the dialog is dismissed
                    NSString *tag = [NSString stringWithFormat:@"%d", dialogID];
                    UnitySendMessage("DialogManager", "OnSubmit", tag.UTF8String);
                    [self->alerts removeObjectForKey:@(dialogID)];
                }];
            }];
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
                    // Find the dialog view
                    UIView *dialogView = nil;
                    for (UIView *subview in alertVC.view.subviews) {
                        if ([subview.layer.cornerRadius > 0]) {
                            dialogView = subview;
                            break;
                        }
                    }
                    
                    // Animate dismissal if we found the dialog view
                    if (dialogView) {
                        [UIView animateWithDuration:0.2 animations:^{
                            dialogView.transform = CGAffineTransformMakeScale(0.9, 0.9);
                            dialogView.alpha = 0;
                            alertVC.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
                        } completion:^(BOOL finished) {
                            [alertVC dismissViewControllerAnimated:NO completion:nil];
                            [strongSelf->alerts removeObjectForKey:@(theID)];
                        }];
                    } else {
                        // Fallback if we couldn't find the dialog view
                        [alertVC dismissViewControllerAnimated:YES completion:nil];
                        [strongSelf->alerts removeObjectForKey:@(theID)];
                    }
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