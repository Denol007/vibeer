# 🚀 Инструкция по запуску приложения Vibe

## ✅ Текущий статус
- Приложение работает с MockAuthService (тестовый вход)
- Google Maps и Firebase НЕ настроены

## ⚠️ Что нужно сделать

### Вариант 1: Быстрый тест (без карт и событий)
Приложение уже работает! Вы можете:
- Войти через "Sign in with Google" (тестовый вход)
- Посмотреть интерфейс
- Увидеть экран настройки вместо карты

### Вариант 2: Полная функциональность

#### Шаг 1: Google Maps API Key

1. Откройте https://console.cloud.google.com/
2. Создайте проект
3. Включите "Maps SDK for Android"
4. Создайте API ключ (Credentials → Create → API Key)
5. Откройте `android/app/src/main/AndroidManifest.xml`
6. Замените `YOUR_GOOGLE_MAPS_API_KEY_HERE` на ваш ключ

#### Шаг 2: Firebase (опционально)

```bash
# Установите flutterfire CLI
dart pub global activate flutterfire_cli

# Настройте Firebase
flutterfire configure
```

Затем:
1. В `lib/main.dart` раскомментируйте Firebase.initializeApp()
2. В `lib/features/auth/providers/auth_provider.dart`:
   - Закомментируйте: `return MockAuthService();`
   - Раскомментируйте: `return FirebaseAuthService();`

## �� Быстрый запуск

```bash
# Просто запустите - приложение работает с mock-данными
flutter run

# После добавления Google Maps API ключа:
# Измените в lib/core/router/app_router.dart:
# builder: (context, state) => const MapScreen(),
```

## 📝 Что работает сейчас

✅ Вход (MockAuthService)
✅ Навигация между экранами  
✅ UI/UX интерфейс
✅ Профиль (mock данные)
❌ Карта (нужен Google Maps API)
❌ События, чат (нужен Firebase)

## 🆘 Помощь

См. `GOOGLE_MAPS_SETUP.md` для подробных инструкций
