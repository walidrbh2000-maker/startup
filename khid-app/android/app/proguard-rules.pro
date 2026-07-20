# Règles ProGuard pour Khidmeti

# Garder les classes Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Garder les services
-keep class com.khidmeti.services.** { *; }
-keep class com.khidmeti.receivers.** { *; }
-keep class com.khidmeti.utils.** { *; }

# Garder les classes avec annotations @Keep
-keep @androidx.annotation.Keep class * { *; }

# Garder les classes Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Garder les classes de localisation
-keep class android.location.** { *; }
-keep class com.google.android.gms.location.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Gson (si utilisé)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }

# Préserver les numéros de ligne pour les stack traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Optimisations
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

-keep class com.google.android.play.core.** { *; }

-keep class com.google.android.gms.** { *; }

-dontwarn com.google.android.play.**