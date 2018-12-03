//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//
//  Derived From:
//  ALKeyboardObservingView.swift
//  ALTextInputBar https://github.com/AlexLittlejohn/ALTextInputBar
//

#import "ConversationKeyboardObservingView.h"

NSString *const kOWSKeyboardFrameDidChangeNotification = @"OWSKeyboardFrameDidChangeNotification";

@interface ConversationKeyboardObservingView(){
    CGFloat defaultHeight;
}

@property (weak, nonatomic) UIView *observedView;
@end

@implementation ConversationKeyboardObservingView

-(id)init{
    if (self = [super init]){
        defaultHeight = 44;
    }
    return self;
}

-(CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, defaultHeight);
}

-(void)willMoveToSuperview:(UIView *)newSuperview{
    [self removeKeyboardObserver];
    if(newSuperview) {
        [self addKeyboardObserver:newSuperview];
    }
    [super willMoveToSuperview:newSuperview];
}

-(void)dealloc {
    [self removeKeyboardObserver];
}

-(void)addKeyboardObserver:(UIView *)observed {
    self.observedView = observed;
    [observed addObserver:self forKeyPath:self.keyboardHandlingKeyPath options:NSKeyValueObservingOptionNew context:nil];
}

-(void)removeKeyboardObserver {
    if (self.observedView) {
        [self.observedView removeObserver:self forKeyPath:self.keyboardHandlingKeyPath];
        self.observedView = nil;
    }
}

-(NSString *)keyboardHandlingKeyPath{
    return @"center";
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (object == self.superview  && [keyPath isEqualToString:self.keyboardHandlingKeyPath]) {
        UIView * s = self.superview;

        CGRect keyboardFrame = s.frame;
        CGRect screenBounds = UIScreen.mainScreen.bounds;
        CGRect intersectRect = CGRectIntersection(keyboardFrame, screenBounds);
        CGFloat keyboardHeight = 0;
        if (!CGRectIsNull(intersectRect)) {
            keyboardHeight = intersectRect.size.height;
        }

        CGRect changeRect = CGRectMake(keyboardFrame.origin.x, keyboardFrame.origin.y, keyboardFrame.size.width, keyboardHeight);
        [self keyboardDidChangeFrame:changeRect];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)keyboardDidChangeFrame:(CGRect)newFrame{
    NSDictionary *userInfo = @{
                               UIKeyboardFrameEndUserInfoKey: [NSValue valueWithCGRect:newFrame]
                               };
    [NSNotificationCenter.defaultCenter postNotificationName:kOWSKeyboardFrameDidChangeNotification object:nil userInfo:userInfo];
}

-(void)updateHeight:(CGFloat)height {
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height);
}

@end
