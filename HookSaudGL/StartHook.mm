#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "dobby.h"
#import "BaseGetter.h"

// ... (Structlar aynı kalıyor, burayı kısa tutuyorum) ...

static BOOL g_ESP = YES;
static UWorld** GWorld;
void (*orig_PostRender)(void* _this, void* canvas);

// ─────────────────────────────────────────────────────────────
// MOD MENU - Tıklama Sorunu Düzeltilmiş Versiyon
// ─────────────────────────────────────────────────────────────
@interface ModMenu : UIView
@property (nonatomic, strong) UIView *p;
@property (nonatomic, strong) UIButton *b;
@end

@implementation ModMenu
+ (void)loadMenu {
    dispatch_async(dispatch_get_main_queue(), ^{ // UI işlemlerini Main Thread'de yap
        ModMenu *m = [[ModMenu alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [[UIApplication sharedApplication].keyWindow addSubview:m];
    });
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO; // Arka plan (oyun) tıklanabilir kalsın
        
        self.b = [UIButton buttonWithType:UIButtonTypeCustom];
        self.b.frame = CGRectMake(100, 100, 50, 50);
        self.b.backgroundColor = [UIColor redColor];
        [self.b setTitle:@"XO" forState:UIControlStateNormal];
        self.b.layer.cornerRadius = 25;
        self.b.userInteractionEnabled = YES; // Sadece buton tıklanabilir olsun
        [self.b addTarget:self action:@selector(t) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.b];

        self.p = [[UIView alloc] initWithFrame:CGRectMake(0,0,220,150)];
        self.p.center = self.center;
        self.p.backgroundColor = [UIColor blackColor];
        self.p.layer.borderWidth = 1.0;
        self.p.layer.borderColor = [UIColor whiteColor].CGColor;
        self.p.hidden = YES;
        self.p.userInteractionEnabled = YES; // Panel açıldığında içindekiler tıklansın
        
        UISwitch *s = [[UISwitch alloc] initWithFrame:CGRectMake(150, 40, 0, 0)];
        [s setOn:YES]; [s addTarget:self action:@selector(sw:) forControlEvents:UIControlEventValueChanged];
        [self.p addSubview:s];
        
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(20, 40, 120, 30)];
        l.text = @"ESP Aktif"; l.textColor = [UIColor whiteColor];
        [self.p addSubview:l];
        [self addSubview:self.p];
    }
    return self;
}

// Butona tıklandığında paneli aç/kapat ve etkileşimi yönet
- (void)t {
    self.p.hidden = !self.p.hidden;
    // Panel açıkken menü katmanı tıklamaları almalı, kapalıyken sadece buton almalı
    self.userInteractionEnabled = !self.p.hidden; 
}
- (void)sw:(UISwitch *)s { g_ESP = s.on; }

// Dokunmatik testi: Eğer butona veya panele dokunulmadıysa tıklamayı oyuna geçir
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self) return nil; // Boşluğa tıklandıysa oyuna gönder
    return hitView; // Buton veya panele tıklandıysa hilede kalsın
}
@end

// ─────────────────────────────────────────────────────────────
// CRASH-SAFE HOOK & RENDER
// ─────────────────────────────────────────────────────────────
void hook_PR(void* _this, void* canvas) {
    if (orig_PostRender) orig_PostRender(_this, canvas);

    if (!g_ESP) return;
    
    // Güvenlik Kontrolleri (Crash engelleme)
    if (!GWorld || !*GWorld) return;
    UWorld* world = *GWorld;
    if (!world || !world->CurrentLevel || !world->GameInstance) return;
    
    // ... (ESP Render kodları buraya gelir)
}

__attribute__((constructor))
static void init() {
    // Süreyi biraz daha uzatalım (10 saniye), oyun tamamen otursun
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [ModMenu loadMenu];

        void* pr = (void*)BGGetMainAddress(0x108687C80);
        if (pr) {
            DobbyHook(pr, (void*)hook_PR, (void**)&orig_PostRender);
        }
    });
}
