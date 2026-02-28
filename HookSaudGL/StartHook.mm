// ==========================================
// İSTEDİĞİN TÜM KÜTÜPHANELER (FULL LIST)
// ==========================================
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

#import <mach-o/dyld.h>
#import <mach/mach.h>
#import "dobby.h"
#import "BaseGetter.h"

// ==========================================
// OFFSETS & ANALİZ VERİLERİ
// ==========================================
#define UWorld_Offset 0x106684010
#define ANOGS_STR_CMP_OFFSET 0x17470 // str_cmp17470 analizinden gelen offset

// ==========================================
// SYSCALL & ANOGS BYPASS (DOBBY HOOKS)
// ==========================================

// 1. str_cmp17470 Bypass: Dosya bütünlük kontrolünü kandırır.
int (*orig_str_cmp17470)(const char *a1, const char *a2);
int hooked_str_cmp17470(const char *a1, const char *a2) {
    // Analiz notuna göre: ret 0 demek "dosyalar aynı/temiz" demek.
    // Oyun kendi __TEXT segmentini kontrol ettiğinde '0' döndürerek hileyi gizliyoruz.
    return 0; 
}

// 2. strcmp Bypass: Dylib isimlerini (Shadow, Dobby vb.) tarayıcıdan gizler.
int (*orig_strcmp)(const char *s1, const char *s2);
int hooked_strcmp(const char *s1, const char *s2) {
    if (s1 && s2) {
        if (strstr(s1, "Shadow") || strstr(s1, "dobby") || strstr(s1, "AppSync")) {
            return 1; // Eşleşme bulunamadı gibi davran
        }
    }
    return orig_strcmp(s1, s2);
}

// ==========================================
// iOS 17 GÜVENLİ YAZICI (READ-ONLY FIX)
// ==========================================
void safe_patch_ios17(uintptr_t address, float value) {
    if (address < 0x100000000) return;
    vm_address_t addr = (vm_address_t)address;
    vm_size_t size = sizeof(float);
    
    // Yazma izni al (R/W)
    if (vm_protect(mach_task_self(), addr, size, false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY) == KERN_SUCCESS) {
        *(float *)address = value;
        // iOS 17 kuralı: Tekrar Salt-Okunur yap (R)
        vm_protect(mach_task_self(), addr, size, false, VM_PROT_READ);
    }
}

// ==========================================
// ANA MOTOR & BYPASS AKTİVASYONU
// ==========================================
void apply_bypass_and_start() {
    uintptr_t baseAddr = BGGetMainAddress(0);

    // Dobby ile Anogs'un kalbine hook atıyoruz
    DobbyHook((void *)(baseAddr + ANOGS_STR_CMP_OFFSET), (void *)hooked_str_cmp17470, (void **)&orig_str_cmp17470);
    DobbyHook((void *)strcmp, (void *)hooked_strcmp, (void **)&orig_strcmp);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        while (true) {
            uintptr_t uworld = *(uintptr_t *)(baseAddr + UWorld_Offset);
            if (uworld > 0x100000000) {
                // Sekmeme işlemleri güvenli yazıcı ile...
                // safe_patch_ios17(shootComp + 0xBC8, 0.0f);
            }
            [NSThread sleepForTimeInterval:2.0];
        }
    });
}

// ==========================================
// UI & BAŞLATICI
// ==========================================
__attribute__((constructor))
static void initialize() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 40 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        // Ekrana durum yazısı
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(50, 50, 250, 40)];
        label.text = @"XO-VIP PB 4.2 FULL BYPASS ✅";
        label.textColor = [UIColor greenColor];
        label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        label.textAlignment = NSTextAlignmentCenter;
        label.layer.cornerRadius = 10;
        label.clipsToBounds = YES;
        [[[UIApplication sharedApplication] keyWindow] addSubview:label];

        apply_bypass_and_start();
    });
}
