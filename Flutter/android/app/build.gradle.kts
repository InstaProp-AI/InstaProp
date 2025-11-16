plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.instaprop.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Application ID for Instaprop
        applicationId = "com.instaprop.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // For demo/testing: Using debug keys (not secure for production)
            // For production: Create a keystore and configure signing
            // See: https://docs.flutter.dev/deployment/android#signing-the-app
            signingConfig = signingConfigs.getByName("debug")
            
            // Enable code shrinking and obfuscation for release builds
            isMinifyEnabled = false
            isShrinkResources = false
            
            // ProGuard rules (uncomment if enabling minification)
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    
    // Uncomment and configure for production signing:
    // signingConfigs {
    //     create("release") {
    //         storeFile = file("path/to/your/keystore.jks")
    //         storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
    //         keyAlias = "your-key-alias"
    //         keyPassword = System.getenv("KEY_PASSWORD") ?: ""
    //     }
    // }
    // Then change release buildType to: signingConfig = signingConfigs.getByName("release")
}

flutter {
    source = "../.."
}
