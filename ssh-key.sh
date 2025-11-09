#!/usr/bin/env bash
set -euo pipefail

# ---------- helpers ----------
detect_home_user() {
  if [[ -n "${SUDO_USER-}" && "${SUDO_USER}" != "root" ]]; then
    # original invoking user
    eval echo "~${SUDO_USER}"
  else
    echo "${HOME}"
  fi
}

downloads_dir() {
  local uh
  uh="$(detect_home_user)"
  echo "${uh%/}/Downloads"
}

require_bin() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1"
    echo "Please install OpenSSH client (ssh-keygen)."
    exit 1
  }
}

timestamp() { date +%Y%m%d-%H%M%S; }

read_choice() {
  local prompt="$1"
  local var
  printf "%s" "$prompt"
  read -r var
  echo "$var"
}

# ---------- i18n ----------
# We avoid bash associative arrays for macOS Bash 3.x compatibility.
set_lang() {
  case "$1" in
    1|en)
      L_WELCOME="SSH Key Tool"
      L_CHOOSE_LANG="Choose language:"
      L_LANGS="1) English  2) 简体中文  3) 繁體中文  4) Français  5) Русский  6) فارسی  7) 日本語"
      L_MENU="Select an option: 1) Generate keys  2) Derive public key from private  3) Exit : "
      L_GEN_TITLE="Key type: 1) RSA-2048  2) RSA-3072  3) RSA-4096  4) Ed25519 : "
      L_GEN_START="Generating locally..."
      L_GEN_DONE="Done."
      L_SHOW_PRIV="----- Private Key -----"
      L_SHOW_PUB="----- Public Key ------"
      L_EXPORT_ASK="Export both keys to Downloads? (y/N): "
      L_EXPORTED_TO="Exported to"
      L_ENTER_PATH_OR_PASTE="Enter a private-key file path (or drag file here); or press ENTER to paste key:"
      L_PASTE_INSTRUCT="Paste the private key (end with a single line: END):"
      L_DERIVED="Derived public key:"
      L_SAVE_NAME="Base filename (without path, default: id_key): "
      L_SAVED="Saved:"
      L_PRESS_ENTER="Press ENTER to continue..."
      L_BYE="Bye!"
      ;;
    2|zh|zh-CN)
      L_WELCOME="SSH 密钥工具"
      L_CHOOSE_LANG="选择语言："
      L_LANGS="1) English  2) 简体中文  3) 繁體中文  4) Français  5) Русский  6) فارسی  7) 日本語"
      L_MENU="选择操作：1) 生成密钥  2) 由私钥查询公钥  3) 退出 ："
      L_GEN_TITLE="选择类型：1) RSA-2048  2) RSA-3072  3) RSA-4096  4) Ed25519 ："
      L_GEN_START="本地生成中..."
      L_GEN_DONE="完成。"
      L_SHOW_PRIV="----- 私钥 -----"
      L_SHOW_PUB="----- 公钥 -----"
      L_EXPORT_ASK="导出两份文件到下载目录？(y/N)："
      L_EXPORTED_TO="已导出到"
      L_ENTER_PATH_OR_PASTE="请输入私钥文件路径（或将文件拖入终端）；或回车以粘贴私钥："
      L_PASTE_INSTRUCT="请粘贴私钥（以独立一行 END 结束）："
      L_DERIVED="推导出的公钥："
      L_SAVE_NAME="文件基础名（不含路径，默认：id_key）："
      L_SAVED="已保存："
      L_PRESS_ENTER="回车继续..."
      L_BYE="再见！"
      ;;
    3|zh-TW)
      L_WELCOME="SSH 金鑰工具"
      L_CHOOSE_LANG="選擇語言："
      L_LANGS="1) English  2) 简体中文  3) 繁體中文  4) Français  5) Русский  6) فارسی  7) 日本語"
      L_MENU="選擇操作：1) 產生金鑰  2) 由私鑰查詢公鑰  3) 離開 ："
      L_GEN_TITLE="選擇類型：1) RSA-2048  2) RSA-3072  3) RSA-4096  4) Ed25519 ："
      L_GEN_START="本機產生中..."
      L_GEN_DONE="完成。"
      L_SHOW_PRIV="----- 私鑰 -----"
      L_SHOW_PUB="----- 公鑰 -----"
      L_EXPORT_ASK="匯出兩個檔案到下載資料夾？(y/N)："
      L_EXPORTED_TO="已匯出到"
      L_ENTER_PATH_OR_PASTE="請輸入私鑰檔案路徑（或拖曳到終端）；或直接按 Enter 貼上私鑰："
      L_PASTE_INSTRUCT="請貼上私鑰（以單獨一行 END 結束）："
      L_DERIVED="推導出的公鑰："
      L_SAVE_NAME="檔名基底（不含路徑，預設：id_key）："
      L_SAVED="已儲存："
      L_PRESS_ENTER="按 Enter 繼續..."
      L_BYE="掰！"
      ;;
    4|fr)
      L_WELCOME="Outil de clés SSH"
      L_CHOOSE_LANG="Choisissez la langue :"
      L_LANGS="1) English  2) 简体中文  3) 繁體中文  4) Français  5) Русский  6) فارسی  7) 日本語"
      L_MENU="Choix : 1) Générer des clés  2) Dériver la clé publique  3) Quitter : "
      L_GEN_TITLE="Type : 1) RSA-2048  2) RSA-3072  3) RSA-4096  4) Ed25519 : "
      L_GEN_START="Génération locale..."
      L_GEN_DONE="Terminé."
      L_SHOW_PRIV="----- Clé privée -----"
      L_SHOW_PUB="----- Clé publique -----"
      L_EXPORT_ASK="Exporter les deux fichiers vers Téléchargements ? (y/N) : "
      L_EXPORTED_TO="Exporté vers"
      L_ENTER_PATH_OR_PASTE="Entrez le chemin du fichier de clé privée (ou glissez-le) ; ou Entrée pour coller :"
      L_PASTE_INSTRUCT="Collez la clé privée (terminez par une ligne : END) :"
      L_DERIVED="Clé publique dérivée :"
      L_SAVE_NAME="Nom de base (sans chemin, défaut : id_key) : "
      L_SAVED="Enregistré :"
      L_PRESS_ENTER="Appuyez sur Entrée pour continuer..."
      L_BYE="Au revoir !"
      ;;
    5|ru)
      L_WELCOME="Инструмент ключей SSH"
      L_CHOOSE_LANG="Выберите язык:"
      L_LANGS="1) English  2) 简体中文  3) 繁體中文  4) Français  5) Русский  6) فارسی  7) 日本語"
      L_MENU="Выбор: 1) Сгенерировать ключи  2) Получить публичный из приватного  3) Выход : "
      L_GEN_TITLE="Тип: 1) RSA-2048  2) RSA-3072  3) RSA-4096  4) Ed25519 : "
      L_GEN_START="Локальная генерация..."
      L_GEN_DONE="Готово."
      L_SHOW_PRIV="----- Приватный ключ -----"
      L_SHOW_PUB="----- Публичный ключ -----"
      L_EXPORT_ASK="Экспортировать оба файла в Загрузки? (y/N): "
      L_EXPORTED_TO="Экспортировано в"
      L_ENTER_PATH_OR_PASTE="Укажите путь к приватному ключу (или перетащите файл); или Enter для вставки:"
      L_PASTE_INSTRUCT="Вставьте приватный ключ (завершите строкой END):"
      L_DERIVED="Полученный публичный ключ:"
      L_SAVE_NAME="Базовое имя файла (по умолчанию: id_key): "
      L_SAVED="Сохранено:"
      L_PRESS_ENTER="Нажмите Enter для продолжения..."
      L_BYE="Пока!"
      ;;
    6|fa|fa-IR|persian)
      L_WELCOME="ابزار کلیدهای SSH"
      L_CHOOSE_LANG="زبان را انتخاب کنید:"
      L_LANGS="1) English  2) 简体中文  3) 繁體中文  4) Français  5) Русский  6) فارسی  7) 日本語"
      L_MENU="گزینه: 1) ساخت کلید  2) استخراج کلید عمومی از خصوصی  3) خروج : "
      L_GEN_TITLE="نوع: 1) RSA-2048  2) RSA-3072  3) RSA-4096  4) Ed25519 : "
      L_GEN_START="در حال ساخت محلی..."
      L_GEN_DONE="انجام شد."
      L_SHOW_PRIV="----- کلید خصوصی -----"
      L_SHOW_PUB="----- کلید عمومی -----"
      L_EXPORT_ASK="خروجی هر دو فایل به پوشه Downloads ؟ (y/N): "
      L_EXPORTED_TO="ذخیره شد در"
      L_ENTER_PATH_OR_PASTE="مسیر فایل کلید خصوصی را وارد کنید (یا فایل را بکشید)؛ یا Enter برای چسباندن:"
      L_PASTE_INSTRUCT="کلید خصوصی را بچسبانید (با خط END تمام کنید):"
      L_DERIVED="کلید عمومی استخراج‌شده:"
      L_SAVE_NAME="نام پایه فایل (پیش‌فرض: id_key): "
      L_SAVED="ذخیره شد:"
      L_PRESS_ENTER="برای ادامه Enter بزنید..."
      L_BYE="خدانگهدار!"
      ;;
    7|ja)
      L_WELCOME="SSHキー・ツール"
      L_CHOOSE_LANG="言語を選択："
      L_LANGS="1) English  2) 简体中文  3) 繁體中文  4) Français  5) Русский  6) فارسی  7) 日本語"
      L_MENU="選択：1) 鍵を生成  2) 秘密鍵から公開鍵  3) 終了 ："
      L_GEN_TITLE="種類：1) RSA-2048  2) RSA-3072  3) RSA-4096  4) Ed25519 ："
      L_GEN_START="ローカル生成中..."
      L_GEN_DONE="完了。"
      L_SHOW_PRIV="----- 秘密鍵 -----"
      L_SHOW_PUB="----- 公開鍵 -----"
      L_EXPORT_ASK="ダウンロードへ2ファイルを書き出しますか？(y/N)："
      L_EXPORTED_TO="出力先"
      L_ENTER_PATH_OR_PASTE="秘密鍵ファイルのパスを入力（ドラッグ可）；またはEnterで貼り付け："
      L_PASTE_INSTRUCT="秘密鍵を貼り付けてください（単独行 END で終了）："
      L_DERIVED="生成された公開鍵："
      L_SAVE_NAME="基本ファイル名（既定: id_key）："
      L_SAVED="保存："
      L_PRESS_ENTER="Enterで続行..."
      L_BYE="バイ！"
      ;;
    *) set_lang 2 ;;
  esac
}

