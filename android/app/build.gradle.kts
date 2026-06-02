import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import com.android.build.api.dsl.ApplicationExtension

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android Gradle plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

extensions.configure<ApplicationExtension> {
    namespace = "com.mrunit.etherly"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }



    defaultConfig {
        // Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mrunit.etherly"
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

    applicationVariants.all {
        outputs.forEach { output ->
            val apkOutput = output as? com.android.build.gradle.api.ApkVariantOutput
            apkOutput?.outputFileName = "Etherly.apk"
        }
    }
}

flutter {
    source = "../.."
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}
