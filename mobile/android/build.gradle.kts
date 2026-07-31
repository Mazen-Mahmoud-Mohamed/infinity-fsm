allprojects {
    repositories {
        google()
        mavenCentral()
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

// Flutter plugins (e.g. geocoding_android) hardcode compileSdk 33 in their own
// build.gradle. Force every Android library/app module to compileSdk 36 so
// dependency metadata that requires API 34+ can compile.
subprojects {
    afterEvaluate {
        val android = extensions.findByName("android") ?: return@afterEvaluate
        try {
            val setCompileSdk =
                android.javaClass.methods.firstOrNull {
                    it.name == "setCompileSdk" && it.parameterCount == 1
                }
            if (setCompileSdk != null) {
                setCompileSdk.invoke(android, 36)
                return@afterEvaluate
            }
            val setCompileSdkVersion =
                android.javaClass.methods.firstOrNull {
                    it.name == "setCompileSdkVersion" &&
                        it.parameterCount == 1 &&
                        it.parameterTypes[0] == Int::class.javaPrimitiveType
                }
            setCompileSdkVersion?.invoke(android, 36)
        } catch (_: Exception) {
            // Non-Android subprojects are ignored.
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
