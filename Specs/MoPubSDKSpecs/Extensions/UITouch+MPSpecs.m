//
//  UITouch+MPSpecs.m
//  MoPubSDK
//
//  Copyright (c) 2013 MoPub. All rights reserved.
//

#import "UITouch+MPSpecs.h"

typedef struct {
    unsigned int _firstTouchForView:1;
    unsigned int _isTap:1;
    unsigned int _isDelayed:1;
    unsigned int _sentTouchesEnded:1;
    unsigned int _abandonForwardingRecord:1;
} UITouchFlags;

@interface UITouch ()

@property(assign) BOOL isTap;
@property(assign) NSUInteger tapCount;
@property(assign) UITouchPhase phase;
@property(nonatomic) UIView *view;
@property(nonatomic) UIWindow *window;
@property(assign) NSTimeInterval timestamp;

- (void)setGestureView:(UIView *)view;
- (void)_setLocationInWindow:(CGPoint)location resetPrevious:(BOOL)resetPrevious;
- (void)_setIsFirstTouchForView:(BOOL)firstTouchForView;

@end

@implementation UITouch (MPSpecs)

- (id)initInView:(UIView *)view;
{
    CGRect frame = view.frame;
    CGPoint centerPoint = CGPointMake(frame.size.width * 0.5f, frame.size.height * 0.5f);
    return [self initInView:view atPoint:centerPoint];
}

- (id)initAtPoint:(CGPoint)point inWindow:(UIWindow *)window;
{
    self = [super init];
    if (self == nil) {
        return nil;
    }

    // Create a fake tap touch
    [self setWindow:window]; // Wipes out some values.  Needs to be first.

    [self setTapCount:1];
    [self _setLocationInWindow:point resetPrevious:YES];

    UIView *hitTestView = [window hitTest:point withEvent:nil];

    [self setView:hitTestView];
    [self setPhase:UITouchPhaseBegan];
    [self _setIsFirstTouchForView:YES];
    [self setIsTap:YES];
    [self setTimestamp:[[NSProcessInfo processInfo] systemUptime]];

    if ([self respondsToSelector:@selector(setGestureView:)]) {
        [self setGestureView:hitTestView];
    }

    return self;
}

- (id)initInView:(UIView *)view atPoint:(CGPoint)point;
{
    return [self initAtPoint:[view.window convertPoint:point fromView:view] inWindow:view.window];
}

//
// setLocationInWindow:
//
// Setter to allow access to the _locationInWindow member.
//
- (void)setLocationInWindow:(CGPoint)location
{
    [self setTimestamp:[[NSProcessInfo processInfo] systemUptime]];
    [self _setLocationInWindow:location resetPrevious:NO];
}

- (void)changeToPhase:(UITouchPhase)phase
{
    [self setTimestamp:[[NSProcessInfo processInfo] systemUptime]];
    [self setPhase:phase];
}

@end
