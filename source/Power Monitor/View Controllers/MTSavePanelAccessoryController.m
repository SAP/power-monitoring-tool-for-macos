/*
     MTSavePanelAccessoryController.m
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

#import "MTSavePanelAccessoryController.h"
#import "Constants.h"
#import <UniformTypeIdentifiers/UTCoreTypes.h>

@implementation MTSavePanelAccessoryController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.summarizeType = [self summarizeTypeForTag:[[NSUserDefaults standardUserDefaults] integerForKey:kMTDefaultsJournalExportSummarizeKey]];
}

- (NSCalendarUnit)summarizeTypeForTag:(NSInteger)tag
{
    NSCalendarUnit type = 0;
    
    switch (tag) {
            
        case 1:
            type = NSCalendarUnitWeekOfYear;
            break;
            
        case 2:
            type = NSCalendarUnitMonth;
            break;
            
        case 3:
            type = NSCalendarUnitYear;
            break;
            
        default:
            type = 0;
            break;
    }
    
    return type;
}

- (IBAction)selectExportFileType:(id)sender
{
    NSSavePanel *savePanel = (NSSavePanel*)[sender window];
    [savePanel setAllowedContentTypes:[NSArray arrayWithObject:([sender selectedTag] == 1) ? UTTypeJSON : UTTypeCommaSeparatedText]];
}

- (IBAction)setSummarizing:(id)sender
{
    self.summarizeType = [self summarizeTypeForTag:[sender selectedTag]];
}

@end
