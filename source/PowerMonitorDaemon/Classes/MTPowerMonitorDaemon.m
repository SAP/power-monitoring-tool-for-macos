/*
     MTPowerMonitorDaemon.m
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

#import "MTPowerMonitorDaemon.h"
#import "MTPowerMeasurement.h"
#import "MTPowerMeasurementWriter.h"
#import "MTSystemInfo.h"
#import "Constants.h"
#import <os/log.h>

@interface MTPowerMonitorDaemon ()
@property (atomic, strong, readwrite) NSXPCListener *listener;
@property (nonatomic, strong, readwrite) NSTimer *measurementTimer;
@property (nonatomic, strong, readwrite) MTPowerMeasurementWriter *pMWriter;
@property (nonatomic, strong, readwrite) MTSleepWatcher *watcher;
@property (assign) BOOL isDarkWake;
@property (assign) BOOL resetMeasurements;
@end

@implementation MTPowerMonitorDaemon

- (instancetype)init
{
    self = [super init];
    
    if (self) {
                
        _listener = [[NSXPCListener alloc] initWithMachServiceName:kMTDaemonMachServiceName];
        [_listener setDelegate:self];
        [_listener resume];
    }
    
    return self;
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    BOOL acceptConnection = NO;
    
    if (listener == _listener && newConnection != nil) {
        
        NSXPCInterface *exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(PowerMonitorDaemonProtocol)];
        [newConnection setExportedInterface:exportedInterface];
        [newConnection setExportedObject:self];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
        [newConnection setInvalidationHandler:^{
                      
            [newConnection setInvalidationHandler:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                os_log(OS_LOG_DEFAULT, "SAPCorp: %{public}@ invalidated", newConnection);
            });
        }];
#pragma clang diagnostic pop
        
        // Resuming the connection allows the system to deliver more incoming messages.
        [newConnection resume];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            os_log(OS_LOG_DEFAULT, "SAPCorp: %{public}@ established", newConnection);
        });
        
        acceptConnection = YES;
    }

    return acceptConnection;
}

- (BOOL)startMonitoring
{
    BOOL success = NO;
    
    _pMWriter = [[MTPowerMeasurementWriter alloc] initWithFileAtPath:kMTMeasurementFilePath
                                                 maximumMeasurements:kMTMeasurementTimePeriod * 60 * (60 / kMTMeasurementInterval)];
    if (_pMWriter) {
        
#ifdef DEBUG
        printf("Power monitoring started…\n");
#endif
        success = YES;
        
        _watcher = [[MTSleepWatcher alloc] initWithDelegate:self];
        [_watcher startWatching];
        
        _isDarkWake = ([[_watcher currentEvent] type] == MTPowerEventTypeDarkWake) ? YES : NO;
        
        // get the latest measurement to adjust file location
        __block NSInteger bufferIndex = [_pMWriter currentBufferIndex];
        
        // start measuring…
        _measurementTimer = [NSTimer scheduledTimerWithTimeInterval:kMTMeasurementInterval
                                                            repeats:YES
                                                              block:^(NSTimer *timer) {
            if (self->_resetMeasurements) {
                
                bufferIndex = 0;
                NSMutableData *zeroData = [[NSMutableData alloc] initWithLength:[[self->_pMWriter measurementData] length]];
                [[self->_pMWriter measurementData] replaceMappedBytesInRange:NSMakeRange(bufferIndex, [[self->_pMWriter measurementData] length])
                                                                   withBytes:[zeroData bytes]];
                self->_resetMeasurements = NO;
            }
            
            // get current system power
            float powerValue = [MTSystemInfo rawSystemPower];
            
            if (powerValue > 0) {
                
                // write data
                MeasurementStruct data;
                data.timestamp = CFSwapInt64HostToBig([[NSDate date] timeIntervalSince1970]);
                data.value = CFSwapInt32HostToBig(*(int*)(&powerValue));
                data.darkwake = self->_isDarkWake;
                [[self->_pMWriter measurementData] replaceMappedBytesInRange:NSMakeRange(bufferIndex, sizeof(data)) withBytes:&data];
#ifdef DEBUG
                printf("System power (%lu): %f W\n", bufferIndex / sizeof(data), powerValue);
#endif
                if (bufferIndex + sizeof(data) >= [[self->_pMWriter measurementData] length]) {
                    bufferIndex = 0;
                } else {
                    bufferIndex += sizeof(data);
                }
            }
        }];

    } else {

        fprintf(stderr, "ERROR! Failed to access buffer file: %s\n", [kMTMeasurementFilePath UTF8String]);
    }
    
    return success;
}

- (BOOL)stopMonitoring
{
    [_measurementTimer invalidate];
    _measurementTimer = nil;
    _pMWriter = nil;
    
    BOOL success = [_watcher stopWatching];
    
#ifdef DEBUG
    printf("Power monitoring stopped\n");
#endif
    
    return success;
}

#pragma mark exported methods

- (void)connectWithEndpointReply:(void (^)(NSXPCListenerEndpoint *endpoint))reply
{
    reply([_listener endpoint]);
}

- (void)logEntriesSinceDate:(NSDate*)date completionHandler:(void (^)(NSArray<OSLogEntry*> *entries))completionHandler
{
    OSLogStore *logStore = [OSLogStore storeWithScope:OSLogStoreSystem error:nil];
    
    OSLogPosition *position = (date) ? [logStore positionWithDate:date] : nil;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"subsystem == %@ AND category IN %@",
                              @"com.apple.powerd",
                              [NSArray arrayWithObjects:
                                    @"assertions",
                                    @"coreSmartPowerNap",
                                    @"lowPowerMode",
                                    @"pmSettings",
                                    @"sleepWake",
                                    @"systemLoad",
                                    @"wakeRequests",
                                    nil
                              ]
    ];
    
    OSLogEnumerator *logEnumerator = [logStore entriesEnumeratorWithOptions:0
                                                                   position:position
                                                                  predicate:predicate
                                                                      error:nil];
    completionHandler([logEnumerator allObjects]);
}

- (void)deleteMeasurementsWithCompletionHandler:(void (^)(void))completionHandler
{
    _resetMeasurements = YES;
    [_measurementTimer fire];
    
    completionHandler();
}

- (void)enablePowerNap:(BOOL)enable acPowerOnly:(BOOL)aconly completionHandler:(void (^)(BOOL success))completionHandler
{
    BOOL success = [MTSystemInfo enablePowerNap:enable acPowerOnly:aconly];
    completionHandler(success);
}

#pragma mark MTSleepWatcherDelegate methods

- (void)powerEvent:(MTPowerEvent *)event willChangeType:(MTPowerEventType)type
{
    _isDarkWake = (type == MTPowerEventTypeDarkWake) ? YES : NO;
}

- (void)powerEventDidEnd:(MTPowerEvent *)event
{
    return;
}

- (void)powerEventDidStart:(MTPowerEvent *)event
{
    _isDarkWake = ([event type] == MTPowerEventTypeDarkWake) ? YES : NO;
}

@end
