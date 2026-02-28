#import "BaseGetter.h"
#import "dobby.h"
#import <stdint.h>

// Dosyadan alınan güncel offsetler
const uintptr_t ShootWeaponEntityComp = 0x12C0; // PB42_offsets.mm içinden
const uintptr_t STExtraBaseCharacter = 0x28E0;   // PB42_offsets.mm içinden

// Geri tepme (Recoil) ile ilgili alt offsetler (Genel PB yapısı)
const uintptr_t AccessoriesVRecoilFactor = 0x858;
const uintptr_t AccessoriesHRecoilFactor = 0x85C;
const uintptr_t AccessoriesRecoveryFactor = 0x860;

// Orijinal fonksiyonu saklamak için
void (*orig_STExtraBaseCharacter_Update)(void *instance, float deltaTime);

// Hook fonksiyonu
void hook_STExtraBaseCharacter_Update(void *instance, float deltaTime) {
    if (instance != NULL) {
        // Character -> ShootWeaponEntityComp yolunu izle
        uintptr_t weaponEntity = *(uintptr_t *)((uintptr_t)instance + ShootWeaponEntityComp);
        
        if (weaponEntity != 0) {
            // Dikey, Yatay geri tepme ve sarsılmayı sıfırla
            *(float *)(weaponEntity + AccessoriesVRecoilFactor) = 0.0f;
            *(float *)(weaponEntity + AccessoriesHRecoilFactor) = 0.0f;
            *(float *)(weaponEntity + AccessoriesRecoveryFactor) = 0.0f;
        }
    }
    // Orijinal fonksiyonu devam ettir
    orig_STExtraBaseCharacter_Update(instance, deltaTime);
}

void setupHooks() {
    // Ana uygulama base adresini al (ShadowTrackerExtra)
    // STExtraBaseCharacter Update fonksiyonunun offsetini buraya yazmalısın
    // Örnek olarak 0x10XXXXXXX verilmiştir.
    void *updateAddr = (void*)BGGetMainAddress(0x104aa76a8); // Örnek offset, dump içindeki ilgili Update fonksiyonu ile değiştirilmeli
    
    if (updateAddr) {
        DobbyHook(updateAddr, (void*)hook_STExtraBaseCharacter_Update, (void**)&orig_STExtraBaseCharacter_Update);
    }
}
