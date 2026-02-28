#import <Foundation/Foundation.h> // NULL ve temel tipler için gerekli
#import "BaseGetter.h"
#import "dobby.h"
#import <stdint.h>

// PB 4.2 Güncel Offsetler
const uintptr_t ShootWeaponEntityComp = 0x12C0;
const uintptr_t AccessoriesVRecoilFactor = 0x858;
const uintptr_t AccessoriesHRecoilFactor = 0x85C;
const uintptr_t AccessoriesRecoveryFactor = 0x860;

// Orijinal fonksiyonu saklamak için
static void (*orig_STExtraBaseCharacter_Update)(void *instance, float deltaTime);

// Hook fonksiyonu (Statik yaparak 'prototype' uyarısını giderdik)
static void hook_STExtraBaseCharacter_Update(void *instance, float deltaTime) {
    if (instance != nullptr) { // NULL yerine modern C++ için nullptr
        uintptr_t weaponEntity = *(uintptr_t *)((uintptr_t)instance + ShootWeaponEntityComp);
        
        if (weaponEntity != 0) {
            // Geri tepmeleri sıfırla
            *(float *)(weaponEntity + AccessoriesVRecoilFactor) = 0.0f;
            *(float *)(weaponEntity + AccessoriesHRecoilFactor) = 0.0f;
            *(float *)(weaponEntity + AccessoriesRecoveryFactor) = 0.0f;
        }
    }
    orig_STExtraBaseCharacter_Update(instance, deltaTime);
}

// Dışarıdan çağrılacak kurulum fonksiyonu
extern "C" void setupHooks() {
    // BURADAKİ OFFSETİ DUMP DOSYANDAN KONTROL ET:
    // STExtraBaseCharacter'in Update fonksiyonunun adresini yazmalısın.
    void *updateAddr = (void*)BGGetMainAddress(0x104aa76a8); 
    
    if (updateAddr != nullptr) {
        DobbyHook(updateAddr, (void*)hook_STExtraBaseCharacter_Update, (void**)&orig_STExtraBaseCharacter_Update);
    }
}
