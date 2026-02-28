#import "BaseGetter.h"
#import "dobby.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// ─────────────────────────────────────────────────────────────
// MARK: Mod Kontrol Değişkenleri
// ─────────────────────────────────────────────────────────────
static BOOL g_ESP_Enabled = YES;
static BOOL g_ESP_Lines   = YES;
static BOOL g_ESP_Boxes   = YES;

// ─────────────────────────────────────────────────────────────
// MARK: Menü Arayüzü (UIKit)
// ─────────────────────────────────────────────────────────────
@interface ModMenu : UIView
@property (nonatomic, strong) UIView *menuPanel;
@property (nonatomic, strong) UIButton *menuButton;
@end

@implementation ModMenu

static ModMenu *sharedInstance;

+ (void)loadMenu {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ModMenu alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [[UIApplication sharedApplication].keyWindow addSubview:sharedInstance];
    });
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO; // Arka plana dokunmayı engelleme
        [self setupMenuButton];
        [self setupMenuPanel];
    }
    return self;
}

- (void)setupMenuButton {
    self.menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.menuButton.frame = CGRectMake(50, 150, 50, 50);
    self.menuButton.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    [self.menuButton setTitle:@"XO" forState:UIControlStateNormal];
    self.menuButton.layer.cornerRadius = 25;
    [self.menuButton addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
    
    // Sürüklenebilir buton (Pan Gesture)
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.menuButton addGestureRecognizer:pan];
    
    [self addSubview:self.menuButton];
}

- (void)setupMenuPanel {
    self.menuPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 250, 200)];
    self.menuPanel.center = self.center;
    self.menuPanel.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
    self.menuPanel.layer.cornerRadius = 10;
    self.menuPanel.hidden = YES;
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 250, 30)];
    title.text = @"XO VIP MENU v4.2";
    title.textColor = [UIColor whiteColor];
    title.textAlignment = NSTextAlignmentCenter;
    [self.menuPanel addSubview:title];

    // Switch: ESP
    [self addSwitchWithTitle:@"ESP Enable" y:50 action:@selector(toggleESP:)];
    [self addSwitchWithTitle:@"ESP Box" y:90 action:@selector(toggleBox:)];
    [self addSwitchWithTitle:@"ESP Line" y:130 action:@selector(toggleLine:)];

    [self addSubview:self.menuPanel];
}

- (void)addSwitchWithTitle:(NSString *)title y:(float)y action:(SEL)action {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 150, 30)];
    lbl.text = title;
    lbl.textColor = [UIColor whiteColor];
    [self.menuPanel addSubview:lbl];

    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(180, y, 0, 0)];
    sw.on = YES;
    [sw addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    [self.menuPanel addSubview:sw];
}

// Buton İşlemleri
- (void)togglePanel { self.menuPanel.hidden = !self.menuPanel.hidden; self.userInteractionEnabled = !self.menuPanel.hidden; }
- (void)handlePan:(UIPanGestureRecognizer *)p {
    CGPoint translation = [p translationInView:self];
    self.menuButton.center = CGPointMake(self.menuButton.center.x + translation.x, self.menuButton.center.y + translation.y);
    [p setTranslation:CGPointZero inView:self];
}
- (void)toggleESP:(UISwitch *)s { g_ESP_Enabled = s.on; }
- (void)toggleBox:(UISwitch *)s { g_ESP_Boxes = s.on; }
- (void)toggleLine:(UISwitch *)s { g_ESP_Lines = s.on; }
@end

// ─────────────────────────────────────────────────────────────
// MARK: ESP & Hook Entegrasyonu (Önceki Kodun Devamı)
// ─────────────────────────────────────────────────────────────

void hooked_PostRender(void* _this, void* canvas) {
    if (orig_PostRender) orig_PostRender(_this, canvas);

    // Menüden gelen kontrole bakıyoruz
    if (!g_ESP_Enabled) return;

    // ... (Burada daha önce yazdığımız RenderMyESP fonksiyonu çalışır)
    // Render içinde g_ESP_Boxes ve g_ESP_Lines değişkenlerini kontrol edebilirsin.
}

__attribute__((constructor))
static void initialize() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        // Menüyü Ekrana Bas
        [ModMenu loadMenu];

        // Hookları Başlat
        GWorld = (UWorld**)BGGetMainAddress(0x106684010);
        void* postRenderAddr = (void*)BGGetMainAddress(0x108687C80);
        
        if (postRenderAddr) {
            DobbyHook(postRenderAddr, (void*)hooked_PostRender, (void**)&orig_PostRender);
        }
    });
}
