# Выгрузка всех игр из личной библиотеки GOG

У меня за несколько лет использования GOG, накопилось больше ста игр.
И однажды встал вопрос, как бы их разом сдампить. Залез на страницу, увидел API-вызовы и понеслось)

![Demonstration of running the script](/../../../../dok2d/assets/blob/master/gog-games-downloader-preview.jpg)

## Требования: jq, curl, wget
Перед запуском необходимо заполнить в начале скрипта параметры:
- platforms — список платформ, для которых нужно скачать игры. Например, lin, win, mac.
- langs_priority — список языков, которые нужно скачать, в порядке приоритета. Например, deu, eng.
- outpath — путь, куда будут скачаны игры. Например, /var/www.

Далее, захватываем и сохраняем свою куку с www.gog.com в файл. Выглядит она, примерно, так

```
Cookie: csrf=true; gog_lc=RU_RUB_ru-RU; CookieConsent={stamp:%274W2xTRAtatatatatatatata+TRAtata+Nnoasdg==%27%2Cnecessary:true%2Cpreferences:false%2Cstatistics:false%2Cmarketing:false%2Cmethod:%27explicit%27%2Cver:1%2Cutc:749574957495%2Cregion:%27ru%27}; gog_us=OOOOOMoyaOboronaaaa; cart_token=aff749574957495f; gog-al=10O8XXXXXXXXXXXXXX-H3XXXXXXXXXXX-KoXXXXXXXXXXXX_XXXXXXXXXXXXXX-; front_ab=old
```

## Запуск
`bash gog-games-downloader.sh cookie_file`

### Особенности
- Поддерживает 16 языков(больше в своей библиотеке не нашёл)
- Скачает только первый найденный язык по указанным приоритетам
- Если файл игры уже был скачан, то его скипнет
- Если установщик игры составляет более одного файла, то кладёт в отдельную директорию
- Если выдаётся cd-key игры, то он скачается тоже

### TODO на будущее
- Перед запросом списка игр, curl-запрос на https://www.gog.com/giveaway/claim
- Добавить опциональную загрузку дополнительных материалов
- Добавить проверку ранее скачанной предыдущей версии, если в gog обновили игру
- Сверка md5 [[forum](https://www.gog.com/forum/general/verifying_integrity_of_downloaded_games)]
