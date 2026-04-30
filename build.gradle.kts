//allprojects {
//    repositories {
//        google()
//        mavenCentral()
//    }
//}
//
//val newBuildDir: Directory =
//    rootProject.layout.buildDirectory
//        .dir("../../build")
//        .get()// android/build.gradle.kts
//
//buildscript {
//    repositories {
//        google()
//        mavenCentral()
//    }
//    dependencies {
//        // Firebase ke liye version check karlein, 4.4.0 stable hai
//        classpath("com.google.gms:google-services:4.4.0")
//    }
//}
//
//allprojects {
//    repositories {
//        google()
//        mavenCentral()
//    }
//}
//
//tasks.register<Delete>("clean") {
//    delete(rootProject.layout.buildDirectory)
//}
//
//subprojects {
//    project.evaluationDependsOn(":app")
//}
//rootProject.layout.buildDirectory.value(newBuildDir)
//
//subprojects {
//    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
//    project.layout.buildDirectory.value(newSubprojectBuildDir)
//}
//subprojects {
//    project.evaluationDependsOn(":app")
//}
//
//tasks.register<Delete>("clean") {
//    delete(rootProject.layout.buildDirectory)
//}
