#!/bin/bash

# Vibe App - Git Setup and Push to GitHub
# Этот скрипт инициализирует git репозиторий и делает первый push

set -e  # Exit on error

REPO_URL="https://github.com/Denol007/vibeer.git"
BRANCH="main"

echo "🚀 Инициализация Git репозитория для Vibe App"
echo "Repository: $REPO_URL"
echo ""

# Переход в директорию проекта
cd "$(dirname "$0")/.."

# Проверка, инициализирован ли уже git
if [ -d ".git" ]; then
    echo "✅ Git репозиторий уже существует"
else
    echo "📦 Инициализация git репозитория..."
    git init
    echo "✅ Git инициализирован"
fi

# Проверка наличия remote
if git remote | grep -q "origin"; then
    echo "✅ Remote 'origin' уже настроен"
    CURRENT_REMOTE=$(git remote get-url origin)
    echo "   Текущий remote: $CURRENT_REMOTE"
    
    if [ "$CURRENT_REMOTE" != "$REPO_URL" ]; then
        echo "⚠️  Remote URL отличается, обновляем..."
        git remote set-url origin "$REPO_URL"
        echo "✅ Remote обновлен"
    fi
else
    echo "🔗 Добавление remote origin..."
    git remote add origin "$REPO_URL"
    echo "✅ Remote добавлен"
fi

# Проверка текущей ветки
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

if [ -z "$CURRENT_BRANCH" ]; then
    echo "📝 Создание начального коммита..."
    
    # Добавление всех файлов
    git add .
    
    # Создание первого коммита
    git commit -m "chore: initial commit - Vibe social events platform

- ✨ Flutter 3.24.3 app with Firebase integration
- 🗺️ Events map with geolocation
- 💬 Private and group chats
- 👥 Friends system with requests
- 🔍 User search by @username
- 🎨 Dark/Light theme support
- 🔔 Push notifications
- 🚀 GitHub Actions CI/CD setup"
    
    echo "✅ Начальный коммит создан"
    
    # Создание и переключение на main ветку
    git branch -M main
    echo "✅ Создана ветка main"
else
    echo "✅ Текущая ветка: $CURRENT_BRANCH"
    
    # Проверка наличия изменений
    if git diff-index --quiet HEAD --; then
        echo "ℹ️  Нет изменений для коммита"
    else
        echo "📝 Обнаружены изменения, создаем коммит..."
        git add .
        git commit -m "chore: update project files"
        echo "✅ Коммит создан"
    fi
fi

# Push в GitHub
echo ""
echo "📤 Push в GitHub..."
echo "⚠️  Если репозиторий защищен, может потребоваться авторизация"
echo ""

if git push -u origin main; then
    echo ""
    echo "✅ Успешно! Проект загружен в GitHub"
    echo ""
    echo "🔗 Откройте репозиторий:"
    echo "   https://github.com/Denol007/vibeer"
    echo ""
    echo "📋 Следующие шаги:"
    echo "   1. Настройте GitHub Secrets для CI/CD (см. .github/CI_CD_GUIDE.md)"
    echo "   2. Создайте Firebase проект и настройте индексы"
    echo "   3. Добавьте тестеров в Firebase App Distribution"
    echo ""
else
    echo ""
    echo "❌ Ошибка при push в GitHub"
    echo ""
    echo "🔧 Возможные решения:"
    echo "   1. Проверьте, что репозиторий существует: https://github.com/Denol007/vibeer"
    echo "   2. Убедитесь, что у вас есть права доступа"
    echo "   3. Попробуйте аутентифицироваться:"
    echo "      gh auth login  # если используете GitHub CLI"
    echo "   4. Или выполните push вручную:"
    echo "      git push -u origin main"
    echo ""
    exit 1
fi
