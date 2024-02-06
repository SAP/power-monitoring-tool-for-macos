/*
     MTCredentialsController.m
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

#import "MTCredentialsController.h"
#import "MTCarbonFootprint.h"
#import "MTCarbonAPIKey.h"
#import "Constants.h"

@interface MTCredentialsController ()
@property (weak) IBOutlet NSTextField *apiKeyText;
@property (weak) IBOutlet NSSecureTextField *apiKeyTextField;
@property (weak) IBOutlet NSButton *continueButton;

@property (nonatomic, strong, readwrite) MTCarbonFootprint *carbonFootprint;
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@property (assign) MTCarbonAPIType apiType;
@property (assign) BOOL verifyingCredentials;
@property (assign) BOOL badCredentials;
@end

@implementation MTCredentialsController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _userDefaults = [NSUserDefaults standardUserDefaults];
    _apiType = MTCarbonAPITypeCO2Signal;
    
    // make the link in our text field clickable
    [_apiKeyText setAttributedStringValue:[self stringWithClickableLinksFromString:[_apiKeyText attributedStringValue]]];
}

- (NSAttributedString*)stringWithClickableLinksFromString:(NSAttributedString*)string
{
    NSMutableAttributedString *finalString = [[NSMutableAttributedString alloc] initWithAttributedString:string];
        
    NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    NSArray *allMatches = [linkDetector matchesInString:[finalString string] options:0 range:NSMakeRange(0, [[finalString string] length])];
    
    for (NSTextCheckingResult *match in [allMatches reverseObjectEnumerator]) {
        [finalString addAttribute:NSLinkAttributeName value:[match URL] range:[match range]];
    }
   
    return finalString;
}

- (IBAction)closeWindow:(id)sender
{
    if ([sender tag] == 1) {
        
        [[[self view] window] makeFirstResponder:nil];
        self.verifyingCredentials = YES;
        [_continueButton setEnabled:NO];
        
        // verify the credentials
        _carbonFootprint = [[MTCarbonFootprint alloc] initWithAPIKey:[_apiKeyTextField stringValue]];
        [_carbonFootprint setApiType:_apiType];
        [_carbonFootprint currentLocationWithCompletionHandler:^(CLLocation *location, BOOL preciseLocation) {
            
            [self->_carbonFootprint footprintWithLocation:location
                                        completionHandler:^(NSNumber *gramsCO2eqkWh, NSError *error) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (error) {
                        
                        self.verifyingCredentials = NO;
                        self.badCredentials = YES;
                        [self->_continueButton setEnabled:YES];
                        
                    } else {
                        
                        MTCarbonAPIKey *apiKey = [[MTCarbonAPIKey alloc] initWithAPIType:self->_apiType];
                        [apiKey storeKey:[self->_apiKeyTextField stringValue] completionHandler:^(OSStatus status, CFTypeRef item) {
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self->_userDefaults setBool:YES forKey:kMTDefaultsShowCarbonKey];
                                [self->_userDefaults setInteger:self->_apiType forKey:kMTDefaultsCarbonAPITypeKey];
                                [self dismissController:self];
                            });
                        }];
                        
                    }
                });
            }];
        }];
        
    } else {

        [_userDefaults setBool:NO forKey:kMTDefaultsShowCarbonKey];
        [self dismissController:self];
    }
}

- (IBAction)selectAPI:(id)sender
{
    _apiType = (MTCarbonAPIType)[sender tag];
    
    if (_apiType == MTCarbonAPITypeCO2Signal) {
        [_apiKeyText setStringValue:NSLocalizedString(@"apiKeyTextCO2Signal", nil)];
    } else {
        [_apiKeyText setStringValue:NSLocalizedString(@"apiKeyTextElectricityMaps", nil)];
    }
    
    [_apiKeyText setAttributedStringValue:[self stringWithClickableLinksFromString:[_apiKeyText attributedStringValue]]];
}

- (void)controlTextDidChange:(NSNotification*)aNotification
{
    if ([[_apiKeyTextField stringValue] length] > 0) {
        [_continueButton setEnabled:YES];
    } else {
        [_continueButton setEnabled:NO];
    }
    
    self.badCredentials = NO;
}

@end
