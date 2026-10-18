# R8 keep rules for release builds.
#
# Some Flutter plugins now call their Android code from Dart over JNI
# (package:jni), looking classes and methods up *by name*. R8 doesn't see those
# calls, so without these rules it strips or renames the methods and the app
# fails at startup with NoSuchMethodError (seen with shared_preferences_android
# 2.5.0: SharedPreferencesApiRegistrar.getAll). Remove a rule only once the
# plugin ships its own consumer rules.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }

# Types those JNI bindings reference directly.
-keep class kotlin.Unit { *; }
-keep interface kotlin.coroutines.Continuation { *; }
-keep class kotlin.enums.EnumEntries { *; }
-keep interface kotlin.enums.EnumEntries { *; }
-keep class kotlin.jvm.internal.DefaultConstructorMarker { *; }
