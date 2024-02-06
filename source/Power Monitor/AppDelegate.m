/*
     AppDelegate.m
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

#import "AppDelegate.h"
#import "MTPowerMeasurement.h"
#import "MTPowerMeasurementReader.h"
#import "MTPowerMeasurementArray.h"
#import "Constants.h"
#import "MTCarbonFootprint.h"
#import "MTStatusItemMenu.h"

@interface AppDelegate ()
@property (weak) IBOutlet MTStatusItemMenu *statusItemMenu;

@property (nonatomic, strong, readwrite) NSStatusItem *statusItem;
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@property (nonatomic, strong, readwrite) NSWindowController *mainWindowController;
@property (nonatomic, strong, readwrite) NSWindowController *settingsWindowController;
@property (nonatomic, strong, readwrite) MTCarbonFootprint *carbonFootprint;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _userDefaults = [NSUserDefaults standardUserDefaults];
    
    [_userDefaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSKeyedArchiver archivedDataWithRootObject:[NSColor colorNamed:@"GraphFillColor"] requiringSecureCoding:YES error:nil], kMTDefaultsGraphFillColorKey,
                                     [NSKeyedArchiver archivedDataWithRootObject:[NSColor colorNamed:@"GraphPowerNapFillColor"] requiringSecureCoding:YES error:nil], kMTDefaultsGraphPowerNapFillColorKey,
                                     [NSKeyedArchiver archivedDataWithRootObject:[NSColor colorNamed:@"GraphAverageLineColor"] requiringSecureCoding:YES error:nil], kMTDefaultsGraphAverageColorKey,
                                     [NSKeyedArchiver archivedDataWithRootObject:[NSColor colorNamed:@"GraphDayMarkerColor"] requiringSecureCoding:YES error:nil], kMTDefaultsGraphDayMarkerColorKey,
                                     [NSKeyedArchiver archivedDataWithRootObject:[NSColor colorNamed:@"GraphPositionLineColor"] requiringSecureCoding:YES error:nil], kMTDefaultsGraphPositionLineColorKey,
                                     [NSNumber numberWithBool:YES], kMTDefaultsLogFollowCursorKey,
                                     nil]
    ];
    
    NSArray *appArguments = [[NSProcessInfo processInfo] arguments];
    
    if ([appArguments containsObject:@"--noGUI"]) {

        MTPowerMeasurementReader *pM = [[MTPowerMeasurementReader alloc] initWithContentsOfFile:kMTMeasurementFilePath];
        
        if (pM) {

            NSArray *allMeasurements = [pM allMeasurements];
            MTPowerMeasurement *averagePower = [allMeasurements averagePower];
            
            if ([averagePower doubleValue] > 0) {

                printf("Average system power (in W): %.2f\n", [averagePower doubleValue]);
                printf("Number of measurements: %lu\n", (unsigned long)[allMeasurements count]);
                
                _carbonFootprint = [[MTCarbonFootprint alloc] initWithAPIKey:nil];
                [_carbonFootprint currentLocationWithCompletionHandler:^(CLLocation *location, BOOL preciseLocation) {

                    [self->_carbonFootprint countryCodeWithLocation:location
                                                  completionHandler:^(NSString *countryCode) {

                        printf("Country code: %s\n", [countryCode UTF8String]);
                        printf("Precise location: %s\n", (preciseLocation) ? "yes" : "no");
                        
                        // if we use a static list of carbon intensity values (either imported
                        // directly into the app or provided via configuration profile), we also
                        // print the carbon footprint value
                        NSDictionary *carbonRegions = [self->_userDefaults objectForKey:kMTDefaultsCarbonRegionsKey];
    
                        if (carbonRegions) {
                            
                            NSNumber *gramsCO2eqkWh = ([carbonRegions objectForKey:countryCode]) ? [carbonRegions valueForKey:countryCode] : [carbonRegions valueForKey:NSLocalizedStringFromTable(countryCode, @"Alpha-2toAlpha-3", nil)];
                            
                            if ([gramsCO2eqkWh floatValue] > 0) {

                                NSMeasurement *measurementPowerKW = [averagePower measurementByConvertingToUnit:[NSUnitPower kilowatts]];
                                NSMeasurement *measurementCarbon = [[NSMeasurement alloc] initWithDoubleValue:[measurementPowerKW doubleValue] * [gramsCO2eqkWh floatValue]
                                                                                                                     unit:[NSUnitMass grams]];
                                printf("Carbon footprint (in gCO2eq/h): %.2f\n", [measurementCarbon doubleValue]);
                                            
                            } else {
                                            
                                printf("Carbon footprint (in gCO2eq/h): unavailable\n");
                            }
                                        
                        } else {
                            
                            printf("Carbon footprint (in gCO2eq/h): unavailable\n");
                        }

                        [NSApp terminate:self];
                    }];
                }];
                                    
            } else {
                
                printf("No measurements\n");
                [NSApp terminate:self];
            }
            
        } else {
            
            fprintf(stderr, "ERROR! Failed to access buffer file\n");
            [NSApp terminate:self];
        }
        
    } else {
        
        NSStoryboard *storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
        _mainWindowController = [storyboard instantiateControllerWithIdentifier:@"corp.sap.PowerMonitor.MainController"];
                    
        // run as status item or regular application
        [self runAsStatusItem:[_userDefaults boolForKey:kMTDefaultsRunInBackgroundKey]];
        
        // observe changes of the kMTDefaultsRunInBackgroundKey value
        [_userDefaults addObserver:self forKeyPath:kMTDefaultsRunInBackgroundKey options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)runAsStatusItem:(BOOL)status
{
    if (status) {

        if (!self->_statusItem) {

            self->_statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
            [[self->_statusItem button] setImage:[NSImage imageNamed:@"StatusItem"]];
            [self->_statusItem setMenu:self->_statusItemMenu];
        }
        
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
        if (self->_mainWindowController) { [[self->_mainWindowController window] close]; }
        if (self->_settingsWindowController) { [[self->_settingsWindowController window] close]; }
        
    } else {
        
        if (_statusItem) {
            
            [[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
            _statusItem = nil;
        }
            
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        
        if (_mainWindowController) {
            [_mainWindowController showWindow:nil];
            [[_mainWindowController window] makeKeyAndOrderFront:nil];
        }
        
        [NSApp activateIgnoringOtherApps:YES];
    }
}

#pragma mark IBActions

- (IBAction)showSettingsWindow:(id)sender
{
    if (!_settingsWindowController) {
        
        NSStoryboard *storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
        _settingsWindowController = [storyboard instantiateControllerWithIdentifier:@"corp.sap.PowerMonitor.SettingsController"];
    }
    
    [_settingsWindowController showWindow:nil];
    [[_settingsWindowController window] makeKeyAndOrderFront:nil];
    
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)showMainWindow:(id)sender
{
    if (_mainWindowController) {
        [_mainWindowController showWindow:nil];
        [[_mainWindowController window] makeKeyAndOrderFront:nil];        
    }
}

- (IBAction)showConsoleWindow:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNameShowConsole
                                                        object:nil
                                                      userInfo:nil
    ];
}

- (IBAction)openGitHub:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kMTGitHubURL]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:kMTDefaultsRunInBackgroundKey]) {
        
        [self runAsStatusItem:[_userDefaults boolForKey:kMTDefaultsRunInBackgroundKey]];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app
{
    return YES;
}

@end
