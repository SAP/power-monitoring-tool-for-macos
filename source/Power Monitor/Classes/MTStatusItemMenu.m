/*
     MTStatusItemMenu.m
     Copyright 2023-2024 SAP SE
     
     Licensed under the Apache License, Version 2.0 (the "License");
     you may not use this file except in compliance with the License.
     You may obtain a copy of the License at
     
     http://www.apache.org/licenses/LICENSE-2.0
     
     Unless required by applicable law or agreed to in writing, software
     distributed under the License is distributed on an "AS IS" BASIS,
     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     See the License for the specific language governing permissions and
     limitations under the License.
*/

#import "MTStatusItemMenu.h"
#import "MTUsagePriceTextTransformer.h"
#import "Constants.h"

@interface MTStatusItemMenu ()
@property(nonatomic, strong, readwrite) NSString *carbonValue;
@property(nonatomic, strong, readwrite) NSString *averagePowerValue;
@property(nonatomic, strong, readwrite) NSString *currentPowerValue;
@property(nonatomic, strong, readwrite) NSString *consumptionValue;
@property (assign) BOOL isOpen;
@end

@implementation MTStatusItemMenu

- (instancetype)init
{
    self = [super init];
    if (self) { [self setUpMenu]; }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) { [self setUpMenu]; }
    
    return self;
}

- (void)setUpMenu
{
    // register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateValues:)
                                                 name:kMTNotificationNameCarbonValue
                                               object:nil
    ];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateValues:)
                                                 name:kMTNotificationNamePowerStats
                                               object:nil
    ];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateValues:)
                                                 name:kMTNotificationNameCurrentPowerValue
                                               object:nil
    ];
    
    // set delegate
    [self setDelegate:self];
}

- (void)updateValues:(NSNotification*)notification
{
    if ([[notification name] isEqualToString:kMTNotificationNameCarbonValue]) {
        
        self.carbonValue = [[notification userInfo] objectForKey:kMTNotificationKeyCarbonValue];
        if ([self isOpen]) { [self updateCarbonValue]; }
        
    } else if ([[notification name] isEqualToString:kMTNotificationNamePowerStats]) {
        
        self.averagePowerValue = [[notification userInfo] objectForKey:kMTNotificationKeyAveragePowerValue];
        self.consumptionValue = [[notification userInfo] objectForKey:kMTNotificationKeyConsumptionValue];
        if ([self isOpen]) { [self updatePowerStats]; }
        
    } else if ([[notification name] isEqualToString:kMTNotificationNameCurrentPowerValue]) {

        self.currentPowerValue = [[notification userInfo] objectForKey:kMTNotificationKeyCurrentPowerValue];
        if ([self isOpen]) { [self updateCurrentPowerValue]; }
    }
}

- (void)updateCarbonValue
{
    [[self itemWithTag:3000] setTitle:[NSString localizedStringWithFormat:([[NSUserDefaults standardUserDefaults] boolForKey:kMTDefaultsTodayValuesOnlyKey]) ? NSLocalizedString(@"statusItemCarbonFootprintToday", nil) : NSLocalizedString(@"statusItemCarbonFootprint", nil), (_carbonValue) ? _carbonValue : NSLocalizedString(@"statusItemValueUnknown", nil)]];
}

- (void)updatePowerStats
{
    [[self itemWithTag:2000] setTitle:[NSString localizedStringWithFormat:NSLocalizedString(@"statusItemAveragePower", nil), (_averagePowerValue) ? _averagePowerValue : NSLocalizedString(@"statusItemValueUnknown", nil)]];

    MTUsagePriceTextTransformer *valueTransformer = [[MTUsagePriceTextTransformer alloc] init];
    BOOL showPrice = [[NSUserDefaults standardUserDefaults] boolForKey:kMTDefaultsShowPriceKey];
    NSString *valueString = [valueTransformer transformedValue:[NSNumber numberWithBool:showPrice]];
    [[self itemWithTag:2100] setTitle:[NSString stringWithFormat:@"%@ %@", valueString, (_consumptionValue) ? _consumptionValue : NSLocalizedString(@"statusItemValueUnknown", nil)]];
}

- (void)updateCurrentPowerValue
{
    [[self itemWithTag:1000] setTitle:[NSString localizedStringWithFormat:NSLocalizedString(@"statusItemCurrentPower", nil), (_currentPowerValue) ? _currentPowerValue : NSLocalizedString(@"statusItemValueUnknown", nil)]];
}

- (void)menuWillOpen:(NSMenu *)menu
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kMTDefaultsShowCarbonKey]) {
        
        [self updateCarbonValue];
        [[self itemWithTag:3000] setHidden:NO];
        
    } else {
        
        [[self itemWithTag:3000] setHidden:YES];
    }
    
    [self updatePowerStats];
    [self updateCurrentPowerValue];
    
    _isOpen = YES;
}

- (void)menuDidClose:(NSMenu *)menu
{
    _isOpen = NO;
}

@end
