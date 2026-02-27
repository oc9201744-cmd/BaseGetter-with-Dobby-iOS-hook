#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "dobby.h"
#import "BaseGetter.h"

// ─────────────────────────────────────────────────────────────
// 1. SDK & STRUCTS (Hata Almamak İçin Tam Liste)
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
// 2. GLOBALS & HOOKS
// ─────────────────────────────────────────────────────────────
static BOOL g_ESP = YES;
static UWorld** GWorld;
void (*orig_PostRender)(void* _this, void* canvas);

typedef bool (*tW2S)(void* pc, FVector world, FVector2D& screen, bool relative);
tW2S ProjectWorldLocationToScreen;

typedef void (*tDrawLine)(void* hud, FVector2D s, FVector2D e, FLinearColor c, float t);
tDrawLine O_DrawLine;

// ─────────────────────────────────────────────────────────────
// 3. MOD MENU (Tıklama ve Çökme Sorunu Düzeltilmiş)
// ─────────────────────────────────────────────────────────────
@interface ModMenu : UIView
@property (nonatomic, strong) UIView *p;
@property (nonatomic, strong) UIButton *b;
@end

@implementation ModMenu
+ (void)loadMenu {
    dispatch_async(dispatch_get_main_queue(), ^{
        ModMenu *m = [[ModMenu alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [[UIApplication sharedApplication].keyWindow addSubview:m];
    });
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        
        self.b = [UIButton buttonWithType:UIButtonTypeCustom];
        self.b.frame = CGRectMake(100, 100, 50, 50);
        self.b.backgroundColor = [UIColor redColor];
        [self.b setTitle:@"XO" forState:UIControlStateNormal];
        self.b.layer.cornerRadius = 25;
        self.b.userInteractionEnabled = YES;
        [self.b addTarget:self action:@selector(t) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.b];

        self.p = [[UIView alloc] initWithFrame:CGRectMake(0,0,220,120)];
        self.p.center = self.center;
        self.p.backgroundColor = [UIColor colorWithWhite:0 alpha:0.9];
        self.p.layer.cornerRadius = 10;
        self.p.layer.borderWidth = 1.0;
        self.p.layer.borderColor = [UIColor whiteColor].CGColor;
        self.p.hidden = YES;
        self.p.userInteractionEnabled = YES;
        
        UISwitch *s = [[UISwitch alloc] initWithFrame:CGRectMake(150, 45, 0, 0)];
        [s setOn:YES]; [s addTarget:self action:@selector(sw:) forControlEvents:UIControlEventValueChanged];
        [self.p addSubview:s];
        
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(20, 45, 120, 30)];
        l.text = @"ESP AKTIF"; l.textColor = [UIColor whiteColor];
        [self.p addSubview:l];
        [self addSubview:self.p];
    }
    return self;
}

- (void)t { self.p.hidden = !self.p.hidden; self.userInteractionEnabled = !self.p.hidden; }
- (void)sw:(UISwitch *)s { g_ESP = s.on; }

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *v = [super hitTest:point withEvent:event];
    if (v == self) return nil;
    return v;
}
@end

// ─────────────────────────────────────────────────────────────
// 4. RENDER & HOOK LOGIC
// ─────────────────────────────────────────────────────────────
void hook_PR(void* _this, void* canvas) {
    if (orig_PostRender) orig_PostRender(_this, canvas);

    if (!g_ESP || !GWorld || !*GWorld) return;
    
    UWorld* world = *GWorld;
    if (!world || !world->CurrentLevel || !world->GameInstance) return;

    ULevel* level = world->CurrentLevel;
    if (!level || !level->ActorCluster) return;

    TArray<AActor*>& actors = level->ActorCluster->Actors;
    for (int i = 0; i < actors.Num(); i++) {
        AActor* a = actors[i];
        if (!a) continue;
        
        FVector loc = a->GetLocation();
        FVector2D sc;
        // World To Screen ve DrawLine çağrıları...
    }
}

__attribute__((constructor))
static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 12 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [ModMenu loadMenu];
        
        GWorld = (UWorld**)BGGetMainAddress(0x106684010);
        ProjectWorldLocationToScreen = (tW2S)BGGetMainAddress(0x105EFB82C);
        O_DrawLine = (tDrawLine)BGGetMainAddress(0x105F52364);
        void* pr = (void*)BGGetMainAddress(0x108687C80);

        if (pr) {
            DobbyHook(pr, (void*)hook_PR, (void**)&orig_PostRender);
        }
    });
}
