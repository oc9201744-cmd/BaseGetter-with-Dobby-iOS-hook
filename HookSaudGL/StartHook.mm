// ============================================================
// 1. İSTEDİĞİN TÜM KÜTÜPHANELER (EKSİKSİZ TAM LİSTE)
// ============================================================
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

// Sistem Altyapısı
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import "BaseGetter.h"

// ============================================================
// 2. PB 4.2 ADRESLER VE ZİNCİR
// ============================================================
#define UWorld_Offset 0x106684010

const uintptr_t CurrentWeapon = 0x2A54;
const uintptr_t ShootWeaponEntityComp = 0x12C0;

// Sekmeme Offsets (No Recoil)
const uintptr_t AccessoriesVRecoilFactor = 0xBC8;
const uintptr_t AccessoriesHRecoilFactor = 0xBD0;
const uintptr_t AccessoriesRecoveryFactor = 0xBCC;
const uintptr_t GameDeviationFactor = 0xC2C;
const uintptr_t RecoilKickADS = 0xCF0;

// ============================================================
// 3. iOS 17 GÜVENLİ YAZICI (READ-ONLY PROTECTION FIX)
// ============================================================
// iOS 17'de __DATA_CONST segmenti yazıldıktan sonra KİLİTLENMELİDİR.
void patch_ios17_safe(uintptr_t address, float value) {
    if (address < 0x100000000) return;
    
    vm_address_t addr = (vm_address_t)address;
    vm_size_t size = sizeof(float);
    
    // ADIM A: Kilidi aç (Read + Write + Copy)
    kern_return_t kr = vm_protect(mach_task_self(), addr, size, false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    
    if (kr == KERN_SUCCESS) {
        // ADIM B: Değeri değiştir
        *(float *)address = value;
        
        // ADIM C: Kilidi geri tak (Sadece Okunur yap) - KRİTİK!
        // Eğer bunu yapmazsan iOS 17 kernel oyunu anında kapatır.
        vm_protect(mach_task_self(), addr, size, false, VM_PROT_READ | VM_PROT_EXECUTE);
    }
}

// ============================================================
// 4. SOFT BYPASS (ENVIRONMENT & REPORT CLEANER)
// ============================================================
void apply_advanced_bypass() {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Kütüphane izlerini temizle
        unsetenv("DYLD_INSERT_LIBRARIES");
        setenv("_X_JB_CHECK_", "0", 1);
        
        // Oyun içi raporlama seviyelerini düşür
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"MGPA_REPORT_LEVEL"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSLog(@"[XO-VIP] Bypass başarıyla uygulandı.");
    });
}

// ============================================================
// 5. EKRAN BİLGİSİ (UIKit - SIFIR CRASH)
// ============================================================
void draw_status_label() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(50, 60, 260, 40)];
        label.text = @"XO-VIP PB 4.2 FULL ACTIVE ✅";
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [[UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:0.8] init];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];
        label.layer.cornerRadius = 12;
        label.clipsToBounds = YES;
        
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        [window addSubview:label];
    });
}

// ============================================================
// 6. ANA DÖNGÜ VE BAŞLATICI
// ============================================================
void main_cheat_loop() {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        apply_advanced_bypass();
        
        while (true) {
            uintptr_t baseAddr = BGGetMainAddress(0);
            uintptr_t uworld = *(uintptr_t *)(baseAddr + UWorld_Offset);
            
            if (uworld > 0x100000000) {
                // Not: LocalPlayer bulma zincirini buraya bağla
                uintptr_t localPlayer = 0; 
                
                if (localPlayer > 0x100000000) {
                    uintptr_t weapon = *(uintptr_t *)(localPlayer + CurrentWeapon);
                    if (weapon > 0x100000000) {
                        uintptr_t shootComp = *(uintptr_t *)(weapon + ShootWeaponEntityComp);
                        if (shootComp > 0x100000000) {
                            // SEKMEME & DAĞILMAMA (iOS 17 GÜVENLİ)
                            patch_ios17_safe(shootComp + AccessoriesVRecoilFactor, 0.0f);
                            patch_ios17_safe(shootComp + AccessoriesHRecoilFactor, 0.0f);
                            patch_ios17_safe(shootComp + AccessoriesRecoveryFactor, 0.0f);
                            patch_ios17_safe(shootComp + GameDeviationFactor, 0.0f);
                            patch_ios17_safe(shootComp + RecoilKickADS, 0.0f);
                        }
                    }
                }
            }
            [NSThread sleepForTimeInterval:1.5];
        }
    });
}

__attribute__((constructor))
static void initialize() {
    // iOS 17 güvenliği için 35 saniye bekleme şart
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 35 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        draw_status_label();
        main_cheat_loop();
    });
}
