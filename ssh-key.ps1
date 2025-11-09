#Requires -Version 5
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-Has {
  param([Parameter(Mandatory)][string]$Name)
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

if (-not (Test-Has -Name "ssh-keygen")) {
  throw "ssh-keygen not found. Please enable Windows OpenSSH Client (optional feature)."
}

function Get-Timestamp { Get-Date -Format "yyyyMMdd-HHmmss" }

function Get-DownloadsPath {
  # Prefer original user when elevated? Use the current user's profile.
  $home = $env:USERPROFILE
  $dl = Join-Path $home "Downloads"
  if (-not (Test-Path $dl)) { New-Item -ItemType Directory -Path $dl | Out-Null }
  $dir = Join-Path $dl (Get-Timestamp)
  New-Item -ItemType Directory -Path $dir | Out-Null
  return $dir
}

function Open-ExportFolder {
  param([Parameter(Mandatory)][string]$Path)
  try {
    if (Test-Path $Path) {
      Start-Process -FilePath "explorer.exe" -ArgumentList "`"$Path`""
    }
  } catch { }
}

# --- i18n -------------------------------------------------------------------
$LangId = "en"
Write-Host @"
Choose language / 选择语言 / 選擇語言 / Choisir la langue / Выбрать язык / انتخاب زبان / 言語を選択:
  1) English
  2) 简体中文
  3) 繁體中文
  4) Français
  5) Русский
  6) فارسی (ایرانی)
  7) 日本語
"@
$choice = Read-Host ">"
switch ($choice) {
  "2" { $LangId = "zh-CN" }
  "3" { $LangId = "zh-TW" }
  "4" { $LangId = "fr" }
  "5" { $LangId = "ru" }
  "6" { $LangId = "fa" }
  "7" { $LangId = "ja" }
  default { $LangId = "en" }
}

# texts
switch ($LangId) {
 "en" {
  $T_MENU = "1) Generate key`n2) Derive public key from private key`n3) Exit"
  $T_CHOICE = "Choose an option: "
  $T_ALGO = "Select algorithm:`n  1) RSA 2048`n  2) RSA 3072`n  3) RSA 4096`n  4) Ed25519"
  $T_INPUT = "Input private key by:`n  1) Paste text`n  2) File path (drag & drop allowed)"
  $T_PASTE = "Paste PRIVATE KEY (finish with an empty line), then press Enter twice:"
  $T_PATH = "Enter file path: "
  $T_PRIV = "--- PRIVATE KEY ---"
  $T_PUB  = "--- PUBLIC KEY ---"
  $T_EXPORT = "Export both keys to files? [y/N]: "
  $T_EXPORTED = "Exported to:"
  $T_ENTER = "Press Enter to continue..."
  $T_DONE = "Done."
  $T_INVALID = "Invalid choice."
 }
 "zh-CN" {
  $T_MENU = "1) 生成密钥`n2) 由私钥查询公钥`n3) 退出"
  $T_CHOICE = "请选择："
  $T_ALGO = "选择算法：`n  1) RSA 2048`n  2) RSA 3072`n  3) RSA 4096`n  4) Ed25519"
  $T_INPUT = "选择私钥输入方式：`n  1) 粘贴文本`n  2) 文件路径（可拖拽到终端）"
  $T_PASTE = "请粘贴【私钥】，以空行结束，然后连续按两次回车："
  $T_PATH = "请输入文件路径："
  $T_PRIV = "--- 私钥 ---"
  $T_PUB  = "--- 公钥 ---"
  $T_EXPORT = "是否导出到文件？[y/N]："
  $T_EXPORTED = "已导出到："
  $T_ENTER = "回车继续……"
  $T_DONE = "完成。"
  $T_INVALID = "无效选择。"
 }
 "zh-TW" {
  $T_MENU = "1) 產生金鑰`n2) 由私鑰查詢公鑰`n3) 離開"
  $T_CHOICE = "請選擇："
  $T_ALGO = "選擇演算法：`n  1) RSA 2048`n  2) RSA 3072`n  3) RSA 4096`n  4) Ed25519"
  $T_INPUT = "選擇私鑰輸入方式：`n  1) 貼上文本`n  2) 檔案路徑（可拖曳至終端）"
  $T_PASTE = "請貼上【私鑰】，以空行結束，然後連按兩次 Enter："
  $T_PATH = "請輸入檔案路徑："
  $T_PRIV = "--- 私鑰 ---"
  $T_PUB  = "--- 公鑰 ---"
  $T_EXPORT = "是否匯出為檔案？[y/N]："
  $T_EXPORTED = "已匯出至："
  $T_ENTER = "按 Enter 繼續……"
  $T_DONE = "完成。"
  $T_INVALID = "無效選擇。"
 }
 "fr" {
  $T_MENU = "1) Générer une clé`n2) Obtenir la clé publique depuis la clé privée`n3) Quitter"
  $T_CHOICE = "Votre choix : "
  $T_ALGO = "Choisir l’algorithme :`n  1) RSA 2048`n  2) RSA 3072`n  3) RSA 4096`n  4) Ed25519"
  $T_INPUT = "Saisir la clé privée par :`n  1) Coller le texte`n  2) Chemin de fichier (glisser-déposer)"
  $T_PASTE = "Collez la CLÉ PRIVÉE (terminez par une ligne vide), puis Entrée deux fois :"
  $T_PATH = "Saisir le chemin du fichier : "
  $T_PRIV = "--- CLÉ PRIVÉE ---"
  $T_PUB  = "--- CLÉ PUBLIQUE ---"
  $T_EXPORT = "Exporter les deux clés ? [y/N] : "
  $T_EXPORTED = "Exporté vers :"
  $T_ENTER = "Appuyez sur Entrée pour continuer…"
  $T_DONE = "Terminé."
  $T_INVALID = "Choix invalide."
 }
 "ru" {
  $T_MENU = "1) Сгенерировать ключ`n2) Получить публичный ключ из приватного`n3) Выход"
  $T_CHOICE = "Выберите действие: "
  $T_ALGO = "Выберите алгоритм:`n  1) RSA 2048`n  2) RSA 3072`n  3) RSA 4096`n  4) Ed25519"
  $T_INPUT = "Как ввести приватный ключ:`n  1) Вставить текст`n  2) Путь к файлу (перетаскивание)"
  $T_PASTE = "Вставьте ПРИВАТНЫЙ КЛЮЧ, завершите пустой строкой, затем дважды Enter:"
  $T_PATH = "Введите путь к файлу: "
  $T_PRIV = "--- ПРИВАТНЫЙ КЛЮЧ ---"
  $T_PUB  = "--- ПУБЛИЧНЫЙ КЛЮЧ ---"
  $T_EXPORT = "Экспортировать в файлы? [y/N]: "
  $T_EXPORTED = "Экспортировано в:"
  $T_ENTER = "Нажмите Enter для продолжения…"
  $T_DONE = "Готово."
  $T_INVALID = "Неверный выбор."
 }
 "fa" {
  $T_MENU = "1) تولید کلید`n2) استخراج کلید عمومی از کلید خصوصی`n3) خروج"
  $T_CHOICE = "گزینه را انتخاب کنید: "
  $T_ALGO = "الگوریتم:`n  1) RSA 2048`n  2) RSA 3072`n  3) RSA 4096`n  4) Ed25519"
  $T_INPUT = "ورود کلید خصوصی:`n  1) چسباندن متن`n  2) مسیر فایل (درگ‌اند‌دراپ)"
  $T_PASTE = "کلید خصوصی را بچسبانید (با خط خالی پایان دهید)، سپس دو بار Enter:"
  $T_PATH = "مسیر فایل را وارد کنید: "
  $T_PRIV = "--- کلید خصوصی ---"
  $T_PUB  = "--- کلید عمومی ---"
  $T_EXPORT = "به فایل‌ها خروجی بگیرم؟ [y/N]: "
  $T_EXPORTED = "ذخیره شد در:"
  $T_ENTER = "برای ادامه Enter را بزنید…"
  $T_DONE = "انجام شد."
  $T_INVALID = "گزینه نامعتبر."
 }
 "ja" {
  $T_MENU = "1) 鍵を生成`n2) 秘密鍵から公開鍵を取得`n3) 終了"
  $T_CHOICE = "番号を選択してください: "
  $T_ALGO = "アルゴリズム:`n  1) RSA 2048`n  2) RSA 3072`n  3) RSA 4096`n  4) Ed25519"
  $T_INPUT = "秘密鍵の入力方法:`n  1) テキスト貼り付け`n  2) ファイルパス（ドラッグ＆ドロップ可）"
  $T_PASTE = "【秘密鍵】を貼り付け、空行で終了、Enter を 2 回押してください:"
  $T_PATH = "ファイルパスを入力: "
  $T_PRIV = "--- 秘密鍵 ---"
  $T_PUB  = "--- 公開鍵 ---"
  $T_EXPORT = "ファイルへ出力しますか？ [y/N]: "
  $T_EXPORTED = "出力先:"
  $T_ENTER = "続行するには Enter を押してください…"
  $T_DONE = "完了しました。"
  $T_INVALID = "無効な選択です。"
 }
}

function Pause-Enter { Read-Host $T_ENTER | Out-Null }

function Generate-Key {
  Write-Host $T_ALGO
  $sel = Read-Host ">"
  $tmp = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid()) -Force
  $key = Join-Path $tmp "id_tmp"
  switch ($sel) {
    "1" { & ssh-keygen -t rsa -b 2048  -N "" -C ("rsa-2048-" + (Get-Timestamp)) -f $key | Out-Null }
    "2" { & ssh-keygen -t rsa -b 3072  -N "" -C ("rsa-3072-" + (Get-Timestamp)) -f $key | Out-Null }
    "3" { & ssh-keygen -t rsa -b 4096  -N "" -C ("rsa-4096-" + (Get-Timestamp)) -f $key | Out-Null }
    "4" { & ssh-keygen -t ed25519 -a 100 -N "" -C ("ed25519-" + (Get-Timestamp)) -f $key | Out-Null }
    default { Write-Host $T_INVALID; Pause-Enter; return }
  }

  Write-Host $T_PRIV
  Get-Content -Raw "$key"
  "`n$T_PUB"
  Get-Content -Raw "$key.pub"

  $ans = Read-Host $T_EXPORT
  if ($ans -match '^[Yy]') {
    $outdir = Get-DownloadsPath
    if ($sel -in "1","2","3") {
      $bits = @{ "1"=2048; "2"=3072; "3"=4096 }[$sel]
      Copy-Item "$key"     (Join-Path $outdir "id_rsa_$bits")
      Copy-Item "$key.pub" (Join-Path $outdir "id_rsa_$bits.pub")
      Write-Host "$T_EXPORTED $outdir"
    } else {
      Copy-Item "$key"     (Join-Path $outdir "id_ed25519")
      Copy-Item "$key.pub" (Join-Path $outdir "id_ed25519.pub")
      Write-Host "$T_EXPORTED $outdir"
    }
    Open-ExportFolder -Path $outdir
  }
  Remove-Item $tmp -Recurse -Force
  Write-Host $T_DONE
  Pause-Enter
}

