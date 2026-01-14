#!/bin/bash


# chmod +x deploy.sh - даем права на выполнение
# ./deploy.sh - запуск скрипта


# Проверяем, установлен ли Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter не установлен!"
    exit 1
fi

# Очищаем предыдущую сборку
echo "🧹 Очистка предыдущей сборки..."
rm -rf build/web

# Сборка проекта
echo "🚀 Сборка веб-приложения..."
flutter build web --release

# Создаем временную папку для деплоя
TEMP_DIR="/tmp/gh-pages-deploy-$(date +%s)"
mkdir -p "$TEMP_DIR"

# Копируем собранный проект во временную папку
cp -r build/web/* "$TEMP_DIR"/

# Переход во временную папку
cd "$TEMP_DIR"

# Инициализация git репозитория
git init
git checkout -b gh-pages
git add -A
git commit -m "Deploy to GitHub Pages - $(date)"

# Пуш в ветку gh-pages с force (перезапись)
echo "📤 Загрузка на GitHub Pages..."
git remote add origin https://github.com/DenUP/shedule.git
git push -f origin gh-pages

# Создание файла .nojekyll
touch .nojekyll
git add .nojekyll
git commit -m "Add .nojekyll"
git push origin gh-pages

# Очищаем временную папку
cd ..
rm -rf "$TEMP_DIR"

# Очищаем .git папку если она осталась в build/web
rm -rf ../build/web/.git 2>/dev/null || true

echo "✅ Деплой успешно завершен!"
echo "🌐 GitHub Pages: https://denup.github.io/shedule/"