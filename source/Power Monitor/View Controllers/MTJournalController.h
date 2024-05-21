/*
     MTJournalController.h
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

#import <Cocoa/Cocoa.h>

@class MTJournalController;
/*!
 @protocol      MTJournalControllerDelegate
 @abstract      Defines an interface for delegates of MTJournalController to be notified if specific aspects of the journal have changed.
*/
@protocol MTJournalControllerDelegate <NSObject>

/*!
 @method        journalControllerSelectionDidChange:
 @abstract      Called whenever the selection of the journal array controller changed.
 @param         controller A reference to the NSArrayController instance.
 @discussion    Delegates receive this message whenever the selection of the journal array controller changed.
 */
- (void)journalControllerSelectionDidChange:(NSArrayController*)controller;

@end

@interface MTJournalController : NSViewController <NSTableViewDelegate>

/*!
 @property      delegate
 @abstract      The receiver's delegate.
 @discussion    The value of this property is an object conforming to the MTJournalControllerDelegate protocol.
*/
@property (weak) id <MTJournalControllerDelegate> delegate;

@end
