plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.tvhome.launcher"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.tvhome.launcher"
        minSdk = 22          // Fire OS 5 and newer
        targetSdk = 34
        versionCode = 26
        versionName = "26"
    }

    // one fixed key, so APKs built on GitHub install over each other
    signingConfigs {
        create("tvhome") {
            storeFile = file("tvhome.keystore")
            storePassword = "tvhome123"
            keyAlias = "tvhome"
            keyPassword = "tvhome123"
        }
    }
    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("tvhome")
        }
        release {
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("tvhome")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}

dependencies {
    // ExoPlayer (Media3) plays IPTV (MPEG-TS / HLS) and Jellyfin (direct play + HLS transcodes)
    val media3 = "1.4.1"
    implementation("androidx.media3:media3-exoplayer:$media3")
    implementation("androidx.media3:media3-exoplayer-hls:$media3")
    implementation("androidx.media3:media3-ui:$media3")
    implementation("androidx.annotation:annotation-experimental:1.4.1")
}
