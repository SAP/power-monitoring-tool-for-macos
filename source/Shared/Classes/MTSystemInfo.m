/*
     MTSystemInfo.m
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

#import "MTSystemInfo.h"
#import <libproc.h>

@implementation MTSystemInfo

typedef struct {
  uint32_t  key;
  char      unused0[24];
  uint32_t  size;
  char      unused1[10];
  char      command;
  char      unused2[5];
  float     value;
  char      unused3[28];
} AppleSMCData;

+ (NSArray *)processList
{
    NSMutableArray *processList = [[NSMutableArray alloc] init];
    
    int numberOfProcesses = proc_listpids(PROC_ALL_PIDS, 0, NULL, 0);
    pid_t pids[numberOfProcesses];
    bzero(pids, sizeof(pids));
    proc_listpids(PROC_ALL_PIDS, 0, pids, (int)sizeof(pids));
    
    for (int i = 0; i < numberOfProcesses; ++i) {
        if (pids[i] == 0) { continue; }
        char pathBuffer[PROC_PIDPATHINFO_MAXSIZE];
        bzero(pathBuffer, PROC_PIDPATHINFO_MAXSIZE);
        proc_pidpath(pids[i], pathBuffer, sizeof(pathBuffer));
        
        if (strlen(pathBuffer) > 0) {
            NSString *processPath = [NSString stringWithUTF8String:pathBuffer];
            NSString *processName = [processPath lastPathComponent];
            [processList addObject:processName];
        }
    }
    
    return processList;
}

+ (float)rawSystemPower
{
    float returnValue = 0;
    
    io_service_t smc = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"));
    
    if (smc) {
        
        io_connect_t conn = IO_OBJECT_NULL;
        IOReturn result = IOServiceOpen(smc, mach_task_self(), 1, &conn);
        
        if (result == kIOReturnSuccess && conn != IO_OBJECT_NULL) {
            
            AppleSMCData inStruct, outStruct;
            size_t outStructSize = sizeof(AppleSMCData);

            bzero(&inStruct, sizeof(AppleSMCData));
            bzero(&outStruct, sizeof(AppleSMCData));
            
            inStruct.command = 5; // read command
            inStruct.size = 4;
            inStruct.key = ('P' << 24) + ('S' << 16) + ('T' << 8) + 'R';
            
            result = IOConnectCallStructMethod(conn, 2, &inStruct, sizeof(AppleSMCData), &outStruct, &outStructSize);
            IOServiceClose(conn);

            if (result == kIOReturnSuccess) { returnValue = outStruct.value; }
        }
    }
    
    return returnValue;
}

@end
