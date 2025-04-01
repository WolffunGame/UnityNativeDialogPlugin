//
//  UNDialogManager.h
//  UnityDialogPlugin
//
//  Created by ibu on 12/10/09.
//  Copyright (c) 2012年 kayac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface UNDialogManager : NSObject{
    NSInteger _id;
    NSMutableDictionary *alerts;
    NSString *decideLabel;
    NSString *cancelLabel;
    NSString *closeLabel;
}

+ (UNDialogManager*) sharedManager;

- (int) showSelectDialog:(NSString *)msg;
- (int) showSelectDialog:(NSString *)title message:(NSString*)msg;

- (int) showSubmitDialog:(NSString *)msg;
- (int) showSubmitDialog:(NSString *)title message:(NSString*)msg;

- (void) dissmissDialog:(int)theID;

- (void) setLabelTitleWithDecide:(NSString*)decide
                      cancel:(NSString*)cancel
                       close:(NSString*) close;

// Helper methods for Clash Royale style
- (UIView *)createClashRoyaleStyleDialogWithTitle:(NSString *)title message:(NSString *)message buttonText:(NSString *)buttonText;
- (void)presentClashRoyaleDialog:(UIView *)dialogView withID:(int)dialogID;
- (void)dialogButtonTapped:(UIButton *)sender;
- (void)buttonTouchDown:(UIButton *)sender;
- (void)buttonTouchUp:(UIButton *)sender;

@end