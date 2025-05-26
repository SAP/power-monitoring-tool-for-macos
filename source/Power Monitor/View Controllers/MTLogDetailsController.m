/*
     MTLogDetailsController.m
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

#import "MTLogDetailsController.h"
#import "Constants.h"

@interface MTLogDetailsController ()
@property (weak) IBOutlet NSTextView *logDetailsView;
@end

@implementation MTLogDetailsController

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    [_logDetailsView setFont:[NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightRegular]];
    
    // register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDetailView:)
                                                 name:kMTNotificationNameLogMessage
                                               object:nil
    ];
}

- (void)updateDetailView:(NSNotification*)notification
{
    NSDictionary *userInfo = [notification userInfo];
    
    if (userInfo) {
        
        NSString *logMessage = [userInfo objectForKey:kMTNotificationKeyLogMessage];
        if (logMessage) { [self.logDetailsView setString:logMessage]; }
    }
}

@end
