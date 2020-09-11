//
//  CodeInjection.m
//  Attacks
//
//  Created by Toureek
//  Copyright © 2020 com.toureek.defense. All rights reserved.
//

#import "CodeInjection.h"
#import "SystemPtraceHeader.h"
#import "fishhook.h"

@implementation CodeInjection

+ (void)load {
    [self fishHookPtraceForHackingApp];
}

int (*pointerOnSystemPtrace)(int _request, pid_t _pid, caddr_t _addr, int _data);

int hooked_ptrace(int _request, pid_t _pid, caddr_t _addr, int _data) {
    if (_request != PT_DENY_ATTACH) {
        return pointerOnSystemPtrace(_request, _pid, _addr, _data);
    }
    return 0;
}

+ (void)fishHookPtraceForHackingApp {
    struct rebinding rebs;
    rebs.name = "ptrace";
    rebs.replacement = hooked_ptrace;
    rebs.replaced = (void *)&pointerOnSystemPtrace;
    struct rebinding array[] = {rebs};
    rebind_symbols(array, 1);
    NSLog(@"Break up ptrace(....) in Framework Injections successfully! ");
}

@end

