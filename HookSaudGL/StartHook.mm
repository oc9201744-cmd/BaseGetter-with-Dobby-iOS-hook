#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <mach/vm_prot.h>       // Bellek izinlerini değiştirmek için
#import <mach/mach.h>          // Mach API için ihtiyaç duyulan başlık
#include "BaseGetter.h"        // BaseGetter.h dahil

const uintptr_t AccessoriesVRecoilFactor = 0xBC8; // Dikey geri tepme
const uintptr_t AccessoriesHRecoilFactor = 0xBD0; // Yatay geri tepme
const uintptr_t AccessoriesRecoveryFactor = 0xBCC; // Geri tepme toparlanma

// Segmentin erişim izinlerini değiştir
bool setMemoryReadWrite(uintptr_t address, size_t size) {
    vm_address_t alignedAddress = (vm_address_t)(address & ~((uintptr_t)getpagesize() - 1)); // Sayfa başına hizalama
    kern_return_t kr = vm_protect(mach_task_self(), alignedAddress, size, false, VM_PROT_READ | VM_PROT_WRITE);
    if (kr != KERN_SUCCESS) {
        NSLog(@"[Tweak] Bellek R/W moduna alınamadı: %d", kr);
        return false;
    }
    return true;
}

bool setMemoryReadOnly(uintptr_t address, size_t size) {
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
    
    // Gerekli Offset Adreslerini Hesapla
    uintptr_t vRecoilAddress = baseAddress + AccessoriesVRecoilFactor;
    uintptr_t hRecoilAddress = baseAddress + AccessoriesHRecoilFactor;
    uintptr_t recoveryAddress = baseAddress + AccessoriesRecoveryFactor;
    
    // __DATA_CONST Segmentinde olduğunu varsayıyoruz
    // Önce R/W moduna alın
    if (setMemoryReadWrite(vRecoilAddress, sizeof(float))) {
        // Değişiklikler yap
        *(float *)vRecoilAddress = 0.0f;
        *(float *)hRecoilAddress = 0.0f;
        *(float *)recoveryAddress = 1.0f;
        NSLog(@"No Recoil Değiştirildi!");

        // Belleği tekrar R/O (read-only) moduna al
        if (!setMemoryReadOnly(vRecoilAddress, sizeof(float))) {
            NSLog(@"Belleği read-only moduna alırken hata oluştu!");
        }
    } else {
        NSLog(@"Belleği R/W moduna alma başarısız!");
    }
}

%end

__attribute__((constructor))
static void tweakEntry() {
    NSLog(@"Tweak yüklendi: Vtable Hook iOS 17 destekli.");
    %init;
}