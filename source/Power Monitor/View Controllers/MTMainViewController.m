/*
     MTMainViewController.m
     Copyright 2023 SAP SE
     
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

#import "MTMainViewController.h"
#import "MTPowerMeasurement.h"
#import "MTPowerMeasurementReader.h"
#import "MTPowerMeasurementArray.h"
#import "MTCarbonFootprint.h"
#import "MTCarbonAPIKey.h"
#import "MTPowerGraphView.h"
#import "Constants.h"
#import <ServiceManagement/ServiceManagement.h>

@interface MTMainViewController ()
@property (weak) IBOutlet MTPowerGraphView *graphView;
@property (weak) IBOutlet NSTextField *currentPowerText;
@property (weak) IBOutlet NSTextField *averagePowerText;
@property (weak) IBOutlet NSTextField *maximumPowerText;
@property (weak) IBOutlet NSTextField *measurementCountText;
@property (weak) IBOutlet NSTextField *carbonPerHour;
@property (weak) IBOutlet NSProgressIndicator *carbonLookupProgressIndicator;

@property (nonatomic, strong, readwrite) MTPowerMeasurementReader *pM;
@property (nonatomic, strong, readwrite) MTCarbonFootprint *carbonFootprint;
@property (nonatomic, strong, readwrite) NSWindowController *settingsController;
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@property (nonatomic, strong, readwrite) NSRunningApplication *runningSystemSettings;
@property (assign) BOOL carbonLookupInProgress;
@property (assign) BOOL carbonFootprintEnabled;
@end

@implementation MTMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
            
    _userDefaults = [NSUserDefaults standardUserDefaults];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self checkForLoginItem];
    });
}

- (void)checkForLoginItem
{
    SMAppService *launchdService = [SMAppService daemonServiceWithPlistName:kMTDaemonPlistName];
    
    if ([launchdService status] == SMAppServiceStatusRequiresApproval) {
                
        // the user disabled the login item
        NSAlert *theAlert = [[NSAlert alloc] init];
        [theAlert setMessageText:NSLocalizedString(@"dialogLoginItemDisabledTitle", nil)];
        [theAlert setInformativeText:NSLocalizedString(@"dialogLoginItemDisabledMessage", nil)];
        [theAlert addButtonWithTitle:NSLocalizedString(@"tryAgainButton", nil)];
        [theAlert addButtonWithTitle:NSLocalizedString(@"openSettingsButton", nil)];
        [theAlert addButtonWithTitle:NSLocalizedString(@"quitButton", nil)];
        [theAlert setAlertStyle:NSAlertStyleCritical];
        [theAlert beginSheetModalForWindow:[[self view] window] completionHandler:^(NSModalResponse returnCode) {
               
               if (returnCode == NSAlertFirstButtonReturn) {
                   
                   // retry
                   dispatch_async(dispatch_get_main_queue(), ^{
                       [self checkForLoginItem];
                   });
                   
               } else if (returnCode == NSAlertSecondButtonReturn) {
                   
                   [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"x-apple.systempreferences:com.apple.LoginItems-Settings.extension"]
                                            configuration:[NSWorkspaceOpenConfiguration configuration]
                                        completionHandler:^(NSRunningApplication *app, NSError *error) {
                       
                       if (app && ![app isFinishedLaunching]) {
                           
                           // notification
                           self->_runningSystemSettings = app;
                           [self->_runningSystemSettings addObserver:self
                                                          forKeyPath:@"isFinishedLaunching"
                                                             options:NSKeyValueObservingOptionNew
                                                             context:nil
                           ];
                           
                       } else {
                           [app activateWithOptions:0];
                       }
                       
                       dispatch_async(dispatch_get_main_queue(), ^{
                           [self checkForLoginItem];
                       });
                   }];
                   
               } else {
                   
                   [NSApp terminate:self];
               }
       }];
        
    } else {
        
        _pM = [[MTPowerMeasurementReader alloc] initWithContentsOfFile:kMTMeasurementFilePath];
        
        if (_pM) {
            
            if ([_userDefaults boolForKey:kMTDefaultsShowCarbonKey]) {
                self.carbonFootprintEnabled = YES;
                [self updateCarbonFootprint];
            }
            
            [self updateCurrentPower];
            [self updateMeasurements];
            
            NSTimer *graphUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:kMTGraphUpdateInterval
                                                                        repeats:YES
                                                                          block:^(NSTimer *timer) {
                
                [self updateMeasurements];
            }];
            
            NSTimer *powerUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:kMTCurrentPowerUpdateInterval
                                                                        repeats:YES
                                                                          block:^(NSTimer *timer) {
                
                [self updateCurrentPower];
            }];
            
            // make sure the timers update even if the status
            // item's menu is open
            [[NSRunLoop currentRunLoop] addTimer:graphUpdateTimer forMode:NSEventTrackingRunLoopMode];
            [[NSRunLoop currentRunLoop] addTimer:powerUpdateTimer forMode:NSEventTrackingRunLoopMode];
            
            // observe our user defaults for changes
            [_userDefaults addObserver:self forKeyPath:kMTDefaultsShowCarbonKey options:NSKeyValueObservingOptionNew context:nil];
            [_userDefaults addObserver:self forKeyPath:kMTDefaultsGraphFillColorKey options:NSKeyValueObservingOptionNew context:nil];
            [_userDefaults addObserver:self forKeyPath:kMTDefaultsGraphAverageColorKey options:NSKeyValueObservingOptionNew context:nil];
            [_userDefaults addObserver:self forKeyPath:kMTDefaultsGraphDayMarkerColorKey options:NSKeyValueObservingOptionNew context:nil];
            [_userDefaults addObserver:self forKeyPath:kMTDefaultsGraphShowAverageKey options:NSKeyValueObservingOptionNew context:nil];
            [_userDefaults addObserver:self forKeyPath:kMTDefaultsGraphShowDayMarkersKey options:NSKeyValueObservingOptionNew context:nil];
            [_userDefaults addObserver:self forKeyPath:kMTDefaultsRunInBackgroundKey options:NSKeyValueObservingOptionNew context:nil];
            
        } else {
            
            NSAlert *theAlert = [[NSAlert alloc] init];
            [theAlert setMessageText:NSLocalizedString(@"dialogNoMeasurementsTitle", nil)];
            [theAlert setInformativeText:NSLocalizedString(@"dialogNoMeasurementsMessage", nil)];
            [theAlert addButtonWithTitle:NSLocalizedString(@"tryAgainButton", nil)];
            [theAlert addButtonWithTitle:NSLocalizedString(@"quitButton", nil)];
            [theAlert setAlertStyle:NSAlertStyleCritical];
            [theAlert beginSheetModalForWindow:[[self view] window]
                             completionHandler:^(NSModalResponse returnCode) {
                
                if (returnCode == NSAlertFirstButtonReturn) {
                    
                    // retry
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self checkForLoginItem];
                    });
                    
                } else {
                    
                    [NSApp terminate:self];
                }
            }];
            
        }
    }
}

- (void)updateMeasurements
{
    NSArray *measurementData = [_pM allMeasurements];

    MTPowerMeasurement *maxValue = [measurementData maximumPower];
    MTPowerMeasurement *avgValue = [measurementData averagePower];
    
    NSMeasurementFormatter *powerFormatter = [[NSMeasurementFormatter alloc] init];
    [[powerFormatter numberFormatter] setMinimumFractionDigits:2];
    [[powerFormatter numberFormatter] setMaximumFractionDigits:2];
    
    NSMeasurement *measurementCoverage = [[NSMeasurement alloc] initWithDoubleValue:[measurementData count] * kMTMeasurementInterval
                                                                               unit:[NSUnitDuration seconds]];
    
    NSMeasurementFormatter *hourFormatter = [[NSMeasurementFormatter alloc] init];
    [[hourFormatter numberFormatter] setMaximumFractionDigits:0];
    [hourFormatter setUnitStyle:NSFormattingUnitStyleLong];
    [hourFormatter setUnitOptions:NSMeasurementFormatterUnitOptionsNaturalScale];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_averagePowerText setStringValue:[powerFormatter stringFromMeasurement:avgValue]];
        [self->_maximumPowerText setStringValue:[powerFormatter stringFromMeasurement:maxValue]];
        [self->_measurementCountText setStringValue:[hourFormatter stringFromMeasurement:measurementCoverage]];
    });
    
    // post notification
    [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNameAveragePowerValue
                                                        object:nil
                                                      userInfo:[NSDictionary dictionaryWithObject:[powerFormatter stringFromMeasurement:avgValue]
                                                                                           forKey:kMTNotificationKeyAveragePowerValue]
    ];
        
    // we don't update the graph if we run as status item
    if (![_userDefaults boolForKey:kMTDefaultsRunInBackgroundKey]) {
        
        [_graphView setMeasurementData:measurementData];
        [_graphView setGraphColor:(NSColor*)[NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class] fromData:[_userDefaults dataForKey:kMTDefaultsGraphFillColorKey] error:nil]];
        [_graphView setAverageLineColor:(NSColor*)[NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class] fromData:[_userDefaults dataForKey:kMTDefaultsGraphAverageColorKey] error:nil]];
        [_graphView setDayMarkerColor:(NSColor*)[NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class] fromData:[_userDefaults dataForKey:kMTDefaultsGraphDayMarkerColorKey] error:nil]];
        [_graphView setShowAverage:[_userDefaults boolForKey:kMTDefaultsGraphShowAverageKey]];
        [_graphView setShowDayMarkers:[_userDefaults boolForKey:kMTDefaultsGraphShowDayMarkersKey]];
        
        [_graphView setNeedsDisplay:YES];
    }
}

- (void)updateCurrentPower
{
    NSMeasurementFormatter *powerFormatter = [[NSMeasurementFormatter alloc] init];
    [[powerFormatter numberFormatter] setMinimumFractionDigits:2];
    [[powerFormatter numberFormatter] setMaximumFractionDigits:2];
    
    MTPowerMeasurement *currentPower = [self->_pM currentPower];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_currentPowerText setStringValue:[powerFormatter stringFromMeasurement:currentPower]];
    });
    
    // post notification
    [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNameCurrentPowerValue
                                                        object:nil
                                                      userInfo:[NSDictionary dictionaryWithObject:[powerFormatter stringFromMeasurement:currentPower]
                                                                                           forKey:kMTNotificationKeyCurrentPowerValue]
    ];
}

- (void)updateCarbonFootprint
{
    NSDictionary *carbonRegions = [_userDefaults objectForKey:kMTDefaultsCarbonRegionsKey];

    if (carbonRegions) {
                            
        // get the current region
        _carbonFootprint = [[MTCarbonFootprint alloc] initWithAPIKey:nil];
        [_carbonFootprint setAllowUserInteraction:YES];
        [_carbonFootprint currentLocationWithCompletionHandler:^(CLLocation *location, BOOL preciseLocation) {
            
            [self->_carbonFootprint countryCodeWithLocation:location
                                          completionHandler:^(NSString *countryCode) {

                if (countryCode) {
                    
                    NSNumber *gramsCO2eqkWh = ([carbonRegions objectForKey:countryCode]) ? [carbonRegions valueForKey:countryCode] : [carbonRegions valueForKey:NSLocalizedStringFromTable(countryCode, @"Alpha-2toAlpha-3", nil)];
                    
                    if ([gramsCO2eqkWh floatValue] > 0) {

                        NSMeasurement *measurementPowerKW = [[[self->_pM allMeasurements] averagePower] measurementByConvertingToUnit:[NSUnitPower kilowatts]];
                        NSMeasurement *measurementCarbon = [[NSMeasurement alloc] initWithDoubleValue:[measurementPowerKW doubleValue] * 60.0 * [gramsCO2eqkWh floatValue]
                                                                                                 unit:[NSUnitMass grams]];
                        
                        NSMeasurementFormatter *carbonFormatter = [[NSMeasurementFormatter alloc] init];
                        [[carbonFormatter numberFormatter] setMaximumFractionDigits:0];
                        [carbonFormatter setUnitStyle:NSFormattingUnitStyleLong];
                        [carbonFormatter setUnitOptions:NSMeasurementFormatterUnitOptionsProvidedUnit];
                        
                        [self->_carbonPerHour setStringValue:[NSString localizedStringWithFormat:NSLocalizedString(@"carbonFootprint", nil), (preciseLocation) ? NSLocalizedString(@"carbonLocationPrecise", nil) : NSLocalizedString(@"carbonLocationNotPrecise", nil), [carbonFormatter stringFromMeasurement:measurementCarbon]]];
                        
                        // post a notification
                        [carbonFormatter setUnitStyle:NSFormattingUnitStyleMedium];
                        [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNameCarbonValue
                                                                            object:nil
                                                                          userInfo:[NSDictionary dictionaryWithObject:[carbonFormatter stringFromMeasurement:measurementCarbon]
                                                                                                               forKey:kMTNotificationKeyCarbonValue]
                        ];
                        
                    } else {
                        
                        [self->_carbonPerHour setStringValue:NSLocalizedString(@"carbonFootprintUnavailable", nil)];
                    }
                    
                } else {
                    
                    [self->_carbonPerHour setStringValue:NSLocalizedString(@"carbonFootprintUnavailable", nil)];
                }
            }];
        }];
            
    } else {
        
        self.carbonLookupInProgress = YES;
        
        if (!_carbonFootprint) {
            
            // check for existing credentials
            if ([_userDefaults objectForKey:kMTDefaultsCarbonAPITypeKey]) {
                
                MTCarbonAPIType apiType = (MTCarbonAPIType)[_userDefaults integerForKey:kMTDefaultsCarbonAPITypeKey];
                MTCarbonAPIKey *apiKey = [[MTCarbonAPIKey alloc] initWithAPIType:apiType];
                
                dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                
                [apiKey getKeyWithCompletionHandler:^(NSString *key) {
                    
                    if (key) {
                        
                        self->_carbonFootprint = [[MTCarbonFootprint alloc] initWithAPIKey:key];
                        [self->_carbonFootprint setAllowUserInteraction:YES];
                        
                    } else {
                        
                        [self->_userDefaults setBool:NO forKey:kMTDefaultsShowCarbonKey];
                        self.carbonLookupInProgress = NO;
                    }
                    
                    dispatch_semaphore_signal(semaphore);
                }];
                
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            }
        }
        
        if (_carbonFootprint) {
            
            [_carbonFootprint currentLocationWithCompletionHandler:^(CLLocation *location, BOOL preciseLocation) {
                
                [self->_carbonFootprint footprintWithLocation:location
                                            completionHandler:^(NSNumber *gramsCO2eqkWh, NSError *error) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{

                        if ([gramsCO2eqkWh floatValue] > 0) {
                            
                            NSMeasurement *measurementPowerKW = [[[self->_pM allMeasurements] averagePower] measurementByConvertingToUnit:[NSUnitPower kilowatts]];
                            NSMeasurement *measurementCarbon = [[NSMeasurement alloc] initWithDoubleValue:[measurementPowerKW doubleValue] * 60.0 * [gramsCO2eqkWh floatValue]
                                                                                                     unit:[NSUnitMass grams]];
                            
                            NSMeasurementFormatter *carbonFormatter = [[NSMeasurementFormatter alloc] init];
                            [[carbonFormatter numberFormatter] setMaximumFractionDigits:0];
                            [carbonFormatter setUnitStyle:NSFormattingUnitStyleLong];
                            [carbonFormatter setUnitOptions:NSMeasurementFormatterUnitOptionsProvidedUnit];
                            
                            [self->_carbonPerHour setStringValue:[NSString localizedStringWithFormat:NSLocalizedString(@"carbonFootprint", nil), (preciseLocation) ? NSLocalizedString(@"carbonLocationPrecise", nil) : NSLocalizedString(@"carbonLocationNotPrecise", nil), [carbonFormatter stringFromMeasurement:measurementCarbon]]];
                            
                            // post a notification
                            [carbonFormatter setUnitStyle:NSFormattingUnitStyleMedium];
                            [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNameCarbonValue
                                                                                object:nil
                                                                              userInfo:[NSDictionary dictionaryWithObject:[carbonFormatter stringFromMeasurement:measurementCarbon]
                                                                                                                   forKey:kMTNotificationKeyCarbonValue]
                            ];
                            
                        } else {
                            
                            [self->_carbonPerHour setStringValue:NSLocalizedString(@"carbonFootprintUnavailable", nil)];
                        }
                        
                        self.carbonLookupInProgress = NO;
                    });
                }];
            }];
            
        }
    }
}

- (IBAction)openGitHub:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kMTGitHubURL]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:kMTDefaultsShowCarbonKey]) {
        
        if ([_userDefaults integerForKey:kMTDefaultsShowCarbonKey] == 1) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.carbonFootprintEnabled = YES;
                [self updateCarbonFootprint];
            });
            
        } else {
            
            dispatch_async(dispatch_get_main_queue(), ^{ self.carbonFootprintEnabled = NO; });
        }
        
    } else if ([keyPath isEqualToString:kMTDefaultsGraphFillColorKey] || [keyPath isEqualToString:kMTDefaultsGraphAverageColorKey] || [keyPath isEqualToString:kMTDefaultsGraphDayMarkerColorKey] || [keyPath isEqualToString:kMTDefaultsGraphShowAverageKey] || [keyPath isEqualToString:kMTDefaultsGraphShowDayMarkersKey] || [keyPath isEqualToString:kMTDefaultsRunInBackgroundKey]) {

        [self updateMeasurements];
    }
}

@end
