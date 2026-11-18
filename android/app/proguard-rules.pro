# Firebase discovers ComponentRegistrar implementations at runtime and creates
# them with Class.newInstance(), so the no-arg constructor must survive R8.
# The consumer rule shipped with firebase-components 18.0.0 only keeps the class
# itself, which made release builds fail with:
#   NoSuchMethodException: <init> []
#   NullPointerException: FirebaseCrashlytics component is not present.
# 19.0.0 ships this same member spec; keep it locally until that version resolves.
-keep class * implements com.google.firebase.components.ComponentRegistrar { <init>(); }
