// ======================================
// 1️⃣ Déclaration des plugins avec versions
// ======================================
plugins {
    id("com.android.application") apply false
    id("com.android.library") apply false
    id("org.jetbrains.kotlin.android") apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

// ======================================
// 2️⃣ Repositories pour tous les projets
// ======================================
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ======================================
// 3️⃣ Rediriger les build directories
// ======================================
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

// ======================================
// 4️⃣ Tâche clean
// ======================================
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
