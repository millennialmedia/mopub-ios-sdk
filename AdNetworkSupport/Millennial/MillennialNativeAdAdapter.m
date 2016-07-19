//
//  MillennialNativeAdAdapter.m
//
//  Copyright (c) 2015 Millennial Media, Inc. All rights reserved.
//

#import "MillennialNativeAdAdapter.h"
#import "MPNativeAdConstants.h"
#import "MPStaticNativeAdImpressionTimer.h"
#import "MMNativeAd+ClientMediation.h"

@interface MillennialNativeAdAdapter() <MPStaticNativeAdImpressionTimerDelegate>

@property ( nonatomic, strong ) MMNativeAd *mmNativeAd;
@property (nonatomic) MPStaticNativeAdImpressionTimer *impressionTimer;

@end

@implementation MillennialNativeAdAdapter

@synthesize properties = _properties;
@synthesize defaultActionURL = _defaultActionURL;

- (instancetype)initWithMMNativeAd:(MMNativeAd *)ad {
    self = [super init];
    
    if (self) {
        NSMutableDictionary *properties = [NSMutableDictionary dictionary];
        
        if (ad.title.text) {
            [properties setObject:ad.title.text forKey:kAdTitleKey];
        }
        
        if (ad.body.text) {
            [properties setObject:ad.body.text forKey:kAdTextKey];
        }
        
        if (ad.callToActionButton.titleLabel.text) {
            [properties setObject:ad.callToActionButton.titleLabel.text forKey:kAdCTATextKey];
        }
        
        if(ad.rating.text)
        {
            [properties setObject:@(ad.rating.text.integerValue) forKey:kAdStarRatingKey];
        }
        
        if(ad.mainImageInfo[MMNativeImageInfoURLKey])
        {
            [properties setObject:[NSString stringWithFormat:@"%@", ad.mainImageInfo[MMNativeImageInfoURLKey]] forKey:kAdMainImageKey];
        }

        if(ad.iconImageInfo[MMNativeImageInfoURLKey])
        {
            [properties setObject:[NSString stringWithFormat:@"%@", ad.iconImageInfo[MMNativeImageInfoURLKey]] forKey:kAdIconImageKey];
        }
        
        self.mmNativeAd = ad;
        _properties = properties;
        
        // Impression tracking
        _impressionTimer = [[MPStaticNativeAdImpressionTimer alloc] initWithRequiredSecondsForImpression:0.0 requiredViewVisibilityPercentage:0.5];
        _impressionTimer.delegate = self;
        
    }
    return self;
}

#pragma mark - Click Tracking

- (void)displayContentForURL:(NSURL *)URL rootViewController:(UIViewController *)controller {
    [self.mmNativeAd invokeDefaultAction];
    [self.delegate nativeAdDidClick:self];
}

#pragma mark - Impression tracking

- (void)willAttachToView:(UIView *)view {
    
    [self.impressionTimer startTrackingView:view];
}

- (void)trackImpression {
    
    [self.delegate nativeAdWillLogImpression:self];
    
    // Handle the impression
    [self.mmNativeAd fireImpression];
}

@end
