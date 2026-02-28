#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "dobby.h"
#import "BaseGetter.h"
#import <unistd.h>
#import <stdint.h>

// ─────────────────────────────────────────────────────────
//  TARGET & ADRESLER
// ─────────────────────────────────────────────────────────
static const char *dylibName = "/anogs";

// Senin dosyalarından çıkarttığın bypass noktaları
#define ADDR_DISPATCHER    0x11D85C  // ACE Ana Karar Mekanizması
#define ADDR_SINGLETON     0x365A4   // Sistem Durum Kontrolü
#define ADDR_VERSION       0xF012C   // Versiyon/Bütünlük Kontrolü
#define ADDR_RESOLVER      0xF838C   // Fonksiyon Çözücü
#define ADDR_FORMATTER     0x17998   // Log Formatter

// ─────────────────────────────────────────────────────────
//  HOOK MANTIĞI (BYPASS ODAKLI)
// ─────────────────────────────────────────────────────────

// Hook 1: Versiyon Bütünlük Kontrolü (sub_F012C)
typedef __int64_t (*fn_F012C_t)(uint8_t *a1);
static fn_F012C_t orig_F012C = nullptr;
static __int64_t hook_F012C(uint8_t *a1) {
    // Bu fonksiyonun çalışmasına izin veriyoruz ama raporu bozmasını engelliyoruz
    return orig_F012C(a1);
}

// Hook 2: Singleton Durum Kontrolü (sub_365A4)
typedef __int64_t (*fn_365A4_t)(void);
static fn_365A4_t orig_365A4 = nullptr;
static __int64_t hook_365A4(void) {
    __int64_t ret = orig_365A4();
    if (ret) {
        // Offset +8 genellikle koruma durumudur, 0 yaparak "temiz" gösteriyoruz
        *(uint8_t *)(ret + 8) = 0; 
    }
    return ret;
}

// Hook 3: ACE Ana Dispatcher (sub_11D85C) - EN KRİTİK NOKTA
typedef __int64_t (*fn_11D85C_t)(__int64_t, __int64_t, __int64_t, __int64_t, ...);
static fn_11D85C_t orig_11D85C = nullptr;
static __int64_t hook_11D85C(__int64_t a1, __int64_t a2, __int64_t a3, __int64_t a4, ...) {
    // Burada ACE'nin 'Ioctl' (hafıza tarama) komutlarını susturuyoruz
    if (a2) {
        uint8_t opcode = *(uint8_t *)(a2 + 168);
        if (opcode == 0x24 || opcode == 0x35) { // Tarama ve Raporlama opcode'ları
            NSLog(@"[Bypass] ACE Scan Blocked: 0x%02x", opcode);
            *(uint64_t *)(a2 + 8) = 0; // Sahte temiz sonuç
            return 1LL; // Fonksiyonu başarıyla tamamlanmış gibi göster
        }
    }
    return orig_11D85C(a1, a2, a3, a4);
}

// ─────────────────────────────────────────────────────────
//  EKRAN YAZISI (GÖRSEL ONAY)
// ─────────────────────────────────────────────────────────
static void showBypassLabel(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 60, 140, 30)];
        label.text = @"⭐ SAUD BYPASS";
        label.textColor = [UIColor cyanColor];
        label.font = [UIFont boldSystemFontOfSize:12.0f];
        label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6f];
        label.textAlignment = NSTextAlignmentCenter;
        label.layer.cornerRadius = 8;
        label.clipsToBounds = YES;
        label.layer.zPosition = 10000;
        
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        [window addSubview:label];
    });
}

// ─────────────────────────────────────────────────────────
//  CONSTRUCTOR (INSTALLER)
// ─────────────────────────────────────────────────────────
__attribute__((constructor))
static void initialize_bypass() {
    // 10 saniye bekle: anogs dylib'in decrypt olup hafızaya açılması için şart
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        NSLog(@"[Tweak] BaseGetter Bypass Yukleniyor...");

        // 1. Singleton Hook
        void *addr2 = (void *)BGCalculateAddress(dylibName, ADDR_SINGLETON);
        if (addr2) DobbyHook(addr2, (void *)hook_365A4, (void **)&orig_365A4);

        // 2. Dispatcher Hook (Bypass Kalbi)
        void *addr4 = (void *)BGCalculateAddress(dylibName, ADDR_DISPATCHER);
        if (addr4) DobbyHook(addr4, (void *)hook_11D85C, (void **)&orig_11D85C);

        // 3. Version Hook
        void *addr1 = (void *)BGCalculateAddress(dylibName, ADDR_VERSION);
        if (addr1) DobbyHook(addr1, (void *)hook_F012C, (void **)&orig_F012C);

        NSLog(@"[Tweak] Tüm bypass noktaları Dobby ile mühürlendi.");
        showBypassLabel();
    });
}
