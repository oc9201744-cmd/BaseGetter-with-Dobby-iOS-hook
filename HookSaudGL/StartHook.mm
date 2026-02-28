//
//  Tweak.mm
//  DobbyHookGL
//
//  Extracted from IDA decompiled targets:
//    - sub_11D85C  (bak.txt)
//    - sub_365A4   (bak_2.txt / bak_3.txt)
//    - sub_F012C   (bak_4.txt / bak_5.txt)
//    - sub_F838C   (bak_6.txt)
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "dobby.h"
#import "BaseGetter.h"
#import <unistd.h>
#import <stdint.h>

// ─────────────────────────────────────────────────────────
//  Ekranda "Hile Aktif" yazısı — Sol Üst Köşe
// ─────────────────────────────────────────────────────────
static void showHileAktifLabel(void)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;

        // iOS 13+ için aktif sahneyi al
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        }

        // Fallback eski yöntem
        if (!window) {
            window = [UIApplication sharedApplication].keyWindow;
        }

        if (!window) return;

        UILabel *label       = [[UILabel alloc] init];
        label.text           = @"✅ Hile Aktif";
        label.textColor      = [UIColor greenColor];
        label.font           = [UIFont boldSystemFontOfSize:14.0f];
        label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.55f];
        label.layer.cornerRadius = 6.0f;
        label.layer.masksToBounds = YES;
        label.textAlignment  = NSTextAlignmentCenter;
        [label sizeToFit];

        // Sol üst köşe — status bar altı
        CGFloat x = 10.0f;
        CGFloat y = 50.0f;   // status bar yüksekliği kadar boşluk
        CGFloat w = label.frame.size.width  + 16.0f;
        CGFloat h = label.frame.size.height + 8.0f;
        label.frame = CGRectMake(x, y, w, h);

        // Diğer view'ların üstünde kalması için
        label.layer.zPosition = 9999;
        label.userInteractionEnabled = NO;

        [window addSubview:label];
        NSLog(@"[Tweak] 'Hile Aktif' etiketi eklendi.");
    });
}

// ─────────────────────────────────────────────────────────
//  Target library  (adjust path if needed)
// ─────────────────────────────────────────────────────────
static const char *dylibName = "/anogs";

// ═════════════════════════════════════════════════════════
//  HOOK 1 — sub_F012C  (0xF012C)
//  Builds the ACE version / capability string sent to the
//  anti-cheat server.  Hook it to observe or spoof info.
// ═════════════════════════════════════════════════════════
static void *addr_F012C = (void *)BGCalculateAddress(dylibName, 0xF012C);

typedef __int64_t (*fn_F012C_t)(uint8_t *a1);
static fn_F012C_t orig_F012C = nullptr;

static __int64_t hook_F012C(uint8_t *a1)
{
    NSLog(@"[Tweak] sub_F012C called — version string buffer @ %p", a1);

    __int64_t ret = orig_F012C(a1);

    // After the original runs, a1 contains the assembled version string.
    // Uncomment to log it:
    // NSLog(@"[Tweak] Version string: %s", (char *)a1);

    return ret;
}

// ═════════════════════════════════════════════════════════
//  HOOK 2 — sub_365A4  (0x365A4)
//  Thread-safe singleton getter (pthread_once pattern).
//  Returns a heap object; byte at offset +8 is set by
//  nullsub_61().  Hook to inspect or replace the singleton.
// ═════════════════════════════════════════════════════════
static void *addr_365A4 = (void *)BGCalculateAddress(dylibName, 0x365A4);

typedef __int64_t (*fn_365A4_t)(void);
static fn_365A4_t orig_365A4 = nullptr;

static __int64_t hook_365A4(void)
{
    __int64_t ret = orig_365A4();

    NSLog(@"[Tweak] sub_365A4 → singleton @ 0x%llx  byte+8 = 0x%02x",
          ret,
          ret ? *(uint8_t *)(ret + 8) : 0);

    return ret;
}

// ═════════════════════════════════════════════════════════
//  HOOK 3 — sub_F838C  (0xF838C)
//  Resolves a numeric capability/opcode (read from a remote
//  config string) to a function pointer stored via *a2.
//  Intercept to log which syscall wrappers get registered,
//  or to redirect them.
//
//  Signature:
//    uint8_t * sub_F838C(__int64 a1,
//                        __int64 (**a2)(),
//                        uint64_t  a3,
//                        uint64_t *a4)
// ═════════════════════════════════════════════════════════
static void *addr_F838C = (void *)BGCalculateAddress(dylibName, 0xF838C);

typedef uint8_t *(*fn_F838C_t)(__int64_t, __int64_t (**)(), uint64_t, uint64_t *);
static fn_F838C_t orig_F838C = nullptr;

