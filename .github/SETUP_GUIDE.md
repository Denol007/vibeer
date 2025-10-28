# 🚀 Пошаговая настройка CI/CD для Vibe App

## Шаг 1: Подготовка репозитория GitHub (5 минут)

### 1.1 Создайте репозиторий (если еще не создали)

1. Откройте https://github.com/new
2. Repository name: `vibeer`
3. Description: `Vibe - Social Events Platform`
4. **Важно**: Выберите **Public** (для бесплатного GitHub Actions)
5. **НЕ** создавайте README, .gitignore или LICENSE (они уже есть)
6. Нажмите **Create repository**

### 1.2 Push кода в GitHub

```bash
cd /Users/denol/specifyTry/vibe_app
./scripts/setup_git.sh
```

Если скрипт просит авторизацию:
```bash
# Вариант 1: GitHub CLI (рекомендуется)
brew install gh
gh auth login

# Вариант 2: Personal Access Token
# Создайте токен: https://github.com/settings/tokens/new
# Scope: repo (полный доступ)
# Используйте токен как пароль при git push
```

---

## Шаг 2: Настройка Firebase (10 минут)

### 2.1 Получите Firebase App ID

1. Откройте [Firebase Console](https://console.firebase.google.com/)
2. Выберите проект **vibe-a0d7b**
3. Перейдите в **Project Settings** (⚙️ иконка)
4. Прокрутите до раздела **Your apps**
5. Найдите Android приложение
6. Скопируйте **App ID** (формат: `1:123456789:android:abcdef`)

**📋 Сохраните это значение** - оно понадобится для GitHub Secrets

### 2.2 Создайте Service Account

1. В Firebase Console → **Project Settings**
2. Вкладка **Service Accounts**
3. Нажмите **Generate new private key**
4. Подтвердите, скачается JSON файл
5. Откройте этот файл в текстовом редакторе

**📋 Сохраните весь JSON** - он понадобится для GitHub Secrets

---

## Шаг 3: Создание GitHub Secrets (5 минут)

### 3.1 Откройте настройки секретов

1. Откройте репозиторий: https://github.com/Denol007/vibeer
2. Перейдите в **Settings** → **Secrets and variables** → **Actions**
3. Нажмите **New repository secret**

### 3.2 Добавьте первый секрет: FIREBASE_ANDROID_APP_ID

1. Name: `FIREBASE_ANDROID_APP_ID`
2. Secret: вставьте **App ID** из шага 2.1
3. Нажмите **Add secret**

**Пример значения:**
```
1:123456789012:android:abc123def456ghi789
```

### 3.3 Добавьте второй секрет: FIREBASE_SERVICE_ACCOUNT

1. Нажмите **New repository secret** еще раз
2. Name: `FIREBASE_SERVICE_ACCOUNT`
3. Secret: вставьте **весь JSON файл** из шага 2.2
4. Нажмите **Add secret**

**Пример значения (ваш JSON будет похож):**
```json
{
  "type": "service_account",
  "project_id": "vibe-a0d7b",
  "private_key_id": "abc123...",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@vibe-a0d7b.iam.gserviceaccount.com",
  "client_id": "123456789012345678901",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  ...
}
```

**⚠️ Важно**: Вставьте ВЕСЬ JSON, включая все фигурные скобки {}

---

## Шаг 4: Настройка Firebase App Distribution (5 минут)

### 4.1 Включите App Distribution

1. В Firebase Console откройте **App Distribution**
2. Нажмите **Get Started** (если еще не включено)

### 4.2 Создайте группу тестеров

1. В App Distribution перейдите на вкладку **Testers & Groups**
2. Нажмите **Add group**
3. Group name: `testers`
4. Нажмите **Create group**

### 4.3 Добавьте тестеров

1. В группе `testers` нажмите **Add testers**
2. Введите email адреса тестеров (можно свой)
3. Нажмите **Add testers**

**Пример:**
```
your.email@gmail.com
tester1@example.com
```

---

## Шаг 5: Проверка работы CI/CD (2 минуты)

### 5.1 Триггер автоматической сборки

```bash
cd /Users/denol/specifyTry/vibe_app

# Создайте небольшое изменение
echo "# CI/CD configured" >> .github/CI_CD_STATUS.md

# Commit и push
git add .
git commit -m "chore: trigger CI/CD workflow"
git push origin main
```

### 5.2 Проверьте статус

1. Откройте https://github.com/Denol007/vibeer/actions
2. Вы увидите запущенный workflow
3. Кликните на него, чтобы увидеть процесс сборки в реальном времени

**Что должно произойти:**
- ✅ Test and Analyze (проверка кода, тесты)
- ✅ Build Android APK (сборка APK)
- ✅ Артефакт `release-apk` появится внизу

---

## Шаг 6: Создание первого релиза (3 минуты)

### 6.1 Создайте тег версии

```bash
cd /Users/denol/specifyTry/vibe_app

# Создайте тег версии 1.0.0
git tag v1.0.0

# Push тега
git push origin v1.0.0
```

### 6.2 Проверьте деплой в Firebase

1. Откройте https://github.com/Denol007/vibeer/actions
2. Найдите workflow **Deploy to Firebase App Distribution**
3. Подождите завершения (2-3 минуты)
4. Откройте Firebase Console → App Distribution → Releases
5. Вы увидите новый релиз!

### 6.3 Тестеры получат уведомление

- Тестеры получат email с ссылкой для скачивания APK
- Они смогут установить приложение прямо из email

---

## 📊 Итоговая проверка

### Что должно быть настроено:

- ✅ Репозиторий на GitHub: https://github.com/Denol007/vibeer
- ✅ 2 GitHub Secrets добавлены
- ✅ Firebase App Distribution включен
- ✅ Группа тестеров создана
- ✅ Workflow успешно выполняется
- ✅ APK артефакты доступны для скачивания

---

## 🎯 Основные команды

### Ежедневная разработка

```bash
# Обычный коммит (запустит тесты и сборку)
git add .
git commit -m "feat: добавил новую функцию"
git push origin main
```

### Создание релиза для тестеров

```bash
# Увеличьте версию и создайте тег
git tag v1.0.1
git push origin v1.0.1

# Автоматически:
# 1. Соберется APK
# 2. Загрузится в Firebase App Distribution
# 3. Тестеры получат уведомление
```

### Скачать собранный APK из GitHub

1. https://github.com/Denol007/vibeer/actions
2. Выберите последний успешный workflow
3. Прокрутите вниз до раздела **Artifacts**
4. Скачайте `release-apk`

---

## ⚠️ Возможные проблемы и решения

### Проблема 1: "Failed to authenticate with Firebase"

**Решение:**
1. Проверьте, что `FIREBASE_SERVICE_ACCOUNT` содержит ВЕСЬ JSON
2. JSON должен быть валидным (проверьте на jsonlint.com)
3. Пересоздайте Service Account Key и обновите секрет

### Проблема 2: "Group 'testers' not found"

**Решение:**
1. Убедитесь, что группа создана ТОЧНО с именем `testers` (lowercase)
2. Или измените имя группы в `.github/workflows/deploy-firebase.yml`:
```yaml
groups: ваше-имя-группы
```

### Проблема 3: Workflow не запускается

**Решение:**
1. Проверьте, что репозиторий **Public** (для бесплатных Actions)
2. Или включите Actions: Settings → Actions → Allow all actions

### Проблема 4: "Gradle task failed"

**Решение:**
1. Проверьте `android/local.properties` - не должен быть в git
2. Убедитесь, что `.gitignore` правильно настроен
3. Очистите кэш: `flutter clean && flutter pub get`

---

## 📱 Тестирование на устройстве

### Вариант 1: Через Firebase App Distribution (рекомендуется)

1. Тестер получает email от Firebase
2. Кликает на ссылку
3. Скачивает и устанавливает APK

### Вариант 2: Скачать из GitHub Actions

1. Скачайте `release-apk` из Artifacts
2. Распакуйте zip
3. Установите через adb:
```bash
adb install app-release.apk
```

### Вариант 3: Локальная сборка

```bash
cd /Users/denol/specifyTry/vibe_app
./scripts/build.sh
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 🎓 Дополнительная информация

### Стоимость GitHub Actions

- **Public репозиторий**: БЕСПЛАТНО без лимитов
- **Private репозиторий**: 
  - 2000 минут/месяц бесплатно (Linux runners)
  - iOS сборки (macOS) - 50 минут = 10 минут Linux кредитов

### Как добавить iOS сборку (опционально)

В `.github/workflows/flutter-ci.yml` раскомментируйте job `build-ios`.

**Важно**: macOS runners дорогие! Используйте только при необходимости.

### Добавление badge в README

Бейджи уже добавлены в README.md. Они покажут:
- ✅ Статус последней сборки
- 📊 Версию Flutter
- 📄 Лицензию

---

## 🆘 Нужна помощь?

1. **Проблемы с GitHub**: https://github.com/Denol007/vibeer/issues
2. **Firebase документация**: https://firebase.google.com/docs/app-distribution
3. **GitHub Actions документация**: https://docs.github.com/en/actions

---

## ✅ Чеклист готовности

Отметьте каждый пункт:

- [ ] Репозиторий создан на GitHub
- [ ] Код загружен (`git push`)
- [ ] `FIREBASE_ANDROID_APP_ID` секрет добавлен
- [ ] `FIREBASE_SERVICE_ACCOUNT` секрет добавлен
- [ ] Firebase App Distribution включен
- [ ] Группа `testers` создана
- [ ] Хотя бы один тестер добавлен
- [ ] Первый workflow запустился успешно
- [ ] APK артефакт доступен
- [ ] Тег создан и релиз в Firebase виден

**Когда все ✅ - CI/CD полностью настроен! 🎉**
