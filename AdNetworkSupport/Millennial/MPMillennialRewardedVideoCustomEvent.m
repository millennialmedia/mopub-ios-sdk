//
//  MPMillennialRewardedVideoCustomEvent.m
//
//  Created by Terence Worley on 8/25/16
//  Copyright (c) 2016 MillennialMedia. All rights reserved.
//

#import "MPMillennialRewardedVideoCustomEvent.h"
#import "MPMillennialInterstitialCustomEvent.h"
#import "MPLogging.h"
#import <MMAdSDK/MMAd+Experimental.h>


static NSString *const kMoPubMMAdapterAdUnit = @"adUnitID";
static NSString *const kMoPubMMAdapterDCN = @"dcn";


@interface MPMillennialRewardedVideoCustomEvent () <MMXIncentiveDelegate, MPInterstitialCustomEventDelegate>
@property (nonatomic, strong) MPMillennialInterstitialCustomEvent *interstitialEvent;
@end

@implementation MPMillennialRewardedVideoCustomEvent

- (id)init
{
    self = [super init];
    if (self) {
        if ([[UIDevice currentDevice] systemVersion].floatValue >= 7.0) {
            MMSDK *mmSDK = [MMSDK sharedInstance];
            if ([mmSDK isInitialized] == NO) {
                [mmSDK initializeWithSettings:[[MMAppSettings alloc] init]
                             withUserSettings:nil];
            }
        } else {
            self = nil; // No support below minimum OS.
        }
    }
    return self;
}

- (void)requestRewardedVideoWithCustomEventInfo:(NSDictionary<NSString *, id> *)info
{
    MPLogDebug(@"Requesting Millennial rewarded video event info %@.", info);
    
    NSString *placementId = info[kMoPubMMAdapterAdUnit];
    if (! placementId) {
        NSError *error = [NSError errorWithDomain:MMSDKErrorDomain
                                             code:MMSDKErrorServerResponseNoContent
                                         userInfo:@{
                                                    NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Millennial received no placement ID. Request failed."]
                                                    }];
        MPLogError(@"*** %@", [error localizedDescription]);
        [self.delegate rewardedVideoDidFailToLoadAdForCustomEvent:self error:error];
        return; // Early return
    }
    
    MMSDK *mmSDK = [MMSDK sharedInstance];
    [mmSDK appSettings].mediator = NSStringFromClass([MPMillennialRewardedVideoCustomEvent class]);
    if (info[kMoPubMMAdapterDCN]) {
        [mmSDK appSettings].siteId = info[kMoPubMMAdapterDCN];
    } else {
        [mmSDK appSettings].siteId = nil;
    }
    
    // Create a new interstitial event for the reward video playback.
    self.interstitialEvent = [[MPMillennialInterstitialCustomEvent alloc] init];
    self.interstitialEvent.delegate = self;
    [self.interstitialEvent requestInterstitialWithCustomEventInfo:info];
}

- (BOOL)hasAdAvailable
{
    return [self.interstitialEvent.interstitial ready];
}

- (void)presentRewardedVideoFromViewController:(UIViewController *)viewController
{
    if ([self hasAdAvailable]) {
        [self.interstitialEvent showInterstitialFromRootViewController:viewController];
    } else {
        NSError *error = [NSError errorWithDomain:MMSDKErrorDomain
                                             code:MMSDKErrorNoFill
                                         userInfo:@{
                                                    NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Millennial reward video was unavailable to display."]
                                                    }];
        MPLogError(@"*** %@", [error localizedDescription]);
        [self.delegate rewardedVideoDidFailToPlayForCustomEvent:self error:error];
    }
}

- (void)handleCustomEventInvalidated
{
    self.interstitialEvent.delegate = nil;
    self.interstitialEvent.interstitial.xIncentiveDelegate = nil;
    self.interstitialEvent = nil;
    self.delegate = nil;
}

- (void)handleAdPlayedForCustomEventNetwork
{
    // If we no longer have an ad available, report back up to the application that this ad expired.
    if (! [self hasAdAvailable]) {
        [self.delegate rewardedVideoDidExpireForCustomEvent:self];
    }
}

#pragma mark - MMXIncentiveDelegate

- (BOOL)incentivizedAdCompletedVideo:(MMAd *)ad
{
    MPRewardedVideoReward *reward = [[MPRewardedVideoReward alloc] initWithCurrencyAmount:@(kMPRewardedVideoRewardCurrencyAmountUnspecified)];
    MPLogInfo(@"%@ incentivizedAdCompletedVideo %@, reward: %@.", NSStringFromClass([self class]), ad, reward);
    [self.delegate rewardedVideoShouldRewardUserForCustomEvent:self reward:reward];
    return YES;
}

