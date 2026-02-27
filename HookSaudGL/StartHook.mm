#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "dobby.h"
#import "BaseGetter.h"

// ─────────────────────────────────────────────────────────────
// MARK: 1. SDK YAPILARI (Unreal Engine v4.2)
// ─────────────────────────────────────────────────────────────
struct FVector { float X, Y, Z; };
struct FVector2D { float X, Y; };
struct FLinearColor { float R, G, B, A; };

template<typename T>
struct TArray {
    T* Data;
    int32_t Count;
    int32_t Max;
    int Num() const { return Count; }
    T& operator[](int i) { return Data[i]; }
};

struct AActor {
    FVector GetLocation() {
        uintptr_t root = *(uintptr_t*)((uintptr_t)this + 0x150);
        if (!root) return {0,0,0};
        return *(FVector*)(root + 0x11C);
    }
};

struct ULevel {
    char pad[0xE0];
    struct { uintptr_t pad; TArray<AActor*> Actors; } *ActorCluster;
};

struct UWorld {
    char pad[0x468];
    ULevel* CurrentLevel;
    void* GameInstance;
};

// ─────────────────────────────────────────────────────────────
// MARK: 2. MOD DEĞİŞKENLERİ & GLOBAL POINTERLAR
// ─────────────────────────────────────────────────────────────
static BOOL g_ESP_Enabled = YES;
static UWorld** GWorld;
void (*orig_PostRender)(void* _this, void* canvas);

typedef bool (*tW2S)(void* pc, FVector world, FVector2D& screen, bool relative);
tW2S ProjectWorldLocationToScreen;

typedef void (*tDrawLine)(void* hud, FVector2D s, FVector2D e, FLinearColor c, float t);
tDrawLine O_DrawLine;

// ─────────────────────────────────────────────────────────────
// MARK: 3. MOD MENÜ (UIKit)
// ─────────────────────────────────────────────────────────────
@interface ModMenu : UIView
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UIButton *btn;
@end

@implementation ModMenu
+ (void)loadMenu {
    static ModMenu *menu;
    if (!menu) {
        menu = [[ModMenu alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [[UIApplication sharedApplication].keyWindow addSubview:menu];
    }
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    self.btn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.btn.frame = CGRectMake(100, 100, 50, 50);
    self.btn.backgroundColor = [UIColor redColor];
    [self.btn setTitle:@"XO" forState:UIControlStateNormal];
    self.btn.layer.cornerRadius = 25;
    [self.btn addTarget:self action:@selector(toggle) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.btn];

    self.panel = [[UIView alloc] initWithFrame:CGRectMake(0,0,200,150)];
    self.panel.center = self.center;
    self.panel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
    self.panel.hidden = YES;
    
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(130, 50, 0, 0)];
    [sw setOn:YES];
    [sw addTarget:self action:@selector(swESP:) forControlEvents:UIControlEventValueChanged];
    [self.panel addSubview:sw];
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 50, 100, 30)];
    lbl.text = @"ESP ON/OFF"; lbl.textColor = [UIColor whiteColor];
    [self.panel addSubview:lbl];
    [self addSubview:self.panel];
}
- (void)toggle { self.panel.hidden = !self.panel.hidden; self.userInteractionEnabled = !self.panel.hidden; }
- (void)swESP:(UISwitch *)s { g_ESP_Enabled = s.on; }
@end

// ─────────────────────────────────────────────────────────────
// MARK: 4. ESP MANTĞI & HOOK
// ─────────────────────────────────────────────────────────────
void RenderESP(void* hud, void* pc) {
    if (!g_ESP_Enabled || !GWorld || !*GWorld) return;
    
    ULevel* level = (*GWorld)->CurrentLevel;
    if (!level || !level->ActorCluster) return;

    TArray<AActor*>& actors = level->ActorCluster->Actors;
    for (int i = 0; i < actors.Num(); i++) {
        AActor* actor = actors[i];
        if (!actor) continue;

        FVector loc = actor->GetLocation();
        FVector2D screen;
        if (ProjectWorldLocationToScreen(pc, loc, screen, false)) {
            FLinearColor col = {1, 0, 0, 1}; // Kırmızı
            O_DrawLine(hud, {screen.X, 0}, screen, col, 1.0f);
        }
    }
}

void hook_PostRender(void* _this, void* canvas) {
    if (orig_PostRender) orig_PostRender(_this, canvas);

    if (GWorld && *GWorld && (*GWorld)->GameInstance) {
        uintptr_t gi = (uintptr_t)(*GWorld)->GameInstance;
        TArray<uintptr_t>& lp = *(TArray<uintptr_t>*)(gi + 0x48);
        if (lp.Num() > 0) {
            void* pc = *(void**)(lp[0] + 0x30);
            if (pc) RenderESP(_this, pc);
        }
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: 5. BAŞLATICI (CONSTRUCTOR)
// ─────────────────────────────────────────────────────────────
__attribute__((constructor))
static void initialize() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        [ModMenu loadMenu];

        // Ofsetleri BaseGetter ile bağlıyoruz (v4.2)
        GWorld = (UWorld**)BGGetMainAddress(0x106684010);
        ProjectWorldLocationToScreen = (tW2S)BGGetMainAddress(0x105EFB82C);
        O_DrawLine = (tDrawLine)BGGetMainAddress(0x105F52364);
        void* postRenderAddr = (void*)BGGetMainAddress(0x108687C80);

        if (postRenderAddr) {
            DobbyHook(postRenderAddr, (void*)hook_PostRender, (void**)&orig_PostRender);
        }
    });
}
