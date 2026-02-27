#import <Foundation/Foundation.h>
#import "BaseGetter.h"
#import "dobby.h"

// Orijinal fonksiyonu saklamak için
float (*orig_Deviation)(float FinalDeviation);

// Mermi sapmasını 0 yapan yeni fonksiyonumuz
float hook_Deviation(float FinalDeviation) {
    // Ne gelirse gelsin 0 döndür, mermi sekmesin/sapmasın
    return 0.0f;
}

__attribute__((constructor))
static void init() {
    // Jailbreak mantığında bile lobiye giriş anını beklemek sağlıklıdır
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        // Senin attığın görseldeki ofset: 0x103995018
        // BaseGetter ile ana dosyanın base adresini alıp ofseti ekliyoruz
        void * targetAddr = (void*)BGGetMainAddress(0x103995018);

        if (targetAddr) {
            // Dobby ile fonksiyonun kafasına çöküyoruz
            DobbyHook(targetAddr, (void*)hook_Deviation, (void**)&orig_Deviation);
        }
    });
}
