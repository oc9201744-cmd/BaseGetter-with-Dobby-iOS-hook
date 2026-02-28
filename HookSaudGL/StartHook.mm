// StartHook.mm
// DobbyGL + BaseGetter ile no-recoil / no-spread örnek hook'u
//
// NOT: Bu dosya, DobbyHookGL projesinde DobbyGL target'ı için
//      ana entry ve hook kodlarını içerir.
//
// Offsetler PB 4.2 için UC/xxMEKKYxx/@pubg_dev setine göre girildi.
// BGMI'de ÇALIŞMAZ. (Sadece teknik örnek)

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import <mach/vm_prot.h>
#import <mach-o/dyld.h>

#import "dobby.h"
#import "BaseGetter.h"

#pragma mark - Offsets (PB 4.2, VNG/GL, NOT BGMI)

// Global / world
static const uintptr_t GWORLD_ADDR            = 0x10A4A1960;   // senin verdiğin gworld_data

static const uintptr_t PersistentLevel        = 0x30;
static const uintptr_t GameState              = 0x428;
static const uintptr_t STPlayerController     = 0x49E8;
static const uintptr_t PlayerController       = 0x30;
static const uintptr_t AcknowledgedPawn       = 0x528;

// Pawn / Character
static const uintptr_t WeaponManagerComponent = 0x2588;
static const uintptr_t CurrentWeapon          = 0x2A54;
static const uintptr_t CurrentWeaponReplicated= 0x5C8;
static const uintptr_t ShootWeaponComponent   = 0xF30;

// Weapon / recoil / deviation
static const uintptr_t BulletTrackDistance            = 0x930;
static const uintptr_t AccessoriesVRecoilFactor       = 0xBC8;
static const uintptr_t AccessoriesHRecoilFactor       = 0xBD0;
static const uintptr_t AccessoriesRecoveryFactor      = 0xBCC;
static const uintptr_t GameDeviationFactor            = 0xC2C;
static const uintptr_t GameDeviationAccuracy          = 0xC30;
static const uintptr_t ShotGunVerticalSpread          = 0xC38;
static const uintptr_t ShotGunHorizontalSpread        = 0xC3C;
static const uintptr_t VehicleWeaponDeviationAngle    = 0xC4C;
static const uintptr_t RecoilKickADS                  = 0xCF0;

#pragma mark - vm_protect helpers (iOS 17, __DATA_CONST)

static bool setRW(uintptr_t addr, size_t size) {
    vm_size_t pageSize = (vm_size_t)getpagesize();
    vm_address_t aligned = (vm_address_t)(addr & ~((vm_address_t)pageSize - 1));
    kern_return_t kr = vm_protect(mach_task_self(),
                                  aligned,
                                  size,
                                  false,
                                  VM_PROT_READ | VM_PROT_WRITE);
    return (kr == KERN_SUCCESS);
}

static bool setRO(uintptr_t addr, size_t size) {
    vm_size_t pageSize = (vm_size_t)getpagesize();
    vm_address_t aligned = (vm_address_t)(addr & ~((vm_address_t)pageSize - 1));
    kern_return_t kr = vm_protect(mach_task_self(),
                                  aligned,
                                  size,
                                  false,
                                  VM_PROT_READ);
    return (kr == KERN_SUCCESS);
}

#pragma mark - Read pointer safely

static uintptr_t readPtr(uintptr_t addr) {
    if (!addr) return 0;
    if (!setRW(addr, sizeof(uintptr_t))) return 0;
    uintptr_t val = *(uintptr_t *)addr;
    setRO(addr, sizeof(uintptr_t));
    return val;
}

#pragma mark - Patch weapon recoil params

static void patchWeaponRecoil(uintptr_t weapon) {
    if (!weapon) return;

    // Bu alandaki float'ları güvenli olsun diye toplu RW yapalım
    uintptr_t recoilBase = weapon + AccessoriesVRecoilFactor; // en düşük offset burası
    size_t   span        = (RecoilKickADS + sizeof(float)) - AccessoriesVRecoilFactor;

    if (!setRW(recoilBase, span)) {
        NSLog(@"[PB42][NO_RECOIL] RW fail weapon @ 0x%lx", (unsigned long)weapon);
        return;
    }

    float *vRecoilFactor   = (float *)(weapon + AccessoriesVRecoilFactor);
    float *hRecoilFactor   = (float *)(weapon + AccessoriesHRecoilFactor);
    float *recovFactor     = (float *)(weapon + AccessoriesRecoveryFactor);
    float *devFactor       = (float *)(weapon + GameDeviationFactor);
    float *devAccuracy     = (float *)(weapon + GameDeviationAccuracy);
    float *sgVert          = (float *)(weapon + ShotGunVerticalSpread);
    float *sgHoriz         = (float *)(weapon + ShotGunHorizontalSpread);
    float *vehDevAngle     = (float *)(weapon + VehicleWeaponDeviationAngle);
    float *recoilKickADS   = (float *)(weapon + RecoilKickADS);
    float *bulletTrackDist = (float *)(weapon + BulletTrackDistance);

    // Tam no recoil / no spread:
    *vRecoilFactor   = 0.0f;
    *hRecoilFactor   = 0.0f;
    *recovFactor     = 1.0f;      // hızlı toparlama (istersen >1.0 yap)
    *devFactor       = 0.0f;      // dağılma yok
    *devAccuracy     = 1.0f;      // maksimum isabet
    *sgVert          = 0.0f;
    *sgHoriz         = 0.0f;
    *vehDevAngle     = 0.0f;
    *recoilKickADS   = 0.0f;
    *bulletTrackDist = 9999.0f;   // istersen mermi izi mesafesini arttır

    setRO(recoilBase, span);

    NSLog(@"[PB42][NO_RECOIL] Patched weapon recoil @ 0x%lx", (unsigned long)weapon);
}