function Derive-Public {
  Write-Host $T_INPUT
  $sel = Read-Host ">"
  $tmp = [System.IO.Path]::GetTempFileName()
  if ($sel -eq "1") {
    Write-Host $T_PASTE
    $sb = New-Object System.Text.StringBuilder
    while ($true) {
      $line = Read-Host
      if ([string]::IsNullOrWhiteSpace($line)) { break }
      [void]$sb.AppendLine($line)
    }
    [IO.File]::WriteAllText($tmp, $sb.ToString())
  } elseif ($sel -eq "2") {
    $p = Read-Host $T_PATH
    if (-not (Test-Path $p)) { throw "File not found." }
    Copy-Item $p $tmp -Force
  } else {
    Write-Host $T_INVALID; Pause-Enter; return
  }

  try {
    $pub = & ssh-keygen -y -f $tmp 2>$null
    Write-Host $T_PUB
    Write-Host $pub
    $ans = Read-Host $T_EXPORT
    if ($ans -match '^[Yy]') {
      $outdir = Get-DownloadsPath
      Copy-Item $tmp (Join-Path $outdir "derived_private")
      Set-Content -Path (Join-Path $outdir "derived_public.pub") -Value $pub -NoNewline
      Write-Host "$T_EXPORTED $outdir"
      Open-ExportFolder -Path $outdir
    }
    Write-Host $T_DONE
    Pause-Enter
  } finally {
    Remove-Item $tmp -Force
  }
}

while ($true) {
  Clear-Host
  Write-Host $T_MENU
  $c = Read-Host $T_CHOICE
  switch ($c) {
    "1" { Generate-Key }
    "2" { Derive-Public }
    "3" { break }
    default { Write-Host $T_INVALID; Pause-Enter }
  }
}
