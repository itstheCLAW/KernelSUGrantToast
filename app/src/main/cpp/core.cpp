#include "jni.h"
#include "android/log.h"
#include <cstdio>
#include <unistd.h>
#include <asm-generic/fcntl.h>
#include "sys/epoll.h"
#include "sys/prctl.h"
#include "sys/inotify.h"
#include <sys/stat.h>
#include "thread"
#include "util.h"
#include "map"
#include "ctime"
#include <cstring>
#include <string>

#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, "KsuToast", __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, "KsuToast", __VA_ARGS__)

#define LASTSU_FILE "/data/adb/su-toast/lastsu.txt"
#define LASTSU_DIR  "/data/adb/su-toast"

static JavaVM *jvm = nullptr;
static jclass globalEntryClass = nullptr;
static jmethodID onFallbackSuEventJavaMethod = nullptr;
static jmethodID onNewSuEventJavaMethod = nullptr;
static std::map<uint32_t, time_t> toastedApplication;
static std::map<uint32_t, time_t> ignoredProcess;
static std::map<uint32_t, time_t> ignoredUid;
static short packageSearchDepth = 1;
static bool autoDeleteLog = false;

void pushToastedApplicationMap(uint32_t pid, time_t timestamp) {
    if (toastedApplication.size() > 4) {
        toastedApplication.erase(toastedApplication.begin());
    }
    toastedApplication[pid] = timestamp;
}

void pushIgnoredProcessMap(uint32_t pid, time_t timestamp) {
    if (ignoredProcess.size() > 8) {
        ignoredProcess.erase(ignoredProcess.begin());
    }
    ignoredProcess[pid] = timestamp;
}

void pushIgnoredUidMap(uint32_t pid, time_t timestamp) {
    if (ignoredUid.size() > 8) {
        ignoredUid.erase(ignoredUid.begin());
    }
    ignoredUid[pid] = timestamp;
}

// Read package name from lastsu.txt and call jniOnFallbackSuEvent
void processLastSuFile(JNIEnv *threadJniEnv) {
    FILE *f = fopen(LASTSU_FILE, "r");
    if (!f) return;
    char pkg[256] = {0};
    if (fgets(pkg, sizeof(pkg), f)) {
        // Strip newline
        size_t len = strlen(pkg);
        while (len > 0 && (pkg[len-1] == '\n' || pkg[len-1] == '\r')) {
            pkg[--len] = '\0';
        }
        if (len > 0) {
            LOGI("New su event for package: %s", pkg);
            jstring pkgStr = threadJniEnv->NewStringUTF(pkg);
            threadJniEnv->CallStaticVoidMethod(globalEntryClass, onFallbackSuEventJavaMethod, pkgStr);
            threadJniEnv->DeleteLocalRef(pkgStr);
        }
    }
    fclose(f);
}

// Watch lastsu.txt for changes using inotify
void pollingLastSuFile() {
    JNIEnv *localJniEnv;
    jvm->AttachCurrentThread(&localJniEnv, nullptr);
    setresuid(0, 0, 0);

    int inotifyFd = inotify_init1(IN_CLOEXEC);
    if (inotifyFd < 0) {
        LOGE("Failed to init inotify");
        goto done;
    }

    // Watch the directory for close_write events on lastsu.txt
    if (inotify_add_watch(inotifyFd, LASTSU_DIR, IN_CLOSE_WRITE) < 0) {
        LOGE("Failed to add inotify watch on %s", LASTSU_DIR);
        close(inotifyFd);
        goto done;
    }

    LOGI("Watching %s for changes", LASTSU_DIR);

    {
        char buf[sizeof(struct inotify_event) + 256];
        while (true) {
            ssize_t n = read(inotifyFd, buf, sizeof(buf));
            if (n < 0) {
                if (errno == EINTR) continue;
                break;
            }
            struct inotify_event *event = (struct inotify_event *)buf;
            // Check it's our file
            if (event->len > 0 && strcmp(event->name, "lastsu.txt") == 0) {
                processLastSuFile(localJniEnv);
            }
        }
        close(inotifyFd);
    }

    done:
    jvm->DetachCurrentThread();
    LOGE("pollingLastSuFile exited");
}

