//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//
//  Derived From:
//  ALKeyboardObservingView.swift
//  ALTextInputBar https://github.com/AlexLittlejohn/ALTextInputBar
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
extern NSString *const kOWSKeyboardFrameDidChangeNotification;

@interface ConversationKeyboardObservingView : UIView
-(void)updateHeight:(CGFloat)height;
@end

NS_ASSUME_NONNULL_END
