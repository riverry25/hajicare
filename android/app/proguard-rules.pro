# MediaPipe Tasks Vision 0.10.14 exposes AutoValue's annotation processor on
# its runtime classpath. These javax.lang.model types are JDK compiler APIs and
# are not used by the generated AutoValue models at Android runtime.
-dontwarn javax.lang.model.SourceVersion
-dontwarn javax.lang.model.element.Element
-dontwarn javax.lang.model.element.ElementKind
-dontwarn javax.lang.model.type.TypeMirror
-dontwarn javax.lang.model.type.TypeVisitor
-dontwarn javax.lang.model.util.SimpleTypeVisitor8
