#!/usr/bin/env bash
set -euo pipefail

# --- helpers ---------------------------------------------------------------
die(){ echo "Error: $*" >&2; exit 1; }
have(){ command -v "$1" >/dev/null 2>&1; }
trim(){ awk '{$1=$1}1'; }
is_yes(){ case "$1" in [Yy]) return 0;; *) return 1;; esac; }
is_macos(){ [[ "$(uname -s)" == "Darwin" ]]; }
is_linux(){ [[ "$(uname -s)" == "Linux" ]]; }

if ! have ssh-keygen; then
  die "ssh-keygen not found. Please install OpenSSH client."
fi

# Detect original user's HOME even under sudo
resolve_user_home(){
  if [[ -n "${SUDO_USER-}" && "$SUDO_USER" != "root" ]]; then
    eval echo "~$SUDO_USER"
  else
    echo "$HOME"
  fi
}

# Best-effort Downloads dir
detect_downloads_dir(){
  local home dl
  home="$(resolve_user_home)"
  if is_macos; then
    dl="$home/Downloads"
  elif is_linux; then
    # Try XDG from user-dirs.dirs
    local xdg_file="$home/.config/user-dirs.dirs"
    if [[ -f "$xdg_file" ]]; then
      # shellcheck disable=SC2016
      dl="$(. "$xdg_file"; printf '%s' "${XDG_DOWNLOAD_DIR:-$home/Downloads}")"
      dl="${dl/\$HOME/$home}"
    else
      dl="$home/Downloads"
    fi
  else
    dl="$home/Downloads"
  fi
  echo "$dl"
}

timestamp(){ date +"%Y%m%d-%H%M%S"; }
safe_clear(){ if have clear; then clear; fi; }
read_line(){ local __p="$1"; local __varname="$2"; local __val; read -r -p "$__p" __val; printf -v "$__varname" '%s' "$__val"; }
press_enter(){ read -r -p "$MSG_PRESS_ENTER" _; }

# Open folder in GUI (Finder / KDE/GNOME/Nemo/Thunar, etc.)
open_folder_gui(){
  local dir="$1" opener=""
  if is_macos && have open; then
    open "$dir" >/dev/null 2>&1 || true
    return
  fi
  if is_linux; then
    if   have xdg-open;    then opener=(xdg-open)
    elif have gio;         then opener=(gio open)
    elif have kioclient5;  then opener=(kioclient5 exec)
    elif have dolphin;     then opener=(dolphin)
    elif have nautilus;    then opener=(nautilus)
    elif have nemo;        then opener=(nemo)
    elif have thunar;      then opener=(thunar)
    elif have pcmanfm;     then opener=(pcmanfm)
    else return 0; fi
    if [[ -n "${SUDO_USER-}" && "$SUDO_USER" != "root" ]]; then
      sudo -u "$SUDO_USER" -H env DISPLAY="${DISPLAY-:0}" XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR-}" \
        "${opener[@]}" "$dir" >/dev/null 2>&1 & disown || true
    else
      "${opener[@]}" "$dir" >/dev/null 2>&1 & disown || true
    fi
  fi
}

