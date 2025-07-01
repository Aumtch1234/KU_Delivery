import java.util.Properties // Add this line at the very top
import java.io.FileInputStream // Also add this, as it's often needed with Properties

plugins {
    id("com.android.application")
    kotlin("android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.feas.deliveryapp"
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
        applicationId = "com.feas.deliveryapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val keystoreProperties = Properties() // Now 'Properties' should be resolved
    val keystorePropertiesFile = rootProject.file("key.properties")

    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use {
            keystoreProperties.load(it)
        }
    } else {
        println("WARNING: key.properties file not found at ${keystorePropertiesFile.absolutePath}")
    }

    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties.getProperty("storeFile"))
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}