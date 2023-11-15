/*
     MTSettingsCarbonController.m
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

#import "MTSettingsCarbonController.h"
#import "MTCarbonAPIKey.h"
#import "MTCarbonFootprint.h"
#import "Constants.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface MTSettingsCarbonController ()
@property (nonatomic, strong, readwrite) MTCarbonFootprint *carbonFootprint;
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@property (assign) BOOL verifyingCredentials;

@property (weak) IBOutlet NSButton *showFootprintCheckbox;
@property (weak) IBOutlet NSButton *importButton;
@end

@implementation MTSettingsCarbonController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _userDefaults = [NSUserDefaults standardUserDefaults];
    [self defaultsChanged];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultsChanged)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil
    ];
}

- (void)defaultsChanged
{
    [_showFootprintCheckbox setEnabled:![_userDefaults objectIsForcedForKey:kMTDefaultsShowCarbonKey]];
    [_importButton setEnabled:![_userDefaults objectIsForcedForKey:kMTDefaultsCarbonRegionsKey]];
}

- (IBAction)showCarbonFootprint:(id)sender
{
    if ([sender state] == NSControlStateValueMixed) {
        
        // if a static list of regions and their respective
        // carbon values has been deployed via configuration
        // profile or has been imported into the app, we use
        // these information instead of one of the carbon APIs.
        if ([_userDefaults objectForKey:kMTDefaultsCarbonRegionsKey]) {
            
            [self->_userDefaults setBool:YES forKey:kMTDefaultsShowCarbonKey];
            
        } else {
            
            self.verifyingCredentials = YES;
            
            // check for existing credentials
            if ([_userDefaults objectForKey:kMTDefaultsCarbonAPITypeKey]) {
                
                MTCarbonAPIType apiType = (MTCarbonAPIType)[_userDefaults integerForKey:kMTDefaultsCarbonAPITypeKey];
                MTCarbonAPIKey *apiKey = [[MTCarbonAPIKey alloc] initWithAPIType:apiType];
                
                [apiKey getKeyWithCompletionHandler:^(NSString *key) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        if (key) {
                            
                            self->_carbonFootprint = [[MTCarbonFootprint alloc] initWithAPIKey:key];
                            [self->_carbonFootprint setApiType:apiType];
                            [self->_carbonFootprint currentLocationWithCompletionHandler:^(CLLocation *location, BOOL preciseLocation) {
                                
                                [self->_carbonFootprint footprintWithLocation:location
                                                            completionHandler:^(NSNumber *gramsCO2eqkWh, NSError *error) {
                                    
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        
                                        self.verifyingCredentials = NO;
                                        
                                        if ([gramsCO2eqkWh floatValue] > 0) {
                                            
                                            [self->_userDefaults setBool:YES forKey:kMTDefaultsShowCarbonKey];
                                            
                                        } else {
                                            
                                            [self performSegueWithIdentifier:@"corp.sap.PowerMonitor.CredentialSegue" sender:nil];
                                        }
                                    });
                                }];
                            }];
                            
                        } else {
                            
                            [self performSegueWithIdentifier:@"corp.sap.PowerMonitor.CredentialSegue" sender:nil];
                            
                        }
                    });
                }];
                
            } else {
                
                [self performSegueWithIdentifier:@"corp.sap.PowerMonitor.CredentialSegue" sender:nil];
            }
        }
    }
}

- (IBAction)importCarbonIntensityData:(id)sender
{
    if ([[sender title] isEqualToString:NSLocalizedString(@"importButtonTitle", nil)]) {
        
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        [panel setCanChooseFiles:YES];
        [panel setPrompt:NSLocalizedString(@"selectButton", nil)];
        [panel setCanChooseDirectories:NO];
        [panel setAllowsMultipleSelection:NO];
        [panel setCanCreateDirectories:NO];
        [panel setAllowedContentTypes:[NSArray arrayWithObject:UTTypeCommaSeparatedText]];
        [panel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result) {
            
            if (result == NSModalResponseOK) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSString *csvString = [NSString stringWithContentsOfURL:[panel URL]
                                                                   encoding:NSUTF8StringEncoding
                                                                      error:nil
                    ];
                    
                    NSMutableDictionary *carbonRegions = [[NSMutableDictionary alloc] init];
                    
                    [csvString enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
                        
                        // remove all whitespace
                        NSString *strippedLine = [line stringByReplacingOccurrencesOfString:@"\\s"
                                                                                 withString:@""
                                                                                    options:NSRegularExpressionSearch
                                                                                      range:NSMakeRange(0, [line length])
                        ];
                        
                        NSArray *lineComponents = [strippedLine componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@",;"]];
                        
                        if (lineComponents && [lineComponents count] == 2) {
                            
                            NSString *countryCode = [lineComponents firstObject];
                            NSString *carbonValueString = [lineComponents lastObject];
                            NSNumber *carbonValue = [NSNumber numberWithFloat:[carbonValueString floatValue]];;
                            
                            if (countryCode && carbonValue) {
                                [carbonRegions setObject:carbonValue forKey:countryCode];
                            }
                        }
                    }];
                    
                    NSAlert *theAlert = [[NSAlert alloc] init];
                    
                    if ([carbonRegions count] > 0) {
                        
                        [theAlert setMessageText:NSLocalizedString(@"dialogImportSuccessTitle", nil)];
                        [theAlert setInformativeText:[NSString localizedStringWithFormat:NSLocalizedString(@"dialogImportSuccessMessage", nil), [carbonRegions count]]];
                        
                        [self->_userDefaults setObject:carbonRegions forKey:kMTDefaultsCarbonRegionsKey];
                        
                    } else {
                        
                        [theAlert setMessageText:NSLocalizedString(@"dialogImportErrorTitle", nil)];
                        [theAlert setInformativeText:[NSString localizedStringWithFormat:NSLocalizedString(@"dialogImportErrorMessage", nil), [carbonRegions count]]];
                    }
                    
                    [theAlert addButtonWithTitle:NSLocalizedString(@"okButton", nil)];
                    [theAlert setAlertStyle:NSAlertStyleInformational];
                    [theAlert beginSheetModalForWindow:[[self view] window] completionHandler:nil];
                });
            }
        }];
        
    } else {
        
        NSAlert *theAlert = [[NSAlert alloc] init];
        [theAlert setMessageText:NSLocalizedString(@"dialogCarbonDataClearTitle", nil)];
        [theAlert setInformativeText:NSLocalizedString(@"dialogCarbonDataClearMessage", nil)];
        [theAlert addButtonWithTitle:NSLocalizedString(@"clearButton", nil)];
        [theAlert addButtonWithTitle:NSLocalizedString(@"cancelButton", nil)];
        [theAlert setAlertStyle:NSAlertStyleInformational];
        [theAlert beginSheetModalForWindow:[[self view] window]
                         completionHandler:^(NSModalResponse returnCode) {

            if (returnCode == NSAlertFirstButtonReturn) {
                [self->_userDefaults removeObjectForKey:kMTDefaultsCarbonRegionsKey];
                [self->_userDefaults setBool:NO forKey:kMTDefaultsShowCarbonKey];
            }
        }];
    }
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.verifyingCredentials = NO;
        [self->_userDefaults setBool:NO forKey:kMTDefaultsShowCarbonKey];
    });
}

@end