# -------- GUI save dialogs --------------------------------------------------
# Return chosen *file* path (or empty) via stdout.
pick_save_path(){
  local default_name="$1" title="$2" ; local result=""
  local home dl; dl="$(detect_downloads_dir)"
  local default_path="$dl/$default_name"

  if is_macos && have osascript; then
    # AppleScript choose file name
    result="$(osascript 2>/dev/null <<OSA || true
set fp to POSIX path of (choose file name with prompt "$title" default name "$default_name")
fp
OSA
)"
    printf '%s' "$result"
    return
  fi

  if is_linux; then
    if have zenity; then
      # GNOME常见：zenity
      if [[ -n "${SUDO_USER-}" && "$SUDO_USER" != "root" ]]; then
        result="$(sudo -u "$SUDO_USER" -H env DISPLAY="${DISPLAY-:0}" XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR-}" \
          zenity --file-selection --save --confirm-overwrite --filename="$default_path" --title="$title" 2>/dev/null || true)"
      else
        result="$(zenity --file-selection --save --confirm-overwrite --filename="$default_path" --title="$title" 2>/dev/null || true)"
      fi
      printf '%s' "$result"; return
    elif have kdialog; then
      # KDE常见：kdialog
      if [[ -n "${SUDO_USER-}" && "$SUDO_USER" != "root" ]]; then
        result="$(sudo -u "$SUDO_USER" -H env DISPLAY="${DISPLAY-:0}" XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR-}" \
          kdialog --getsavefilename "$default_path" "*" --title "$title" 2>/dev/null || true)"
      else
        result="$(kdialog --getsavefilename "$default_path" "*" --title "$title" 2>/dev/null || true)"
      fi
      printf '%s' "$result"; return
    fi
  fi

  # Fallback: TTY prompt
  read_line "$MSG_SAVE_PATH_PROMPT" result
  printf '%s' "$result"
}

# Change extension to .pub (keep dirname and basename)
with_pub_ext(){
  local p="$1"
  if [[ "$p" == *.* ]]; then
    echo "${p%.*}.pub"
  else
    echo "${p}.pub"
  fi
}

# --- i18n -------------------------------------------------------------------
LANG_ID="en"

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
    MSG_EXPORT="Export to files via a save dialog? [y/N]: "
    MSG_SAVE_PRIV_TITLE="Save private key as..."
    MSG_SAVE_PUB_TITLE="Save public key as..."
    MSG_SAVE_PATH_PROMPT="Enter save path (or leave empty to cancel): "
    MSG_SAVE_CANCELED="Save canceled."
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
    MSG_EXPORT="通过“保存”对话框导出到文件？[y/N]："
    MSG_SAVE_PRIV_TITLE="将私钥另存为…"
    MSG_SAVE_PUB_TITLE="将公钥另存为…"
    MSG_SAVE_PATH_PROMPT="请输入保存路径（留空取消）："
    MSG_SAVE_CANCELED="已取消保存。"
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
    MSG_EXPORT="透過「另存新檔」對話框匯出？[y/N]："
    MSG_SAVE_PRIV_TITLE="將私鑰另存為…"
    MSG_SAVE_PUB_TITLE="將公鑰另存為…"
    MSG_SAVE_PATH_PROMPT="請輸入儲存路徑（留白取消）："
    MSG_SAVE_CANCELED="已取消儲存。"
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
    MSG_EXPORT="Exporter via une boîte de dialogue d’enregistrement ? [y/N] : "
    MSG_SAVE_PRIV_TITLE="Enregistrer la clé privée sous…"
    MSG_SAVE_PUB_TITLE="Enregistrer la clé publique sous…"
    MSG_SAVE_PATH_PROMPT="Saisir le chemin d’enregistrement (laisser vide pour annuler) : "
    MSG_SAVE_CANCELED="Enregistrement annulé."
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
    MSG_EXPORT="Экспортировать через диалог сохранения? [y/N]: "
    MSG_SAVE_PRIV_TITLE="Сохранить приватный ключ как..."
    MSG_SAVE_PUB_TITLE="Сохранить публичный ключ как..."
    MSG_SAVE_PATH_PROMPT="Введите путь для сохранения (или оставьте пустым для отмены): "
    MSG_SAVE_CANCELED="Сохранение отменено."
    MSG_EXPORTED_TO="Сохранено в:"
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
    MSG_EXPORT="خروجی با پنجرهٔ «ذخیره»؟ [y/N]: "
    MSG_SAVE_PRIV_TITLE="ذخیرهٔ کلید خصوصی با نام..."
    MSG_SAVE_PUB_TITLE="ذخیرهٔ کلید عمومی با نام..."
    MSG_SAVE_PATH_PROMPT="مسیر ذخیره را وارد کنید (برای لغو خالی بگذارید): "
    MSG_SAVE_CANCELED="ذخیره لغو شد."
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
    MSG_EXPORT="保存ダイアログで出力しますか？ [y/N] : "
    MSG_SAVE_PRIV_TITLE="秘密鍵の保存先を選択..."
    MSG_SAVE_PUB_TITLE="公開鍵の保存先を選択..."
    MSG_SAVE_PATH_PROMPT="保存パスを入力（空欄でキャンセル）："
    MSG_SAVE_CANCELED="保存をキャンセルしました。"
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
  local type bits tmpdir keyfile pubfile
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
    ssh-keygen -t ed25519 -a 100 -N "" -C "ed25519-$(timestamp)" -f "$keyfile" >/devnull 2>&1
  fi

  echo "$MSG_SHOW_PRIV"
  cat "$keyfile"
  echo
  echo "$MSG_SHOW_PUB"
  cat "$pubfile"
  echo

  read -r -p "$MSG_EXPORT" ans
  if is_yes "$ans"; then
    local default_base
    if [[ "$type" == "rsa" ]]; then default_base="id_rsa_${bits}"; else default_base="id_ed25519"; fi
    local save_priv save_pub
    save_priv="$(pick_save_path "${default_base}" "$MSG_SAVE_PRIV_TITLE")"
    if [[ -n "$save_priv" ]]; then
      mkdir -p "$(dirname "$save_priv")"
      cp "$keyfile" "$save_priv"
      save_pub="$(with_pub_ext "$save_priv")"
      cp "$pubfile" "$save_pub"
      echo "$MSG_EXPORTED_TO $save_priv"
      echo "$MSG_EXPORTED_TO $save_pub"
      open_folder_gui "$(dirname "$save_priv")"
    else
      echo "$MSG_SAVE_CANCELED"
    fi
  fi
  rm -rf "$tmpdir"
  echo "$MSG_DONE"; press_enter
}

