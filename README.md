# GOG Personal Library Downloader

Over the years I accumulated over a hundred games on GOG, and one day the question arose — how to dump them all at once?
After inspecting the API calls on the site, I created this script to automate the process.

![Demonstration of running the script](https://github.com/dok2d/assets/blob/master/gog-games-downloader-preview.jpg)

## Requirements: jq, curl, wget

Before running, you need to capture and save your cookie from www.gog.com into a file. It looks roughly like this:

```
Cookie: csrf=true; gog_lc=RU_RUB_ru-RU; CookieConsent={stamp:%274W2xTRAtatatatatatatata+TRAtata+Nnoasdg==%27%2Cnecessary:true%2Cpreferences:false%2Cstatistics:false%2Cmarketing:false%2Cmethod:%27explicit%27%2Cver:1%2Cutc:749574957495%2Cregion:%27ru%27}; gog_us=OOOOOMoyaOboronaaaa; cart_token=aff749574957495f; gog-al=10O8XXXXXXXXXXXXXX-H3XXXXXXXXXXX-KoXXXXXXXXXXXX_XXXXXXXXXXXXXX-; front_ab=old
```

To obtain it, use the browser developer tools on gog.com.
Open the Network tab, filter by domain:api.gog.com and check XHR. Reload the page.
Right-click any request that appears → "Copy as cURL", then find the Cookie field in the copied command.

## Usage

`bash gog-games-downloader.sh -c cookie_file`

### Arguments

- `-c` `--cookie-file` Path to the cookie file. Required.
- `-o` `--out-path` Download destination path. Defaults to `~/gog-dump`.
- `-p` `--platforms` Target OS platforms. Defaults to `lin win`. Allowed values: `lin win mac`
- `-l` `--langs-priority` Language priority. Defaults to `rus eng`. Allowed values: `deu eng spa por tur fra ita pol ron fin swe ces rus zho jpn kor`
- `--only-giveawayclaim` Only check for the free giveaway and exit.
- `--no-dlc` Skip DLC downloads.
- `--no-md5` Skip MD5 integrity checks on downloaded files.

### Examples

- `bash gog-games-downloader.sh -c cook_file -p mac win -l fra eng`
- `bash gog-games-downloader.sh -c cook_file --only-giveawayclaim`

### Features

- Supports 16 languages
- Downloads only the first matching language according to the specified priority
- Skips files that have already been downloaded
- Places multi-part game installers into a separate subdirectory
- Downloads CD keys if provided for a game
- Sends a request to https://www.gog.com/giveaway/claim before fetching the game list
- MD5 integrity verification
- Skips download if there is not enough disk space
- Downloads DLC add-ons

### TODO
- Optional download of bonus materials
- Check previously downloaded versions when GOG updates a game

---

[Русская версия / Russian version](README.ru.md)
