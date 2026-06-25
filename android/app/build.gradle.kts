plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.emoney_walet"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.emoney.service"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}

tasks.register("copyNotificationIcons") {
    doLast {
        val resDir = file("src/main/res")
        val densities = listOf("hdpi", "mdpi", "xhdpi", "xxhdpi", "xxxhdpi")
        for (density in densities) {
            val srcFile = file("$resDir/mipmap-$density/launcher_icon.png")
            val destFile = file("$resDir/drawable-$density/launcher_icon.png")
            if (srcFile.exists()) {
                destFile.parentFile.mkdirs()
                srcFile.copyTo(destFile, overwrite = true)
                println("Copied launcher_icon.png to drawable-$density")
            }
            
            val srcFile2 = file("$resDir/mipmap-$density/ic_launcher.png")
            val destFile2 = file("$resDir/drawable-$density/ic_launcher.png")
            if (srcFile2.exists()) {
                destFile2.parentFile.mkdirs()
                srcFile2.copyTo(destFile2, overwrite = true)
                println("Copied ic_launcher.png to drawable-$density")
            }
        }
        
        // Delete duplicate PNG to prevent build failure
        val duplicatePng = file("$resDir/drawable/ic_notification.png")
        if (duplicatePng.exists()) {
            duplicatePng.delete()
            println("Deleted duplicate ic_notification.png to resolve resource conflict")
        }
    }
}

tasks.matching { it.name.startsWith("preBuild") }.configureEach {
    dependsOn("copyNotificationIcons")
}
