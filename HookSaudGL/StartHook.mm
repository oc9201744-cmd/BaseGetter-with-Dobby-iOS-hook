// --- İstenen Kütüphane ve Framework'ler ---
#import <UIKit/UIKit.h>                  // iOS UI katmanı
#import <Foundation/Foundation.h>        // Temel Obj-C altyapısı
#import <CoreFoundation/CoreFoundation.h>
#import <Metal/Metal.h>                  // GPU rendering
#import <MetalKit/MetalKit.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#import <QuartzCore/QuartzCore.h>        // Grafik katmanı
#import <CoreGraphics/CoreGraphics.h>
#import <AVFoundation/AVFoundation.h>    // Ses/video
#import <GameController/GameController.h> // Oyun kontrolcüsü
#import <GameKit/GameKit.h>
#import <CloudKit/CloudKit.h>            // Apple sunucu servisleri
#import <DeviceCheck/DeviceCheck.h>
#import <CoreLocation/CoreLocation.h>    // Konum
#import <CoreTelephony/CTTelephonyNetworkInfo.h> // GSM bilgisi
#import <Speech/Speech.h>                // Ses işleme
#import <OpenAL/al.h>
#import <Security/Security.h>            // Keychain / kriptolib

// --- Standart C++ ve Hook Kütüphaneleri ---
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <stdint.h>
#import "dobby.h"
#import "BaseGetter.h"

// ==========================================
// PB 4.2 OFFSETS (VNG / GL vb.)
// ==========================================
const uintptr_t CurrentWeapon = 0x2A54;
const uintptr_t ShootWeaponEntityComp = 0x12C0; // Dosyandaki 0x12C0
const uintptr_t AccessoriesVRecoilFactor = 0xBC8;
const uintptr_t AccessoriesHRecoilFactor = 0xBD0;
const uintptr_t AccessoriesRecoveryFactor = 0xBCC;
const uintptr_t GameDeviationFactor = 0xC2C;    // Mermi dağılması
const uintptr_t RecoilKickADS = 0xCF0;          // Dürbün tepmesi

// ==========================================
// NO RECOIL HOOK LOGIC
// ==========================================
typedef void (*orig_Update_t)(void *instance, float dt);
orig_Update_t orig_Update = nullptr;

void hook_MainUpdate(void *instance, float dt) {
    if (instance) {
        uintptr_t base = (uintptr_t)instance;
        
        // 1. Silah objesine geçiş
        uintptr_t weapon = *(uintptr_t *)(base + CurrentWeapon);
        if (weapon > 0x100000000) {
            
            // 2. Ateş mekanizmasına (Entity) geçiş
            uintptr_t entity = *(uintptr_t *)(weapon + ShootWeaponEntityComp);
            if (entity > 0x100000000) {
                
                // 3. Pointerleri al
                float *vRecoil = (float *)(entity + AccessoriesVRecoilFactor);
                float *hRecoil = (float *)(entity + AccessoriesHRecoilFactor);
                float *recovery = (float *)(entity + AccessoriesRecoveryFactor);
                float *deviation = (float *)(entity + GameDeviationFactor);
                float *kickADS = (float *)(entity + RecoilKickADS);

                // 4. Değerleri sıfırla (Gereksiz yazmayı önlemek için kontrol et)
                if (vRecoil && *vRecoil != 0.0f) *vRecoil = 0.0f;       // Dikey
                if (hRecoil && *hRecoil != 0.0f) *hRecoil = 0.0f;       // Yatay
                if (recovery && *recovery != 0.0f) *recovery = 0.0f;    // Toparlanma
                if (deviation && *deviation != 0.0f) *deviation = 0.0f; // Dağılma
                if (kickADS && *kickADS != 0.0f) *kickADS = 0.0f;       // ADS Tepme
            }
        }
    }
    orig_Update(instance, dt);
}

// ==========================================
// ARAYÜZ (UIKIT KULLANIMI)
// ==========================================
static void showHackActiveUI() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 50, 200, 35)];
        statusLabel.text = @"🔥 SaudGL No Recoil Aktif";
        statusLabel.textColor = [UIColor systemGreenColor];
        statusLabel.font = [UIFont boldSystemFontOfSize:14.0];
        statusLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        statusLabel.textAlignment = NSTextAlignmentCenter;
        statusLabel.layer.cornerRadius = 8;
        statusLabel.clipsToBounds = YES;
        statusLabel.layer.zPosition = 9999; // En üstte kalması için (QuartzCore)
        
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        [window addSubview:statusLabel];
    });
}

// ==========================================
// BAŞLATICI (INITIALIZER)
// ==========================================
__attribute__((constructor))
static void saud_gl_init() {
    // Kütüphanelerin ve oyunun oturması için gecikme (CoreFoundation)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        NSLog(@"[SaudGL] Sistem başlatılıyor...");

        // ÖNEMLİ: STExtraBaseCharacter::Update adresi. 
        // Dump dosyanızdan asıl offseti buraya girmelisiniz.
        uint64_t updateOffset = 0x104aa76a8; 
        void *targetFunc = (void *)BGGetMainAddress(updateOffset);
        
        if (targetFunc) {
            DobbyHook(targetFunc, (void *)hook_MainUpdate, (void **)&orig_Update);
            NSLog(@"[SaudGL] No Recoil (Sekmeme) başarıyla bağlandı.");
            
            // Ekrana UIKit ile yazıyı bas
            showHackActiveUI();
        } else {
            NSLog(@"[SaudGL] HATA: Update adresi bulunamadı!");
        }
    });
}
