// --- Gerekli Tüm Framework ve Kütüphaneler ---
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AVFoundation/AVFoundation.h>
#import <GameController/GameController.h>
#import <GameKit/GameKit.h>
#import <CloudKit/CloudKit.h>
#import <DeviceCheck/DeviceCheck.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <Speech/Speech.h>
#import <Security/Security.h>

// --- Altyapı ---
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import "BaseGetter.h"

// ==========================================
// PB 4.2 OFFSETS
// ==========================================
const uintptr_t CurrentWeapon = 0x2A54;
const uintptr_t ShootWeaponEntityComp = 0x12C0;
const uintptr_t AccessoriesVRecoilFactor = 0xBC8;
const uintptr_t AccessoriesHRecoilFactor = 0xBD0;
const uintptr_t AccessoriesRecoveryFactor = 0xBCC;
const uintptr_t GameDeviationFactor = 0xC2C;
const uintptr_t RecoilKickADS = 0xCF0;

// Hafızaya Güvenli Yazma (Non-JB için vm_protect kullanımı)
void write_float(uintptr_t address, float value) {
    if (address < 0x100000000) return;
    vm_protect(mach_task_self(), (vm_address_t)address, sizeof(float), false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    *(float *)address = value;
    vm_protect(mach_task_self(), (vm_address_t)address, sizeof(float), false, VM_PROT_READ | VM_PROT_EXECUTE);
}

// ==========================================
// NO RECOIL LOOP
// ==========================================
void start_no_recoil() {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (true) {
            // Not: STExtraBaseCharacter instance'ını kendi methodunla çekmelisin
            // Örnek olarak BaseCharacter üzerinden silah enetity'sine ulaşıyoruz
            uintptr_t baseCharacter = 0; // Burada yerel oyuncu adresi olmalı
            
            if (baseCharacter > 0x100000000) {
                uintptr_t weapon = *(uintptr_t *)(baseCharacter + CurrentWeapon);
                if (weapon > 0x100000000) {
                    uintptr_t entity = *(uintptr_t *)(weapon + ShootWeaponEntityComp);
                    if (entity > 0x100000000) {
                        // Sekmeme ve Yayılma değerlerini sıfırla
                        write_float(entity + AccessoriesVRecoilFactor, 0.0f);
                        write_float(entity + AccessoriesHRecoilFactor, 0.0f);
                        write_float(entity + AccessoriesRecoveryFactor, 0.0f);
                        write_float(entity + GameDeviationFactor, 0.0f);
                        write_float(entity + RecoilKickADS, 0.0f);
                    }
                }
            }
            [NSThread sleepForTimeInterval:0.5]; // CPU yormadan 500ms'de bir tazele
        }
    });
}

__attribute__((constructor))
static void initialize() {
    // 15 saniye bekle (Oyunun açılması ve kütüphanelerin yüklenmesi için)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        start_no_recoil();
    });
}
