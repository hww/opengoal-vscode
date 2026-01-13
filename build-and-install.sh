#!/bin/bash

# Останавливаем скрипт при любой ошибке
set -e

echo "🚀 Начинаю процесс сборки и установки OpenGoal VSCode..."

# 1. Установка зависимостей (если папка node_modules отсутствует)
if [ ! -d "node_modules" ]; then
    echo "📦 Зависимости не найдены. Запускаю yarn install..."
    yarn install
fi

# 2. Очистка старых .vsix файлов
echo "🧹 Удаление старых сборок..."
rm -f *.vsix

# 3. Сборка пакета
echo "🏗️ Упаковка расширения через vsce..."
# Используем npx на случай, если vsce не установлен глобально
npx @vscode/vsce package

# 4. Поиск созданного файла (имя зависит от версии в package.json)
VSIX_FILE=$(ls *.vsix | head -n 1)

if [ -f "$VSIX_FILE" ]; then
    echo "✅ Файл собран: $VSIX_FILE"
    
    # 5. Установка в VS Code
    echo "📥 Установка в Visual Studio Code..."
    code --install-extension "$VSIX_FILE"
    
    echo "🎉 Готово! Перезапустите VS Code (или выполните Developer: Reload Window), чтобы изменения вступили в силу."
else
    echo "❌ Ошибка: .vsix файл не был найден."
    exit 1
fi
