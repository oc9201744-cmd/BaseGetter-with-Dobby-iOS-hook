#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "dobby.h"
#import "BaseGetter.h"

// --- 1. Orijinal Fonksiyon Saklayıcı ---
// Derleme hatası almamak için static olarak tanımlıyoruz
static float (*orig_RecoilFunc)(void* _this, float val);

// --- 2. Senin Verdiğin Özel Ofset ---
#define TARGET_OFFSET 0x10035fd6

// --- 3. Hook Fonksiyonu (Mermiyi Düz Yapar) ---
float hooked_RecoilFunc(void* _this, float val) {
    // Fonksiyonun hesapladığı değeri çöpe atıp 0 döndürüyoruz
    // Bu işlem sekmeyi ve yayılmayı (spread) teorik olarak sıfırlar
    return 0.0f;
}

// --- 4. Ekranda Durum Yazısı ---
static void ShowHackStatus() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    win = scene.windows.firstObject;
                    break;
                }
            }
        } else {
            win = [UIApplication sharedApplication].keyWindow;
        }

        if (win) {
            UILabel *statusLbl = [[UILabel alloc] initWithFrame:CGRectMake(40, 60, 140, 25)];
            statusLbl.text = @"🚀 C0035FD6 AKTIF";
            statusLbl.textColor = [UIColor yellowColor];
            statusLbl.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
            statusLbl.textAlignment = NSTextAlignmentCenter;
            statusLbl.font = [UIFont boldSystemFontOfSize:11];
            statusLbl.layer.cornerRadius = 4;
            statusLbl.clipsToBounds = YES;
            [win addSubview:statusLbl];
        }
    });
}

// --- 5. Başlatıcı ---
__attribute__((constructor))
static void initialize() {
    // Anti-cheat taramasını atlatmak ve lobi yüklenmesi için 15 sn bekleme
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        ShowHackStatus();

        // BaseGetter kullanarak ana adresle ofseti birleştiriyoruz
        void* targetAddr = (void*)BGGetMainAddress(TARGET_OFFSET);
        
        if (targetAddr) {
            // Dobby ile fonksiyonun üstüne kendi fonksiyonumuzu yazıyoruz
            DobbyHook(targetAddr, (void*)hooked_RecoilFunc, (void**)&orig_RecoilFunc);
        }
    });
}
