/*
     MTSettingsViewOptionsController.m
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

#import "MTSettingsViewOptionsController.h"
#import "Constants.h"

@interface MTSettingsViewOptionsController ()
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;

@property (weak) IBOutlet NSButton *showAverageCheckbox;
@property (weak) IBOutlet NSButton *showDayMarkersCheckbox;
@property (weak) IBOutlet NSButton *markPowerNapsCheckbox;
@property (weak) IBOutlet NSColorWell *graphColorWell;
@property (weak) IBOutlet NSColorWell *graphPowerNapColorWell;
@property (weak) IBOutlet NSColorWell *averageColorWell;
@property (weak) IBOutlet NSColorWell *dayMarkersColorWell;
@property (weak) IBOutlet NSColorWell *positionLineColorWell;
@property (weak) IBOutlet NSButton *resetColorsButton;
@end

@implementation MTSettingsViewOptionsController

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
    dispatch_async(dispatch_get_main_queue(), ^{
    
        // options
        [self->_showAverageCheckbox setEnabled:![self->_userDefaults objectIsForcedForKey:kMTDefaultsGraphShowAverageKey]];
        [self->_showDayMarkersCheckbox setEnabled:![self->_userDefaults objectIsForcedForKey:kMTDefaultsGraphShowDayMarkersKey]];
        [self->_markPowerNapsCheckbox setEnabled:![self->_userDefaults objectIsForcedForKey:kMTDefaultsGraphMarkPowerNapsKey]];
        
        // color wells
        [self->_graphColorWell setEnabled:![self->_userDefaults objectIsForcedForKey:kMTDefaultsGraphFillColorKey]];
        [self->_graphPowerNapColorWell setEnabled:![self->_userDefaults objectIsForcedForKey:kMTDefaultsGraphPowerNapFillColorKey]];
        [self->_averageColorWell setEnabled:![self->_userDefaults objectIsForcedForKey:kMTDefaultsGraphAverageColorKey]];
        [self->_dayMarkersColorWell setEnabled:![self->_userDefaults objectIsForcedForKey:kMTDefaultsGraphDayMarkerColorKey]];
        [self->_positionLineColorWell setEnabled:![self->_userDefaults objectIsForcedForKey:kMTDefaultsGraphPositionLineColorKey]];
        
        // button
        [self->_resetColorsButton setEnabled:!([self->_userDefaults objectIsForcedForKey:kMTDefaultsGraphFillColorKey] &&
                                               [self->_userDefaults objectIsForcedForKey:kMTDefaultsGraphPowerNapFillColorKey] &&
                                               [self->_userDefaults objectIsForcedForKey:kMTDefaultsGraphAverageColorKey] &&
                                               [self->_userDefaults objectIsForcedForKey:kMTDefaultsGraphDayMarkerColorKey] &&
                                               [self->_userDefaults objectIsForcedForKey:kMTDefaultsGraphPositionLineColorKey])];
    });
}

- (IBAction)resetGraphColors:(id)sender
{
    [_userDefaults removeObjectForKey:kMTDefaultsGraphFillColorKey];
    [_userDefaults removeObjectForKey:kMTDefaultsGraphPowerNapFillColorKey];
    [_userDefaults removeObjectForKey:kMTDefaultsGraphAverageColorKey];
    [_userDefaults removeObjectForKey:kMTDefaultsGraphDayMarkerColorKey];
    [_userDefaults removeObjectForKey:kMTDefaultsGraphPositionLineColorKey];
}

@end