clear
echo "==== SSH Key Tool ===="
echo "1) English  2) 简体中文  3) 繁體中文  4) Français  5) Русский  6) فارسی  7) 日本語"
lang_choice="$(read_choice "> ")"
set_lang "${lang_choice}"

require_bin ssh-keygen

while :; do
  echo
  echo "$L_MENU"
  read -r main_choice
  case "$main_choice" in
    1)
      algo_choice="$(read_choice "$L_GEN_TITLE")"
      case "$algo_choice" in
        1) type="rsa"; bits=2048 ;;
        2) type="rsa"; bits=3072 ;;
        3) type="rsa"; bits=4096 ;;
        4) type="ed25519"; bits="" ;;
        *) continue ;;
      esac
      ts="$(timestamp)"
      comment="${type}-${ts}"
      tmpdir="$(mktemp -d)"
      keyfile="${tmpdir}/id_key"
      echo "$L_GEN_START"
      if [[ "$type" == "rsa" ]]; then
        ssh-keygen -t rsa -b "$bits" -N "" -C "$comment" -f "$keyfile" >/dev/null
      else
        ssh-keygen -t ed25519 -a 100 -N "" -C "$comment" -f "$keyfile" >/dev/null
      fi
      echo "$L_GEN_DONE"
      echo
      echo "$L_SHOW_PRIV"
      cat "$keyfile"
      echo
      echo "$L_SHOW_PUB"
      cat "${keyfile}.pub"
      echo
      read -r -p "$L_EXPORT_ASK" yn
      if [[ "${yn:-}" =~ ^[Yy]$ ]]; then
        dld="$(downloads_dir)"
        outdir="${dld}/ssh-keys-${ts}"
        mkdir -p "$outdir"
        # Default base name
        read -r -p "$L_SAVE_NAME" base
        base="${base:-id_key}"
        cp "$keyfile"      "${outdir}/${base}"
        cp "${keyfile}.pub" "${outdir}/${base}.pub"
        chmod 600 "${outdir}/${base}"
        echo "$L_EXPORTED_TO ${outdir}"
        echo "$L_SAVED ${outdir}/${base}"
        echo "$L_SAVED ${outdir}/${base}.pub"
      fi
      rm -rf "$tmpdir"
      read -r -p "$L_PRESS_ENTER" _
      ;;
    2)
      echo "$L_ENTER_PATH_OR_PASTE"
      read -r path_or_blank || true
      tmpdir="$(mktemp -d)"
      keyfile="${tmpdir}/id_priv"
      if [[ -n "${path_or_blank}" && -e "${path_or_blank/#\~/$HOME}" ]]; then
        # path exists
        src="${path_or_blank/#\~/$HOME}"
        cp "$src" "$keyfile"
      else
        echo "$L_PASTE_INSTRUCT"
        : > "$keyfile"
        while IFS= read -r line; do
          [[ "$line" == "END" ]] && break
          printf "%s\n" "$line" >> "$keyfile"
        done
      fi
      echo
      echo "$L_DERIVED"
      if ssh-keygen -y -f "$keyfile" > "${keyfile}.pub" 2>/dev/null; then
        cat "${keyfile}.pub"
        echo
        read -r -p "$L_EXPORT_ASK" yn2
        if [[ "${yn2:-}" =~ ^[Yy]$ ]]; then
          dld="$(downloads_dir)"
          ts="$(timestamp)"
          outdir="${dld}/ssh-keys-${ts}"
          mkdir -p "$outdir"
          read -r -p "$L_SAVE_NAME" base
          base="${base:-id_key}"
          cp "$keyfile"        "${outdir}/${base}"
          cp "${keyfile}.pub"  "${outdir}/${base}.pub"
          chmod 600 "${outdir}/${base}"
          echo "$L_EXPORTED_TO ${outdir}"
          echo "$L_SAVED ${outdir}/${base}"
          echo "$L_SAVED ${outdir}/${base}.pub"
        fi
      else
        echo "Failed to derive public key (maybe passphrase wrong or invalid key)."
      fi
      rm -rf "$tmpdir"
      read -r -p "$L_PRESS_ENTER" _
      ;;
    3) echo "$L_BYE"; exit 0 ;;
    *) ;;
  esac
done
