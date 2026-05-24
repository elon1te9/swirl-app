# Swirl

Swirl - учебный fullstack-проект для изучения английских слов русскоязычными начинающими пользователями. Проект объединяет backend API на ASP.NET Core и мобильный Flutter-клиент для Android. Основной сценарий строится вокруг тематических разделов, уровней, изучения слов, упражнений, ежедневного теста, прогресса и серии занятий.

## Возможности

Backend API:

- регистрация, вход и получение текущего пользователя через JWT;
- профиль пользователя, выбор аватара и сводка прогресса;
- тематические разделы, уровни и статусы доступности уровней;
- выдача слов уровня и отметка слов как изученных;
- формирование тренировочной сессии уровня с упражнениями;
- завершение уровня с сохранением попытки, ответов, прогресса и открытием следующего уровня;
- ежедневный тест по изученным словам и обновление серии занятий;
- seed-данные для разделов, уровней, слов, упражнений и аватаров;
- единый JSON-формат ошибок и Swagger/OpenAPI в режиме разработки.

Flutter-клиент:

- стартовые экраны, регистрация и вход;
- API-клиент на Dio с передачей JWT в `Authorization` header;
- хранение токена через `flutter_secure_storage`;
- маршрутизация через GoRouter;
- экраны home, profile, sections, level map, learn word, tasks и daily test;
- часть экранов подготовлена как UI-основа для дальнейшей интеграции с backend API.

## Стек технологий

Backend:

- C#;
- .NET 8;
- ASP.NET Core Web API;
- Entity Framework Core;
- PostgreSQL;
- Npgsql EF Core provider;
- JWT Bearer Authentication;
- Swagger / OpenAPI через Swashbuckle.

Frontend:

- Flutter;
- Dart;
- Dio;
- GoRouter;
- Riverpod;
- flutter_secure_storage;
- audioplayers;
- flutter_lints;
- Android.

## Скриншоты

### Первый экран

![Первый экран](frontend/design/screenshots/first__1-15.png)

### Авторизация

![Авторизация](frontend/design/screenshots/log-in__6-49.png)

### Главный экран

![Главный экран](frontend/design/screenshots/home-page__24-64.png)

### Разделы

![Разделы](frontend/design/screenshots/sections__6-93.png)

### Задание с вводом слова

![Задание с вводом слова](frontend/design/screenshots/task-with-a-word-input__20-37.png)

## Архитектура проекта

Backend реализован как REST API с разделением ответственности по слоям:

- `Controllers` принимают HTTP-запросы и возвращают DTO;
- `Services` содержат бизнес-логику обучения, прогресса, профиля, авторизации и ежедневного теста;
- `Interfaces` описывают контракты сервисов;
- `Models` содержат EF Core-сущности;
- `Requests` и `Responses` содержат модели входных и выходных данных API;
- `Data` содержит `AppDbContext`, настройки связей и seed-логику;
- `Migrations` содержит миграции базы данных.

При текущей конфигурации API может применять миграции и запускать seed-логику при старте. Пользовательские endpoints защищены JWT, кроме регистрации, входа, списка аватаров и статических media-файлов.

Flutter-приложение разделено на несколько основных областей:

- `app` — корневой виджет, тема и маршрутизация;
- `core` — сетевой клиент, хранение токена, обработка API-ошибок и общие утилиты;
- `data` — API-классы и пути endpoints;
- `domain` — модели приложения;
- `presentation` — экраны, виджеты и состояние UI.

Дизайн-материалы Flutter-клиента хранятся отдельно в `frontend/design`: там находятся экспортированные скриншоты экранов, Figma node JSON и markdown-спецификации.

## Структура репозитория

```text
Swirl/
  backend/
    Swirl.Api/
      Controllers/
      Data/
      Interfaces/
      Migrations/
      Models/
      Requests/
      Responses/
      Services/
      Properties/
      wwwroot/media/
      Program.cs
      appsettings.json
      appsettings.Development.example.json
      Swirl.Api.csproj
  frontend/
    swirl_app/
      android/
      images/
      lib/
      test/
      pubspec.yaml
    design/
      screenshots/
      specs/
      figma/
  docs/
  Swirl.sln
  README.md
```

## Запуск проекта локально

### Требования

- .NET 8 SDK;
- PostgreSQL;
- Flutter SDK, совместимый с Dart `^3.11.1`;
- Android Studio, Android SDK и эмулятор или физическое Android-устройство;
- `dotnet-ef` для явного применения EF Core migrations.

### Клонирование

```bash
git clone https://github.com/elon1te9/swirl-app.git
cd Swirl
```

### Backend

Создайте базу данных PostgreSQL, например `swirl_db`.

Подготовьте локальную конфигурацию. Можно создать или обновить файл `backend/Swirl.Api/appsettings.Development.json` на основе `backend/Swirl.Api/appsettings.Development.example.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=swirl_db;Username=postgres;Password=<your_password>"
  },
  "Cors": {
    "AllowedOrigins": [
      "http://localhost:3000",
      "http://localhost:5173",
      "http://localhost:8080",
      "http://10.0.2.2:8080"
    ]
  },
  "Media": {
    "RootPath": "wwwroot/media",
    "RequestPath": "/media"
  },
  "Jwt": {
    "Issuer": "Swirl.Api",
    "Audience": "Swirl.Android",
    "AccessTokenMinutes": 60,
    "Secret": "<your_long_random_jwt_key_at_least_32_chars>"
  }
}
```

