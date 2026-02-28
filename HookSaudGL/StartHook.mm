#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import "dobby.h"

// Jailbreak'siz cihazlarda kütüphane adını tam yol olarak değil, 
// sadece dylib ismiyle aratmak daha sağlıklıdır.
static const char *targetLib = "anogs"; 

// --- BYPASS ADRESLERİ (GÖNDERDİĞİN DOSYALARDAN) ---
#define ADDR_ASSERT_P      0x23A278  
#define ADDR_ASSERT_TAG    0x23A2A0  
#define ADDR_DISPATCHER    0x11D85C

// ─────────────────────────────────────────────────────────
//  FONKSİYONLARI TAMAMEN DEVRE DIŞI BIRAKAN YAMA (PATCH)
// ─────────────────────────────────────────────────────────

// ACE'nin 'Atma' komutlarını susturmak için boş fonksiyon
void silenced_call() {
    return;
}

// Karar mekanizmasını her zaman 'Başarılı' döndüren fonksiyon
__int64_t fake_dispatcher(__int64_t a1, __int64_t a2, ...) {
    // İçerideki opcode'ları kontrol etmeden her şeyi "OK" sayıyoruz
    return 1LL; 
}

// ─────────────────────────────────────────────────────────
//  YÜKLEME MEKANİZMASI (NON-JB ÖZEL)
// ─────────────────────────────────────────────────────────

__attribute__((constructor))
static void non_jb_bypass_init() {
    // Jailbreak'siz cihazlarda uygulama çok daha hızlı denetlenir.
    // 15-20 saniye beklemek yerine ACE'nin yüklenmesini bekleyen bir loop kuruyoruz.
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        uintptr_t baseAddr = 0;
        
        // anogs kütüphanesi hafızaya yüklenene kadar tara
        while (baseAddr == 0) {
            uint32_t count = _dyld_image_count();
            for (uint32_t i = 0; i < count; i++) {
                const char *name = _dyld_get_image_name(i);
                if (strstr(name, targetLib)) {
                    baseAddr = _dyld_get_image_vmaddr_slide(i) + 0x100000000; // ASLR Slide + Base
                    break;
                }
            }
            [NSThread sleepForTimeInterval:0.5];
        }

        NSLog(@"[Saud] anogs bulundu, Bypass uygulanıyor...");

        // Adresleri hesapla (BaseGetter yerine manuel hesaplama - Non-JB için daha stabil)
        void *p_target = (void *)(baseAddr + ADDR_ASSERT_P);
        void *tag_target = (void *)(baseAddr + ADDR_ASSERT_TAG);
        void *disp_target = (void *)(baseAddr + ADDR_DISPATCHER);

        // Dobby ile sadece en kritik yerleri "Replace" et
        if (p_target) DobbyHook(p_target, (void *)silenced_call, NULL);
        if (tag_target) DobbyHook(tag_target, (void *)silenced_call, NULL);
        if (disp_target) DobbyHook(disp_target, (void *)fake_dispatcher, NULL);

        NSLog(@"[Saud] Non-JB Bypass Tamamlandı.");
    });
}
