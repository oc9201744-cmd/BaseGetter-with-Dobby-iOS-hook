#import <Foundation/Foundation.h>
#import "BaseGetter.h"
#import "dobby.h"
#import <stdint.h>

// Prototip bildirimi (Warning hatasını engeller)
extern "C" void setupHooks();

// Senin verdiğin sekmeme (no recoil) offseti ve yaması
const uintptr_t RecoilOffset = 0x02ECF004;
const uint32_t PatchValue = 0xC0035FD6;

void setupHooks() {
    // 1. Ana uygulamanın (ShadowTrackerExtra) base adresini alıyoruz
    uintptr_t baseAddress = (uintptr_t)BGGetMainAddress(0);
    
    if (baseAddress != 0) {
        // 2. Hedef adresi hesapla (Base + Offset)
        void *targetAddr = (void *)(baseAddress + RecoilOffset);
        
        // 3. DobbyCodePatch ile yamayı uygula
        // Hata enumlarını kullanmak yerine doğrudan sonucu kontrol ediyoruz
        int result = DobbyCodePatch(targetAddr, (uint8_t *)&PatchValue, sizeof(PatchValue));
        
        if (result == 0) { // 0 genellikle başarıyı temsil eder (kMemoryOperationSuccess)
            NSLog(@"[Gemini] Sekmeme Yaması Başarılı! Adres: %p", targetAddr);
        } else {
            NSLog(@"[Gemini] Yama Hatası! Sonuç kodu: %d", result);
        }
    } else {
        NSLog(@"[Gemini] Hata: Base adresi alınamadı!");
    }
}