Восстановите зависимости и соберите решение:

```bash
dotnet restore Swirl.sln
dotnet build Swirl.sln
```

Примените миграции явно, если нужно подготовить базу до запуска API:

```bash
dotnet ef database update --project backend/Swirl.Api/Swirl.Api.csproj --startup-project backend/Swirl.Api/Swirl.Api.csproj
```

Запустите backend:

```bash
dotnet run --project backend/Swirl.Api --launch-profile http
```

В режиме разработки Swagger UI доступен по адресу:

```text
http://localhost:5122/swagger
```

### Flutter-клиент

Перейдите в папку мобильного приложения и установите зависимости:

```bash
cd frontend/swirl_app
flutter pub get
```

Для Android-эмулятора локальный backend обычно доступен через `10.0.2.2`. Запуск с явным адресом API:

```bash
flutter run --dart-define=SWIRL_BACKEND_ORIGIN=http://10.0.2.2:5122
```

При запуске на физическом устройстве укажите адрес backend в локальной сети:

```bash
flutter run --dart-define=SWIRL_BACKEND_ORIGIN=http://<your_api_url>
```

Для проверки Flutter-клиента можно выполнить:

```bash
flutter test
```

## Конфигурация

Backend использует следующие локальные значения:

- `ConnectionStrings:DefaultConnection` - строка подключения к PostgreSQL;
- `Jwt:Secret` - секретный ключ для подписи JWT;
- `Jwt:Issuer` и `Jwt:Audience` - параметры проверки JWT;
- `Cors:AllowedOrigins` - разрешенные origins для локальной разработки;
- `Media:RootPath` и `Media:RequestPath` - путь к media-файлам и URL-префикс.

Секреты можно задавать через `appsettings.Development.json`, User Secrets или переменные окружения:

```env
ConnectionStrings__DefaultConnection=Host=localhost;Port=5432;Database=swirl_db;Username=postgres;Password=<your_password>
Jwt__Secret=<your_long_random_jwt_key_at_least_32_chars>
```

Flutter-клиент читает адрес backend из compile-time переменной:

```text
SWIRL_BACKEND_ORIGIN=http://<your_api_url>
```

Не публикуйте реальные пароли, JWT keys и внешние токены в репозитории.

## API

Базовый путь API:

```text
/api
```

Основные группы endpoints:

- `POST /api/auth/register` и `POST /api/auth/login` - регистрация и вход;
- `GET /api/auth/me` - текущий пользователь;
- `GET /api/avatars` - доступные аватары;
- `GET /api/profile` и `PUT /api/profile/avatar` - профиль и выбор аватара;
- `GET /api/sections` и `GET /api/sections/{sectionId}` - разделы и прогресс;
- `GET /api/sections/{sectionId}/levels` - уровни раздела;
- `GET /api/levels/{levelId}` - информация об уровне;
- `GET /api/levels/{levelId}/words` - слова уровня;
- `POST /api/levels/{levelId}/words/mark-learned` - отметка изученных слов;
- `GET /api/levels/{levelId}/session` - тренировочная сессия уровня;
- `POST /api/levels/{levelId}/complete` - завершение уровня;
- `GET /api/daily-test` и `POST /api/daily-test/complete` - ежедневный тест;
- `/media/...` - статические изображения и аудио из backend.

Подробный контракт API описан в `docs/03_API_CONTRACT.md`.

## Полученные навыки

- проектирование REST API на ASP.NET Core с DTO-моделями;
- моделирование предметной области через EF Core и PostgreSQL;
- настройка миграций, seed-данных и связей между сущностями;
- реализация JWT-аутентификации и защиты пользовательских endpoints;
- разделение backend-кода на controllers, services, interfaces и models;
- организация Flutter-приложения с маршрутизацией, состоянием и сетевым слоем;
- интеграция мобильного клиента с backend API и безопасным хранением токена.

## Возможные улучшения

- расширить покрытие автотестами для backend-сервисов и ключевых пользовательских сценариев Flutter;
- добавить Docker Compose для локального запуска API и PostgreSQL;
- добавить GitHub Actions workflow для сборки и проверок;
- завершить подключение всех экранов Flutter-клиента к backend API;
- вынести конфигурацию окружений Flutter в более гибкую схему;
- улучшить состояния загрузки, ошибок и пустых списков в клиенте;
- расширить набор media-файлов для слов и упражнений.

## Документация

В репозитории есть проектная документация:

- `docs/00_PROJECT_OVERVIEW.md` - обзор продукта и MVP-сценария;
- `docs/01_BACKEND_ARCHITECTURE.md` - архитектура backend;
- `docs/02_DATABASE_SCHEMA.md` - схема базы данных;
- `docs/03_API_CONTRACT.md` - контракт API;
- `docs/04_AUTH_AND_SECURITY.md` - авторизация и безопасность;
- `docs/06_LEARNING_LOGIC.md` - логика обучения и прогресса;
- `docs/07_DAILY_TEST_AND_STREAK.md` - ежедневный тест и серии занятий;
- `docs/08_SEED_DATA.md` - seed-данные;
- `docs/12_FLUTTER_TASKS.md` и `docs/15_FLUTTER_IMPLEMENTATION_PLAN.md` - задачи и план Flutter-части;
- `frontend/design/screenshots/` - экспортированные скриншоты экранов;
- `frontend/design/specs/` - markdown-спецификации дизайн-экранов.
