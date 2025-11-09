#!/usr/bin/env bash
set -euo pipefail

# --- helpers ---------------------------------------------------------------
die(){ echo "Error: $*" >&2; exit 1; }
have(){ command -v "$1" >/dev/null 2>&1; }
trim(){ awk '{$1=$1}1'; }

if ! have ssh-keygen; then
  die "ssh-keygen not found. Please install OpenSSH client."
fi

# Detect original user's Downloads even under sudo
resolve_user_home(){
  if [[ -n "${SUDO_USER-}" && "$SUDO_USER" != "root" ]]; then
    eval echo "~$SUDO_USER"
  else
    echo "$HOME"
  fi
}

timestamp(){ date +"%Y%m%d-%H%M%S"; }

make_export_dir(){
  local base home dl t
  home="$(resolve_user_home)"
  dl="$home/Downloads"
  t="$(timestamp)"
  mkdir -p "$dl/$t"
  echo "$dl/$t"
}

read_line(){ # prompt -> var
  local __p="$1"; local __varname="$2"; local __val
  read -r -p "$__p" __val
  printf -v "$__varname" '%s' "$__val"
}

press_enter(){ read -r -p "$MSG_PRESS_ENTER" _; }

# --- i18n -------------------------------------------------------------------
# Default English
LANG_ID="en"
if [[ -n "${LANG-}" ]]; then :; fi

choose_lang(){
  cat <<'EOF'
Choose language / 选择语言 / 選擇語言 / Choisir la langue / Выбрать язык / انتخاب زبان / 言語を選択:
  1) English
  2) 简体中文
  3) 繁體中文
  4) Français
  5) Русский
  6) فارسی (ایرانی)
  7) 日本語
EOF
  read -r -p "> " choice
  case "$choice" in
    2) LANG_ID="zh-CN" ;;
    3) LANG_ID="zh-TW" ;;
    4) LANG_ID="fr" ;;
    5) LANG_ID="ru" ;;
    6) LANG_ID="fa" ;;
    7) LANG_ID="ja" ;;
    *) LANG_ID="en" ;;
  esac
}

