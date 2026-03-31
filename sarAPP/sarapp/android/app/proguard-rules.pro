# flutter_local_notifications — keep receiver classes used for scheduled alarms
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Gson (used internally by flutter_local_notifications to serialise pending notifications)
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
