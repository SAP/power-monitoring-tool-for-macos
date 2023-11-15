/*
     MTSystemInfo.h
     Copyright 2023 SAP SE
     
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

#import <Foundation/Foundation.h>

/*!
 @class         MTSystemInfo
 @abstract      This class provides methods to get some system information.
*/

@interface MTSystemInfo : NSObject

/*!
 @method        processList
 @abstract      Returns a list of all running processes.
 @discussion    Returns an array containing the complete paths to all running processes
                or nil, if an error occurred.
*/
+ (NSArray*)processList;

/*!
 @method        rawSystemPower
 @abstract      Returns the Mac's current power value.
*/
+ (float)rawSystemPower;


@end
