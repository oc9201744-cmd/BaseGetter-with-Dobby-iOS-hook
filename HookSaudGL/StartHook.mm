#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <mach/vm_prot.h>       // Bellek izinlerini değiştirmek için
#import <mach/mach.h>          // Mach API için ihtiyaç duyulan başlıklar
#include "BaseGetter.h"        // BaseGetter.h içe aktarıldı

const uintptr_t AccessoriesVRecoilFactor = 0xBC8; // Dikey geri tepme (Vertical Recoil)
const uintptr_t AccessoriesHRecoilFactor = 0xBD0; // Yatay geri tepme (Horizontal Recoil)
const uintptr_t AccessoriesRecoveryFactor = 0xBCC; // Geri tepme toparlama (Recovery)

// Bellek izinlerini değiştiren yardımcı fonksiyonlar
static bool setMemoryReadWrite(uintptr_t address, size_t size) {
    vm_address_t alignedAddress = (vm_address_t)(address & ~((uintptr_t)getpagesize() - 1)); // Sayfa hizalaması
    kern_return_t kr = vm_protect(mach_task_self(), alignedAddress, size, false, VM_PROT_READ | VM_PROT_WRITE);
    if (kr != KERN_SUCCESS) {
        NSLog(@"[Tweak] Bellek R/W moduna alınamadı: %d", kr);
        return false;
    }
    return true;
}

static bool setMemoryReadOnly(uintptr_t address, size_t size) {
    vm_address_t alignedAddress = (vm_address_t)(address & ~((uintptr_t)getpagesize() - 1)); // Sayfa hizalaması
    kern_return_t kr = vm_protect(mach_task_self(), alignedAddress, size, false, VM_PROT_READ);
    if (kr != KERN_SUCCESS) {
        NSLog(@"[Tweak] Bellek read-only moduna alınamadı: %d", kr);
        return false;
    }
    return true;
}

%hook YourGameClass

- (void)NoRecoilFunction {
    uintptr_t baseAddress = getBaseAddress("ShadowTrackerExtra");
    if (baseAddress == 0) {
        NSLog(@"Base Address bulunamadı!");
        return;
    }
    
    // Bellek adresleri
    uintptr_t vRecoilAddress = baseAddress + AccessoriesVRecoilFactor;
    uintptr_t hRecoilAddress = baseAddress + AccessoriesHRecoilFactor;
    uintptr_t recoveryAddress = baseAddress + AccessoriesRecoveryFactor;
    
    // READ-WRITE Bellek izini aç
    if (setMemoryReadWrite(vRecoilAddress, sizeof(float))) {
        *(float *)vRecoilAddress = 0.0f;
        *(float *)hRecoilAddress = 0.0f;
        *(float *)re