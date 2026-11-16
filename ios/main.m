#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#define SDL_MAIN_HANDLED 1
#include "SDL.h"
#include "SDL_main.h"

#ifdef __cplusplus
extern "C" {
#endif
int SDL_main(int argc, char **argv);
/* gl4es on Apple: the auto-init constructor is compiled out (NO_INIT_CONSTRUCTOR),
   so the app must initialize it itself before ANY gl call (see gl4esinit.h). */
void initialize_gl4es(void);
#ifdef __cplusplus
}
#endif

static void ac_log_line(const char *s)
{
    fputs(s, stderr);
    fputc('\n', stderr);
    fflush(stderr);
}

/* Runs before any main() variant, i.e. before the engine makes its first gl call. */
__attribute__((constructor))
static void ac_ios_setup(void)
{
    NSString *resPath = [[NSBundle mainBundle] resourcePath];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *home = ([paths count] > 0) ? [[paths objectAtIndex:0] stringByAppendingPathComponent:@"assaultcube"] : nil;
    NSString *logPath = [home stringByAppendingPathComponent:@"ac_log.txt"];

    if (home) {
        [[NSFileManager defaultManager] createDirectoryAtPath:home
                                 withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if (logPath) {
        freopen([logPath UTF8String], "a", stdout);
        freopen([logPath UTF8String], "a", stderr);
    }
    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);

    fprintf(stderr, "=== AssaultCube iOS start ===\n");
    fprintf(stderr, "bundle: %s\n", resPath ? [resPath UTF8String] : "(nil)");

    if (resPath && chdir([resPath UTF8String]) == 0) ac_log_line("chdir -> bundle ok");
    else ac_log_line("chdir FAILED");

    if (home) setenv("AC_HOME_DIR", [home UTF8String], 1);

    /* No GL context exists yet, so skip gl4es hardware probing and use sane
       OpenGL ES 2.0 defaults (npot/fbo/etc) instead of a half-empty state. */
    setenv("LIBGL_NOTEST", "1", 1);
    initialize_gl4es();
    ac_log_line("gl4es initialized (LIBGL_NOTEST=1, ES2 defaults)");
}

/* Engine's console paste path calls mac_pasteconsole() with C++ linkage. */
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

/* weak: SDL2's static lib may supply its own UIKit main() */
__attribute__((weak))
int main(int argc, char **argv)
{
    return SDL_UIKitRunApp(argc, argv, SDL_main);
}
