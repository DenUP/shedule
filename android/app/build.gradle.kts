import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.shedule_test"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = "upload"
            keyPassword = "504774" // если использовали тот же, что и хранилище, то повторите
            storeFile = file("keystore.jks")
            storePassword = "504774"
        }
    }

    defaultConfig {
        applicationId = "com.example.shedule_test"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("release") // важно: debug тоже подписывается тем же ключом
        }
        release {
            signingConfig = signingConfigs.getByName("release")
            // можно добавить minifyEnabled и т.д., если нужно
        }
    }
}

flutter {
    source = "../.."
}