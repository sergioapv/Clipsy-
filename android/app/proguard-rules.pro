# R8 keep rules for release builds.
#
# Several Flutter plugins (via package:jni) call Android/Kotlin code from Dart
# by *name*: classes, methods and fields are looked up at runtime with exact
# JNI signatures. R8 can't see those uses, so it strips or renames them and
# the app fails at startup (NoSuchMethodError / ClassNotFoundException).
# tool/check_jni_keep.sh verifies a built APK against every lookup.

# package:jni bridges Kotlin coroutines and touches stdlib internals
# (Result$Failure.exception, CoroutineSingletons, IntrinsicsKt, Unit.INSTANCE),
# and generated bindings use Kotlin types in their signatures. Keep the
# Kotlin stdlib intact rather than chasing individual classes.
-keep class kotlin.** { *; }
-keep interface kotlin.** { *; }

# The JNI bridge itself and the plugins whose Android code is bound over JNI.
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }

# Flutter embedding types used in those JNI signatures (e.g. JniFlutterPlugin's
# FlutterPluginBinding / ActivityPluginBinding parameters).
-keep class io.flutter.embedding.engine.plugins.** { *; }
-keep interface io.flutter.embedding.engine.plugins.** { *; }
