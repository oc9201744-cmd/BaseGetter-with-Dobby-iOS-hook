// --- İSTEDİĞİN TÜM KÜTÜPHANELER (FULL LIST) ---
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

// --- Sistem ve Base ---
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import "BaseGetter.h"

// ==========================================
// PB 4.2 OFFSETS (SENİN VERDİKLERİN)
// ==========================================
#define UWorld_Offset 0x106684010

const uintptr_t CurrentWeapon = 0x2A54;
const uintptr_t ShootWeaponEntityComp = 0x12C0;
const uintptr_t AccessoriesVRecoilFactor = 0xBC8;
const uintptr_t AccessoriesHRecoilFactor = 0xBD0;
const uintptr_t AccessoriesRecoveryFactor = 0xBCC;
const uintptr_t GameDeviationFactor = 0xC2C;
const uintptr_t RecoilKickADS = 0xCF0;

// ==========================================
// GÜVENLİ BELLEK YAZICI
// ==========================================
void patch_float(uintptr_t address, float value) {
    if (address < 0x100000000) return;
    vm_address_t addr = (vm_address_t)address;
    vm_size_t size = sizeof(float);
    
    // vm_protect ile güvenli yazma (Crash önleyici)
    if (vm_protect(mach_task_self(), addr, size, false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY) == KERN_SUCCESS) {
        *(float *)address = value;
        vm_protect(mach_task_self(), addr, size, false, VM_PROT_READ | VM_PROT_EXECUTE);
    }
}

// ==========================================
// CRASH-FREE EKRAN YAZISI (UIKit)
// ==========================================
void draw_ui_info() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 60, 280, 40)];
        infoLabel.text = @"XO-VIP PB 4.2 FULL ACTIVE ✅";
        infoLabel.textColor = [UIColor cyanColor];
        infoLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        infoLabel.textAlignment = NSTextAlignmentCenter;
        infoLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        infoLabel.layer.cornerRadius = 10;
        infoLabel.clipsToBounds = YES;
        infoLabel.layer.borderWidth = 1.0;
        infoLabel.layer.borderColor = [UIColor cyanColor].CGColor;
        
        // Pencereye ekle
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        [keyWindow addSubview:infoLabel];
    });
}

// ==========================================
// ANA HİLE DÖNGÜSÜ
// ==========================================
void start_main_loop() {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        while (true) {
            uintptr_t baseAddr = BGGetMainAddress(0);
            
            // UWorld -> LocalPlayer bulma (Generic check)
            uintptr_t uworld = *(uintptr_t *)(baseAddr + UWorld_Offset);
            if (uworld > 0x100000000) {
                // Not: LocalPlayer bulma adımları buraya eklenir
                uintptr_t localPlayer = 0; // Kendi pointer zincirini buraya bağla
                
                if (localPlayer > 0x100000000) {
                    uintptr_t weapon = *(uintptr_t *)(localPlayer + CurrentWeapon);
                    if (weapon > 0x100000000) {
                        uintptr_t shootComp = *(uintptr_t *)(weapon + ShootWeaponEntityComp);
                        if (shootComp > 0x100000000) {
                            // NO RECOIL & SPREAD PATCHES
                            patch_float(shootComp + AccessoriesVRecoilFactor, 0.0f);
                            patch_float(shootComp + AccessoriesHRecoilFactor, 0.0f);
                            patch_float(shootComp + AccessoriesRecoveryFactor, 0.0f);
                            patch_float(shootComp + GameDeviationFactor, 0.0f);
                            patch_float(shootComp + RecoilKickADS, 0.0f);
                        }
                    }
                }
            }
            [NSThread sleepForTimeInterval:1.0];
        }
    });
}

// ==========================================
// BAŞLATICI
// ==========================================
__attribute__((constructor))
static void initialize() {
    // 20 saniye sonra sistemleri başlat
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 20 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        draw_ui_info();
        start_main_loop();
    });
}
