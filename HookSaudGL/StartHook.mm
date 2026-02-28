#import <Foundation/Foundation.h>
#import "BaseGetter.h"
#import "dobby.h"
#import <stdint.h>

// Senin verdiğin değerler
const uintptr_t RecoilOffset = 0x02ECF004;
const uint32_t PatchValue = 0xC0035FD6; // Yazılacak yeni değer

extern "C" void setupHooks() {
    // 1. Ana uygulama (ShadowTrackerExtra) base adresini alıyoruz
    // BGGetMainAddress(0) bize başlangıç noktasını verir
    uintptr_t baseAddress = (uintptr_t)BGGetMainAddress(0);
    
    if (baseAddress != 0) {
        // 2. Hedef adresi hesapla (Base + Offset)
        void *targetAddr = (void *)(baseAddress + RecoilOffset);
        
        // 3. DobbyCodePatch ile değeri oraya gömüyoruz
        // Bu fonksiyon otomatik olarak yazma korumasını (Write Protection) aşar.
        MemoryOperationError err = DobbyCodePatch(targetAddr, (uint8_t *)&PatchValue, sizeof(PatchValue));
        
        if (err == kMemoryOperationSuccess) {
            NSLog(@"[Gemini] Sekmeme Yaması Başarılı! Adres: %p, Değer: 0x%X", targetAddr, PatchValue);
        } else {
            NSLog(@"[Gemini] Yama Hatası! Hata Kodu: %d", err);
        }
    } else {
        NSLog(@"[Gemini] Hata: Base adresi alınamadı!");
    }
}
