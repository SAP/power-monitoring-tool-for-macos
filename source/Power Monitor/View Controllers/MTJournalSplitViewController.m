/*
     MTJournalSplitViewController.m
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

#import "MTJournalSplitViewController.h"
#import "MTJournalController.h"
#import "MTJournalInspectorController.h"
#import "Constants.h"

@implementation MTJournalSplitViewController

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    NSSplitViewItem *contentItem = [[self splitViewItems] firstObject];
    NSSplitViewItem *inspectorItem = [[self splitViewItems] lastObject];
    
    // set a delegate so we can pass data to our inspector
    MTJournalController *contentController = (MTJournalController*)[contentItem viewController];
    MTJournalInspectorController *inspectorController = (MTJournalInspectorController*)[inspectorItem viewController];
    [contentController setDelegate:inspectorController];
}

@end
