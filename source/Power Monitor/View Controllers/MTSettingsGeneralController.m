/*
     MTSettingsGeneralController.m
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

#import "MTSettingsGeneralController.h"
#import "Constants.h"

@interface MTSettingsGeneralController ()
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;

@property (weak) IBOutlet NSButton *showAverageCheckbox;
@property (weak) IBOutlet NSButton *showDayMarkersCheckbox;
@property (weak) IBOutlet NSColorWell *graphColorWell;
@property (weak) IBOutlet NSColorWell *averageColorWell;
@property (weak) IBOutlet NSColorWell *dayMarkersColorWell;
@property (weak) IBOutlet NSButton *resetColorsButton;
@property (weak) IBOutlet NSButton *runInBackgroundButton;
@end

@implementation MTSettingsGeneralController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _userDefaults = [NSUserDefaults standardUserDefaults];
    
    [self defaultsChanged];
    [_runInBackgroundButton setState:([_userDefaults boolForKey:kMTDefaultsRunInBackgroundKey]) ? NSControlStateValueOn : NSControlStateValueOff];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultsChanged)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil
    ];
}

- (void)defaultsChanged
{
    [_showAverageCheckbox setEnabled:![_userDefaults objectIsForcedForKey:kMTDefaultsGraphShowAverageKey]];
    [_showDayMarkersCheckbox setEnabled:![_userDefaults objectIsForcedForKey:kMTDefaultsGraphShowDayMarkersKey]];
    [_graphColorWell setEnabled:![_userDefaults objectIsForcedForKey:kMTDefaultsGraphFillColorKey]];
    [_averageColorWell setEnabled:![_userDefaults objectIsForcedForKey:kMTDefaultsGraphAverageColorKey]];
    [_dayMarkersColorWell setEnabled:![_userDefaults objectIsForcedForKey:kMTDefaultsGraphDayMarkerColorKey]];
    [_resetColorsButton setEnabled:!([_userDefaults objectIsForcedForKey:kMTDefaultsGraphFillColorKey] && [_userDefaults objectIsForcedForKey:kMTDefaultsGraphAverageColorKey] && [_userDefaults objectIsForcedForKey:kMTDefaultsGraphDayMarkerColorKey])];
}

- (IBAction)resetGraphColors:(id)sender
{
    [_userDefaults removeObjectForKey:kMTDefaultsGraphFillColorKey];
    [_userDefaults removeObjectForKey:kMTDefaultsGraphAverageColorKey];
    [_userDefaults removeObjectForKey:kMTDefaultsGraphDayMarkerColorKey];
}

- (IBAction)setBackgroundMode:(id)sender
{
    if ([sender state] == NSControlStateValueOn) {
        
        NSAlert *theAlert = [[NSAlert alloc] init];
        [theAlert setMessageText:NSLocalizedString(@"dialogBackgroundTitle", nil)];
        [theAlert setInformativeText:NSLocalizedString(@"dialogBackgroundMessage", nil)];
        [theAlert addButtonWithTitle:NSLocalizedString(@"backgroundButton", nil)];
        [theAlert addButtonWithTitle:NSLocalizedString(@"cancelButton", nil)];
        [theAlert setAlertStyle:NSAlertStyleInformational];
        [theAlert beginSheetModalForWindow:[NSApp mainWindow]
                        completionHandler:^(NSModalResponse returnCode) {
            
            [self->_userDefaults setBool:(returnCode == NSAlertFirstButtonReturn) ? YES : NO forKey:kMTDefaultsRunInBackgroundKey];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [sender setState:(returnCode == NSAlertFirstButtonReturn) ? NSControlStateValueOn : NSControlStateValueOff];
            });
        }];
        
    } else {
        
        [self->_userDefaults setBool:NO forKey:kMTDefaultsRunInBackgroundKey];
    }
}

@end
