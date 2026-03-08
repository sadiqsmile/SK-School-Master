import java.io.FileInputStream
import java.util.Properties

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
    namespace = "com.sk.schoolmaster"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Release signing (Play Store)
    //
    // Create android/key.properties (ignored by git) and point it to your keystore.
    // Example:
    // storePassword=your_store_password
    // keyPassword=your_key_password
    // keyAlias=your_key_alias
    // storeFile=upload-keystore.jks
    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")

    fun kp(name: String): String? {
        val v = keystoreProperties.getProperty(name)?.trim() ?: return null
        if (v.isEmpty()) return null
        if (v.equals("CHANGE_ME", ignoreCase = true)) return null
        return v
    }

    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    // Only enable release signing if we have all required properties AND the keystore file exists.
    // This prevents placeholder key.properties from breaking local release builds.
    val storeFileProp = kp("storeFile")
    val storeFileResolved = storeFileProp?.let { file(it) }
    val hasReleaseKeystore =
        storeFileResolved != null &&
            storeFileResolved.exists() &&
            kp("keyAlias") != null &&
            kp("keyPassword") != null &&
            kp("storePassword") != null

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.sk.schoolmaster"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = kp("keyAlias")
                keyPassword = kp("keyPassword")
                storeFile = storeFileResolved
                storePassword = kp("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // If key.properties is not present, fall back to debug signing so local
            // release builds still work. Play Store requires a real release keystore.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
