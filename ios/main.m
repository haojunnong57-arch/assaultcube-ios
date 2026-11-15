#import <UIKit/UIKit.h>
#define SDL_MAIN_HANDLED 1
#include "SDL.h"
#include "SDL_main.h"

#ifdef __cplusplus
extern "C" {
#endif
int SDL_main(int argc, char **argv);
#ifdef __cplusplus
}
#endif

/* Runs before main() no matter who provides main (SDL2 UIKit bootstrap or our own). */
__attribute__((constructor))
static void ac_ios_setup(void)
{
    NSString *resPath = [[NSBundle mainBundle] resourcePath];
    NSString *resSlash = [resPath stringByAppendingString:@"/"];
    setenv("AC_BASE_DIR", [resSlash UTF8String], 1);

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *home = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"assaultcube"];
    [[NSFileManager defaultManager] createDirectoryAtPath:home
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    setenv("AC_HOME_DIR", [home UTF8String], 1);
}

/* Engine's console paste path calls mac_pasteconsole() under __APPLE__
   with C++ linkage (declared inside console.cpp). Provide it via SDL's
   clipboard API (works via UIPasteboard on iOS). Must NOT be extern "C". */
void mac_pasteconsole(char *dst)
{
    const char *txt = SDL_GetClipboardText();
    if (txt) {
        snprintf(dst, 260, "%s", txt);
        SDL_free((void *)txt);
    } else {
        dst[0] = '\0';
    }
}

/* weak: if SDL2's static lib already provides main() for UIKit, that one wins */
__attribute__((weak))
int main(int argc, char **argv)
{
    return SDL_UIKitRunApp(argc, argv, SDL_main);
}