derive_public(){
  echo "$MSG_INPUT_METHOD"
  read -r -p "> " im
  local tmpfile; tmpfile="$(mktemp)"

  if [[ "$im" == "1" ]]; then
    echo "$MSG_PASTE"
    { while IFS= read -r line; do
        [[ -z "$line" ]] && break
        echo "$line"
      done
    } > "$tmpfile"
  elif [[ "$im" == "2" ]]; then
    local path; read_line "$MSG_PATH" path; path="$(echo "$path" | trim)"
    [[ -f "$path" ]] || die "File not found."
    cp "$path" "$tmpfile"
  else
    echo "$MSG_INVALID"; return
  fi

  if pub=$(ssh-keygen -y -f "$tmpfile" 2>/dev/null); then
    echo "$MSG_SHOW_PUB"
    echo "$pub"
    echo

    # Ask to save private copy
    read -r -p "$MSG_EXPORT" ans
    if is_yes "$ans"; then
      local save_priv save_pub
      save_priv="$(pick_save_path "derived_private" "$MSG_SAVE_PRIV_TITLE")"
      if [[ -n "$save_priv" ]]; then
        mkdir -p "$(dirname "$save_priv")"
        cp "$tmpfile" "$save_priv"
        echo "$MSG_EXPORTED_TO $save_priv"
      else
        echo "$MSG_SAVE_CANCELED"
      fi
      save_pub="$(pick_save_path "derived_public.pub" "$MSG_SAVE_PUB_TITLE")"
      if [[ -n "$save_pub" ]]; then
        mkdir -p "$(dirname "$save_pub")"
        printf "%s\n" "$pub" > "$save_pub"
        echo "$MSG_EXPORTED_TO $save_pub"
        open_folder_gui "$(dirname "$save_pub")"
      else
        echo "$MSG_SAVE_CANCELED"
      fi
    fi

    echo "$MSG_DONE"; press_enter
  else
    die "Failed to parse private key. Make sure it is an OpenSSH/PEM private key."
  fi
  rm -f "$tmpfile"
}

main_menu(){
  while true; do
    safe_clear
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
