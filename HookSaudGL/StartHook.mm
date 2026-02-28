#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <mach/vm_prot.h>
#import <mach/mach.h>

#include "BaseGetter.h"   // getBaseAddress buradan geliyor

// Offsets
const uintptr_t AccessoriesVRecoilFactor    = 0xBC8;
const uintptr_t AccessoriesHRecoilFactor    = 0xBD0;
const uintptr_t AccessoriesRecoveryFactor   = 0xBCC;

// Bellek izinlerini ayarlayan yardımcılar
static bool setMemoryReadWrite(uintptr_t address, size_t size) {
    vm_address_t pageSize = (vm_address_t)getpagesize();
    vm_address_t aligned  = (vm_address_t)(address & ~(pageSize - 1));

    kern_return_t kr = vm_protect(mach_task_self(),
                                  aligned,
                                  size,
                                  false,
                                  VM_PROT_READ | VM_PROT_WRITE);
    if (kr != KERN_SUCCESS) {
        NSLog(@"[XO] vm_protect RW failed: %d", kr);
        return false;
    }
    return true;
}

static bool setMemoryReadOnly(uintptr_t address, size_t size) {
    vm_address_t pageSize = (vm_address_t)getpagesize();
    vm_address_t aligned  = (vm_address_t)(address & ~(pageSize - 1));

    kern_return_t kr = vm_protect(mach_task_self(),
                                  aligned,
                                  size,
                                  false,
                                  VM_PROT_READ);
    if (kr != KERN_SUCCESS) {
        NSLog(@"[XO] vm_protect RO failed: %d", kr);
        return false;
    }
    return true;
}

// Orijinal metod imzası
typedef void (*NoRecoilFunc_t)(id, SEL);

// Globalde orijinal implementation
static NoRecoilFunc_t g_origNoRecoil = NULL;

// Asıl patch işi – ShadowTrackerExtra base + offsets
static void XO_ApplyNoRecoil(void) {
    uintptr_t baseAddress = getBaseAddress("ShadowTrackerExtra");
    if (baseAddress == 0) {
        NSLog(@"[XO] Base address bulunamadı (ShadowTrackerExtra)");
        return;
    }

    uintptr_t vRecoilAddress  = baseAddress + AccessoriesVRecoilFactor;
    uintptr_t hRecoilAddress  = baseAddress + AccessoriesHRecoilFactor;
    uintptr_t recoveryAddress = baseAddress + AccessoriesRecoveryFactor;

    // __DATA_CONST'ta olma ihtimaline karşı önce R/W yap
    if (!setMemoryReadWrite(vRecoilAddress, sizeof(float))) {
        NSLog(@"[XO] Belleği RW yaparken hata");
        return;
    }

    *(float *)vRecoilAddress  = 0.0f;
    *(float *)hRecoilAddress  = 0.0f;
    *(float *)recoveryAddress = 1.0f;

    // Tekrar read-only'a al (iOS 17 SG_READ_ONLY kuralı)
    if (!setMemoryReadOnly(vRecoilAddress, sizeof(float))) {
        NSLog(@"[XO] Belleği tekrar RO yaparken hata");
    }

    NSLog(@"[XO] NoRecoil patch uygulandı. base=0x%lx",
          (unsigned long)baseAddress);
}

// Hook'lanmış metodun gövdesi
static void XO_NoRecoilFunction(id self, SEL _cmd) {
    // İstersen oyunun orijinal fonksiyonunu da çağır:
    if (g_origNoRecoil) {
        g_origNoRecoil(self, _cmd);
    }

    // Ardından bizim patch
    XO_ApplyNoRecoil();
}

// Constructor – class ve method'u bularak hooklar
__attribute__((constructor))
static void XO_StartHook(void) {
    @autoreleasepool {
        NSLog(@"[XO] StartHook constructor çalıştı");

        // Burada gerçek sınıf adını yazman gerekiyor
        // Örn: @"PlayerController" vs.
        Class gameClass = NSClassFromString(@"YourGameClass");
        if (!gameClass) {
            NSLog(@"[XO] YourGameClass bulunamadı! Sınıf adını düzelt.");
            return;
        }

        // Burada da gerçek selector adını yaz:
        SEL sel = NSSelectorFromString(@"NoRecoilFunction");
        Method m = class_getInstanceMethod(gameClass, sel);
        if (!m) {
            NSLog(@"[XO] NoRecoilFunction metodu bulunamadı! Selector adını kontrol et.");
            return;
        }

        IMP origImp = method_getImplementation(m);
        g_origNoRecoil = (NoRecoilFunc_t)origImp;

        IMP newImp = (IMP)XO_NoRecoilFunction;
        method_setImplementation(m, newImp);

        NSLog(@"[XO] %@::NoRecoilFunction hooklandı", NSStringFromClass(gameClass));
    }
}