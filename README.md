# claude-skill-end-session

Навык для Claude Code (Windows): закрывает процесс `claude.exe` выбранной или текущей сессии, чтобы он не занимал оперативную память (~250 МБ на сессию). История сессии остаётся, при открытии процесс запускается заново.

## Установка

Скопируйте папку `end-session` в `%USERPROFILE%\.claude\skills\`.

## Использование

- «закрой сессию», «освободи память» — закрыть текущую сессию
- «закрой сессию X» — закрыть другую сессию по названию (сначала покажет, что будет закрыто)

Скрипт `close-session.ps1` без флага `-Apply` ничего не завершает. Папка с данными сессий ищется автоматически в `%LOCALAPPDATA%\Claude-Data`.

## Требования

Windows, PowerShell 5.1+, десктопное приложение Claude (вкладка Code).

## English

A Claude Code skill for Windows that kills the `claude.exe` process of a chosen (or the current) session to free RAM (~250 MB each). Session history is kept; the process restarts when you reopen the session. Copy `end-session` to `%USERPROFILE%\.claude\skills\`. The script is dry-run unless `-Apply` is passed.

## Лицензия / License

MIT — пользуйтесь свободно. / MIT — free to use.