- (BOOL)incentivizedAd:(MMAd *)ad triggeredEvent:(MMXIncentiveEvent *)event
{
    // kMMXIncentiveVideoCompleteEventId events already special-cased by the SDK
    // to call incentivizedAdCompletedVideo directly. Otherwise we could check
    // for it here and call incentivizedAdCompletedVideo.
    MPLogInfo(@"%@ incentivizedAd: %@  triggeredEvent: %@.", NSStringFromClass([self class]), ad, event);
    return YES;
}

-(void)xIncentiveEventWasTriggered:(MMXIncentiveEvent *)event
{
    MPLogInfo(@"%@ xIncentiveEventWasTriggered %@.", NSStringFromClass([self class]), event);
}

#pragma mark - MPInterstitialCustomEventDelegate

//
// These protocol methods handle the interstitial custom event (MPMillennialInterstitialCustomEvent)
// generated by this rewarded video custom event (MPMillennialRewardedVideoCustomEvent). However these
// delegate calls are handling this rewarded video instance as the parent, and generally ignore the
// customEvent parameter.
//

- (CLLocation *)location
{
    return [MMSDK sharedInstance].locationManager.location;
}

- (void)interstitialCustomEvent:(MPInterstitialCustomEvent *)customEvent
                      didLoadAd:(id)ad
{
    MPLogInfo(@"%@ interstitialCustomEvent didLoadAd %@ / %@.", NSStringFromClass([self class]), self, customEvent);
    // Now that we have the interstitial, assign the incentive delegate to be
    // notified when the video has completed.
    if (customEvent == self.interstitialEvent) {
        self.interstitialEvent.interstitial.xIncentiveDelegate = self;
    }
    // Let the delegate know we're ready.
    [self.delegate rewardedVideoDidLoadAdForCustomEvent:self];
}

- (void)interstitialCustomEvent:(MPInterstitialCustomEvent *)customEvent
       didFailToLoadAdWithError:(NSError *)error
{
    MPLogInfo(@"%@ interstitialCustomEvent didFailToLoadAdWithError %@ / %@: %@.", NSStringFromClass([self class]), self, customEvent, error);
    if (error.code == MMSDKErrorInterstitialAdAlreadyLoaded) {
        MPLogInfo(@"--- Interstitial already loaded, ignoring this request.");
        [self.delegate rewardedVideoDidLoadAdForCustomEvent:self];
    } else {
        MPLogError(@"--- Interstitial failed with error (%d) %@.", error.code, error.description);
        [self.delegate rewardedVideoDidFailToLoadAdForCustomEvent:self error:error];
    }
}

- (void)interstitialCustomEventDidExpire:(MPInterstitialCustomEvent *)customEvent
{
    [self.delegate rewardedVideoDidExpireForCustomEvent:self];
}

- (void)interstitialCustomEventWillAppear:(MPInterstitialCustomEvent *)customEvent
{
    [self.delegate rewardedVideoWillAppearForCustomEvent:self];
}

- (void)interstitialCustomEventDidAppear:(MPInterstitialCustomEvent *)customEvent
{
    [self.delegate rewardedVideoDidAppearForCustomEvent:self];
}

- (void)interstitialCustomEventWillDisappear:(MPInterstitialCustomEvent *)customEvent
{
    [self.delegate rewardedVideoWillDisappearForCustomEvent:self];
}

- (void)interstitialCustomEventDidDisappear:(MPInterstitialCustomEvent *)customEvent
{
    [self.delegate rewardedVideoDidDisappearForCustomEvent:self];
}

- (void)interstitialCustomEventDidReceiveTapEvent:(MPInterstitialCustomEvent *)customEvent
{
    MPLogDebug(@"%@ interstitialCustomEvent tap event %@ / %@.", NSStringFromClass([self class]), self, customEvent);
    [self.delegate rewardedVideoDidReceiveTapEventForCustomEvent:self];
}

- (void)interstitialCustomEventWillLeaveApplication:(MPInterstitialCustomEvent *)customEvent
{
    [self.delegate rewardedVideoWillLeaveApplicationForCustomEvent:self];
}

- (void)trackImpression
{
    MPLogDebug(@"%@ trackImpression %@.", NSStringFromClass([self class]), self);
    [self.delegate trackImpression];
}

- (void)trackClick
{
    MPLogDebug(@"%@ trackClick %@.", NSStringFromClass([self class]), self);
    [self.delegate trackClick];
}

@end
