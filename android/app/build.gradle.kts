plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.snapsign"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }


    aaptOptions {
        noCompress += "tflite"
        noCompress += "binarypb"
    }

    defaultConfig {
        applicationId = "com.example.snapsign"
        minSdkVersion(24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation("com.google.mediapipe:tasks-vision:0.10.0") // เวอร์ชันล่าสุดที่ใช้ HandLandmarker
}

flutter {
    source = "../.."
}