#pragma mark - World → GameState → Player → Weapon zinciri

static void applyNoRecoilOnce(void) {
    // 1) GWorld pointer
    uintptr_t gworldPtr = readPtr(GWORLD_ADDR);
    if (!gworldPtr) {
        NSLog(@"[PB42][NO_RECOIL] GWorld null");
        return;
    }

    // 2) PersistentLevel
    uintptr_t levelPtrAddr = gworldPtr + PersistentLevel;
    uintptr_t levelPtr     = readPtr(levelPtrAddr);
    if (!levelPtr) {
        NSLog(@"[PB42][NO_RECOIL] Level null");
        return;
    }

    // 3) GameState
    uintptr_t gameStateAddr = levelPtr + GameState;
    uintptr_t gameState     = readPtr(gameStateAddr);
    if (!gameState) {
        NSLog(@"[PB42][NO_RECOIL] GameState null");
        return;
    }

    // 4) PlayerController (STPlayerController field içinden)
    uintptr_t stPCAddr = gameState + STPlayerController;
    uintptr_t stPC     = readPtr(stPCAddr);
    if (!stPC) {
        NSLog(@"[PB42][NO_RECOIL] STPlayerController null");
        return;
    }

    uintptr_t pcAddr = stPC + PlayerController;
    uintptr_t pc     = readPtr(pcAddr);
    if (!pc) {
        NSLog(@"[PB42][NO_RECOIL] PlayerController null");
        return;
    }

    // 5) Pawn (AcknowledgedPawn)
    uintptr_t pawnAddr = pc + AcknowledgedPawn;
    uintptr_t pawn     = readPtr(pawnAddr);
    if (!pawn) {
        NSLog(@"[PB42][NO_RECOIL] Pawn null");
        return;
    }

    // 6) Weapon Manager Component
    uintptr_t wmAddr = pawn + WeaponManagerComponent;
    uintptr_t wm     = readPtr(wmAddr);
    if (!wm) {
        NSLog(@"[PB42][NO_RECOIL] WeaponManagerComponent null");
        return;
    }

    // 7) Current Weapon (veya CurrentWeaponReplicated)
    uintptr_t curWeaponAddr = wm + CurrentWeapon;
    uintptr_t curWeapon     = readPtr(curWeaponAddr);
    if (!curWeapon) {
        // fallback: CurrentWeaponReplicated
        curWeaponAddr = wm + CurrentWeaponReplicated;
        curWeapon     = readPtr(curWeaponAddr);
    }

    if (!curWeapon) {
        NSLog(@"[PB42][NO_RECOIL] CurrentWeapon null");
        return;
    }

    // 8) ShootWeaponComponent (opsiyonel; çoğu parametre weapon üstünde zaten)
    uintptr_t shootCompAddr = pawn + ShootWeaponComponent;
    uintptr_t shootComp     = readPtr(shootCompAddr);
    (void)shootComp; // şimdilik kullanılmıyor ama ileride lazım olabilir

    // Son: weapon recoil parametrelerini patch'le
    patchWeaponRecoil(curWeapon);
}

#pragma mark - CADisplayLink ile sürekli uygulama

static CADisplayLink *gNoRecoilDL = nil;

static void noRecoilLoop(void) {
    @autoreleasepool {
        applyNoRecoilOnce();
    }
}

__attribute__((constructor))
static void StartHookEntry(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[PB42][NO_RECOIL] StartHookEntry init (PB 4.2, VNG/GL)");

        gNoRecoilDL = [CADisplayLink displayLinkWithTarget:[NSBlockOperation blockOperationWithBlock:^{
            noRecoilLoop();
        }] selector:@selector(main)];

        [gNoRecoilDL addToRunLoop:[NSRunLoop mainRunLoop]
                          forMode:NSRunLoopCommonModes];
    });
}