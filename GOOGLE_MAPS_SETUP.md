# Настройка Google Maps API Key

## Проблема
Приложение падает с ошибкой:
```
java.lang.IllegalStateException: API key not found
```

## Решение

### Шаг 1: Получить Google Maps API ключ

1. Перейдите в [Google Cloud Console](https://console.cloud.google.com/)
2. Создайте новый проект или выберите существующий
3. Включите **Maps SDK for Android** API:
   - Перейдите в "APIs & Services" → "Library"
   - Найдите "Maps SDK for Android"
   - Нажмите "Enable"

4. Создайте API ключ:
   - Перейдите в "APIs & Services" → "Credentials"
   - Нажмите "Create Credentials" → "API key"
   - Скопируйте созданный ключ

### Шаг 2: Добавить ключ в приложение

Откройте файл `android/app/src/main/AndroidManifest.xml` и замените:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
    
```

На:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="ВАШ_РЕАЛЬНЫЙ_API_КЛЮЧ"/>
```

### Шаг 3: Перезапустить приложение

```bash
flutter run
```

## Для iOS (если нужно)

Откройте `ios/Runner/AppDelegate.swift` и добавьте:

```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyAkVIsm5GztxD095U9ySIFnLDEHqQH9SX8")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## Настройка Firebase (для полной функциональности)

Чтобы включить Firebase:

1. Запустите `flutterfire configure` в терминале
2. Выберите проект Firebase
3. Выберите платформы (iOS, Android)
4. В `lib/main.dart` раскомментируйте:
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

5. В `lib/features/auth/providers/auth_provider.dart` замените:
```dart
return MockAuthService();
```
На:
```dart
return FirebaseAuthService();
```

## Текущий статус

- ✅ MockAuthService работает (можно войти без Firebase)
- ❌ Google Maps требует API ключ
- ❌ Firebase не настроен (eventsService, profileService не работают)

После добавления Google Maps API ключа приложение запустится, но карта и события не будут работать до настройки Firebase.