bool handleSuLog() {
    // Ensure the directory exists
    mkdir(LASTSU_DIR, 0755);
    std::thread pollingThread(pollingLastSuFile);
    pollingThread.detach();
    return true;
}

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    JNIEnv *jniEnv;
    jvm = vm;
    vm->GetEnv(reinterpret_cast<void **>(&jniEnv), JNI_VERSION_1_6);
    prctl(PR_SET_KEEPCAPS, 1, 0, 0, 0);
    vm->GetEnv(reinterpret_cast<void **>(&jniEnv), JNI_VERSION_1_6);
    jclass entryClass = jniEnv->FindClass("com/suisho/kernelsugranttoast/Entry");
    globalEntryClass = reinterpret_cast<jclass>(jniEnv->NewGlobalRef(entryClass));
    onFallbackSuEventJavaMethod = jniEnv->GetStaticMethodID(globalEntryClass,
                                                            "jniOnFallbackSuEvent",
                                                            "(Ljava/lang/String;)V");
    onNewSuEventJavaMethod = jniEnv->GetStaticMethodID(globalEntryClass, "jniOnNewSuEvent",
                                                       "(II)V");
    jniEnv->DeleteLocalRef(entryClass);
    return JNI_VERSION_1_6;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_suisho_kernelsugranttoast_Entry_jniInit(JNIEnv *env, jclass clazz, short searchDepth, jboolean deleteLog) {
    packageSearchDepth = searchDepth;
    autoDeleteLog = deleteLog;
    if (!utilInit()) return false;
    if (!handleSuLog()) return false;
    LOGI("JNI utilInit successful");
    return true;
}

extern "C"
JNIEXPORT void JNICALL
Java_com_suisho_kernelsugranttoast_Entry_jniSetUid(JNIEnv *env, jclass clazz, jint uid) {
    setresuid(uid, uid, 0);
}

extern "C"
JNIEXPORT void JNICALL
Java_com_suisho_kernelsugranttoast_Entry_jniProcessSharedUidApplication(JNIEnv *threadJniEnv,
                                                                        jclass clazz,
                                                                        jint ppid) {
    time_t currentTime = time(nullptr);
    auto findPpidResult = ignoredProcess.find(ppid);
    if (findPpidResult != ignoredProcess.end()) {
        if (currentTime - findPpidResult->second <= 3) {
            setresuid(1000, 1000, 0);
            return;
        }
    }
    pushIgnoredProcessMap(ppid, currentTime);
    AndroidAppInfo appInfo = queryAndroidApplicationInfo(static_cast<pid_t>(ppid),
                                                         packageSearchDepth);
    if (appInfo.isAndroidApp && !appInfo.cmdline.empty()) {
        auto findToastedApplicationResult = toastedApplication.find(appInfo.realPid);
        if (findToastedApplicationResult != toastedApplication.end()) {
            if (currentTime - findToastedApplicationResult->second <= 5) {
                setresuid(1000, 1000, 0);
                return;
            }
        }
        pushToastedApplicationMap(appInfo.realPid, currentTime);
        jstring cmd = threadJniEnv->NewStringUTF(appInfo.cmdline.c_str());
        threadJniEnv->CallStaticVoidMethod(globalEntryClass, onFallbackSuEventJavaMethod, cmd);
        threadJniEnv->DeleteLocalRef(cmd);
    }
    setresuid(1000, 1000, 0);
}

extern "C"
JNIEXPORT void JNICALL
Java_com_suisho_kernelsugranttoast_Entry_updatePackageSearchDepth(JNIEnv *env, jclass clazz,
                                                                  jshort value) {
    packageSearchDepth = value;
}
