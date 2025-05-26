/*
     MTLogLevelValueTransformer.m
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

#import "MTLogLevelValueTransformer.h"
#import <OSLog/OSLog.h>

@implementation MTLogLevelValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    NSImage *levelIndicator = nil;
    
    if (value && [value isKindOfClass:[OSLogEntryLog class]]) {
        
        OSLogEntryLog *entry = (OSLogEntryLog*)value;

        if ([entry level] == OSLogEntryLogLevelError) {

            NSImageSymbolConfiguration *config = [NSImageSymbolConfiguration configurationWithHierarchicalColor:[NSColor systemYellowColor]];
            
            levelIndicator = [[NSImage imageWithSystemSymbolName:@"circlebadge.fill" accessibilityDescription:nil] imageWithSymbolConfiguration:config];
            
        } else if ([entry level] == OSLogEntryLogLevelFault) {
            
            NSImageSymbolConfiguration *config = [NSImageSymbolConfiguration configurationWithHierarchicalColor:[NSColor systemRedColor]];
            
            levelIndicator = [[NSImage imageWithSystemSymbolName:@"circlebadge.fill" accessibilityDescription:nil] imageWithSymbolConfiguration:config];
        }
    }
        
    return levelIndicator;
}

@end
