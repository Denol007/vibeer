#!/bin/bash

# 🎯 Быстрая проверка готовности CI/CD
# Этот скрипт проверит, что все настроено правильно

set -e

echo "🔍 Проверка готовности CI/CD для Vibe App"
echo "=========================================="
echo ""

ERRORS=0
WARNINGS=0

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Переход в директорию проекта
cd "$(dirname "$0")/.."

# Проверка 1: Git инициализирован
echo -n "📦 Git репозиторий... "
if [ -d ".git" ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌${NC}"
    echo "   Запустите: ./scripts/setup_git.sh"
    ERRORS=$((ERRORS + 1))
fi

# Проверка 2: Remote origin настроен
echo -n "🔗 Git remote origin... "
if git remote | grep -q "origin"; then
    REMOTE_URL=$(git remote get-url origin)
    if [[ "$REMOTE_URL" == *"Denol007/vibeer"* ]]; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${YELLOW}⚠️${NC}"
        echo "   Текущий: $REMOTE_URL"
        echo "   Ожидается: https://github.com/Denol007/vibeer.git"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${RED}❌${NC}"
    echo "   Запустите: ./scripts/setup_git.sh"
    ERRORS=$((ERRORS + 1))
fi

# Проверка 3: GitHub workflows существуют
echo -n "⚙️  GitHub workflows... "
if [ -f ".github/workflows/flutter-ci.yml" ] && [ -f ".github/workflows/deploy-firebase.yml" ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌${NC}"
    echo "   Файлы workflows не найдены"
    ERRORS=$((ERRORS + 1))
fi

# Проверка 4: Flutter доступен
echo -n "🐦 Flutter SDK... "
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -1 | awk '{print $2}')
    echo -e "${GREEN}✅${NC} (версия: $FLUTTER_VERSION)"
else
    echo -e "${RED}❌${NC}"
    echo "   Установите Flutter: https://flutter.dev/docs/get-started/install"
    ERRORS=$((ERRORS + 1))
fi

# Проверка 5: Зависимости установлены
echo -n "📚 Flutter dependencies... "
if [ -f "pubspec.lock" ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${YELLOW}⚠️${NC}"
    echo "   Запустите: flutter pub get"
    WARNINGS=$((WARNINGS + 1))
fi

# Проверка 6: Firebase конфигурация
echo -n "🔥 Firebase config (Android)... "
if [ -f "android/app/google-services.json" ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌${NC}"
    echo "   Скачайте google-services.json из Firebase Console"
    ERRORS=$((ERRORS + 1))
fi

# Проверка 7: Firebase конфигурация iOS
echo -n "🔥 Firebase config (iOS)... "
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${YELLOW}⚠️${NC}"
    echo "   Скачайте GoogleService-Info.plist для iOS (опционально)"
    WARNINGS=$((WARNINGS + 1))
fi

# Проверка 8: Документация
echo -n "📖 Документация CI/CD... "
if [ -f ".github/SETUP_GUIDE.md" ] && [ -f ".github/CI_CD_GUIDE.md" ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${YELLOW}⚠️${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# Проверка 9: Скрипты исполняемые
echo -n "🔧 Исполняемые скрипты... "
if [ -x "scripts/setup_git.sh" ] && [ -x "scripts/build.sh" ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${YELLOW}⚠️${NC}"
    echo "   Запустите: chmod +x scripts/*.sh"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""
echo "=========================================="
echo ""

# Итоги
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}🎉 Все проверки пройдены!${NC}"
    echo ""
    echo "✅ Ваш проект готов к использованию CI/CD"
    echo ""
    echo "📋 Следующие шаги:"
    echo "   1. Прочитайте: .github/SETUP_GUIDE.md"
    echo "   2. Настройте GitHub Secrets (2 секрета)"
    echo "   3. Настройте Firebase App Distribution"
    echo "   4. Сделайте первый push: ./scripts/setup_git.sh"
    echo ""
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Обнаружено предупреждений: $WARNINGS${NC}"
    echo ""
    echo "Проект работоспособен, но есть рекомендации выше"
    echo ""
else
    echo -e "${RED}❌ Обнаружено ошибок: $ERRORS${NC}"
    echo -e "${YELLOW}⚠️  Предупреждений: $WARNINGS${NC}"
    echo ""
    echo "Исправьте ошибки перед продолжением"
    echo ""
    exit 1
fi

# Информация о GitHub Secrets
echo "🔐 Не забудьте настроить GitHub Secrets:"
echo ""
echo "   Репозиторий → Settings → Secrets → Actions"
echo ""
echo "   1. FIREBASE_ANDROID_APP_ID"
echo "      Где найти: Firebase Console → Project Settings → Your apps → App ID"
echo ""
echo "   2. FIREBASE_SERVICE_ACCOUNT"
echo "      Где найти: Firebase Console → Project Settings → Service Accounts"
echo "                 → Generate new private key → скопировать весь JSON"
echo ""
echo "Подробная инструкция: .github/SETUP_GUIDE.md"
echo ""
