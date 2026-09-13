allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Fix: Enforce consistent JVM target for all subprojects (including tflite_flutter, flutter_tts, etc.)
subprojects {
    afterEvaluate {
        // Fix via Android extension (more reliable than task-level override)
        extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
        // Fix Kotlin compile tasks (using new compilerOptions DSL)
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    // Solusi dinamis: Daripada memaksa Java menjadi 21 dan melawan property finalization AGP,
    // kita biarkan plugin Java menggunakan versinya sendiri (misal 11 atau 17), lalu kita
    // selaraskan Kotlin compiler agar menggunakan target yang persis sama dengan Java.
    project.plugins.withId("com.android.library") {
        project.afterEvaluate {
            val androidExt = project.extensions.findByType<com.android.build.gradle.BaseExtension>()
            if (androidExt != null) {
                // Ambil target Java dari plugin (contoh: "1.8", "11", "17")
                val javaTarget = androidExt.compileOptions.targetCompatibility.toString()
                
                project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                    // Setel Kotlin agar sama dengan Java
                    compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.fromTarget(javaTarget))
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
