#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AVFoundation/AVFoundation.h>
#import <GameController/GameController.h>
#import <GameKit/GameKit.h>
#import <CloudKit/CloudKit.h>
#import <DeviceCheck/DeviceCheck.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <Speech/Speech.h>
#import <Security/Security.h>

// BaseGetter'i Dahil Et
#include "BaseGetter.h"

const uintptr_t AccessoriesVRecoilFactor = 0xBC8; // Dikey geri tepme
const uintptr_t AccessoriesHRecoilFactor = 0xBD0; // Yatay geri tepme
const uintptr_t AccessoriesRecoveryFactor = 0xBCC; // Geri tepme toparlanma

// UI'yi Başlatma (Tweak Aktif Uyarısı Göstermek)
void showActiveUI() {
    UIWindow *window = [[UIApplication sharedApplication