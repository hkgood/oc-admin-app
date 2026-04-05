# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# PocketBase
-keep class com.pocketbase.** { *; }
-dontwarn com.pocketbase.**

# Keep SDK classes
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**
