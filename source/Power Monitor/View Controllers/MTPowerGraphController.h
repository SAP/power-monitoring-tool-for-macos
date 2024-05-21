/*
     MTPowerGraphController.h
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
#import "MTPowerGraphView.h"

@class MTPowerGraphController;
/*!
 @protocol      MTPowerGraphControllerDelegate
 @abstract      Defines an interface for delegates of MTPowerGraphController to be notified if specific aspects of the view have changed.
*/
@protocol MTPowerGraphControllerDelegate <NSObject>

/*!
 @method        graphView:didSelectMeasurement:
 @abstract      Called whenever the position line selected a new measurement.
 @param         view A reference to the MTPowerGraphView instance.
 @param         measurement A reference to the MTPowerMeasurement that has been selected.
 @discussion    Delegates receive this message whenever the position line selected a new measurement.
 */
- (void)graphView:(MTPowerGraphView*)view didSelectMeasurement:(MTPowerMeasurement*)measurement;

/*!
 @method        graphView:didChangePinning:
 @abstract      Called whenever the pinning of the view has changed.
 @param         view A reference to the MTPowerGraphView instance.
 @param         isPinned Returns YES if there's a value pinned, otherwise returns NO.
 @discussion    Delegates receive this message whenever pinning changed.
 */
- (void)graphView:(MTPowerGraphView*)view didChangePinning:(BOOL)isPinned;

/*!
 @method        mouseEnteredGraphView:
 @abstract      Called whenever the mouse pointer enters the view.
 @param         view A reference to the MTPowerGraphView instance.
 @discussion    Delegates receive this message whenever the mouse pointer enters the view.
 */
- (void)mouseEnteredGraphView:(MTPowerGraphView*)view;

/*!
 @method        mouseExitedGraphView:
 @abstract      Called whenever the mouse pointer exited the view.
 @param         view A reference to the MTPowerGraphView instance.
 @discussion    Delegates receive this message whenever the mouse pointer exited the view.
 */
- (void)mouseExitedGraphView:(MTPowerGraphView*)view;

@end

@interface MTPowerGraphController : NSViewController

/*!
 @property      delegate
 @abstract      The receiver's delegate.
 @discussion    The value of this property is an object conforming to the MTPowerGraphControllerDelegate protocol.
*/
@property (weak) id <MTPowerGraphControllerDelegate> delegate;

@end

