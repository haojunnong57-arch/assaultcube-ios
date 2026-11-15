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

/* weak: if SDL2's static lib already provides main() for UIKit, that one wins */
__attribute__((weak))
int main(int argc, char **argv)
{
    return SDL_UIKitRunApp(argc, argv, SDL_main);
}