set_texts(){
  case "$LANG_ID" in
  en)
    MSG_MENU=$'1) Generate key\n2) Derive public key from private key\n3) Exit'
    MSG_CHOICE="Choose an option: "
    MSG_ALGO=$'Select algorithm:\n  1) RSA 2048\n  2) RSA 3072\n  3) RSA 4096\n  4) Ed25519'
    MSG_INPUT_METHOD=$'Input private key by:\n  1) Paste text\n  2) File path (you can drag & drop into terminal)'
    MSG_PASTE="Paste PRIVATE KEY (end with an empty line), then press Enter twice:"
    MSG_PATH="Enter file path: "
    MSG_SHOW_PRIV="--- PRIVATE KEY ---"
    MSG_SHOW_PUB="--- PUBLIC KEY ---"
    MSG_EXPORT="Export both keys to files? [y/N]: "
    MSG_EXPORTED_TO="Exported to:"
    MSG_PRESS_ENTER="Press Enter to continue..."
    MSG_DONE="Done."
    MSG_INVALID="Invalid choice."
    ;;
  zh-CN)
    MSG_MENU=$'1) 生成密钥\n2) 由私钥查询公钥\n3) 退出'
    MSG_CHOICE="请选择："
    MSG_ALGO=$'选择算法：\n  1) RSA 2048\n  2) RSA 3072\n  3) RSA 4096\n  4) Ed25519'
    MSG_INPUT_METHOD=$'选择私钥输入方式：\n  1) 粘贴文本\n  2) 文件路径（可拖拽到终端）'
    MSG_PASTE="请粘贴【私钥】，以空行结束，然后连续按两次回车："
    MSG_PATH="请输入文件路径："
    MSG_SHOW_PRIV="--- 私钥 ---"
    MSG_SHOW_PUB="--- 公钥 ---"
    MSG_EXPORT="是否导出到文件？[y/N]："
    MSG_EXPORTED_TO="已导出到："
    MSG_PRESS_ENTER="回车继续……"
    MSG_DONE="完成。"
    MSG_INVALID="无效选择。"
    ;;
  zh-TW)
    MSG_MENU=$'1) 產生金鑰\n2) 由私鑰查詢公鑰\n3) 離開'
    MSG_CHOICE="請選擇："
    MSG_ALGO=$'選擇演算法：\n  1) RSA 2048\n  2) RSA 3072\n  3) RSA 4096\n  4) Ed25519'
    MSG_INPUT_METHOD=$'選擇私鑰輸入方式：\n  1) 貼上文本\n  2) 檔案路徑（可拖曳至終端）'
    MSG_PASTE="請貼上【私鑰】，以空行結束，然後連按兩次 Enter："
    MSG_PATH="請輸入檔案路徑："
    MSG_SHOW_PRIV="--- 私鑰 ---"
    MSG_SHOW_PUB="--- 公鑰 ---"
    MSG_EXPORT="是否匯出為檔案？[y/N]："
    MSG_EXPORTED_TO="已匯出至："
    MSG_PRESS_ENTER="按 Enter 繼續……"
    MSG_DONE="完成。"
    MSG_INVALID="無效選擇。"
    ;;
  fr)
    MSG_MENU=$'1) Générer une clé\n2) Obtenir la clé publique depuis la clé privée\n3) Quitter'
    MSG_CHOICE="Votre choix : "
    MSG_ALGO=$'Choisir l’algorithme :\n  1) RSA 2048\n  2) RSA 3072\n  3) RSA 4096\n  4) Ed25519'
    MSG_INPUT_METHOD=$'Saisir la clé privée par :\n  1) Coller le texte\n  2) Chemin de fichier (glisser-déposer possible)'
    MSG_PASTE="Collez la CLÉ PRIVÉE (terminez par une ligne vide), puis Entrée deux fois :"
    MSG_PATH="Saisir le chemin du fichier : "
    MSG_SHOW_PRIV="--- CLÉ PRIVÉE ---"
    MSG_SHOW_PUB="--- CLÉ PUBLIQUE ---"
    MSG_EXPORT="Exporter les deux clés vers des fichiers ? [y/N] : "
    MSG_EXPORTED_TO="Exporté vers :"
    MSG_PRESS_ENTER="Appuyez sur Entrée pour continuer…"
    MSG_DONE="Terminé."
    MSG_INVALID="Choix invalide."
    ;;
  ru)
    MSG_MENU=$'1) Сгенерировать ключ\n2) Получить публичный ключ из приватного\n3) Выход'
    MSG_CHOICE="Выберите действие: "
    MSG_ALGO=$'Выберите алгоритм:\n  1) RSA 2048\n  2) RSA 3072\n  3) RSA 4096\n  4) Ed25519'
    MSG_INPUT_METHOD=$'Как ввести приватный ключ:\n  1) Вставить текст\n  2) Путь к файлу (можно перетащить в терминал)'
    MSG_PASTE="Вставьте ПРИВАТНЫЙ КЛЮЧ, завершите пустой строкой, затем дважды Enter:"
    MSG_PATH="Введите путь к файлу: "
    MSG_SHOW_PRIV="--- ПРИВАТНЫЙ КЛЮЧ ---"
    MSG_SHOW_PUB="--- ПУБЛИЧНЫЙ КЛЮЧ ---"
    MSG_EXPORT="Экспортировать оба ключа в файлы? [y/N]: "
    MSG_EXPORTED_TO="Экспортировано в:"
    MSG_PRESS_ENTER="Нажмите Enter для продолжения…"
    MSG_DONE="Готово."
    MSG_INVALID="Неверный выбор."
    ;;
  fa)
    MSG_MENU=$'1) تولید کلید\n2) استخراج کلید عمومی از کلید خصوصی\n3) خروج'
    MSG_CHOICE="گزینه را انتخاب کنید: "
    MSG_ALGO=$'الگوریتم را انتخاب کنید:\n  1) RSA 2048\n  2) RSA 3072\n  3) RSA 4096\n  4) Ed25519'
    MSG_INPUT_METHOD=$'روش ورود کلید خصوصی:\n  1) چسباندن متن\n  2) مسیر فایل (می‌توانید فایل را به ترمینال بکشید)'
    MSG_PASTE="کلید خصوصی را بچسبانید (با یک خط خالی پایان دهید)، سپس دو بار Enter:"
    MSG_PATH="مسیر فایل را وارد کنید: "
    MSG_SHOW_PRIV="--- کلید خصوصی ---"
    MSG_SHOW_PUB="--- کلید عمومی ---"
    MSG_EXPORT="خروجی گرفتن به فایل‌ها؟ [y/N]: "
    MSG_EXPORTED_TO="ذخیره شد در:"
    MSG_PRESS_ENTER="برای ادامه Enter را بزنید…"
    MSG_DONE="انجام شد."
    MSG_INVALID="گزینه نامعتبر."
    ;;
  ja)
    MSG_MENU=$'1) 鍵を生成\n2) 秘密鍵から公開鍵を取得\n3) 終了'
    MSG_CHOICE="番号を選択してください: "
    MSG_ALGO=$'アルゴリズムを選択:\n  1) RSA 2048\n  2) RSA 3072\n  3) RSA 4096\n  4) Ed25519'
    MSG_INPUT_METHOD=$'秘密鍵の入力方法:\n  1) テキスト貼り付け\n  2) ファイルパス（ターミナルへドラッグ可）'
    MSG_PASTE="【秘密鍵】を貼り付け、空行で終了、Enter を 2 回押してください:"
    MSG_PATH="ファイルパスを入力: "
    MSG_SHOW_PRIV="--- 秘密鍵 ---"
    MSG_SHOW_PUB="--- 公開鍵 ---"
    MSG_EXPORT="ファイルへ出力しますか？ [y/N]: "
    MSG_EXPORTED_TO="出力先:"
    MSG_PRESS_ENTER="続行するには Enter を押してください…"
    MSG_DONE="完了しました。"
    MSG_INVALID="無効な選択です。"
    ;;
  esac
}

