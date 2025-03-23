# Выгрузка всех игр из личной библиотеки GOG

С течением лет на платформе GOG у меня накопилось более ста игр, и однажды возник вопрос — как бы разом сдампить их все?
Просмотрев API-вызовы на сайте, я решил создать скрипт для автоматизации этого процесса.

![Demonstration of running the script](/../../../../dok2d/assets/blob/master/gog-games-downloader-preview.jpg)

## Требования: jq, curl, wget

Перед запуском необходимо захватить и сохранить свою куку с www.gog.com в файл. Выглядит она, примерно, так

```
Cookie: csrf=true; gog_lc=RU_RUB_ru-RU; CookieConsent={stamp:%274W2xTRAtatatatatatatata+TRAtata+Nnoasdg==%27%2Cnecessary:true%2Cpreferences:false%2Cstatistics:false%2Cmarketing:false%2Cmethod:%27explicit%27%2Cver:1%2Cutc:749574957495%2Cregion:%27ru%27}; gog_us=OOOOOMoyaOboronaaaa; cart_token=aff749574957495f; gog-al=10O8XXXXXXXXXXXXXX-H3XXXXXXXXXXX-KoXXXXXXXXXXXX_XXXXXXXXXXXXXX-; front_ab=old
```

Для её получения можно использовать инспекцию страницы gog.com.
Вкладка Network, фильтр domain:api.gog.com и отмечаем XHR. Обновляем страницу.
Из контекстного меню любого появившегося пакета -> "Copy as cURL" и там уже находим нужное поле.

## Запуск

`bash gog-games-downloader.sh -с cookie_file`

### Дополнительные аргументы

- `-c` `--cookie-file` Путь до файла с cookie. Обязательный аргумент.
- `-o` `--out-path` Путь куда скачивать. Если не указано, то `~/gog-dump`
- `-p` `--platforms` Под какие ОС скачивать. Доступны lin win mac. Если не указано, то `lin win`. Допустимые значения: lin win mac
- `-l` `--langs-priority` Приоритет выбора языка. Если не указано, то `rus eng`. Допустимые значения: deu eng spa por tur fra ita pol ron fin swe ces rus zho jpn kor
- `--only-giveawayclaim` Только проверка бесплатной раздачи и выход
- `--no-dlc` Не скачивать DLC, если они имеются
- `--no-md5` Не проверять скачанные файлы на целостность по md5

### Примеры запуска

- `bash gog-games-downloader.sh -c cook_file -p mac win -l fra eng`
- `bash gog-games-downloader.sh -c cook_file --only-giveawayclaim`

### Особенности

- Поддерживает 16 языков(больше в своей библиотеке не нашёл)
- Скачает только первый найденный язык по указанным приоритетам
- Если файл игры уже был скачан, то его скипнет
- Если установщик игры составляет более одного файла, то кладёт в отдельную директорию
- Если выдаётся cd-key игры, то он скачается тоже
- Перед запросом списка игр, curl-запрос на https://www.gog.com/giveaway/claim
- Сверка md5
- Пропуск скачивания файла, если на диске недостаточно места
- Добавить загрузку аддонов

### TODO на будущее
- Добавить опциональную загрузку дополнительных материалов
- Добавить проверку ранее скачанной предыдущей версии, если в gog обновили игру

