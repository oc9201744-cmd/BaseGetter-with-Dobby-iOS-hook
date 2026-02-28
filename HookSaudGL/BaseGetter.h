#ifndef BASEGETTER_H
#define BASEGETTER_H

#include <mach-o/dyld.h>
#include <stdint.h>
#include <string.h>

// ShadowTrackerExtra gibi modüllerin base adresini döndürür
// iOS 17'de de çalışacak şekilde, dyld üzerinden slide + header topluyor.
static inline uintptr_t getBaseAddress(const char *moduleName) {
    uintptr_t slide = 0;
    const struct mach_header *header = NULL;

    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, moduleName)) {
            slide  = _dyld_get_image_vmaddr_slide(i);
            header = _dyld_get_image_header(i);
            return (uintptr_t)header + slide;
        }
    }

    return 0;
}

#endif /* BASEGETTER_H */