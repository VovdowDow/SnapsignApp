plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.snapsign"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // ถ้าใช้ AGP เวอร์ชันเก่ากว่า 8 ก็ใช้ aaptOptions ได้ตามเดิม
    aaptOptions {
        noCompress += "tflite"
        noCompress += "binarypb"
    }

    defaultConfig {
        applicationId = "com.example.snapsign"
        // Kotlin DSL เขียนแบบนี้จะชัวร์กว่า
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // ใช้ debug keystore ชั่วคราว
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // กันไฟล์ LICENSE/NOTICE ซ้ำเมื่อดึง lib เพิ่ม
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1,LICENSE*,NOTICE*}"
        }
    }
}


dependencies {
    implementation("com.google.mediapipe:tasks-vision:0.20230731")
    implementation("org.tensorflow:tensorflow-lite:2.14.0")
    implementation("org.tensorflow:tensorflow-lite-support:0.4.4")
}

flutter {
    source = "../.."
}
