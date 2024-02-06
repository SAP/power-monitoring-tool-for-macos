/*
     MTPowerGraphTooltip.m
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

#import "MTPowerGraphTooltip.h"

@interface MTPowerGraphTooltip ()
@property (weak) IBOutlet NSView *tooltipView;
@property (weak) IBOutlet NSTextField *powerValueField;
@property (weak) IBOutlet NSTextField *measurementDateField;
@property (weak) IBOutlet NSTextField *measurementTimeField;
@end

@implementation MTPowerGraphTooltip

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        
        // load the nib file
        NSNib *nibObject = [[NSNib alloc] initWithNibNamed:@"MTPowerGraphTooltip" bundle:nil];
        BOOL success = [nibObject instantiateWithOwner:self topLevelObjects:nil];
        
        if (success) {
            
            NSRect windowFrame = NSMakeRect(
                                            0,
                                            0,
                                            [self powerValueLineWidth] + 20, // add 20 because of 10 pixels leading and trailing space
                                            NSHeight([_tooltipView bounds])
                                            );
            
            [self setStyleMask:NSWindowStyleMaskBorderless];
            [self setBackingType:NSBackingStoreBuffered];
            [self setBackgroundColor:[NSColor clearColor]];
            [self setLevel:NSFloatingWindowLevel];
            [self setMovableByWindowBackground:NO];
            [self setExcludedFromWindowsMenu:YES];
            [self setReleasedWhenClosed:NO];
            [self setOpaque:NO];
            [self setFrame:windowFrame display:NO];
            
            [[self contentView] setFrame:[self frame]];
            [[self contentView] setWantsLayer:YES];
            [[[self contentView] layer] setFrame:[self frame]];
            [[[self contentView] layer] setCornerRadius:10.0];
            [[[self contentView] layer] setMasksToBounds:YES];
            
            NSVisualEffectView *effectView = [[NSVisualEffectView alloc] init];
            [effectView setFrame:[self frame]];
            [effectView setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
            [effectView setState:NSVisualEffectStateActive];
            [effectView setMaterial:NSVisualEffectMaterialToolTip];
            [effectView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
            
            [[self contentView] addSubview:effectView];
            [[self contentView] addSubview:_tooltipView];
        }
    }
    
    return self;
}

- (double)powerValueLineWidth
{
    double lineWidth = 0;
    
    // create an array with all possible types of power values (awake, sleep, power nap)
    MTPowerMeasurement *powerNapMeasurement = [[MTPowerMeasurement alloc] initWithPowerValue:99.99];
    [powerNapMeasurement setDarkWake:YES];
    
    NSArray *stringLengths = [[NSArray alloc] initWithObjects:
                                  [[MTPowerMeasurement alloc] initWithPowerValue:99.99],
                                  [[MTPowerMeasurement alloc] initWithPowerValue:0],
                                  powerNapMeasurement,
                                  nil
    ];
    
    // first, get the longest possible string…
    __block NSMutableAttributedString *longestString = nil;
    [stringLengths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSString *powerString = [self powerStringWithMeasurement:obj];
        
        if ([powerString length] > [[longestString string] length]) {
            longestString = [[NSMutableAttributedString alloc] initWithString:powerString];
        }
    }];
    
    // then, get the text attributes of the powerValue field…
    [_powerValueField setStringValue:@" "];
    NSDictionary *attributes = [[_powerValueField attributedStringValue] attributesAtIndex:0 effectiveRange:nil];
    
    // apply the field's text attributes to our string…
    [longestString setAttributes:attributes range:NSMakeRange(0, [[longestString string] length])];
    
    // and get the width of our attributed string
    CTLineRef ctLine = CTLineCreateWithAttributedString((CFMutableAttributedStringRef)longestString);
    
    if (ctLine) {
        lineWidth = CTLineGetTypographicBounds(ctLine, NULL, NULL, NULL);
        CFRelease(ctLine);
    }
    
    return lineWidth;
}

- (void)setMeasurement:(MTPowerMeasurement*)measurement
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[measurement timeStamp]];
    
    NSString *dateString = [NSDateFormatter localizedStringFromDate:date
                                                          dateStyle:NSDateFormatterMediumStyle
                                                          timeStyle:NSDateFormatterNoStyle
    ];
    
    NSString *timeString = [NSDateFormatter localizedStringFromDate:date
                                                          dateStyle:NSDateFormatterNoStyle
                                                          timeStyle:NSDateFormatterMediumStyle
    ];

    [_powerValueField setStringValue:[self powerStringWithMeasurement:measurement]];
    [_measurementDateField setStringValue:dateString];
    [_measurementTimeField setStringValue:timeString];
}

- (NSString*)powerStringWithMeasurement:(MTPowerMeasurement*)measurement
{
    NSMeasurementFormatter *powerFormatter = [[NSMeasurementFormatter alloc] init];
    NSString *statusString = NSLocalizedString(@"tooltipSleep", nil);
    
    if ([measurement doubleValue] > 0) {
        
        [[powerFormatter numberFormatter] setMinimumFractionDigits:2];
        [[powerFormatter numberFormatter] setMaximumFractionDigits:2];
        
        if ([measurement darkWake]) {
            
            statusString = NSLocalizedString(@"tooltipPowerNap", nil);
            
        } else {
            
            statusString = NSLocalizedString(@"tooltipAwake", nil);
        }
        
    } else {
        
        [[powerFormatter numberFormatter] setMinimumFractionDigits:0];
        [[powerFormatter numberFormatter] setMaximumFractionDigits:0];
    }
    
    return [[powerFormatter stringFromMeasurement:measurement] stringByAppendingFormat:@" (%@)", statusString];
}

# pragma mark window behavior

- (BOOL)canBecomeMainWindow
{
    return NO;
}

- (BOOL)canBecomeKeyWindow
{
    return NO;
}

- (BOOL)isExcludedFromWindowsMenu
{
    return YES;
}

@end
