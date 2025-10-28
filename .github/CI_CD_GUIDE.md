# Vibe App CI/CD

Этот проект использует GitHub Actions для автоматической сборки, тестирования и развертывания.

## Рабочие процессы (Workflows)

### 1. Flutter CI/CD (`flutter-ci.yml`)

Запускается при:
- Push в ветки `main` или `develop`
- Pull Request в ветки `main` или `develop`

**Этапы:**

#### Test and Analyze
- Проверка форматирования кода (`dart format`)
- Статический анализ (`flutter analyze`)
- Запуск тестов (`flutter test`)
- Загрузка покрытия кода в Codecov

#### Build Android APK
- Сборка release APK
- Сохранение артефакта на 30 дней
- Запускается только при push (не для PR)

#### Build Android App Bundle
- Сборка AAB для Google Play
- Запускается только для ветки `main`
- Сохранение артефакта на 30 дней

#### Build iOS IPA
- Сборка iOS приложения
- Запускается только для ветки `main`
- Требует macOS runner
- Сохранение артефакта на 30 дней

### 2. Deploy to Firebase (`deploy-firebase.yml`)

Запускается при:
- Push тега вида `v*` (например, `v1.0.0`, `v1.2.3`)

**Действия:**
- Сборка Android APK
- Загрузка в Firebase App Distribution
- Отправка тестовой группе `testers`

## Настройка секретов GitHub

Для полноценной работы CI/CD нужно добавить следующие секреты в настройках репозитория:

### Обязательные секреты:

1. **FIREBASE_ANDROID_APP_ID**
   - Firebase App ID для Android приложения
   - Найти: Firebase Console → Project Settings → Your apps → Android

2. **FIREBASE_SERVICE_ACCOUNT**
   - JSON файл service account для Firebase
   - Создать: Firebase Console → Project Settings → Service Accounts → Generate new private key

### Опциональные секреты (для подписи приложений):

3. **KEYSTORE_BASE64**
   - Ваш keystore файл, закодированный в base64
   ```bash
   base64 -i android/app/keystore.jks | pbcopy
   ```

4. **KEYSTORE_PASSWORD**
   - Пароль от keystore

5. **KEY_ALIAS**
   - Алиас ключа

6. **KEY_PASSWORD**
   - Пароль ключа

## Добавление секретов

1. Откройте репозиторий на GitHub
2. Перейдите в **Settings** → **Secrets and variables** → **Actions**
3. Нажмите **New repository secret**
4. Добавьте имя и значение секрета

## Использование

### Автоматическая сборка

```bash
# Создать коммит и push
git add .
git commit -m "feat: новая функция"
git push origin develop

# CI/CD автоматически запустится
```

### Создание релиза

```bash
# Создать тег версии
git tag v1.0.0
git push origin v1.0.0

# Автоматически:
# 1. Запустится сборка
# 2. APK загрузится в Firebase App Distribution
# 3. Тестеры получат уведомление
```

### Скачивание артефактов

1. Откройте **Actions** в репозитории
2. Выберите нужный workflow run
3. Внизу найдите секцию **Artifacts**
4. Скачайте нужный файл:
   - `release-apk` - Android APK
   - `release-aab` - Android App Bundle для Play Store
   - `ios-build` - iOS сборка

## Статус сборки

Добавьте badge в README:

```markdown
![Flutter CI](https://github.com/Denol007/vibeer/actions/workflows/flutter-ci.yml/badge.svg)
```

## Покрытие кода

Для просмотра покрытия кода:

1. Зарегистрируйтесь на [codecov.io](https://codecov.io)
2. Подключите репозиторий
3. Добавьте badge:

```markdown
[![codecov](https://codecov.io/gh/Denol007/vibeer/branch/main/graph/badge.svg)](https://codecov.io/gh/Denol007/vibeer)
```

## Настройка Firebase App Distribution

1. Установите Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Войдите в Firebase:
   ```bash
   firebase login
   ```

3. Создайте группу тестеров:
   - Firebase Console → App Distribution
   - Вкладка "Testers & Groups"
   - Создайте группу "testers"
   - Добавьте email адреса тестеров

## Отключение iOS сборки

Если не нужна iOS сборка (macOS runners платные):

1. Откройте `.github/workflows/flutter-ci.yml`
2. Удалите или закомментируйте job `build-ios`

## Локальная проверка перед push

```bash
# Проверить форматирование
dart format .

# Анализ кода
flutter analyze

# Запустить тесты
flutter test

# Собрать APK
flutter build apk --release
```

## Troubleshooting

### Ошибка "Java version"
- Workflow использует Java 17
- Проверьте `android/build.gradle` на совместимость

### Ошибка Firebase Distribution
- Убедитесь что секреты добавлены правильно
- Проверьте что группа "testers" существует

### iOS сборка не работает
- iOS сборка требует macOS runner (дороже)
- Для бесплатного аккаунта лимит 20 часов/месяц

## Стоимость GitHub Actions

- **Linux runners**: 2000 минут/месяц бесплатно
- **macOS runners**: 50 минут = 10 минут Linux кредитов
- Приватные репозитории: учитываются в лимит
- Публичные репозитории: бесплатно без лимита

## Дополнительные workflow ideas

### Автоматическое создание релиза на GitHub:

```yaml
- name: Create GitHub Release
  uses: softprops/action-gh-release@v1
  with:
    files: build/app/outputs/flutter-apk/app-release.apk
```

### Отправка уведомлений в Telegram:

```yaml
- name: Send Telegram notification
  uses: appleboy/telegram-action@master
  with:
    to: ${{ secrets.TELEGRAM_CHAT_ID }}
    token: ${{ secrets.TELEGRAM_BOT_TOKEN }}
    message: "✅ Новая сборка готова!"
```
