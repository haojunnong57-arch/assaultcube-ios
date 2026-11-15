#ifndef STUB_ANDROID_LOG_H
#define STUB_ANDROID_LOG_H
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>

typedef enum android_LogPriority {
    ANDROID_LOG_UNKNOWN = 0,
    ANDROID_LOG_DEFAULT,
    ANDROID_LOG_VERBOSE,
    ANDROID_LOG_DEBUG,
    ANDROID_LOG_INFO,
    ANDROID_LOG_WARN,
    ANDROID_LOG_ERROR,
    ANDROID_LOG_FATAL,
    ANDROID_LOG_SILENT
} android_LogPriority;

static inline int __android_log_print(int prio, const char *tag, const char *fmt, ...) {
    (void)prio;
    fprintf(stderr, "[%s] ", tag ? tag : "");
    va_list ap; va_start(ap, fmt);
    int r = vfprintf(stderr, fmt, ap);
    va_end(ap);
    return r;
}

static inline int __android_log_write(int prio, const char *tag, const char *text) {
    (void)prio;
    fprintf(stderr, "[%s] %s", tag ? tag : "", text ? text : "");
    return 0;
}

static inline int __android_log_vprint(int prio, const char *tag, const char *fmt, va_list ap) {
    (void)prio;
    fprintf(stderr, "[%s] ", tag ? tag : "");
    return vfprintf(stderr, fmt, ap);
}

static inline void __android_log_assert(const char *cond, const char *tag, const char *fmt, ...)
    __attribute__((noreturn));

static inline void __android_log_assert(const char *cond, const char *tag, const char *fmt, ...) {
    fprintf(stderr, "[%s] ASSERT %s: ", tag ? tag : "", cond ? cond : "");
    va_list ap; va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    abort();
}

#endif
