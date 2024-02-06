/*
     MTModifyData.h
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

#import <Foundation/Foundation.h>

/*!
 @abstract      This extends the NSData class with the method replaceMappedBytesInRange:withBytes: to allow
                the modification of memory-mapped data.
*/

@interface NSData (MTModifyData)

/*!
 @method        replaceMappedBytesInRange:withBytes:
 @abstract      Replaces with a given set of bytes a given range within the contents of the receiver.
 @param         range The range within the receiver's contents to replace with bytes. The range must not exceed the bounds of the receiver.
 @param         bytes The data to insert into the receiver's contents.
 @discussion    If the location of range isn’t within the receiver’s range of bytes, an NSRangeException is raised.
                The receiver is resized to accommodate the new bytes, if necessary.
*/
- (void)replaceMappedBytesInRange:(NSRange)range withBytes:(const void *)bytes;

@end
