# MediaPipe Tasks Vision 0.10.14 exposes AutoValue's annotation processor on
# its runtime classpath. These javax.lang.model types are JDK compiler APIs and
# are not used by the generated AutoValue models at Android runtime.
-dontwarn javax.lang.model.SourceVersion
-dontwarn javax.lang.model.element.Element
-dontwarn javax.lang.model.element.ElementKind
-dontwarn javax.lang.model.type.TypeMirror
-dontwarn javax.lang.model.type.TypeVisitor
-dontwarn javax.lang.model.util.SimpleTypeVisitor8

# ============================================================
# AndroidX WindowManager optional extension APIs
# Generated from R8 missing_rules.txt
# ============================================================
-dontwarn androidx.window.extensions.WindowExtensions
-dontwarn androidx.window.extensions.WindowExtensionsProvider
-dontwarn androidx.window.extensions.area.ExtensionWindowAreaPresentation
-dontwarn androidx.window.extensions.layout.DisplayFeature
-dontwarn androidx.window.extensions.layout.FoldingFeature
-dontwarn androidx.window.extensions.layout.WindowLayoutComponent
-dontwarn androidx.window.extensions.layout.WindowLayoutInfo
-dontwarn androidx.window.sidecar.SidecarDeviceState
-dontwarn androidx.window.sidecar.SidecarDisplayFeature
-dontwarn androidx.window.sidecar.SidecarInterface$SidecarCallback
-dontwarn androidx.window.sidecar.SidecarInterface
-dontwarn androidx.window.sidecar.SidecarProvider
-dontwarn androidx.window.sidecar.SidecarWindowLayoutInfo

# ============================================================
# AndroidX WorkManager / WorkDatabase (Room-backed)
# WorkManager uses reflection to instantiate WorkDatabase and
# ListenableWorker subclasses.  R8 must not rename or remove them.
# ============================================================
-keep class androidx.work.** { *; }
-keep interface androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keepclassmembers class * extends androidx.work.Worker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}
-keepclassmembers class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}
-keepclassmembers class * extends androidx.work.CoroutineWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}
-keepclassmembers class * extends androidx.work.RxWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}

# ============================================================
# AndroidX Room (used by WorkManager internally)
# Room generates code at compile time but also loads it via
# reflection at runtime.
# ============================================================
-keep class * extends androidx.room.RoomDatabase { *; }
-keep @androidx.room.Database class * { *; }
-keepclassmembers @androidx.room.Database class * { *; }
-keep class androidx.room.** { *; }
-dontwarn androidx.room.paging.**

# ============================================================
# AndroidX App Startup
# InitializationProvider uses reflection to find Initializer
# implementations.
# ============================================================
-keep class * implements androidx.startup.Initializer { *; }
-keepnames class androidx.startup.AppInitializer
-keep class androidx.startup.** { *; }

# ============================================================
# Firebase / Google Services
# ============================================================
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Crashlytics - preserve source/line info for crash reports
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.google.firebase.crashlytics.** { *; }

# ============================================================
# Kotlin Coroutines / Flow / Serialization
# ============================================================
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}
-dontwarn kotlinx.coroutines.**
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

# ============================================================
# Gson / Reflection-based serialization
# ============================================================
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# ============================================================
# OkHttp / Retrofit (used by Firebase and networking)
# ============================================================
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class retrofit2.** { *; }

# ============================================================
# Google Sign-In / Credentials
# ============================================================
-keep class com.google.android.libraries.identity.googleid.** { *; }
-keep class androidx.credentials.** { *; }

# ============================================================
# Hajicare app & Camera helper
# ============================================================
-keep class com.example.hajicare.** { *; }
-dontwarn com.example.hajicare.**

# ============================================================
# CameraX
# ============================================================
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**
-keep public class androidx.camera.camera2.Camera2Config$DefaultProvider { *; }

# ============================================================
# MediaPipe / TFLite / LiteRT / ONNX (ML inference)
# ============================================================
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**
-keepclassmembers class * extends com.google.protobuf.GeneratedMessageLite { *; }
-keep class com.google.common.flogger.** { *; }
-dontwarn com.google.common.flogger.**
-keepclassmembers class com.google.mediapipe.**$$ExternalSyntheticLambda* { *; }
-keep class com.google.ai.edge.litert.** { *; }
-dontwarn com.google.ai.edge.litert.**
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**
-keep class com.tflite.** { *; }
-dontwarn com.tflite.**
-keep class ai.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**

# ============================================================
# Flutter engine / plugin registrar
# ============================================================
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# ============================================================
# Enums (R8 can inline enum ordinal() but break name() calls)
# ============================================================
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ============================================================
# Parcelables / Serializables
# ============================================================
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ============================================================
# General Android / JNI
# ============================================================
-keepclasseswithmembernames class * {
    native <methods>;
}
-keepclassmembers class * extends android.app.Activity {
    public void *(android.view.View);
}
