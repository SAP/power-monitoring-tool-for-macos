/*
     MTSidebarItem.h
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

#import <Cocoa/Cocoa.h>

/*!
 @class         MTSidebarItem
 @abstract      This class specifies a sidebar item.
*/

@interface MTSidebarItem : NSObject

/*!
 @property      label
 @abstract      A property to specify the text label of a sidebar item.
 @discussion    The value of this property is NSString.
*/
@property (nonatomic, strong, readwrite) NSString *label;

/*!
 @property      image
 @abstract      A property to specify the image of a sidebar item.
 @discussion    The value of this property is NSImage.
*/
@property (nonatomic, strong, readwrite) NSImage *image;

/*!
 @property      targetViewControllerIdentifier
 @abstract      A property to specify the identifier of the target view controller to be called when
                the sidebar item is clicked.
 @discussion    The value of this property is NSString.
*/
@property (nonatomic, strong, readwrite) NSString *targetViewControllerIdentifier;

@end
