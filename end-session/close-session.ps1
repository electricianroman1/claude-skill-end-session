param(
    [string]$Title,      # часть названия сессии (закрыть её процесс)
    [switch]$Self,       # закрыть процесс текущей сессии (предок этого шелла)
    [switch]$List,       # только показать процессы сессий и соответствие
    [int]$Delay = 12,    # для -Self: через сколько секунд завершить процесс
    [switch]$Apply       # без флага — только показ, ничего не завершается
)
$ErrorActionPreference = 'Stop'
$procs = Get-CimInstance Win32_Process -Filter "Name='claude.exe'" | Where-Object { $_.CommandLine -match 'claude-code' }
$root = Join-Path $env:LOCALAPPDATA 'Claude-Data\claude_pzs8sxrjxfjjc\claude-code-sessions'
$sessions = Get-ChildItem $root -Recurse -Filter 'local_*.json' | ForEach-Object {
    $j = Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    [pscustomobject]@{ Id = $j.sessionId; Cli = $j.cliSessionId; Title = $j.title; Archived = $j.isArchived
        Created = [DateTimeOffset]::FromUnixTimeMilliseconds($j.createdAt).LocalDateTime }
}

function Find-Proc($s) {
    # 1) сессия возобновлена: в аргументах --resume=<cliSessionId>
    $m = $procs | Where-Object { $s.Cli -and $_.CommandLine -match [regex]::Escape("--resume=$($s.Cli)") }
    if ($m) { return $m }
    # 2) новая сессия: процесс создан в момент создания сессии (±5 с)
    $procs | Where-Object { [math]::Abs(($_.CreationDate - $s.Created).TotalSeconds) -le 5 }
}

if ($Self) {
    $id = $PID; $target = $null
    while ($id) {
        $p = Get-CimInstance Win32_Process -Filter "ProcessId=$id"
        if (-not $p) { break }
        if ($procs.ProcessId -contains $p.ProcessId) { $target = $p; break }
        $id = $p.ParentProcessId
    }
    $targets = @($target) | Where-Object { $_ }
} elseif ($Title) {
    $targets = $sessions | Where-Object { -not $_.Archived -and $_.Title -like "*$Title*" } | ForEach-Object { Find-Proc $_ }
} else {
    $List = $true
}

if ($List) {
    foreach ($s in $sessions | Where-Object { -not $_.Archived }) {
        $p = Find-Proc $s
        if ($p) { '{0,6} {1,4} МБ  {2}' -f $p.ProcessId, [math]::Round($p.WorkingSetSize/1MB), $s.Title }
    }
    return
}
if (-not $targets) { 'Процесс сессии не найден (возможно, уже закрыт).'; return }
foreach ($t in $targets) {
    if ($Apply -and $Self) {
        # убиваем уже после конца ответа, когда сессия простаивает, — иначе приложение покажет «Сессия прервана»
        Start-Process powershell -WindowStyle Hidden -ArgumentList "-NoProfile -Command `"Start-Sleep $Delay; Stop-Process -Id $($t.ProcessId) -Force`""
        "Процесс $($t.ProcessId) будет завершён через $Delay с — закончите ответ сразу после этого сообщения."
    }
    elseif ($Apply) { Stop-Process -Id $t.ProcessId; "Завершён процесс $($t.ProcessId)" }
    else { "Будет завершён процесс $($t.ProcessId) ($([math]::Round($t.WorkingSetSize/1MB)) МБ). Добавьте -Apply." }
}
