#Requires -Version 5
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-Has { param([Parameter(Mandatory)][string]$Name) [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
if (-not (Test-Has -Name "ssh-keygen")) {
  throw "ssh-keygen not found. Please enable Windows OpenSSH Client (optional feature)."
}

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
  $parts += @("-N",'""',"-C","`"$Comment`"","-f","`"$OutFile`"")
  $cmd = ($parts -join ' ')
  $p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c",$cmd -Wait -PassThru -NoNewWindow
  if ($p.ExitCode -ne 0) { throw "ssh-keygen failed (exit $($p.ExitCode))" }
}

# 默认中文
$LangId = "zh-CN"
Write-Host @"
Choose language / 选择语言 / 選擇語言:
  1) English
  2) 简体中文
"@
$choice = Read-Host ">"
if ($choice -eq "1") { $LangId="en" }

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
 }
 default {
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
 }
}

function Pause-Enter { Read-Host $T_ENTER | Out-Null }

function Generate-Key {
  Write-Host $T_ALGO
  $sel = Read-Host ">"
  $tmp = [System.IO.Path]::GetTempFileName()
  $key = "$tmp.key"
  switch ($sel) {
    "1" { Invoke-SSHKeygen -Type rsa -Bits 2048  -Comment ("rsa-2048-"+(Get-Timestamp)) -OutFile $key }
    "2" { Invoke-SSHKeygen -Type rsa -Bits 3072  -Comment ("rsa-3072-"+(Get-Timestamp)) -OutFile $key }
    "3" { Invoke-SSHKeygen -Type rsa -Bits 4096  -Comment ("rsa-4096-"+(Get-Timestamp)) -OutFile $key }
    "4" { Invoke-SSHKeygen -Type ed25519 -KdfRounds 100 -Comment ("ed25519-"+(Get-Timestamp)) -OutFile $key }
    default { Write-Host $T_INVALID; Pause-Enter; return }
  }
  Write-Host $T_PRIV
  Get-Content -Raw "$key"
  "`n$T_PUB"
  Get-Content -Raw "$key.pub"
  Remove-Item "$key","$key.pub" -Force
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
    [IO.File]::WriteAllText($tmp,$sb.ToString())
  } elseif ($sel -eq "2") {
    $p = Read-Host $T_PATH
    if (-not (Test-Path $p)) { Write-Host "File not found."; Pause-Enter; return }
    Copy-Item $p $tmp -Force
  } else { Write-Host $T_INVALID; Pause-Enter; return }

  $pub = & ssh-keygen -y -f $tmp 2>$null
  Write-Host $T_PUB
  Write-Host $pub
  Remove-Item $tmp -Force
  Write-Host $T_DONE
  Pause-Enter
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
