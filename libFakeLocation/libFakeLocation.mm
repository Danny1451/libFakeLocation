//
//  libFakeLocation.mm
//  libFakeLocation
//
//  Created by danny on 16/7/22.
//  Copyright (c) 2016年 __MyCompanyName__. All rights reserved.
//

// CaptainHook by Ryan Petrich
// see https://github.com/rpetrich/CaptainHook/

#import <Foundation/Foundation.h>
#import "CaptainHook/CaptainHook.h"
#include <notify.h> // not required; for examples only
#import <CoreLocation/CoreLocation.h>

// Objective-C runtime hooking using CaptainHook:
//   1. declare class using CHDeclareClass()
//   2. load class using CHLoadClass() or CHLoadLateClass() in CHConstructor
//   3. hook method using CHOptimizedMethod()
//   4. register hook using CHHook() in CHConstructor
//   5. (optionally) call old method using CHSuper()
@interface CLLocation(Swizzle)

@end

@implementation CLLocation(Swizzle)


//这边设置默认的签到地址
static float x = 31.991912;
static float y = 118.744564; 

+ (void) load {
    Method m1 = class_getInstanceMethod(self, @selector(coordinate));
    Method m2 = class_getInstanceMethod(self, @selector(coordinate_));
    
    method_exchangeImplementations(m1, m2);
    
//    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"_fake_x"]) {
//        x = [[[NSUserDefaults standardUserDefaults] valueForKey:@"_fake_x"] floatValue];
//    };
//    
//    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"_fake_y"]) {
//        y = [[[NSUserDefaults standardUserDefaults] valueForKey:@"_fake_y"] floatValue];
//    };
}

- (CLLocationCoordinate2D) coordinate_ {
    
    CLLocationCoordinate2D pos = [self coordinate_];
    
    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"_fake_x"]) {
        x = [[[NSUserDefaults standardUserDefaults] valueForKey:@"_fake_x"] floatValue];
    };
    
    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"_fake_y"]) {
        y = [[[NSUserDefaults standardUserDefaults] valueForKey:@"_fake_y"] floatValue];
    };
    
    return CLLocationCoordinate2DMake(x, y);
//    return CLLocationCoordinate2DMake(pos.latitude-x, pos.longitude-y);
}


@end


CHDeclareClass(WWKConversationViewController);

CHMethod1(void, WWKConversationViewController, sm_sendLocation, id, arg1){
    CHSuper1(WWKConversationViewController, sm_sendLocation, arg1);
    
    NSLog(@" get info = %@" ,arg1);
    

    Ivar nsDetailIvar = class_getInstanceVariable(objc_getClass("WWKLocationItem"), "_detailAddressName");
    id m_nsDetail = object_getIvar(arg1, nsDetailIvar);
    
    NSLog(@" NOW ADRESS = %@" , m_nsDetail);
    
    Ivar nsCoordinateIvar = class_getInstanceVariable(objc_getClass("WWKLocationItem"), "_coordinate");
//    id m_nsPos = object_getIvar(arg1, nsCoordinateIvar);
    ptrdiff_t offset = ivar_getOffset(nsCoordinateIvar);
    unsigned char *stuffBytes = (unsigned char *)(__bridge void *)arg1;
    CLLocationCoordinate2D posLL = * ((CLLocationCoordinate2D *)(stuffBytes + offset));
    
    NSLog(@" pos x = %F ,pos y =%f" , posLL.latitude , posLL.longitude);
    

    
    [[NSUserDefaults standardUserDefaults] setValue:@(posLL.latitude) forKey:@"_fake_x"];
    [[NSUserDefaults standardUserDefaults] setValue:@(posLL.longitude) forKey:@"_fake_y"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

__attribute__((constructor)) static void entry()
{
    NSLog(@"Hello, Danny Hooked WX WORK!");
    CHLoadLateClass(WWKConversationViewController);
    CHClassHook(1, WWKConversationViewController, sm_sendLocation);
}

