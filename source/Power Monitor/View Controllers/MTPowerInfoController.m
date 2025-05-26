/*
     MTPowerInfoController.m
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

#import "MTPowerInfoController.h"
#import "MTSystemInfo.h"
#import "Constants.h"
#import <IOKit/PS/IOPSKeys.h>

@interface MTPowerInfoController ()
@property (assign) IBOutlet NSTextView *textView;

@property (nonatomic, strong, readwrite, nullable) CFRunLoopSourceRef sourceRef __attribute__ (( NSObject ));
@end

@implementation MTPowerInfoController

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    [self updatePowerInformation];
    
    // we want to get notified whenever power sources change
    self.sourceRef = IOPSNotificationCreateRunLoopSource(powerSourcesDidChange, (__bridge void*)self);
    CFRunLoopRef current = CFRunLoopGetCurrent();
    CFRunLoopAddSource(current, self.sourceRef, kCFRunLoopDefaultMode);
}

static void powerSourcesDidChange(void *context)
{
    MTPowerInfoController *obj = (__bridge MTPowerInfoController*)context;
    [obj updatePowerInformation];
}

- (void)updatePowerInformation
{
    NSMutableAttributedString *contentString = [[NSMutableAttributedString alloc] init];
    
#pragma mark External Power Supply
    
    NSDictionary *externalPower = [MTSystemInfo externalPowerAdapterDetails];
    
    if (externalPower) {

        NSString *localizedHeader = NSLocalizedString(@"acPower", nil);
        [contentString appendAttributedString:[self formattedStringWithDictionary:externalPower header:localizedHeader]];
    }
    
#pragma mark Power Sources
    
    NSArray *powerSources = [MTSystemInfo powerSourcesInfo];
    
    for (NSDictionary *sourceDict in powerSources) {
        
        NSString *localizedHeader = NSLocalizedString(@"powerUnknown", nil);
        NSString *rawTypeString = [sourceDict objectForKey:@kIOPSTypeKey];
        
        if (rawTypeString) {
            
            if ([rawTypeString isEqualToString:@kIOPSInternalBatteryType]) {
                
                localizedHeader = NSLocalizedString(@"powerBattery", nil);
                
            } else if ([rawTypeString isEqualToString:@kIOPSUPSType]) {
                
                localizedHeader = NSLocalizedString(@"powerUPS", nil);
            }
        }
        
        [contentString appendAttributedString:[self formattedStringWithDictionary:sourceDict header:localizedHeader]];
    }
    
    [[_textView textStorage] setAttributedString:contentString];
}

- (NSAttributedString*)formattedStringWithDictionary:(NSDictionary*)dict header:(NSString*)header
{
    NSMutableAttributedString *contentString = [[NSMutableAttributedString alloc] init];
    
    NSArray *boolValues = [NSArray arrayWithObjects:
                            @kIOPSCommandEnableAudibleAlarmKey,
                            @kIOPSInternalFailureKey,
                            @kIOPSIsChargedKey,
                            @kIOPSIsChargingKey,
                            @kIOPSIsFinishingChargeKey,
                            @kIOPSIsPresentKey,
                            @"IsWireless",
                            @"Battery Provides Time Remaining",
                            @"LPM Active",
                            @"Optimized Battery Charging Engaged",
                            nil
    ];
    
    NSArray *currentValues = [NSArray arrayWithObjects:
                                @kIOPSPowerAdapterCurrentKey,
                                @kIOPSCurrentKey,
                                nil
    ];
    
    NSArray *voltageValues = [NSArray arrayWithObjects:
                                @kIOPSVoltageKey,
                                @"AdapterVoltage",
                                nil
    ];
    
    NSDictionary *headerAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSFont systemFontOfSize:[NSFont systemFontSize] weight:NSFontWeightBold],
                                      NSFontAttributeName,
                                      [NSColor textColor],
                                      NSForegroundColorAttributeName,
                                      nil
    
    ];
    NSDictionary *contentAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSFont systemFontOfSize:[NSFont systemFontSize] weight:NSFontWeightRegular],
                                       NSFontAttributeName,
                                       [NSColor textColor],
                                       NSForegroundColorAttributeName,
                                       nil
    ];
    
    NSMutableArray *tabStops = [[NSMutableArray alloc] init];
    NSTextTab *firstTab = [[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentLeft location:10 options:[NSDictionary dictionary]];
    [tabStops addObject:firstTab];
    
    NSMutableParagraphStyle *nameParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    
    // header
    NSAttributedString *headerString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:\n\n", header]
                                                                       attributes:headerAttributes];
    [contentString appendAttributedString:headerString];
    
    // content
    NSArray *allKeys = [dict allKeys];
    
    // sort the keys by length to get the longest key
    NSSortDescriptor *sortedByLength = [NSSortDescriptor sortDescriptorWithKey:@"length" ascending:NO];
    NSString *longestString = [[allKeys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortedByLength]] firstObject];
    
    // get the width for the longest string
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:longestString attributes:contentAttributes];
    NSRect stringRect = [attrString boundingRectWithSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin];
    
    // calculate the position of the second tab
    NSTextTab *lastTab = [[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentLeft location:NSWidth(stringRect) + 30 options:[NSDictionary dictionary]];
    [tabStops addObject:lastTab];
    [nameParagraphStyle setTabStops: tabStops];
    
    for (NSString *aKey in allKeys) {
        
        id objectValue = [dict objectForKey:aKey];
        
        if ([objectValue isKindOfClass:[NSString class]] || [objectValue isKindOfClass:[NSNumber class]]) {
            
            if ([boolValues containsObject:aKey]) {
                
                objectValue = ([objectValue boolValue]) ? @"Yes" : @"No";
                
            } else if ([currentValues containsObject:aKey]) {
                
                NSMeasurement *sourceCurrent = [[NSMeasurement alloc] initWithDoubleValue:[objectValue doubleValue]
                                                                                     unit:[NSUnitElectricCurrent milliamperes]
                ];

                NSMeasurementFormatter *measurementFormatter = [[NSMeasurementFormatter alloc] init];
                [[measurementFormatter numberFormatter] setMinimumFractionDigits:0];
                [[measurementFormatter numberFormatter] setMaximumFractionDigits:0];
                [measurementFormatter setUnitOptions:NSMeasurementFormatterUnitOptionsProvidedUnit];
                
                objectValue = [measurementFormatter stringFromMeasurement:sourceCurrent];
                
            } else if ([voltageValues containsObject:aKey]) {
                
                NSMeasurement *sourceVoltage = [[NSMeasurement alloc] initWithDoubleValue:[objectValue doubleValue]
                                                                                     unit:[NSUnitElectricPotentialDifference millivolts]
                ];

                NSMeasurementFormatter *measurementFormatter = [[NSMeasurementFormatter alloc] init];
                [[measurementFormatter numberFormatter] setMinimumFractionDigits:0];
                [[measurementFormatter numberFormatter] setMaximumFractionDigits:2];
                [measurementFormatter setUnitOptions:NSMeasurementFormatterUnitOptionsNaturalScale];
                
                objectValue = [measurementFormatter stringFromMeasurement:sourceVoltage];
            }
            
            NSString *stringValue = [NSString stringWithFormat:@"\t%@\t %@\n", [aKey stringByAppendingString:@":"], objectValue];
            NSAttributedString *subContentString = [[NSAttributedString alloc] initWithString:stringValue
                                                                                   attributes:contentAttributes];
            [contentString appendAttributedString:subContentString];
        }
    }
    
    [contentString addAttribute:NSParagraphStyleAttributeName
                          value: nameParagraphStyle
                          range: NSMakeRange(0, [contentString length])
    ];
    [contentString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n\n"]];
    
    return contentString;
}

- (IBAction)updateContent:(id)sender
{
    [self updatePowerInformation];
}

#pragma mark NSToolbarItemValidation

- (BOOL)enableToolbarItem:(NSToolbarItem *)item
{
    BOOL enable = NO;
    
    if (item) {

        if ([[item itemIdentifier] isEqualToString:MTToolbarConsoleReloadItemIdentifier]) {
            
            enable = YES;
        }
    }
        
    return enable;
}

- (void)dealloc
{
    CFRunLoopSourceInvalidate(self.sourceRef);
    self.sourceRef = nil;
}


@end
