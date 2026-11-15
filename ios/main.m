#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <signal.h>
#include <execinfo.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>
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

static FILE *g_log = NULL;

static void ac_log(const char *fmt, ...)
{
    if (!g_log) return;
    va_list ap;
    va_start(ap, fmt);
    vfprintf(g_log, fmt, ap);
    va_end(ap);
    fflush(g_log);
}

static void ac_crash_handler(int sig)
{
    void *frames[64];
    int n = backtrace(frames, 64);
    if (g_log) {
        fprintf(g_log, "\n*** CRASH: signal %d ***\n", sig);
        fflush(g_log);
        backtrace_symbols_fd(frames, n, fileno(g_log));
        fflush(g_log);
    }
    _exit(128 + sig);
}

/* Runs before main() no matter who provides main (SDL2 UIKit or ours). */
__attribute__((constructor))
static void ac_ios_setup(void)
{
    NSString *resPath = [[NSBundle mainBundle] resourcePath];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *home = nil;
    if ([paths count] > 0) home = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"assaultcube"];
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
    g_log = stderr;

    ac_log("=== AssaultCube iOS start %s ===\n", [[[NSDate date] description] UTF8String]);
    ac_log("bundle: %s\n", resPath ? [resPath UTF8String] : "(nil)");

    if (resPath && chdir([resPath UTF8String]) == 0) {
        ac_log("chdir ok -> %s\n", [resPath UTF8String]);
    } else {
        ac_log("chdir FAILED\n");
    }
    char cwdbuf[1024];
    cwdbuf[0] = 0;
    if (getcwd(cwdbuf, sizeof(cwdbuf))) ac_log("cwd: %s\n", cwdbuf);

    if (home) setenv("AC_HOME_DIR", [home UTF8String], 1);
    ac_log("home: %s\n", home ? [home UTF8String] : "(nil)");

    NSString *pkg = resPath ? [resPath stringByAppendingPathComponent:@"packages"] : nil;
    ac_log("packages exists: %d\n", pkg ? (int)[[NSFileManager defaultManager] fileExistsAtPath:pkg] : 0);

    signal(SIGSEGV, ac_crash_handler);
    signal(SIGABRT, ac_crash_handler);
    signal(SIGBUS, ac_crash_handler);
    signal(SIGILL, ac_crash_handler);
    signal(SIGFPE, ac_crash_handler);
    signal(SIGTRAP, ac_crash_handler);
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
    ac_log("main() entered, argc=%d\n", argc);
    int r = SDL_UIKitRunApp(argc, argv, SDL_main);
    ac_log("SDL_UIKitRunApp returned %d\n", r);
    return r;
}
