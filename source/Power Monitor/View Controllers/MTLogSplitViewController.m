/*
     MTLogSplitViewController.m
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

#import "MTLogSplitViewController.h"
#import "MTLogController.h"
#import "MTLogDetailsController.h"
#import "Constants.h"

@interface MTLogSplitViewController ()
@property (nonatomic, strong, readwrite) NSSplitViewItem *contentItem;
@property (nonatomic, strong, readwrite) NSSplitViewItem *detailsItem;
@end

@implementation MTLogSplitViewController

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    _contentItem = [[self splitViewItems] firstObject];
    _detailsItem = [[self splitViewItems] lastObject];
}

- (void)splitViewDidResizeSubviews:(NSNotification *)notification
{
    BOOL userResized = [[[notification userInfo] objectForKey:@"NSSplitViewUserResizeKey"] boolValue];
    
    if (userResized) {
        
        CGFloat dividerPosition = NSHeight([[[_contentItem viewController] view] frame]);
        [[NSUserDefaults standardUserDefaults] setFloat:dividerPosition forKey:kMTDefaultsLogDividerPositionKey];
    }
}

@end
