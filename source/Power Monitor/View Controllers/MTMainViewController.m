/*
     MTMainViewController.m
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

#import "MTMainViewController.h"
#import "MTPowerMeasurement.h"
#import "MTPowerMeasurementReader.h"
#import "MTPowerMeasurementArray.h"
#import "MTCarbonFootprint.h"
#import "MTCarbonAPIKey.h"
#import "MTPowerGraphView.h"
#import "Constants.h"
#import "MTUsagePriceValueTransformer.h"
#import "MTUsagePriceTextTransformer.h"
#import <ServiceManagement/SMAppService.h>

@interface MTMainViewController ()
@property (weak) IBOutlet MTPowerGraphView *graphView;
@property (weak) IBOutlet NSTextField *currentPowerText;
@property (weak) IBOutlet NSTextField *averagePowerText;
@property (weak) IBOutlet NSTextField *maximumPowerText;
@property (weak) IBOutlet NSTextField *measurementCountText;
@property (weak) IBOutlet NSTextField *napTimeText;
@property (weak) IBOutlet NSTextField *carbonPerHour;
@property (weak) IBOutlet NSTextField *consumptionLabelText;
@property (weak) IBOutlet NSProgressIndicator *carbonLookupProgressIndicator;

@property (nonatomic, strong, readwrite) MTPowerMeasurementReader *pM;
@property (nonatomic, strong, readwrite) MTCarbonFootprint *carbonFootprint;
@property (nonatomic, strong, readwrite) NSWindowController *consoleWindowController;
@property (nonatomic, strong, readwrite) NSWindowController *graphWindowController;
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@property (nonatomic, strong, readwrite) NSNumber *valuePowerConsumption;
@property (nonatomic, strong, readwrite) NSNumber *valuePowerConsumptionDark;
@property (assign) BOOL carbonLookupInProgress;
@property (assign) BOOL carbonFootprintEnabled;
@property (assign) BOOL insideTrackingArea;
@end

@implementation MTMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _userDefaults = [NSUserDefaults standardUserDefaults];
                
    // add an action to the maximum power text field
    NSClickGestureRecognizer *textFieldClick = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(showMaxValue)];
    [_maximumPowerText addGestureRecognizer:textFieldClick];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self checkForLoginItem];
    });
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    [self updateMeasurements];
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
                                          
                   dispatch_async(dispatch_get_main_queue(), ^{
                       [SMAppService openSystemSettingsLoginItems];
                       [self checkForLoginItem];
                   });
                   
               } else {
                   
                   [NSApp terminate:self];
               }
       }];
        
    } else {
        
        _pM = [[MTPowerMeasurementReader alloc] initWithContentsOfFile:kMTMeasurementFilePath];
        
        if (_pM) {
            
            [self setupGraphView];
            
            if ([_userDefaults boolForKey:kMTDefaultsShowCarbonKey]) {
                self.carbonFootprintEnabled = YES;
                [self updateCarbonFootprint];
            }
            
            [self updateCurrentPower];
            [self updateMeasurements];
            
            NSTimer *graphUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:kMTGraphUpdateInterval
                                                                        repeats:YES
                                                                          block:^(NSTimer *timer) {
                if (self->_pM) {
                    
                    [self updateMeasurements];
                    
                    if ([self->_userDefaults boolForKey:kMTDefaultsShowCarbonKey] && [self->_userDefaults boolForKey:kMTDefaultsUpdateCarbonKey]) {
                        [self updateCarbonFootprint];
                    }
                }
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
            NSArray *observedDefaults = [NSArray arrayWithObjects:
                                         kMTDefaultsShowCarbonKey,
                                         kMTDefaultsGraphFillColorKey,
                                         kMTDefaultsGraphPowerNapFillColorKey,
                                         kMTDefaultsGraphPositionLineColorKey,
                                         kMTDefaultsGraphAverageColorKey,
                                         kMTDefaultsGraphDayMarkerColorKey,
                                         kMTDefaultsGraphShowAverageKey,
                                         kMTDefaultsGraphShowDayMarkersKey,
                                         kMTDefaultsGraphMarkPowerNapsKey,
                                         kMTDefaultsRunInBackgroundKey,
                                         kMTDefaultsElectricityPriceKey,
                                         kMTDefaultsShowPriceKey,
                                         kMTDefaultsTodayValuesOnlyKey,
                                         kMTDefaultsShowSleepIntervalsKey,
                                         nil
            ];
            
            for (NSString *keyPath in observedDefaults) {
                [_userDefaults addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:nil];
            }
            
            // register for notifications to reload the data file
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(reloadDataFile)
                                                         name:kMTNotificationNameReloadDataFile
                                                       object:nil
            ];
            
            // register for notifications to show the console
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(showConsole)
                                                         name:kMTNotificationNameShowConsole
                                                       object:nil
            ];
            
            // register for notifications to show the graph window
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(showGraph)
                                                         name:kMTNotificationNameShowGraphWindow
                                                       object:nil
            ];
            
            // register for notifications to get notified if the
            // mouse enters and exits the graph view
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(showOrHideGraphPopoutButton:)
                                                         name:kMTNotificationNameGraphMouseEntered
                                                       object:_graphView
            ];

            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(showOrHideGraphPopoutButton:)
                                                         name:kMTNotificationNameGraphMouseExited
                                                       object:_graphView
            ];
            
            // register for notifications to show the graph window if the
            // user double-clicked the small graph window in main window
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(showGraph)
                                                         name:kMTNotificationNameGraphShowDetail
                                                       object:nil
            ];
            
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
    NSArray *measurementData = ([_userDefaults boolForKey:kMTDefaultsTodayValuesOnlyKey]) ? [_pM allMeasurementsSinceDate:[[NSCalendar currentCalendar] startOfDayForDate:[NSDate date]]] : [_pM allMeasurements];

    MTPowerMeasurement *maxValue = [measurementData maximumPower];
    MTPowerMeasurement *avgValue = [measurementData averagePower];
    
    NSMeasurementFormatter *powerFormatter = [[NSMeasurementFormatter alloc] init];
    [[powerFormatter numberFormatter] setMinimumFractionDigits:2];
    [[powerFormatter numberFormatter] setMaximumFractionDigits:2];
    
    NSTimeInterval measurementTime = [measurementData totalTime];
    NSMeasurement *measurementCoverage = [[NSMeasurement alloc] initWithDoubleValue:measurementTime unit:[NSUnitDuration seconds]];
    self.valuePowerConsumption = [NSNumber numberWithDouble:[avgValue doubleValue] * measurementTime];

    NSMeasurementFormatter *hourFormatter = [[NSMeasurementFormatter alloc] init];
    [[hourFormatter numberFormatter] setMaximumFractionDigits:0];
    [hourFormatter setUnitStyle:NSFormattingUnitStyleLong];
    [hourFormatter setUnitOptions:NSMeasurementFormatterUnitOptionsNaturalScale];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self->_averagePowerText setStringValue:[powerFormatter stringFromMeasurement:avgValue]];
        [self->_maximumPowerText setStringValue:[powerFormatter stringFromMeasurement:maxValue]];
        [self->_measurementCountText setStringValue:[hourFormatter stringFromMeasurement:measurementCoverage]];
        
        MTUsagePriceTextTransformer *valueTransformer = [[MTUsagePriceTextTransformer alloc] init];
        NSString *consumptionString = [valueTransformer transformedValue:[NSNumber numberWithBool:[self->_userDefaults boolForKey:kMTDefaultsShowPriceKey]]];
        [self->_consumptionLabelText setStringValue:consumptionString];
        
        if ([self->_userDefaults boolForKey:kMTDefaultsGraphMarkPowerNapsKey]) {
            
            NSArray *darkWakeMeasurements = [measurementData powerNapMeasurements];
            NSTimeInterval darkWakeTime = [darkWakeMeasurements totalTime];
            NSMeasurement *darkWakeCoverage = [[NSMeasurement alloc] initWithDoubleValue:darkWakeTime unit:[NSUnitDuration seconds]];
            
            [self->_napTimeText setStringValue:[hourFormatter stringFromMeasurement:darkWakeCoverage]];
            self.valuePowerConsumptionDark = [NSNumber numberWithDouble:[[darkWakeMeasurements averagePower] doubleValue] * darkWakeTime];
        }
    });
    
    // post notification
    MTUsagePriceValueTransformer *valueTransformer = [[MTUsagePriceValueTransformer alloc] init];
    NSString *valueString = [valueTransformer transformedValue:_valuePowerConsumption];

    [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNamePowerStats
                                                        object:nil
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                [powerFormatter stringFromMeasurement:avgValue], kMTNotificationKeyAveragePowerValue,
                                                                valueString, kMTNotificationKeyConsumptionValue,
                                                               nil]
    ];
    
    // we don't update the graph if the main window
    // is not visible (e.g. if running as status item)
    if ([[[self view] window] isVisible]) {

        // add sleep intervals if configured
        if ([_userDefaults boolForKey:kMTDefaultsShowSleepIntervalsKey]) {
            
            __block NSMutableArray *updatedMeasurements = [[NSMutableArray alloc] init];
            __block MTPowerMeasurement *previousMeasurement = nil;
            
            [measurementData enumerateObjectsUsingBlock:^(MTPowerMeasurement *obj, NSUInteger idx, BOOL *stop) {
                
                if (idx == 0) {
                    
                    // if the today view is enabled, the measurements
                    // start always at midnight. Otherwise we start with
                    // the first measurement
                    if ([self->_userDefaults boolForKey:kMTDefaultsTodayValuesOnlyKey]) {
                        
                        NSDate *measurementDate = [NSDate dateWithTimeIntervalSince1970:[obj timeStamp]];
                        NSDate *startOfDay = [[NSCalendar currentCalendar] startOfDayForDate:measurementDate];

                        if ([measurementDate timeIntervalSinceDate:startOfDay] > kMTMeasurementInterval) {
                            
                            previousMeasurement = [[MTPowerMeasurement alloc] initWithPowerValue:0];
                            [previousMeasurement setTimeStamp:[startOfDay timeIntervalSince1970]];
                            
                        } else {
                            
                            previousMeasurement = obj;
                        }
                        
                    } else {
                        
                        previousMeasurement = obj;
                    }
                            
                } else {
                
                    if ([obj timeStamp] - [previousMeasurement timeStamp] > 2 * kMTMeasurementInterval) {
                        
                        for (time_t i = [previousMeasurement timeStamp] + kMTMeasurementInterval; i <= [obj timeStamp] - kMTMeasurementInterval; i += kMTMeasurementInterval) {

                            MTPowerMeasurement *sleepMeasurement = [[MTPowerMeasurement alloc] initWithPowerValue:0];
                            [sleepMeasurement setTimeStamp:i];
                            [updatedMeasurements addObject:sleepMeasurement];
                        }
                    }
                    
                    previousMeasurement = obj;
                }
                
                [updatedMeasurements addObject:obj];
            }];
            
            [_graphView setMeasurementData:updatedMeasurements];
            
        } else {
            
            [_graphView setMeasurementData:measurementData];
        }
        
        [_graphView setNeedsDisplay:YES];
    }
}

- (void)setupGraphView
{
    [_graphView setGraphColor:(NSColor*)[NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class] fromData:[_userDefaults dataForKey:kMTDefaultsGraphFillColorKey] error:nil]];
    [_graphView setPowerNapColor:(NSColor*)[NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class] fromData:[_userDefaults dataForKey:kMTDefaultsGraphPowerNapFillColorKey] error:nil]];
    [_graphView setPositionLineColor:(NSColor*)[NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class] fromData:[_userDefaults dataForKey:kMTDefaultsGraphPositionLineColorKey] error:nil]];
    [_graphView setAverageLineColor:(NSColor*)[NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class] fromData:[_userDefaults dataForKey:kMTDefaultsGraphAverageColorKey] error:nil]];
    [_graphView setDayMarkerColor:(NSColor*)[NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class] fromData:[_userDefaults dataForKey:kMTDefaultsGraphDayMarkerColorKey] error:nil]];
    [_graphView setShowPowerNaps:[_userDefaults boolForKey:kMTDefaultsGraphMarkPowerNapsKey]];
    [_graphView setShowAverage:[_userDefaults boolForKey:kMTDefaultsGraphShowAverageKey]];
    [_graphView setShowDayMarkers:[_userDefaults boolForKey:kMTDefaultsGraphShowDayMarkersKey] && ![_userDefaults boolForKey:kMTDefaultsTodayValuesOnlyKey]];
    [_graphView setAllowToolTip:YES];

    [_graphView setNeedsDisplay:YES];
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
            
            if (location) {
                
                [self->_carbonFootprint countryCodeWithLocation:location
                                              completionHandler:^(NSString *countryCode) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        if (countryCode) {
                            
                            NSNumber *gramsCO2eqkWh = ([carbonRegions objectForKey:countryCode]) ? [carbonRegions valueForKey:countryCode] : [carbonRegions valueForKey:NSLocalizedStringFromTable(countryCode, @"Alpha-2toAlpha-3", nil)];
                            [self updateCarbonUIWithValue:gramsCO2eqkWh preciseLocation:preciseLocation];
                            
                        } else {
                            
                                [self->_carbonPerHour setStringValue:NSLocalizedString(@"carbonFootprintUnavailable", nil)];
                        }
                    });
                }];
                
            } else {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->_carbonPerHour setStringValue:NSLocalizedString(@"carbonFootprintUnavailable", nil)];
                });
            }
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
                        self.carbonFootprintEnabled = NO;
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

                        [self updateCarbonUIWithValue:gramsCO2eqkWh preciseLocation:preciseLocation];
                        self.carbonLookupInProgress = NO;
                    });
                }];
            }];
            
        } else {
            
            self.carbonLookupInProgress = NO;
            [self updateCarbonUIWithValue:0 preciseLocation:NO];
        }
    }
}

- (void)updateCarbonUIWithValue:(NSNumber*)gramsCO2eqkWh preciseLocation:(BOOL)preciseLocation
{
    if ([gramsCO2eqkWh floatValue] > 0) {
        
        BOOL todayOnly = [self->_userDefaults boolForKey:kMTDefaultsTodayValuesOnlyKey];
                            
        NSArray *measurementData = (todayOnly) ? [self->_pM allMeasurementsSinceDate:[[NSCalendar currentCalendar] startOfDayForDate:[NSDate date]]] : [self->_pM allMeasurements];
                
        NSMeasurement *measurementPowerKW = [[measurementData averagePower] measurementByConvertingToUnit:[NSUnitPower kilowatts]];
        NSMeasurement *measurementCarbon = (todayOnly) ? 
        [[NSMeasurement alloc] initWithDoubleValue:[measurementPowerKW doubleValue] * (([measurementData count] * kMTMeasurementInterval) / 3600.0) * [gramsCO2eqkWh floatValue]
                                              unit:[NSUnitMass grams]] :
        [[NSMeasurement alloc] initWithDoubleValue:[measurementPowerKW doubleValue] * [gramsCO2eqkWh floatValue]
                                              unit:[NSUnitMass grams]];
        
        NSMeasurementFormatter *carbonFormatter = [[NSMeasurementFormatter alloc] init];
        [[carbonFormatter numberFormatter] setMaximumFractionDigits:0];
        [carbonFormatter setUnitStyle:NSFormattingUnitStyleLong];
        [carbonFormatter setUnitOptions:NSMeasurementFormatterUnitOptionsProvidedUnit];
                                    
        // one liter of CO2 weighs 1.96 grams and a standard balloon has
        // a volume of around 2.5 liters
        float ballonsCount = ([measurementCarbon doubleValue] / 1.96) / 2.5;
            
        NSString *carbonText = [NSString localizedStringWithFormat:(todayOnly) ? NSLocalizedString(@"carbonFootprintToday", nil) : NSLocalizedString(@"carbonFootprint", nil),
                                  (preciseLocation) ?
                                  NSLocalizedString(@"carbonLocationPrecise", nil) :
                                      NSLocalizedString(@"carbonLocationNotPrecise", nil),
                                  [carbonFormatter stringFromMeasurement:measurementCarbon]
                                 ];
            
        if (ballonsCount >= 1) {
            
            carbonText = [carbonText stringByAppendingString:@" "];
            
            if (ballonsCount > 2) {
                
                carbonText = [carbonText stringByAppendingString:[NSString localizedStringWithFormat:(todayOnly) ? NSLocalizedString(@"carbonBalloonMultipleToday", nil) : NSLocalizedString(@"carbonBalloonMultiple", nil), ballonsCount]];
                
            } else {
                
                carbonText = [carbonText stringByAppendingString:(todayOnly) ? NSLocalizedString(@"carbonBalloonOneToday", nil) : NSLocalizedString(@"carbonBalloonOne", nil)];
            }
        }
                                    
        [self->_carbonPerHour setStringValue:carbonText];
            
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
}

- (void)showMaxValue
{
    if (![_graphView showsPosition]) {
        
        NSArray *measurementData = ([_userDefaults boolForKey:kMTDefaultsTodayValuesOnlyKey]) ? [_pM allMeasurementsSinceDate:[[NSCalendar currentCalendar] startOfDayForDate:[NSDate date]]] : [_pM allMeasurements];
        
        MTPowerMeasurement *maxValue = [measurementData maximumPower];
        [_graphView showMeasurement:maxValue withTooltip:YES];
        
    } else {
        
        [_graphView showMeasurement:nil withTooltip:NO];
    }
}

- (void)reloadDataFile
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self->_pM invalidate];
        self->_pM = nil;
        
        self->_pM = [[MTPowerMeasurementReader alloc] initWithContentsOfFile:kMTMeasurementFilePath];
        [self updateMeasurements];
        [self updateCarbonFootprint];
    });
}

- (void)showConsole
{
    if (!self->_consoleWindowController) {
        
        if (self->_pM) {
            NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:[[[self->_pM allMeasurements] firstObject] timeStamp]];
            [self->_userDefaults setObject:startDate forKey:kMTDefaultsMeasurementStartDateKey];
        }

        self->_consoleWindowController = [[self storyboard] instantiateControllerWithIdentifier:@"corp.sap.PowerMonitor.LogController"];
        [self->_consoleWindowController loadWindow];
    }

    [[self->_consoleWindowController window] makeKeyAndOrderFront:nil];
}

- (void)showOrHideGraphPopoutButton:(NSNotification*)notification
{
    self.insideTrackingArea = ([[notification name] isEqualToString:kMTNotificationNameGraphMouseEntered]) ? YES : NO;
}

- (void)showGraph
{
    if (!self->_graphWindowController) {

        self->_graphWindowController = [[self storyboard] instantiateControllerWithIdentifier:@"corp.sap.PowerMonitor.GraphController"];
        [self->_graphWindowController loadWindow];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNameGraphReloadData
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:_graphView
                                                                                           forKey:kMTNotificationKeyGraphData
                                                               ]
    ];

    [[self->_graphWindowController window] makeKeyAndOrderFront:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:kMTDefaultsShowCarbonKey] ||
        [keyPath isEqualToString:kMTDefaultsTodayValuesOnlyKey]) {
        
        if ([_userDefaults integerForKey:kMTDefaultsShowCarbonKey] == 1) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.carbonFootprintEnabled = YES;
                [self updateCarbonFootprint];
            });

        } else {

            dispatch_async(dispatch_get_main_queue(), ^{ self.carbonFootprintEnabled = NO; });
        }
    }
        
    if ([keyPath isEqualToString:kMTDefaultsGraphFillColorKey] ||
        [keyPath isEqualToString:kMTDefaultsGraphPowerNapFillColorKey] ||
        [keyPath isEqualToString:kMTDefaultsGraphPositionLineColorKey] ||
        [keyPath isEqualToString:kMTDefaultsGraphAverageColorKey] ||
        [keyPath isEqualToString:kMTDefaultsGraphDayMarkerColorKey] ||
        [keyPath isEqualToString:kMTDefaultsGraphShowAverageKey] ||
        [keyPath isEqualToString:kMTDefaultsGraphShowDayMarkersKey] ||
        [keyPath isEqualToString:kMTDefaultsGraphMarkPowerNapsKey] ||
        [keyPath isEqualToString:kMTDefaultsTodayValuesOnlyKey]) {
        
        [self setupGraphView];
    }
    
    if ([keyPath isEqualToString:kMTDefaultsElectricityPriceKey] ||
        [keyPath isEqualToString:kMTDefaultsShowPriceKey] ||
        [keyPath isEqualToString:kMTDefaultsShowSleepIntervalsKey] ||
        [keyPath isEqualToString:kMTDefaultsGraphMarkPowerNapsKey] ||
        [keyPath isEqualToString:kMTDefaultsTodayValuesOnlyKey] ||
        [keyPath isEqualToString:kMTDefaultsRunInBackgroundKey]) {
        
        [self updateMeasurements];
    }
}

@end
