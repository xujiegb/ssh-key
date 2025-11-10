#Requires -Version 5
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-Has { param([Parameter(Mandatory)][string]$Name) [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
if (-not (Test-Has -Name "ssh-keygen")) {
  throw "ssh-keygen not found. Please enable Windows OpenSSH Client (optional feature)."
}

# 确保可用 WinForms 对话框
Add-Type -AssemblyName System.Windows.Forms | Out-Null

function Get-Timestamp { Get-Date -Format "yyyyMMdd-HHmmss" }

function Invoke-SSHKeygen {
  param(
    [Parameter(Mandatory)][ValidateSet('rsa','ed25519')]$Type,
    [int]$Bits = 0,
    [int]$KdfRounds = 0,
    [Parameter(Mandatory)][string]$Comment,
    [Parameter(Mandatory)][string]$OutFile
  )
  $parts = @("ssh-keygen","-q","-t",$Type)
  if ($Type -eq 'rsa' -and $Bits -gt 0) { $parts += @("-b",$Bits) }
  if ($Type -eq 'ed25519' -and $KdfRounds -gt 0) { $parts += @("-a",$KdfRounds) }
  # 通过 cmd 传递 -N "" 为空口令，避免被误判
  $parts += @("-N",'""',"-C","`"$Comment`"","-f","`"$OutFile`"")
  $cmd = ($parts -join ' ')
  $p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c",$cmd -Wait -PassThru -NoNewWindow
  if ($p.ExitCode -ne 0) { throw "ssh-keygen failed (exit $($p.ExitCode))" }
}

function Save-WithDialog {
  param(
    [Parameter(Mandatory)][string]$DefaultFileName,
    [Parameter(Mandatory)][string]$Title,
    [Parameter(Mandatory)][string]$Filter
  )
  $dlg = New-Object System.Windows.Forms.SaveFileDialog
  $dlg.Title   = $Title
  $dlg.Filter  = $Filter    # 例: "SSH Key (*.key)|*.key|All Files (*.*)|*.*"
  $dlg.FileName= $DefaultFileName
  if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    return $dlg.FileName
  }
  return $null
}

# 语言选择
$LangId = "zh-CN"
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
  "1" { $LangId = "en" }
  "2" { $LangId = "zh-CN" }
  "3" { $LangId = "zh-TW" }
  "4" { $LangId = "fr" }
  "5" { $LangId = "ru" }
  "6" { $LangId = "fa" }
  "7" { $LangId = "ja" }
  default { $LangId = "zh-CN" }
}

switch ($LangId) {
 "en" {
  $T_MENU="1) Generate key`n2) Derive public key from private key`n3) Exit"
  $T_CHOICE="Choose an option: "
  $T_ALGO="Select algorithm:`n  1) RSA 2048`n  2) RSA 3072`n  3) RSA 4096`n  4) Ed25519"
  $T_INPUT="Input private key by:`n  1) Paste text`n  2) File path"
  $T_PASTE="Paste PRIVATE KEY (finish with an empty line), then press Enter twice:"
  $T_PATH="Enter file path: "
  $T_PRIV="--- PRIVATE KEY ---"
  $T_PUB="--- PUBLIC KEY ---"
  $T_ENTER="Press Enter to continue..."
  $T_DONE="Done."
  $T_INVALID="Invalid choice."
  $T_SAVE_PRIV_TITLE="Save private key as..."
  $T_SAVE_PUB_TITLE="Save public key as..."
  $T_FILTER_PRIV="SSH private key (*.key)|*.key|All files (*.*)|*.*"
  $T_FILTER_PUB="OpenSSH public key (*.pub)|*.pub|All files (*.*)|*.*"
  $T_SAVED="Saved to:"
  $T_SKIP_SAVE="Skipped saving."
  $T_ASK_SAVE_PRIV="Do you want to save a copy of the PRIVATE KEY? (Y/N): "
  $T_ASK_SAVE_PUB="Do you want to save the PUBLIC KEY? (Y/N): "
 }
 "zh-CN" {
  $T_MENU="1) 生成密钥`n2) 由私钥查询公钥`n3) 退出"
  $T_CHOICE="请选择："
  $T_ALGO="选择算法：`n  1) RSA 2048`n  2) RSA 3072`n  3) RSA 4096`n  4) Ed25519"
  $T_INPUT="选择私钥输入方式：`n  1) 粘贴文本`n  2) 文件路径"
  $T_PASTE="请粘贴【私钥】，以空行结束，然后连续按两次回车："
  $T_PATH="请输入文件路径："
  $T_PRIV="--- 私钥 ---"
  $T_PUB="--- 公钥 ---"
  $T_ENTER="回车继续……"
  $T_DONE="完成。"
  $T_INVALID="无效选择。"
  $T_SAVE_PRIV_TITLE="将私钥另存为…"
  $T_SAVE_PUB_TITLE="将公钥另存为…"
  $T_FILTER_PRIV="SSH 私钥 (*.key)|*.key|所有文件 (*.*)|*.*"
  $T_FILTER_PUB="OpenSSH 公钥 (*.pub)|*.pub|所有文件 (*.*)|*.*"
  $T_SAVED="已保存到："
  $T_SKIP_SAVE="已跳过保存。"
  $T_ASK_SAVE_PRIV="是否保存【私钥】副本？(Y/N)："
  $T_ASK_SAVE_PUB="是否保存【公钥】？(Y/N)："
 }
 "zh-TW" {
  $T_MENU="1) 產生金鑰`n2) 由私鑰查詢公鑰`n3) 離開"
  $T_CHOICE="請選擇："
  $T_ALGO="選擇演算法：`n  1) RSA 2048`n  2) RSA 3072`n  3) RSA 4096`n  4) Ed25519"
  $T_INPUT="選擇私鑰輸入方式：`n  1) 貼上文本`n  2) 檔案路徑"
  $T_PASTE="請貼上【私鑰】，以空行結束，然後連按兩次 Enter："
  $T_PATH="請輸入檔案路徑："
  $T_PRIV="--- 私鑰 ---"
  $T_PUB="--- 公鑰 ---"
  $T_ENTER="按 Enter 繼續……"
  $T_DONE="完成。"
  $T_INVALID="無效選擇。"
  $T_SAVE_PRIV_TITLE="將私鑰另存為…"
  $T_SAVE_PUB_TITLE="將公鑰另存為…"
  $T_FILTER_PRIV="SSH 私鑰 (*.key)|*.key|所有檔案 (*.*)|*.*"
  $T_FILTER_PUB="OpenSSH 公鑰 (*.pub)|*.pub|所有檔案 (*.*)|*.*"
  $T_SAVED="已儲存至："
  $T_SKIP_SAVE="已跳過儲存。"
  $T_ASK_SAVE_PRIV="是否儲存【私鑰】副本？(Y/N)："
  $T_ASK_SAVE_PUB="是否儲存【公鑰】？(Y/N)："
 }
 "fr" {
  $T_MENU="1) Générer une clé`n2) Obtenir la clé publique depuis la clé privée`n3) Quitter"
  $T_CHOICE="Votre choix : "
  $T_ALGO="Choisir l’algorithme :`n  1) RSA 2048`n  2) RSA 3072`n  3) RSA 4096`n  4) Ed25519"
  $T_INPUT="Saisir la clé privée par :`n  1) Coller le texte`n  2) Chemin de fichier"
  $T_PASTE="Collez la CLÉ PRIVÉE (terminez par une ligne vide), puis appuyez deux fois sur Entrée :"
  $T_PATH="Saisir le chemin du fichier : "
  $T_PRIV="--- CLÉ PRIVÉE ---"
  $T_PUB="--- CLÉ PUBLIQUE ---"
  $T_ENTER="Appuyez sur Entrée pour continuer…"
  $T_DONE="Terminé."
  $T_INVALID="Choix invalide."
  $T_SAVE_PRIV_TITLE="Enregistrer la clé privée sous…"
  $T_SAVE_PUB_TITLE="Enregistrer la clé publique sous…"
  $T_FILTER_PRIV="Clé privée SSH (*.key)|*.key|Tous les fichiers (*.*)|*.*"
  $T_FILTER_PUB="Clé publique OpenSSH (*.pub)|*.pub|Tous les fichiers (*.*)|*.*"
  $T_SAVED="Enregistré vers :"
  $T_SKIP_SAVE="Enregistrement ignoré."
  $T_ASK_SAVE_PRIV="Enregistrer une copie de la CLÉ PRIVÉE ? (Y/N) : "
  $T_ASK_SAVE_PUB="Enregistrer la CLÉ PUBLIQUE ? (Y/N) : "
 }
 "ru" {
  $T_MENU="1) Сгенерировать ключ`n2) Получить публичный ключ из приватного`n3) Выход"
  $T_CHOICE="Выберите действие: "
  $T_ALGO="Выберите алгоритм:`n  1) RSA 2048`n  2) RSA 3072`n  3) RSA 4096`n  4) Ed25519"
  $T_INPUT="Как ввести приватный ключ:`n  1) Вставить текст`n  2) Путь к файлу"
  $T_PASTE="Вставьте ПРИВАТНЫЙ КЛЮЧ (завершите пустой строкой), затем дважды Enter:"
  $T_PATH="Введите путь к файлу: "
  $T_PRIV="--- ПРИВАТНЫЙ КЛЮЧ ---"
  $T_PUB="--- ПУБЛИЧНЫЙ КЛЮЧ ---"
  $T_ENTER="Нажмите Enter для продолжения…"
  $T_DONE="Готово."
  $T_INVALID="Неверный выбор."
  $T_SAVE_PRIV_TITLE="Сохранить приватный ключ как..."
  $T_SAVE_PUB_TITLE="Сохранить публичный ключ как..."
  $T_FILTER_PRIV="Приватный ключ SSH (*.key)|*.key|Все файлы (*.*)|*.*"
  $T_FILTER_PUB="Публичный ключ OpenSSH (*.pub)|*.pub|Все файлы (*.*)|*.*"
  $T_SAVED="Сохранено в:"
  $T_SKIP_SAVE="Сохранение пропущено."
  $T_ASK_SAVE_PRIV="Сохранить копию ПРИВАТНОГО КЛЮЧА? (Y/N): "
  $T_ASK_SAVE_PUB="Сохранить ПУБЛИЧНЫЙ КЛЮЧ? (Y/N): "
 }
 "fa" {
  $T_MENU="1) تولید کلید`n2) استخراج کلید عمومی از کلید خصوصی`n3) خروج"
  $T_CHOICE="گزینه را انتخاب کنید: "
  $T_ALGO="الگوریتم را انتخاب کنید:`n  1) RSA 2048`n  2) RSA 3072`n  3) RSA 4096`n  4) Ed25519"
  $T_INPUT="ورود کلید خصوصی:`n  1) چسباندن متن`n  2) مسیر فایل"
  $T_PASTE="کلید خصوصی را بچسبانید (با یک خط خالی پایان دهید)، سپس دو بار Enter:"
  $T_PATH="مسیر فایل را وارد کنید: "
  $T_PRIV="--- کلید خصوصی ---"
  $T_PUB="--- کلید عمومی ---"
  $T_ENTER="برای ادامه Enter را بزنید…"
  $T_DONE="انجام شد."
  $T_INVALID="گزینه نامعتبر."
  $T_SAVE_PRIV_TITLE="ذخیرهٔ کلید خصوصی به نام..."
  $T_SAVE_PUB_TITLE="ذخیرهٔ کلید عمومی به نام..."
  $T_FILTER_PRIV="کلید خصوصی SSH (*.key)|*.key|همهٔ فایل‌ها (*.*)|*.*"
  $T_FILTER_PUB="کلید عمومی OpenSSH (*.pub)|*.pub|همهٔ فایل‌ها (*.*)|*.*"
  $T_SAVED="ذخیره شد در:"
  $T_SKIP_SAVE="ذخیره انجام نشد."
  $T_ASK_SAVE_PRIV="آیا یک کپی از «کلید خصوصی» ذخیره شود؟ (Y/N): "
  $T_ASK_SAVE_PUB="آیا «کلید عمومی» ذخیره شود؟ (Y/N): "
 }
 "ja" {
  $T_MENU="1) 鍵を生成`n2) 秘密鍵から公開鍵を取得`n3) 終了"
  $T_CHOICE="番号を選択してください: "
  $T_ALGO="アルゴリズム:`n  1) RSA 2048`n  2) RSA 3072`n  3) RSA 4096`n  4) Ed25519"
  $T_INPUT="秘密鍵の入力方法:`n  1) テキスト貼り付け`n  2) ファイルパス"
  $T_PASTE="【秘密鍵】を貼り付け、空行で終了後、Enter を 2 回押してください:"
  $T_PATH="ファイルパスを入力: "
  $T_PRIV="--- 秘密鍵 ---"
  $T_PUB="--- 公開鍵 ---"
  $T_ENTER="続行するには Enter を押してください…"
  $T_DONE="完了しました。"
  $T_INVALID="無効な選択です。"
  $T_SAVE_PRIV_TITLE="秘密鍵の保存先を選択..."
  $T_SAVE_PUB_TITLE="公開鍵の保存先を選択..."
  $T_FILTER_PRIV="SSH 秘密鍵 (*.key)|*.key|すべてのファイル (*.*)|*.*"
  $T_FILTER_PUB="OpenSSH 公開鍵 (*.pub)|*.pub|すべてのファイル (*.*)|*.*"
  $T_SAVED="保存しました:"
  $T_SKIP_SAVE="保存をスキップしました。"
  $T_ASK_SAVE_PRIV="【秘密鍵】を保存しますか？(Y/N): "
  $T_ASK_SAVE_PUB="【公開鍵】を保存しますか？(Y/N): "
 }
}

function Pause-Enter { Read-Host $T_ENTER | Out-Null }

function Generate-Key {
  Write-Host $T_ALGO
  $sel = Read-Host ">"
  $tmp = [System.IO.Path]::GetTempFileName()
  $key = "$tmp.key"

  switch ($sel) {
    "1" { Invoke-SSHKeygen -Type rsa -Bits 2048  -Comment ("rsa-2048-"+(Get-Timestamp)) -OutFile $key;  $defBase="id_rsa_2048" }
    "2" { Invoke-SSHKeygen -Type rsa -Bits 3072  -Comment ("rsa-3072-"+(Get-Timestamp)) -OutFile $key;  $defBase="id_rsa_3072" }
    "3" { Invoke-SSHKeygen -Type rsa -Bits 4096  -Comment ("rsa-4096-"+(Get-Timestamp)) -OutFile $key;  $defBase="id_rsa_4096" }
    "4" { Invoke-SSHKeygen -Type ed25519 -KdfRounds 100 -Comment ("ed25519-"+(Get-Timestamp)) -OutFile $key; $defBase="id_ed25519" }
    default { Write-Host $T_INVALID; Pause-Enter; return }
  }

  Write-Host $T_PRIV
  Get-Content -Raw "$key"
  "`n$T_PUB"
  Get-Content -Raw "$key.pub"

  # 资源管理器保存对话框：一次选择私钥，公钥自动 .pub
  $savePriv = Save-WithDialog -DefaultFileName ($defBase + ".key") -Title $T_SAVE_PRIV_TITLE -Filter $T_FILTER_PRIV
  if ($savePriv) {
    try {
      Copy-Item "$key" $savePriv -Force
      $savePub = [System.IO.Path]::ChangeExtension($savePriv, ".pub")
      Copy-Item "$key.pub" $savePub -Force
      Write-Host "$T_SAVED $savePriv"
      Write-Host "$T_SAVED $savePub"
    } catch { Write-Host $_.Exception.Message }
  } else {
    Write-Host $T_SKIP_SAVE
  }

  Remove-Item "$key","$key.pub" -Force
  Write-Host $T_DONE
  Pause-Enter
}

function Derive-Public {
  Write-Host $T_INPUT
  $sel = Read-Host ">"
  $tmp = [System.IO.Path]::GetTempFileName()
  try {
    if ($sel -eq "1") {
      Write-Host $T_PASTE
      $sb = New-Object System.Text.StringBuilder
      while ($true) {
        $line = Read-Host
        if ([string]::IsNullOrWhiteSpace($line)) { break }
        [void]$sb.AppendLine($line)
      }
      [IO.File]::WriteAllText($tmp,$sb.ToString())
    } elseif ($sel -eq "2") {
      $p = Read-Host $T_PATH
      if (-not (Test-Path $p)) { Write-Host "File not found."; Pause-Enter; return }
      Copy-Item $p $tmp -Force
    } else { Write-Host $T_INVALID; Pause-Enter; return }

    $pub = & ssh-keygen -y -f $tmp 2>$null
    Write-Host $T_PUB
    Write-Host $pub

    # 询问是否保存私钥副本
    $ansPriv = Read-Host $T_ASK_SAVE_PRIV
    if ($ansPriv -match '^[Yy]') {
      $savePriv = Save-WithDialog -DefaultFileName "derived_private.key" -Title $T_SAVE_PRIV_TITLE -Filter $T_FILTER_PRIV
      if ($savePriv) {
        Copy-Item $tmp $savePriv -Force
        Write-Host "$T_SAVED $savePriv"
      } else {
        Write-Host $T_SKIP_SAVE
      }
    }

    # 询问是否保存公钥
    $ansPub = Read-Host $T_ASK_SAVE_PUB
    if ($ansPub -match '^[Yy]') {
      $savePub = Save-WithDialog -DefaultFileName "derived_public.pub" -Title $T_SAVE_PUB_TITLE -Filter $T_FILTER_PUB
      if ($savePub) {
        Set-Content -Path $savePub -Value $pub -NoNewline -Encoding ascii
        Write-Host "$T_SAVED $savePub"
      } else {
        Write-Host $T_SKIP_SAVE
      }
    }

    Write-Host $T_DONE
    Pause-Enter
  } finally {
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
  }
}

while ($true) {
  Clear-Host
  Write-Host $T_MENU
  $c = Read-Host $T_CHOICE
  switch ($c) {
    "1" { Generate-Key }
    "2" { Derive-Public }
    "3" { return }
    default { Write-Host $T_INVALID; Pause-Enter }
  }
}
