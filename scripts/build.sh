#!/bin/bash

# Vibe App - Quick Build Script
# Быстрая сборка APK для тестирования

set -e

echo "🔨 Сборка Vibe App (Release APK)"
echo ""

cd "$(dirname "$0")/.."

# Проверка Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter не найден. Установите Flutter SDK"
    exit 1
fi

echo "📦 Получение зависимостей..."
flutter pub get

echo ""
echo "🧪 Запуск тестов..."
flutter test || {
    echo "⚠️  Тесты не прошли, но продолжаем сборку..."
}

echo ""
echo "🔍 Анализ кода..."
flutter analyze || {
    echo "⚠️  Найдены предупреждения анализа, но продолжаем..."
}

echo ""
echo "🏗️  Сборка Release APK..."
flutter build apk --release

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo ""
    echo "✅ Сборка завершена успешно!"
    echo ""
    echo "📱 APK файл:"
    echo "   Путь: $APK_PATH"
    echo "   Размер: $APK_SIZE"
    echo ""
    echo "📤 Для установки на устройство:"
    echo "   adb install $APK_PATH"
    echo ""
else
    echo ""
    echo "❌ Ошибка: APK файл не найден"
    exit 1
fi
