allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    configurations.configureEach {
        resolutionStrategy {
            // integration_test still requests espresso 3.2+, which breaks manifest
            // namespace validation on AGP 9+.
            force(
                "androidx.test.espresso:espresso-core:3.6.1",
                "androidx.test.espresso:espresso-idling-resource:3.6.1",
                "androidx.test:runner:1.6.2",
                "androidx.test:rules:1.6.1",
            )
        }
    }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
