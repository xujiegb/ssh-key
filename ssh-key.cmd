@echo off
setlocal enabledelayedexpansion

:: 可选：如果你在新系统上想要更好的多语言显示，可解注下一行（可能影响控制台显示）
:: chcp 65001 >nul

:: ---- Check ssh-keygen ----------------------------------------------------
where ssh-keygen >nul 2>nul
if errorlevel 1 (
  echo [Error] ssh-keygen not found. Please enable Windows "OpenSSH Client" optional feature.
  echo 控制面板 ^> 可选功能 ^> 添加 "OpenSSH 客户端"
  pause
  exit /b 1
)

:: ---- Timestamp -----------------------------------------------------------
for /f "tokens=1-5 delims=/-: " %%a in ("%date% %time%") do (
  set YY=%%a&set MM=%%b&set DD=%%c&set hh=%%d&set nn=%%e
)
set TS=%YY%%MM%%DD%-%time:~0,2%%time:~3,2%%time:~6,2%
set TS=%TS: =0%

:: ---- i18n (en / zh-CN / zh-TW / fr / ru / fa / ja) ----------------------
set LANG=zh-CN
echo Hello:
echo   1^) English
echo   2^) 简体中文
echo   3^) 繁體中文
echo   4^) Français
echo   5^) Русский
echo   6^) فارسی (ایرانی)
echo   7^) 日本語
set /p CHS=^> 
if "%CHS%"=="1" set LANG=en
if "%CHS%"=="2" set LANG=zh-CN
if "%CHS%"=="3" set LANG=zh-TW
if "%CHS%"=="4" set LANG=fr
if "%CHS%"=="5" set LANG=ru
if "%CHS%"=="6" set LANG=fa
if "%CHS%"=="7" set LANG=ja