static uint8_t *hook_F838C(__int64_t     a1,
                            __int64_t   (**a2)(),
                            uint64_t      a3,
                            uint64_t     *a4)
{
    NSLog(@"[Tweak] sub_F838C called — a1=0x%llx  a3=0x%llx", a1, a3);

    uint8_t *ret = orig_F838C(a1, a2, a3, a4);

    if (ret && a2 && *a2)
        NSLog(@"[Tweak] sub_F838C resolved → fn ptr = %p", (void *)*a2);
    else
        NSLog(@"[Tweak] sub_F838C — no function resolved (ret=%p)", ret);

    return ret;
}

// ═════════════════════════════════════════════════════════
//  HOOK 4 — sub_11D85C  (0x11D85C)
//  Large dispatcher with 63 int params.  Branches on the
//  byte at (a2+1) and (a2+168) to evaluate AST / IR nodes.
//  Handles opcode cases like:
//    0x15 = sub_1277F4 call     0x24 = AnoSDKIoctlOld (cmd 4)
//    0x35 = AnoSDKIoctlOld (cmd 9)  0x1A = sub_136C14
//    0x19 = sub_126AB4        0x21 = sub_14A700
//    0x20 = sub_188E7C        ...
//
//  Signature (simplified — only first 4 named params matter):
//    __int64 sub_11D85C(__int64 a1, __int64 a2,
//                       __int64 a3, __int64 a4, …)
// ═════════════════════════════════════════════════════════
static void *addr_11D85C = (void *)BGCalculateAddress(dylibName, 0x11D85C);

// Use a variadic-style cast; all 63 ints are passed in registers / stack.
typedef __int64_t (*fn_11D85C_t)(__int64_t, __int64_t, __int64_t, __int64_t, ...);
static fn_11D85C_t orig_11D85C = nullptr;

static __int64_t hook_11D85C(__int64_t a1, __int64_t a2,
                              __int64_t a3, __int64_t a4, ...)
{
    uint8_t nodeByte1   = a2 ? *(uint8_t *)(a2 + 1)   : 0xFF;
    uint8_t nodeOpcode  = a2 ? *(uint8_t *)(a2 + 168)  : 0xFF;

    NSLog(@"[Tweak] sub_11D85C  a1=0x%llx  a2=0x%llx  node[1]=0x%02x  opcode=0x%02x",
          a1, a2, nodeByte1, nodeOpcode);

    // ── Example: intercept AnoSDKIoctlOld cmd 4 (opcode 0x24) ──
    // if (nodeByte1 == 5 && nodeOpcode == 0x24) {
    //     NSLog(@"[Tweak] Blocking AnoSDKIoctl cmd=4");
    //     *(uint64_t *)(a2 + 8) = 0;   // fake return value
    //     return 1LL;
    // }

    // ── Example: intercept AnoSDKIoctlOld cmd 9 (opcode 0x35) ──
    // if (nodeByte1 == 5 && nodeOpcode == 0x35) {
    //     NSLog(@"[Tweak] Blocking AnoSDKIoctl cmd=9");
    //     *(uint64_t *)(a2 + 8) = 0;
    //     return 1LL;
    // }

    return orig_11D85C(a1, a2, a3, a4);
}

// ═════════════════════════════════════════════════════════
//  Constructor — install all hooks after a short delay
// ═════════════════════════════════════════════════════════
__attribute__((constructor))
static void ___main(void)
{
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(45 * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
            NSLog(@"[Tweak] Installing hooks…");

            // ── Hook 1: sub_F012C ──────────────────────────
            if (addr_F012C) {
                DobbyHook(addr_F012C,
                          (void *)hook_F012C,
                          (void **)&orig_F012C);
                NSLog(@"[Tweak] sub_F012C hooked @ %p", addr_F012C);
            } else {
                NSLog(@"[Tweak] WARN: sub_F012C address not found");
            }

            // ── Hook 2: sub_365A4 ──────────────────────────
            if (addr_365A4) {
                DobbyHook(addr_365A4,
                          (void *)hook_365A4,
                          (void **)&orig_365A4);
                NSLog(@"[Tweak] sub_365A4 hooked @ %p", addr_365A4);
            } else {
                NSLog(@"[Tweak] WARN: sub_365A4 address not found");
            }

            // ── Hook 3: sub_F838C ──────────────────────────
            if (addr_F838C) {
                DobbyHook(addr_F838C,
                          (void *)hook_F838C,
                          (void **)&orig_F838C);
                NSLog(@"[Tweak] sub_F838C hooked @ %p", addr_F838C);
            } else {
                NSLog(@"[Tweak] WARN: sub_F838C address not found");
            }

            // ── Hook 4: sub_11D85C ─────────────────────────
            if (addr_11D85C) {
                DobbyHook(addr_11D85C,
                          (void *)hook_11D85C,
                          (void **)&orig_11D85C);
                NSLog(@"[Tweak] sub_11D85C hooked @ %p", addr_11D85C);
            } else {
                NSLog(@"[Tweak] WARN: sub_11D85C address not found");
            }

            NSLog(@"[Tweak] All hooks installed.");

            // ── Ekranda "Hile Aktif" göster ───────────────
            showHileAktifLabel();
        });
}