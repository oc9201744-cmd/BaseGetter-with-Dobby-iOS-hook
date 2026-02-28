/*
 * Tweak.mm — PUBG GL 4.2
 * No Recoil + Ekran yazısı
 */

#include <stdint.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BaseGetter.h"
#import "dobby.h"

// ── Offset'ler ────────────────────────────────────────────────
#define OFF_PlayerOwner      0x28
#define OFF_AcknowledgedPawn 0x528
#define OFF_CurrentWeapon    0x2A54
#define OFF_VRecoil          0xBC8
#define OFF_HRecoil          0xBD0
#define OFF_Recovery         0xBCC
#define OFF_ADS_Kick         0xCF0
#define OFF_Deviation        0xC2C
#define OFF_DeviationAcc     0xC30

#define RPTR(base, off) (*((uintptr_t*)((uintptr_t)(base) + (off))))
#define WF32(base, off, val) (*((float*)((uintptr_t)(base) + (off))) = (val))

static inline bool Valid(uintptr_t p) {
    return p > 0x100000UL && p < 0x800000000000UL;
}

// ── Ekran Yazısı ──────────────────────────────────────────────
static void ShowOverlay(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].windows.firstObject;
        if (!win) return;

        UILabel *lbl = [[UILabel alloc] init];
        lbl.text            = @"✅ Hile Aktif";
        lbl.textColor       = [UIColor greenColor];
        lbl.backgroundColor = [UIColor colorWithWhite:0 alpha:0.55f];
        lbl.font            = [UIFont boldSystemFontOfSize:13];
        lbl.textAlignment   = NSTextAlignmentCenter;
        lbl.layer.cornerRadius = 6;
        lbl.clipsToBounds   = YES;
        lbl.frame = CGRectMake(10, 50, 110, 26);
        lbl.userInteractionEnabled = NO;
        [win addSubview:lbl];
    });
}

// ── Silah Patch ───────────────────────────────────────────────
static void PatchWeapon(uintptr_t weapon) {
    WF32(weapon, OFF_VRecoil,      0.0f);
    WF32(weapon, OFF_HRecoil,      0.0f);
    WF32(weapon, OFF_Recovery,     0.0f);
    WF32(weapon, OFF_ADS_Kick,     0.0f);
    WF32(weapon, OFF_Deviation,    0.0f);
    WF32(weapon, OFF_DeviationAcc, 0.0f);
}

// ── HUD Hook ──────────────────────────────────────────────────
typedef void (*tDrawHUD)(uintptr_t hud, uintptr_t canvas);
static tDrawHUD orig_DrawHUD = NULL;

static void hook_DrawHUD(uintptr_t hud, uintptr_t canvas) {
    orig_DrawHUD(hud, canvas);
    if (!Valid(hud)) return;
    uintptr_t pc   = RPTR(hud, OFF_PlayerOwner);    if (!Valid(pc))     return;
    uintptr_t pawn = RPTR(pc,  OFF_AcknowledgedPawn); if (!Valid(pawn))  return;
    uintptr_t wpn  = RPTR(pawn,OFF_CurrentWeapon);    if (!Valid(wpn))   return;
    PatchWeapon(wpn);
}

// ── Constructor ───────────────────────────────────────────────
__attribute__((constructor))
static void TweakInit(void) {
    // Hemen overlay göster — hook'tan bağımsız
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),
        dispatch_get_main_queue(),
        ^{ ShowOverlay(); }
    );

    // Hook 15 sn sonra
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC),
        dispatch_get_main_queue(), ^{
            void *target = (void*)BGGetMainAddress(0x108687C80);
            DobbyHook(target, (void*)hook_DrawHUD, (void**)&orig_DrawHUD);
        }
    );
}