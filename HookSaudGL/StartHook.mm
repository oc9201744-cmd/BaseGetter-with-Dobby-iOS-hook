#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import <stdint.h>
#import "BaseGetter.h"
#import "dobby.h"

#pragma mark - OFFSETS (PB 4.2 GÜNCEL)

// Karakter -> CurrentWeapon (0x2A54)
#define OFF_Level1        0x2A54   

// Weapon -> ShootWeaponEntity (0x12C0)
#define OFF_Level2        0x12C0   

// Entity -> AccessoriesVRecoilFactor (0xBC8)
#define OFF_TargetField   0xBC8    

#pragma mark - ORIG FUNC

// STExtraBaseCharacter::Update fonksiyonu için tanım
typedef void (*orig_TargetFunc_t)(void *instance, float dt);
orig_TargetFunc_t orig_TargetFunc;

#pragma mark - VM CHECK (GÜVENLİK)

static inline bool IsReadable(void *addr) {
    if (!addr || (uintptr_t)addr < 0x100000000) return false; // Basic pointer check
    vm_address_t region = (vm_address_t)addr;
    vm_size_t size = 0;
    mach_port_t object_name;
    vm_region_basic_info_data_64_t info;
    mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;

    kern_return_t kr = vm_region_64(
        mach_task_self(),
        &region,
        &size,
        VM_REGION_BASIC_INFO,
        (vm_region_info_t)&info,
        &count,
        &object_name
    );

    return (kr == KERN_SUCCESS);
}

#pragma mark - HOOK

void hook_TargetFunc(void *instance, float dt)
{
    if (!instance) {
        orig_TargetFunc(instance, dt);
        return;
    }

    uintptr_t base = (uintptr_t)instance;

    // 🔹 1. Seviye: CurrentWeapon (0x2A54)
    void *level1 = *(void **)(base + OFF_Level1);

    if (!level1 || !IsReadable(level1)) {
        orig_TargetFunc(instance, dt);
        return;
    }

    // 🔹 2. Seviye: ShootWeaponEntity (0x12C0)
    void *level2 = *(void **)((uintptr_t)level1 + OFF_Level2);

    if (!level2 || !IsReadable(level2)) {
        orig_TargetFunc(instance, dt);
        return;
    }

    // 🔹 3. Hedef field: AccessoriesVRecoilFactor (0xBC8)
    float *targetValue = (float *)((uintptr_t)level2 + OFF_TargetField);

    if (IsReadable(targetValue)) {

        float current = *targetValue;

        // Sekmeme Uygulama
        if (current != 0.0f) {   
            *targetValue = 0.0f; 
            // NSLog(@"Recoil Patched: %f -> 0", current);
        }
    }

    orig_TargetFunc(instance, dt);
}

#pragma mark - INIT

__attribute__((constructor))
static void init()
{
    // Oyunun yüklenmesi ve adreslerin oturması için 5 saniye gecikme
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{

        // STExtraBaseCharacter::Update (ShadowTrackerExtra içindeki IMP adresi)
        // NOT: Dump dosyasındaki Update fonksiyonunun offsetini buraya yazmalısın.
        void *target = (void *)BGGetMainAddress(0x104aa76a8); 

        if (target) {
            DobbyHook(target,
                      (void *)hook_TargetFunc,
                      (void **)&orig_TargetFunc);
            NSLog(@"[SaudGL] Hook installed successfully");
        } else {
            NSLog(@"[SaudGL] Target address not found!");
        }
    });
}