# --- actions ----------------------------------------------------------------
generate_key(){
  echo "$MSG_ALGO"
  read -r -p "> " algo
  local type bits comment tmpdir keyfile pubfile
  comment="${USER:-user}-$(timestamp)"
  tmpdir="$(mktemp -d)"
  keyfile="$tmpdir/id_tmp"
  pubfile="$keyfile.pub"

  case "$algo" in
    1) type="rsa"; bits=2048 ;;
    2) type="rsa"; bits=3072 ;;
    3) type="rsa"; bits=4096 ;;
    4) type="ed25519"; bits="" ;;
    *) echo "$MSG_INVALID"; return ;;
  esac

  if [[ "$type" == "rsa" ]]; then
    ssh-keygen -t rsa -b "$bits" -N "" -C "$type-$bits-$(timestamp)" -f "$keyfile" >/dev/null
  else
    ssh-keygen -t ed25519 -a 100 -N "" -C "ed25519-$(timestamp)" -f "$keyfile" >/dev/null
  fi

  echo "$MSG_SHOW_PRIV"
  cat "$keyfile"
  echo
  echo "$MSG_SHOW_PUB"
  cat "$pubfile"
  echo

  read -r -p "$MSG_EXPORT" ans
  if [[ "${ans,,}" == "y" ]]; then
    outdir="$(make_export_dir)"
    # give readable names
    if [[ "$type" == "rsa" ]]; then
      cp "$keyfile"     "$outdir/id_rsa_${bits}"
      cp "$pubfile"     "$outdir/id_rsa_${bits}.pub"
      echo "$MSG_EXPORTED_TO $outdir/id_rsa_${bits}  /  $outdir/id_rsa_${bits}.pub"
    else
      cp "$keyfile"     "$outdir/id_ed25519"
      cp "$pubfile"     "$outdir/id_ed25519.pub"
      echo "$MSG_EXPORTED_TO $outdir/id_ed25519  /  $outdir/id_ed25519.pub"
    fi
  fi
  rm -rf "$tmpdir"
  echo "$MSG_DONE"; press_enter
}

derive_public(){
  echo "$MSG_INPUT_METHOD"
  read -r -p "> " im
  local tmpfile
  tmpfile="$(mktemp)"

  if [[ "$im" == "1" ]]; then
    echo "$MSG_PASTE"
    # read until empty line
    {
      while IFS= read -r line; do
        [[ -z "$line" ]] && break
        echo "$line"
      done
    } > "$tmpfile"
  elif [[ "$im" == "2" ]]; then
    read_line "$MSG_PATH" path
    path="$(echo "$path" | trim)"
    [[ -f "$path" ]] || die "File not found."
    cp "$path" "$tmpfile"
  else
    echo "$MSG_INVALID"; return
  fi

  # Try derive
  if pub=$(ssh-keygen -y -f "$tmpfile" 2>/dev/null); then
    echo "$MSG_SHOW_PUB"
    echo "$pub"
    echo
    read -r -p "$MSG_EXPORT" ans
    if [[ "${ans,,}" == "y" ]]; then
      outdir="$(make_export_dir)"
      cp "$tmpfile" "$outdir/derived_private"
      printf "%s\n" "$pub" > "$outdir/derived_public.pub"
      echo "$MSG_EXPORTED_TO $outdir/derived_private  /  $outdir/derived_public.pub"
    fi
    echo "$MSG_DONE"; press_enter
  else
    die "Failed to parse private key. Make sure it is an OpenSSH/PEM private key."
  fi
  rm -f "$tmpfile"
}

main_menu(){
  while true; do
    clear
    echo "$MSG_MENU"
    read -r -p "$MSG_CHOICE" c
    case "$c" in
      1) generate_key ;;
      2) derive_public ;;
      3) exit 0 ;;
      *) echo "$MSG_INVALID"; press_enter ;;
    esac
  done
}

choose_lang
set_texts
main_menu