:: 文案
if /i "%LANG%"=="en" (
  set M1=1^) Generate key
  set M2=2^) Derive public key from private key
  set M3=3^) Exit
  set P_CHOOSE=Choose an option:
  set P_ALGO=Select algorithm:
  set A_LIST=  1^) RSA 2048& set A2=  2^) RSA 3072& set A3=  3^) RSA 4096& set A4=  4^) Ed25519
  set P_INPATH=Enter PRIVATE KEY file path:
  set H_PRIV=--- PRIVATE KEY ---
  set H_PUB=--- PUBLIC KEY ---
  set ASK_EXPORT=Export both keys to files? [y/N]:
  set EXPORTED=Exported to:
  set DONE=Done.
  set INVALID=Invalid choice.
  set ERR_NOFILE=File not found.
  set ERR_GEN=ssh-keygen failed.
  set ERR_PARSE=Failed to parse private key.
) else if /i "%LANG%"=="zh-TW" (
  set M1=1^) 產生金鑰
  set M2=2^) 由私鑰查詢公鑰
  set M3=3^) 離開
  set P_CHOOSE=請選擇：
  set P_ALGO=選擇演算法：
  set A_LIST=  1^) RSA 2048& set A2=  2^) RSA 3072& set A3=  3^) RSA 4096& set A4=  4^) Ed25519
  set P_INPATH=請輸入【私鑰】檔案路徑：
  set H_PRIV=--- 私鑰 ---
  set H_PUB=--- 公鑰 ---
  set ASK_EXPORT=是否匯出為檔案？[y/N]：
  set EXPORTED=已匯出至：
  set DONE=完成。
  set INVALID=無效選擇。
  set ERR_NOFILE=檔案不存在。
  set ERR_GEN=ssh-keygen 失敗。
  set ERR_PARSE=解析私鑰失敗。
) else if /i "%LANG%"=="fr" (
  set M1=1^) Générer une clé
  set M2=2^) Obtenir la clé publique depuis la clé privée
  set M3=3^) Quitter
  set P_CHOOSE=Votre choix :
  set P_ALGO=Choisir l’algorithme :
  set A_LIST=  1^) RSA 2048& set A2=  2^) RSA 3072& set A3=  3^) RSA 4096& set A4=  4^) Ed25519
  set P_INPATH=Saisir le chemin du fichier de CLÉ PRIVÉE :
  set H_PRIV=--- CLÉ PRIVÉE ---
  set H_PUB=--- CLÉ PUBLIQUE ---
  set ASK_EXPORT=Exporter les deux clés ? [y/N] :
  set EXPORTED=Exporté vers :
  set DONE=Terminé.
  set INVALID=Choix invalide.
  set ERR_NOFILE=Fichier introuvable.
  set ERR_GEN=Échec de ssh-keygen.
  set ERR_PARSE=Impossible d’analyser la clé privée.
) else if /i "%LANG%"=="ru" (
  set M1=1^) Сгенерировать ключ
  set M2=2^) Получить публичный ключ из приватного
  set M3=3^) Выход
  set P_CHOOSE=Выберите действие:
  set P_ALGO=Выберите алгоритм:
  set A_LIST=  1^) RSA 2048& set A2=  2^) RSA 3072& set A3=  3^) RSA 4096& set A4=  4^) Ed25519
  set P_INPATH=Укажите путь к файлу приватного ключа:
  set H_PRIV=--- ПРИВАТНЫЙ КЛЮЧ ---
  set H_PUB=--- ПУБЛИЧНЫЙ КЛЮЧ ---
  set ASK_EXPORT=Экспортировать в файлы? [y/N]:
  set EXPORTED=Экспортировано в:
  set DONE=Готово.
  set INVALID=Неверный выбор.
  set ERR_NOFILE=Файл не найден.
  set ERR_GEN=Сбой ssh-keygen.
  set ERR_PARSE=Не удалось разобрать приватный ключ.
) else if /i "%LANG%"=="fa" (
  set M1=1^) تولید کلید
  set M2=2^) استخراج کلید عمومی از کلید خصوصی
  set M3=3^) خروج
  set P_CHOOSE=گزینه را انتخاب کنید:
  set P_ALGO=الگوریتم را انتخاب کنید:
  set A_LIST=  1^) RSA 2048& set A2=  2^) RSA 3072& set A3=  3^) RSA 4096& set A4=  4^) Ed25519
  set P_INPATH=مسیر فایل کلید خصوصی را وارد کنید:
  set H_PRIV=--- کلید خصوصی ---
  set H_PUB=--- کلید عمومی ---
  set ASK_EXPORT=به فایل‌ها خروجی بگیرم؟ [y/N]:
  set EXPORTED=ذخیره شد در:
  set DONE=انجام شد.
  set INVALID=گزینه نامعتبر.
  set ERR_NOFILE=فایل یافت نشد.
  set ERR_GEN=ssh-keygen ناموفق بود.
  set ERR_PARSE=تجزیهٔ کلید خصوصی ناموفق.
) else if /i "%LANG%"=="ja" (
  set M1=1^) 鍵を生成
  set M2=2^) 秘密鍵から公開鍵を取得
  set M3=3^) 終了
  set P_CHOOSE=番号を選択してください:
  set P_ALGO=アルゴリズムを選択:
  set A_LIST=  1^) RSA 2048& set A2=  2^) RSA 3072& set A3=  3^) RSA 4096& set A4=  4^) Ed25519
  set P_INPATH=【秘密鍵】ファイルのパスを入力:
  set H_PRIV=--- 秘密鍵 ---
  set H_PUB=--- 公開鍵 ---
  set ASK_EXPORT=ファイルへ出力しますか？ [y/N]:
  set EXPORTED=出力先:
  set DONE=完了しました。
  set INVALID=無効な選択です。
  set ERR_NOFILE=ファイルが見つかりません。
  set ERR_GEN=ssh-keygen が失敗しました。
  set ERR_PARSE=秘密鍵の解析に失敗しました。
) else (
  set M1=1^) 生成密钥
  set M2=2^) 由私钥查询公钥
  set M3=3^) 退出
  set P_CHOOSE=请选择：
  set P_ALGO=选择算法：
  set A_LIST=  1^) RSA 2048& set A2=  2^) RSA 3072& set A3=  3^) RSA 4096& set A4=  4^) Ed25519
  set P_INPATH=请输入【私钥】文件路径：
  set H_PRIV=--- 私钥 ---
  set H_PUB=--- 公钥 ---
  set ASK_EXPORT=是否导出到文件？[y/N]：
  set EXPORTED=已导出到：
  set DONE=完成。
  set INVALID=无效选择。
  set ERR_NOFILE=文件不存在。
  set ERR_GEN=ssh-keygen 失败。
  set ERR_PARSE=解析私钥失败。
)

:: ---- Export dir chooser (Downloads -> TEMP -> .) -------------------------
call :GET_EXPORT_DIR
set EXPORT_DIR=%RET_DIR%

:MAIN
cls
echo %M1%
echo %M2%
echo %M3%
set /p op=%P_CHOOSE% 
if "%op%"=="1" goto GEN
if "%op%"=="2" goto DER
if "%op%"=="3" goto END
echo %INVALID%
pause
goto MAIN

:GEN
cls
for %%# in ("%TEMP%\sshkey-%RANDOM%-%TS%") do set TMPDIR=%%~f#
mkdir "%TMPDIR%" >nul 2>nul
set KEY=%TMPDIR%\id_tmp

