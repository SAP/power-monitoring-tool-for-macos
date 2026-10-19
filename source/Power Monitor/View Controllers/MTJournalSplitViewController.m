/*
     MTJournalSplitViewController.m
     Copyright 2023-2026 SAP SE
     
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

#import "MTJournalSplitViewController.h"
#import "MTJournalController.h"
#import "MTJournalInspectorController.h"
#import "Constants.h"

@interface MTJournalSplitViewController ()
@property (nonatomic, strong, readwrite) NSSplitViewItem *contentItem;
@property (nonatomic, strong, readwrite) NSSplitViewItem *inspectorItem;
@end

@implementation MTJournalSplitViewController

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    _contentItem = [[self splitViewItems] firstObject];
    _inspectorItem = [[self splitViewItems] lastObject];
    
    // set a delegate so we can pass data to our inspector
    MTJournalController *contentController = (MTJournalController*)[_contentItem viewController];
    MTJournalInspectorController *inspectorController = (MTJournalInspectorController*)[_inspectorItem viewController];
    [contentController setDelegate:inspectorController];
}

- (void)splitViewDidResizeSubviews:(NSNotification *)notification
{
    BOOL userResized = [[[notification userInfo] objectForKey:@"NSSplitViewUserResizeKey"] boolValue];
    
    if (userResized) {
        
        CGFloat dividerPosition = NSWidth([[[_contentItem viewController] view] frame]);
        [[NSUserDefaults standardUserDefaults] setFloat:dividerPosition forKey:kMTDefaultsJournalDividerPositionKey];
    }
}

@end
