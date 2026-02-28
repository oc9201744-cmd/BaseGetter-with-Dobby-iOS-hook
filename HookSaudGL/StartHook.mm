#import <Foundation/Foundation.h>
#import <stdint.h>
#import "BaseGetter.h"
#import "dobby.h"

// --- Dosyandan Gelen Kesin Offsetler ---
#define OFF_CurrentWeapon 0x2A54
#define OFF_ShootWeaponEntity 0x12C0
#define OFF_VRecoil 0xBC8
#define OFF_HRecoil 0xBD0
#define OFF_Recovery 0xBCC
#define OFF_Deviation 0xC2C // Mermi dağılması (isabet için)

// Orijinal fonksiyonu saklamak için yedek
static void (*orig_Character_Update)(void *instance, float deltaTime);

// Hook fonksiyonu - Karakter her hareket ettiğinde/güncellendiğinde çalışır
void hook_Character_Update(void *instance, float deltaTime) {
    if (instance != NULL) {
        // 1. Karakterden mevcut silaha ulaş
        uintptr_t weapon = *(uintptr_t *)((uintptr_t)instance + OFF_CurrentWeapon);
        
        if (weapon != 0) {
            // 2. Silah içindeki ateşleme (Entity) bileşenine git
            uintptr_t shootEntity = *(uintptr_t *)(weapon + OFF_ShootWeaponEntity);
            
            if (shootEntity != 0) {
                // 3. Değerleri sıfırla (Sekmeme ve %100 İsabet)
                *(float *)(shootEntity + OFF_VRecoil) = 0.0f;    // Dikey Sekme
                *(float *)(shootEntity + OFF_HRecoil) = 0.0f;    // Yatay Sekme
                *(float *)(shootEntity + OFF_Recovery) = 0.0f;   // Toparlanma
                *(float *)(shootEntity + OFF_Deviation) = 0.0f;  // Mermi Dağılması
            }
        }
    }
    // Oyunun orijinal fonksiyonunu devam ettir
    orig_Character_Update(instance, deltaTime);
}

__attribute__((constructor))
static void init() {
    // Oyunun yüklenmesi için 5 saniye bekle (Daha güvenli)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        // ÖNEMLİ: 0x104aa76a8 adresi STExtraBaseCharacter::Update fonksiyonudur. 
        // ShadowTrackerExtra dosyasında bu IMP'yi kontrol et.
        void* target = (void*)BGGetMainAddress(0x104aa76a8); 

        if (target != NULL) {
            DobbyHook(target, (void*)hook_Character_Update, (void**)&orig_Character_Update);
            NSLog(@"[SaudGL] Sekmeme ve İsabet başarıyla bağlandı!");
        } else {
            NSLog(@"[SaudGL] Hata: Hedef adres bulunamadı!");
        }
    });
}
