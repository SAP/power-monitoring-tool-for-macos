/*
     MTSettingsCostsController.m
     Copyright 2023-2025 SAP SE
     
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

#import "MTSettingsCostsController.h"
#import "MTElectricityPrice.h"
#import "MTDaemonConnection.h"
#import "MTSegmentedControl.h"
#import "MTWeekdayTextField.h"
#import "Constants.h"

@interface MTSettingsCostsController ()
@property (nonatomic, strong, readwrite) MTDaemonConnection *daemonConnection;
@property (nonatomic, strong, readwrite) NSMutableDictionary *scheduleDict;
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@property (retain) id daemonPreferencesObserver;
@property (assign) BOOL altPriceSelected;
@property (assign) BOOL altPriceEnabled;

@property (weak) IBOutlet NSTextField *priceTextField;
@property (weak) IBOutlet NSTextField *altPriceTextField;
@property (weak) IBOutlet NSButton *showPriceCheckbox;
@property (weak) IBOutlet MTSegmentedControl *segmentedControl1;
@property (weak) IBOutlet MTSegmentedControl *segmentedControl2;
@property (weak) IBOutlet MTSegmentedControl *segmentedControl3;
@property (weak) IBOutlet MTSegmentedControl *segmentedControl4;
@property (weak) IBOutlet MTSegmentedControl *segmentedControl5;
@property (weak) IBOutlet MTSegmentedControl *segmentedControl6;
@property (weak) IBOutlet MTSegmentedControl *segmentedControl7;
@end

@implementation MTSettingsCostsController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _scheduleDict = [[NSMutableDictionary alloc] init];
    _userDefaults = [NSUserDefaults standardUserDefaults];
    _daemonConnection = [[MTDaemonConnection alloc] init];
    
    [self defaultsChanged];
    [self updateAltTariffStatusWithCompletionHandler:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultsChanged)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil
    ];
    
    _daemonPreferencesObserver = [[NSDistributedNotificationCenter defaultCenter] addObserverForName:kMTNotificationNameDaemonConfigDidChange
                                                                                              object:nil
                                                                                               queue:nil
                                                                                          usingBlock:^(NSNotification *notification) {
        
        NSDictionary *userInfo = [notification userInfo];
        
        if (userInfo) {
            
            NSString *changedKey = [userInfo objectForKey:kMTNotificationKeyPreferenceChanged];
            
            if ([changedKey isEqualToString:(NSString*)kMTPrefsUseAltPriceKey] ||
                [changedKey isEqualToString:(NSString*)kMTPrefsAltPriceScheduleKey]) {
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    [self updateAltTariffStatusWithCompletionHandler:nil];
                });
                
            }
        }
    }];
}

- (void)defaultsChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_showPriceCheckbox setEnabled:![self->_userDefaults objectIsForcedForKey:kMTDefaultsShowPriceKey]];
        [self->_priceTextField setEnabled:![self->_userDefaults objectIsForcedForKey:kMTDefaultsElectricityPriceKey]];
        [self->_altPriceTextField setEnabled:![self->_userDefaults objectIsForcedForKey:kMTDefaultsAltElectricityPriceKey]];
    });
}

- (void)updateAltTariffStatusWithCompletionHandler:(void (^)(void))completionHandler
{
    [_daemonConnection connectToDaemonWithExportedObject:nil
                                  andExecuteCommandBlock:^{
        
        [[[self->_daemonConnection connection] remoteObjectProxyWithErrorHandler:^(NSError *error) {
            
            os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_FAULT, "SAPCorp: Failed to connect to daemon: %{public}@", error);
            
        }] altPriceEnabledWithReply:^(BOOL enabled, BOOL forced) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.altPriceSelected = enabled;
                self.altPriceEnabled = !forced;
                
                [[[self->_daemonConnection connection] remoteObjectProxyWithErrorHandler:^(NSError *error) {
                    
                    os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_FAULT, "SAPCorp: Failed to connect to daemon: %{public}@", error);
                    
                }] altPriceScheduleWithReply:^(NSDictionary *schedule, BOOL forced) {
                
                    if (schedule) { [self.scheduleDict setDictionary:schedule]; }

                    NSArray *segmentedControls = [NSArray arrayWithObjects:
                                                  self.segmentedControl1,
                                                  self.segmentedControl2,
                                                  self.segmentedControl3,
                                                  self.segmentedControl4,
                                                  self.segmentedControl5,
                                                  self.segmentedControl6,
                                                  self.segmentedControl7,
                                                  nil
                    ];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                    
                        for (MTSegmentedControl *aControl in segmentedControls) {

                            NSString *dayString = [NSString stringWithFormat:@"%ld", [MTWeekdayTextField dayOfTheWeekForElementWithID:[aControl tag]]];
                            NSArray *dayArray = [self.scheduleDict objectForKey:dayString];
                            [aControl setSelectedSegmentsWithArray:dayArray];
                        }
                            
                        if (completionHandler) { completionHandler(); }
                    });
                }];
            });
        }];
    }];
}

- (void)updatePriceField
{
    NSLog(@"%hd", [_userDefaults objectIsForcedForKey:kMTDefaultsElectricityPriceKey]);
    [_priceTextField setEnabled:!([_userDefaults objectIsForcedForKey:kMTDefaultsElectricityPriceKey])];
    [_priceTextField setStringValue:[_userDefaults stringForKey:kMTDefaultsElectricityPriceKey]];
}

- (void)updateAltPriceField
{
    [_altPriceTextField setEnabled:!([_userDefaults objectIsForcedForKey:kMTDefaultsAltElectricityPriceKey])];
    [_altPriceTextField setStringValue:[_userDefaults stringForKey:kMTDefaultsAltElectricityPriceKey]];
}

- (void)updateShowPriceCheckbox
{
    [_showPriceCheckbox setEnabled:!([_userDefaults objectIsForcedForKey:kMTDefaultsShowPriceKey])];
    [_showPriceCheckbox setState:([_userDefaults boolForKey:kMTDefaultsShowPriceKey]) ? NSControlStateValueOff : NSControlStateValueOn];
}

- (void)controlTextDidEndEditing:(NSNotification *)obj
{
    if ([[_priceTextField stringValue] length] == 0) { [self.priceTextField setStringValue:@"0"]; }
    if ([[_altPriceTextField stringValue] length] == 0) { [self.altPriceTextField setStringValue:@"0"]; }
}

- (void)mouseDown:(NSEvent *)event
{
    [[[self view] window] makeFirstResponder:nil];
}

#pragma mark IBActions

- (IBAction)setAltTariffEnabled:(id)sender
{
    [_daemonConnection connectToDaemonWithExportedObject:nil
                                  andExecuteCommandBlock:^{
        
        [[self->_daemonConnection remoteObjectProxy] setAltPriceEnabled:self->_altPriceSelected completionHandler:^(BOOL success) {
         
            dispatch_async(dispatch_get_main_queue(), ^{

                // revert the selected entry if the operation failed
                if (!success) { self.altPriceSelected = !self.altPriceSelected; }
            });
        }];
    }];
}

- (IBAction)setAltPriceSchedule:(id)sender
{
    
    if ([sender tag] > 0 && [sender isKindOfClass:[NSSegmentedControl class]]) {
        
        NSMutableArray *idxSet = [[NSMutableArray alloc] init];
        NSSegmentedControl *aControl = (NSSegmentedControl*)sender;
        
        if (([NSEvent modifierFlags] & NSEventModifierFlagOption)) {
                        
            if ([aControl isSelectedForSegment:[aControl selectedSegment]]) {
                
                for (int i = 0; i < [aControl segmentCount]; i++) {
                    
                    [aControl setSelected:YES forSegment:i];
                    [idxSet addObject:[NSNumber numberWithInt:i]];
                }
                
            } else {
                
                [aControl setSelectedSegment:-1];
            }
            
        } else {
            
            for (int i = 0; i < [aControl segmentCount]; i++) {
                
                if ([aControl isSelectedForSegment:i]) {
                    [idxSet addObject:[NSNumber numberWithInt:i]];
                }
            }
        }
        
        NSInteger indexInWeek = [MTWeekdayTextField dayOfTheWeekForElementWithID:[sender tag]];

        if (indexInWeek >= 0) {
            
            [_scheduleDict setObject:idxSet forKey:[NSString stringWithFormat:@"%ld", indexInWeek]];
            
            [_daemonConnection connectToDaemonWithExportedObject:nil
                                          andExecuteCommandBlock:^{

                [[[self->_daemonConnection connection] remoteObjectProxyWithErrorHandler:^(NSError *error) {
                    
                    os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_FAULT, "SAPCorp: Failed to connect to daemon: %{public}@", error);
                    
                }] setAltPriceSchedule:self->_scheduleDict completionHandler:^(BOOL success) {
                    
                    if (!success) {
                        os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_FAULT, "SAPCorp: Failed to change schedule for alternative tariff");
                    }
                }];
            }];
        }
    }
}

@end
