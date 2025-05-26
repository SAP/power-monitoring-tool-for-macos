/*
     MTAssertionsController.m
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

#import "MTAssertionsController.h"
#import "MTSystemInfo.h"
#import "Constants.h"

@interface MTAssertionsController ()
@property (nonatomic, strong, readwrite) NSMutableArray *assertionEntries;

@property (weak) IBOutlet NSTableView *assertionsTableView;
@property (weak) IBOutlet NSArrayController *assertionsController;
@end

@implementation MTAssertionsController

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    [_assertionsTableView setAccessibilityLabel:NSLocalizedString(@"accessiblilityLabelAssertionsTableView", nil)];
    
    _assertionEntries = [[NSMutableArray alloc] init];
    NSSortDescriptor *initialSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"Process Name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    [self.assertionsController setSortDescriptors:[NSArray arrayWithObject:initialSortDescriptor]];
    
    [self updateProcessList];
}

- (void)updateProcessList
{
    NSArray *processList = [MTSystemInfo processesPreventingSleep];
    
    if (processList) {
        self.assertionEntries = [NSMutableArray arrayWithArray:processList];
    }
}

- (IBAction)updateContent:(id)sender
{
    [self updateProcessList];
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


@end
