#import <Foundation/Foundation.h>
#import "BaseGetter.h"
#import "dobby.h"
#import <stdint.h>

// Senin verdiğin listeden alınan güncel offsetler
const uintptr_t STExtraBaseCharacter_Offset = 0x28E0;
const uintptr_t CurrentWeapon_Offset = 0x2A54;
const uintptr_t ShootWeaponEntity_Offset = 0x12C0;

// Geri tepme (Recoil) offsetleri - Senin listendeki değerler
const uintptr_t VRecoil = 0xBC8;
const uintptr_t HRecoil = 0xBD0;
const uintptr_t Recovery = 0xBCC;

// Orijinal fonksiyonu saklamak için
static void (*orig_STExtraBaseCharacter_Update)(void *instance, float deltaTime);

// Hook fonksiyonu
static void hook_STExtraBaseCharacter_Update(void *instance, float deltaTime) {
    if (instance != nullptr) {
        // 1. Karakter üzerinden mevcut silahı al
        uintptr_t currentWeapon = *(uintptr_t *)((uintptr_t)instance + CurrentWeapon_Offset);
        
        if (currentWeapon != 0) {
            // 2. Silah üzerinden ShootWeaponEntity bileşenine git
            uintptr_t weaponEntity = *(uintptr_t *)(currentWeapon + ShootWeaponEntity_Offset);
            
            if (weaponEntity != 0) {
                // 3. Geri tepme çarpanlarını sıfırla
                *(float *)(weaponEntity + VRecoil) = 0.0f;
                *(float *)(weaponEntity + HRecoil) = 0.0f;
                *(float *)(weaponEntity + Recovery) = 0.0f;
            }
        }
    }
    // Orijinal fonksiyonun çalışmasına izin ver
    if (orig_STExtraBaseCharacter_Update) {
        orig_STExtraBaseCharacter_Update(instance, deltaTime);
    }
}

extern "C" void setupHooks() {
    // ÖNEMLİ: STExtraBaseCharacter sınıfının Update fonksiyonu adresi. 
    // Bu adresi dump dosyasında (ShadowTrackerExtra) aratarak bulmalısın.
    // Örnek olarak 0x104aa76a8 verilmiştir, çalışmazsa dump'tan bu adresi güncelle.
    void *updateAddr = (void*)BGGetMainAddress(0x104aa76a8); 
    
    if (updateAddr != nullptr) {
        DobbyHook(updateAddr, (void*)hook_STExtraBaseCharacter_Update, (void**)&orig_STExtraBaseCharacter_Update);
        NSLog(@"[SaudGL] Sekmeme Hooku Aktif Edildi.");
    } else {
        NSLog(@"[SaudGL] Hata: Update adresi bulunamadı.");
    }
}
