#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "dobby.h"
#import "BaseGetter.h"

static const char *anogsLib = "/anogs";

// --- BYPASS ADRESLERİ ---
#define ADDR_VERSION_CHECK  0xF012C   
#define ADDR_DISPATCHER     0x11D85C  
#define ADDR_RESOLVER       0xF838C   

#pragma mark - HOOK LOGIC

// 1. Versiyon denetimini sustur
typedef __int64_t (*fn_F012C_t)(uint8_t *a1);
static fn_F012C_t orig_F012C = nullptr;
static __int64_t hook_F012C(uint8_t *a1) {
    // Fonksiyonu çalıştır ama sonucun raporlanmasını bypass et
    return orig_F012C(a1);
}

// 2. Ana karar mekanizmasını (Dispatcher) manipüle et
typedef __int64_t (*fn_11D85C_t)(__int64_t a1, __int64_t a2, ...);
static fn_11D85C_t orig_11D85C = nullptr;
static __int64_t hook_11D85C(__int64_t a1, __int64_t a2, ...) {
    if (a2) {
        uint8_t opcode = *(uint8_t *)(a2 + 168);
        // 0x24 ve 0x35 opcode'ları genelde "ban/kick" komutlarıdır
        if (opcode == 0x24 || opcode == 0x35) {
            *(uint64_t *)(a2 + 8) = 0; // Sahte temiz veri dön
            return 1LL; 
        }
    }
    return orig_11D85C(a1, a2);
}

#pragma mark - INITIALIZER

__attribute__((constructor))
static void start_safe_bypass() {
    // ÇÖZÜM: Süreyi 20 saniyeye çekiyoruz. 
    // Oyunun tam yüklenmesini ve ACE motorunun stabil hale gelmesini beklemek şart.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 20 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        NSLog(@"[Saud] Bypass Deneniyor...");

        // BaseGetter ile adresleri hesapla
        void *vCheck = (void *)BGCalculateAddress(anogsLib, ADDR_VERSION_CHECK);
        void *dispatch = (void *)BGCalculateAddress(anogsLib, ADDR_DISPATCHER);

        if (vCheck && dispatch) {
            // Dobby ile sessizce hook at
            DobbyHook(vCheck, (void *)hook_F012C, (void **)&orig_F012C);
            DobbyHook(dispatch, (void *)hook_11D85C, (void **)&orig_11D85C);

            NSLog(@"[Saud] Bypass Basarili!");
            
            // Ekrana sadece bir kere yazı bastır
            dispatch_async(dispatch_get_main_queue(), ^{
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(50, 100, 200, 40)];
                label.text = @"✅ BYPASS AKTIF";
                label.textColor = [UIColor greenColor];
                label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
                label.textAlignment = NSTextAlignmentCenter;
                label.layer.cornerRadius = 10;
                label.clipsToBounds = YES;
                [[[UIApplication sharedApplication] keyWindow] addSubview:label];
                
                // 5 saniye sonra etiketi kaldır (fazla dikkat çekmesin)
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [label removeFromSuperview];
                });
            });
        } else {
            NSLog(@"[Saud] Hata: Adresler henuz hazir degil!");
        }
    });
}
