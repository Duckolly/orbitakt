# Android build.gradle release patch

Примени эти изменения к файлу:

```text
android/app/build.gradle
```

Не коммить `key.properties` и keystore в git.

---

## 1. Добавь чтение key.properties перед блоком `android`

Добавь в начало файла, после `plugins { ... }`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

---

## 2. Внутри `android {` выставь SDK

```gradle
android {
    namespace = "com.dvizh.app"

    compileSdk = 35

    defaultConfig {
        applicationId = "com.dvizh.app"

        minSdk = 23

        targetSdk = 35

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
}
```

Если у тебя уже другой `namespace` или `applicationId`, замени на свой.  
Для Google Play лучше использовать стабильный reverse-domain ID, например:

```text
com.dvizh.app
```

или

```text
dev.duckolly.dvizh
```

---

## 3. Добавь release signing

Внутри `android {` добавь:

```gradle
signingConfigs {
    release {
        if (keystorePropertiesFile.exists()) {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
}
```

---

## 4. Замени `buildTypes.release`

```gradle
buildTypes {
    release {
        if (keystorePropertiesFile.exists()) {
            signingConfig signingConfigs.release
        } else {
            signingConfig signingConfigs.debug
        }
    }
}
```

Для реального релиза в Google Play подпись должна быть production, не debug.

---

## 5. Локальный файл `android/key.properties`

Создай локально, не в git:

```properties
storePassword=ТВОЙ_ПАРОЛЬ
keyPassword=ТВОЙ_ПАРОЛЬ
keyAlias=ТВОЙ_ALIAS
storeFile=/путь/to/upload-keystore.jks
```

Добавь в `.gitignore`:

```gitignore
android/key.properties
*.jks
*.keystore
```

---

## 6. Сборка AAB

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

Файл:

```text
build/app/outputs/bundle/release/app-release.aab
```
