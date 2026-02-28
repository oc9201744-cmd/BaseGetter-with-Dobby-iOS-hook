#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <mach/vm_prot.h>
#import <mach/mach.h>

#include "BaseGetter.h"

const uintptr_t AccessoriesVRecoilFactor = 0xBC8;
const uintptr_t AccessoriesHRecoilFactor = 0xBD0;
const uintptr_t AccessoriesRecoveryFactor = 0xBCC;

// Bellek izinlerini ayarlayan yardımcılar
static bool setMemoryReadWrite(uintptr_t address, size_t size) {
    vm_address_t alignedAddress = (vm_address_t)(address & ~((uintptr_t)getpagesize() - 1));
    kern_return_t kr = vm_protect(mach_task_self(), alignedAddress, size, false,
                                  VM_PROT_READ | VM_PROT_WRITE);
    if (kr != KERN_SUCCESS) {
        NSLog(@"[XO] vm_protect RW failed: %d", kr);
        return false;
    }
    return true;
}

static bool setMemoryReadOnly(uintptr_t address, size_t size) {
    vm_address_t alignedAddress = (vm_address_t)(address & ~((uintptr_t)getpagesize() - 1));
    kern_return_t kr = vm_protect(mach_task_self(), alignedAddress, size, false,
                                  VM_PROT_READ);
    if (kr != KERN_SUCCESS) {
        NSLog(@"[XO] vm_protect R failed: %d", kr);
        return false;
    }
    return true;
}

// Orijinal metod pointer'ı için typedef
typedef void (*NoRecoilFunc_t)(id, SEL);

// Orijinal implementation'ı tutalım
static NoRecoilFunc_t orig_NoRecoilFunction = NULL;

// ShadowTrackerExtra base + offsets ile no recoil uygula
static void XO_ApplyNoRecoil(void) {
    uintptr_t baseAddress = getBaseAddress("ShadowTrackerExtra");
    if (baseAddress == 0) {
        NSLog(@"[XO] Base address bulunamadı");
        return;
    }

    uintptr_t vRecoilAddress = baseAddress + AccessoriesVRecoilFactor;
    uintptr_t hRecoilAddress = baseAddress + AccessoriesHRecoilFactor;
    uintptr_t recoveryAddress = baseAddress + AccessoriesRecoveryFactor;

    // __DATA_CONST olabilir, önce RW yap
    if (!setMemoryReadWrite(vRecoilAddress, sizeof(float))) {
        NSLog(@"[XO] RW yaparken hata");
        return;
    }

    *(float *)vRecoilAddress = 0.0f;
    *(float *)hRecoilAddress = 0.0f;
    *(float *)recoveryAddress = 1.0f;

    // Tekrar R-only
    if (!setMemoryReadOnly(vRecoilAddress, sizeof(float))) {
        NSLog(@"[XO] RO yaparken hata");
    }

    NSLog(@"[XO] NoRecoil patch uygulandı. base=0x%lx",
          (unsigned long)baseAddress);
}

// Hook'ladığımız metod
static void XO_NoRecoilFunction(id self, SEL _cmd) {
    // İstersen önce orijinali çağır:
    if (orig_NoRecoilFunction) {
        orig_NoRecoilFunction(self, _cmd);
    }

    // Sonra patch uygula
    XO_ApplyNoRecoil();
}

// Entry point – sınıfı bul, metodu hookla
__attribute__((constructor))
static void XO_StartHook(void) {
    @autoreleasepool {
        NSLog(@"[XO] StartHook constructor çalıştı");

        // Oyun sınıfı ismini burada gerçek sınıf adıyla değiştir
        Class gameClass = NSClassFromString(@"YourGameClass");
        if (!gameClass) {
            NSLog(@"[XO] YourGameClass bulunamadı!");
            return;
        }

        SEL sel = NSSelectorFromString(@"NoRecoilFunction");
        Method m = class_getInstanceMethod(gameClass, sel);
        if (!m) {
            NSLog(@"[XO] NoRecoilFunction metodu bulunamadı!");
            return;
        }

        IMP origImp = method_getImplementation(m);
        orig_NoRecoilFunction = (NoRecoilFunc_t)origImp;

        // Yeni implementation
        IMP newImp = (IMP)XO_NoRecoilFunction;
        method_setImplementation(m, newImp);

        NSLog(@"[XO] NoRecoilFunction hooklandı");
    }
}