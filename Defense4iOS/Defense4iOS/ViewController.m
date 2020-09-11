//
//  ViewController.m
//  Defense4iOS
//
//  Created by Toureek
//  Copyright © 2020 com..defense. All rights reserved.
//

#import "ViewController.h"
#import "SystemPtraceHeader.h"
#import <dlfcn.h>
#import <objc/runtime.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>

// 这里只举例一部分
const char *dylibraries_whiteList = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/usr/lib/libBacktraceRecording.dylib;/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/usr/lib/libMainThreadChecker.dylib;/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/Developer/Library/PrivateFrameworks/DTDDISupport.framework/libViewDebuggerSupport.dylib;/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/Frameworks/AssetsLibrary.framework/AssetsLibrary;/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics;/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/Frameworks/Foundation.framework/Foundation;/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/Frameworks/ImageIO.framework/ImageIO;/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/Frameworks/MediaPlayer.framework/MediaPlayer;/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/Frameworks/MobileCoreServices.framework/MobileCoreServices;/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/Frameworks/QuartzCore.framework/QuartzCore;/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/Frameworks/Security.framework/Security;/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/Frameworks/SystemConfiguration.framework/SystemConfiguration;/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/Frameworks/UIKit.framework/UIKit;/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/Frameworks/Photos.framework/Photos;/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/usr/lib/libobjc.A.dylib;/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/usr/lib/libSystem.B.dylib;....";


@interface ViewController ()

@end

@implementation ViewController

+ (void)load {
    [self preventAppFromAttachingDebug_InPtrace];
    [self preventAppFromHookingByFishHook_InDlopenWithPointer];
    [self preventAppFromInjectedByDynamicLibrary_WhiteListFilter];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.userInteractionEnabled = true;
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)runningOrderTest {
    NSLog(@"runningOrderTest");
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"Touching Screen Right Now!!!");
}


/**
 You cannot invoke ptrace(....)-method directly when you want to submit your App to AppStore
 */
+ (void)preventAppFromAttachingDebug_InPtrace {
    ptrace(PT_DENY_ATTACH, 0, 0, 0);
}


/**
 Invoke by handler
 ptrace() stop right there on libsystem_kernel.dylib in Debugging Symbol-BreakingPoint
 Lib-Path on my iPhone is:  /Symbols/usr/lib/system/libsystem_kernel.dylib
 
 Invoke the full method in function-pointer way.
 */
+ (void)preventAppFromHookingByFishHook_InDlopenWithPointer {
    void *handler = dlopen("/usr/lib/system/libsystem_kernel.dylib", RTLD_LAZY);
    int (*pointerOnSystemPtrace)(int _request, pid_t _pid, caddr_t _addr, int _data);
    pointerOnSystemPtrace = dlsym(handler, "ptrace");
    pointerOnSystemPtrace(PT_DENY_ATTACH, 0, 0, 0);
}


+ (void)preventAppFromInjectedByDynamicLibrary_WhiteListFilter {
    int dylibsCount = _dyld_image_count();
    // 因为运行是真机模式，模拟器运行是沙盒sandbox，所以第一个image的path是随机化的
    for (int i = 1; i < dylibsCount; i++) {
        const char *imageName = _dyld_get_image_name(i);
        if (!(strstr(dylibraries_whiteList, imageName))) {  // 白名单检测动态库
            NSLog(@"There is at least one dynamic lib which not in Released-WhiteList\n App is in danger!!!");
        } else {
            NSLog(@"No additional dynamic libs found. Be Safe.");
        }
    }
}

@end