echo %P_ALGO%
echo %A_LIST%
echo %A2%
echo %A3%
echo %A4%
set /p a=^> 
if "%a%"=="1" ( set TYPE=rsa& set BITS=2048 ) else ^
if "%a%"=="2" ( set TYPE=rsa& set BITS=3072 ) else ^
if "%a%"=="3" ( set TYPE=rsa& set BITS=4096 ) else ^
if "%a%"=="4" ( set TYPE=ed25519& set BITS= ) else (
  echo %INVALID%
  rmdir /s /q "%TMPDIR%" >nul 2>nul
  pause
  goto MAIN
)

:: Build ssh-keygen cmd; ensure -N "" empty passphrase
set CMD=ssh-keygen -q -t %TYPE%
if /i "%TYPE%"=="rsa" set CMD=%CMD% -b %BITS%
if /i "%TYPE%"=="ed25519" set CMD=%CMD% -a 100

set COMMENT=%TYPE%-%BITS%-%TS%
if /i "%TYPE%"=="ed25519" set COMMENT=ed25519-%TS%

set CMD=%CMD% -N "" -C "%COMMENT%" -f "%KEY%"

cmd /c %CMD%
if errorlevel 1 (
  echo [Error] %ERR_GEN%
  rmdir /s /q "%TMPDIR%" >nul 2>nul
  pause
  goto MAIN
)

echo %H_PRIV%
type "%KEY%"
echo.
echo %H_PUB%
type "%KEY%.pub"
echo.

set /p ex=%ASK_EXPORT%
if /i "%ex%"=="y" (
  call :ENSURE_DIR "%EXPORT_DIR%"
  if /i "%TYPE%"=="rsa" (
    copy /y "%KEY%" "%EXPORT_DIR%\id_rsa_%BITS%" >nul
    copy /y "%KEY%.pub" "%EXPORT_DIR%\id_rsa_%BITS%.pub" >nul
  ) else (
    copy /y "%KEY%" "%EXPORT_DIR%\id_ed25519" >nul
    copy /y "%KEY%.pub" "%EXPORT_DIR%\id_ed25519.pub" >nul
  )
  echo %EXPORTED% %EXPORT_DIR%
  start "" "%EXPORT_DIR%"
)

rmdir /s /q "%TMPDIR%" >nul 2>nul
echo %DONE%
pause
goto MAIN

:DER
cls
set /p P=%P_INPATH% 
if not exist "%P%" (
  echo %ERR_NOFILE%
  pause
  goto MAIN
)

for %%# in ("%TEMP%\sshkey-%RANDOM%-%TS%") do set TMPDIR=%%~f#
mkdir "%TMPDIR%" >nul 2>nul
set TMPPRIV=%TMPDIR%\in.key
copy /y "%P%" "%TMPPRIV%" >nul

set "PUB="
for /f "usebackq delims=" %%L in (`ssh-keygen -y -f "%TMPPRIV%" 2^>nul`) do (
  set "PUB=%%L"
)
if not defined PUB (
  echo [Error] %ERR_PARSE%
  rmdir /s /q "%TMPDIR%" >nul 2>nul
  pause
  goto MAIN
)

echo %H_PUB%
echo %PUB%
echo.

set /p ex=%ASK_EXPORT%
if /i "%ex%"=="y" (
  call :ENSURE_DIR "%EXPORT_DIR%"
  copy /y "%TMPPRIV%" "%EXPORT_DIR%\derived_private" >nul
  > "%EXPORT_DIR%\derived_public.pub" echo %PUB%
  echo %EXPORTED% %EXPORT_DIR%
  start "" "%EXPORT_DIR%"
)

rmdir /s /q "%TMPDIR%" >nul 2>nul
echo %DONE%
pause
goto MAIN

:GET_EXPORT_DIR
set RET_DIR=
if defined USERPROFILE (
  if not exist "%USERPROFILE%\Downloads" mkdir "%USERPROFILE%\Downloads" >nul 2>nul
  call :PROBE_WRITABLE "%USERPROFILE%\Downloads" && set RET_DIR=%USERPROFILE%\Downloads
)
if not defined RET_DIR if defined TEMP call :PROBE_WRITABLE "%TEMP%" && set RET_DIR=%TEMP%
if not defined RET_DIR set RET_DIR=%cd%

set RET_DIR=%RET_DIR%\%TS%
mkdir "%RET_DIR%" >nul 2>nul
exit /b

:PROBE_WRITABLE
set "_probe=%~1"
if not exist "%_probe%" exit /b 1
set "_pd=%_probe%\._probe_%RANDOM%"
mkdir "%_pd%" >nul 2>nul || exit /b 1
> "%_pd%\p.txt" echo ok
if errorlevel 1 ( rmdir /s /q "%_pd%" >nul 2>nul & exit /b 1 )
rmdir /s /q "%_pd%" >nul 2>nul
exit /b 0

:ENSURE_DIR
if not exist "%~1" mkdir "%~1" >nul 2>nul
exit /b 0

:END
endlocal
exit /b 0
