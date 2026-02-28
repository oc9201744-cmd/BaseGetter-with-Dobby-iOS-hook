/*
 * Tweak.mm — PUBG GL 4.2
 * BaseGetter + Dobby ile No Recoil / No Spread
 */

#include <stdint.h>
#import <Foundation/Foundation.h>
#import "BaseGetter.h"
#import "dobby.h"

// ── Offset'ler ────────────────────────────────────────────────
#define OFF_NetDriver         0x38
#define OFF_ServerConnection  0x78
#define OFF_PlayerController  0x30
#define OFF_AcknowledgedPawn  0x528
#define OFF_CurrentWeapon     0x2A54
#define OFF_VRecoil           0xBC8
#define OFF_HRecoil           0xBD0
#define OFF_Recovery          0xBCC
#define OFF_ADS_Kick          0xCF0
#define OFF_Deviation         0xC2C
#define OFF_DeviationAcc      0xC30

// ── Yardımcılar ───────────────────────────────────────────────
#define RPTR(base, off) (*((uintptr_t*)((uintptr_t)(base) + (off))))
#define RF32(base, off) (*((float*)    ((uintptr_t)(base) + (off))))
#define WF32(base, off, val) (RF32(base, off) = (val))

static inline bool Valid(uintptr_t p) {
    return p > 0x100000UL && p < 0x800000000000UL;
}

// ── GWorld pointer (IDA: 0x106684010) ────────────────────────
static uintptr_t g_GWorldPtr = 0;

static uintptr_t GetLocalCharacter(void) {
    uintptr_t world = RPTR(g_GWorldPtr, 0);
    if (!Valid(world)) return 0;

    uintptr_t netDriver = RPTR(world, OFF_NetDriver);
    if (!Valid(netDriver)) return 0;

    uintptr_t conn = RPTR(netDriver, OFF_ServerConnection);
    if (!Valid(conn)) return 0;

    uintptr_t pc = RPTR(conn, OFF_PlayerController);
    if (!Valid(pc)) return 0;

    uintptr_t pawn = RPTR(pc, OFF_AcknowledgedPawn);
    return Valid(pawn) ? pawn : 0;
}

static void PatchWeapon(uintptr_t weapon) {
    if (!Valid(weapon)) return;
    WF32(weapon, OFF_VRecoil,      0.0f);
    WF32(weapon, OFF_HRecoil,      0.0f);
    WF32(weapon, OFF_Recovery,     0.0f);
    WF32(weapon, OFF_ADS_Kick,     0.0f);
    WF32(weapon, OFF_Deviation,    0.0f);
    WF32(weapon, OFF_DeviationAcc, 0.0f);
}

static void StartLoop(void) {
    dispatch_async(
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            while (true) {
                @autoreleasepool {
                    uintptr_t character = GetLocalCharacter();
                    if (Valid(character)) {
                        uintptr_t weapon = RPTR(character, OFF_CurrentWeapon);
                        if (Valid(weapon)) {
                            PatchWeapon(weapon);
                        }
                    }
                }
                [NSThread sleepForTimeInterval:0.5];
            }
        }
    );
}

__attribute__((constructor))
static void TweakInit(void) {
    // BGGetMainAddress ile GWorld adresini al
    g_GWorldPtr = (uintptr_t)BGGetMainAddress(0x106684010);

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC),
        dispatch_get_main_queue(),
        ^{ StartLoop(); }
    );
}