/*
     MTDescriptionController.m
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

#import "MTDescriptionController.h"
#import "Constants.h"

@interface MTDescriptionController ()
@property (weak) IBOutlet NSTextField *powerDescription;
@end

@implementation MTDescriptionController

- (void)viewDidLoad
{
    [super viewDidLoad];
            
    NSMeasurement *measurementInterval = [[NSMeasurement alloc] initWithDoubleValue:kMTMeasurementInterval
                                                                               unit:[NSUnitDuration seconds]
    ];
    
    NSMeasurement *measurementPeriod = [[NSMeasurement alloc] initWithDoubleValue:kMTMeasurementTimePeriod
                                                                             unit:[NSUnitDuration hours]
    ];
    
    NSMeasurementFormatter *timeFormatter = [[NSMeasurementFormatter alloc] init];
    [[timeFormatter numberFormatter] setMaximumFractionDigits:0];
    [timeFormatter setUnitStyle:NSFormattingUnitStyleLong];
    [timeFormatter setUnitOptions:NSMeasurementFormatterUnitOptionsNaturalScale];

    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setMaximumFractionDigits:0];
    [numberFormatter setNumberStyle:NSNumberFormatterPercentStyle];
    
    [_powerDescription setStringValue:[NSString localizedStringWithFormat:NSLocalizedString(@"powerDescription", nil),
                                       [timeFormatter stringFromMeasurement:measurementInterval],
                                       [timeFormatter stringFromMeasurement:measurementPeriod],
                                       [numberFormatter stringFromNumber:[NSNumber numberWithFloat:.1]]
                                       ]
    ];
}

@end
