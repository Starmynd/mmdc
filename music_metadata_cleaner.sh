#!/bin/bash

# Цветовые коды ANSI для красивого вывода
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
BLUE='\033[1;34m'
NC='\033[0m' # Сброс цвета

# Символы для маркировки
CHECK="✔"
ARROW="➜"
ERROR="✖"

# Массив для хранения изменённых файлов
declare -a CHANGED_FILES

# Проверка наличия утилиты id3v2
if ! command -v id3v2 &> /dev/null; then
    echo -e "${RED}${ERROR} Требуется id3v2. Установи: brew install id3v2${NC}"
    exit 1
fi

# Получение пути к директории, где находится сам скрипт
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Заголовок
echo -e "${BLUE}== MP3 Metadata Cleaner ==${NC}"
echo -e "Сканируем: ${CYAN}$SCRIPT_DIR${NC}\n"

# Поиск всех MP3-файлов (игнорируя скрытые системные файлы macOS ._*), обход вложенных папок
find "$SCRIPT_DIR" -type f -iname "*.mp3" -not -name "._*" | while IFS= read -r file; do

    # Проверка прав на запись
    if [ ! -w "$file" ]; then
        echo -e "${RED}${ERROR} Нет прав на ${CYAN}$(basename "$file")${NC}"
        continue
    fi

    echo -e "${YELLOW}${ARROW} $(basename "$file")${NC}"

    # Флаг, были ли внесены изменения в текущий файл
    changed=false

    ####### ОБРАБОТКА ИСПОЛНИТЕЛЯ (TPE1) ########
    artist=$(id3v2 -l "$file" | grep -E "TPE1" | sed -E 's/.*: (.*)/\1/')
    clean_artist=$(echo "$artist" | sed -E 's/[[:space:]]*(feat\.?|ft\.?)[[:space:]].*//i' | sed -E 's/[[:space:]]*$//')
    if [ "$artist" != "$clean_artist" ]; then
        id3v2 -a "$clean_artist" "$file" > /dev/null 2>&1
        changed=true
    fi

    ####### ОБРАБОТКА НАЗВАНИЯ ТРЕКА (TIT2) ########
    title=$(id3v2 -l "$file" | grep -E "TIT2" | sed -E 's/.*: (.*)/\1/')
    clean_title=$(echo "$title" | sed -E 's/(feat\.?|ft\.?|remix|\[.*\]).*//i' | sed -E 's/[[:space:]]*$//')
    if [ "$title" != "$clean_title" ]; then
        id3v2 -t "$clean_title" "$file" > /dev/null 2>&1
        changed=true
    fi

    ####### ОБРАБОТКА НАЗВАНИЯ АЛЬБОМА (TALB) ########
    album=$(id3v2 -l "$file" | grep -E "TALB" | sed -E 's/.*: (.*)/\1/')
    clean_album=$(echo "$album" | sed -E 's/ *(\(.*Edition\)|Deluxe|Bonus).*//i' | sed -E 's/[[:space:]]*$//')
    if [ "$album" != "$clean_album" ]; then
        id3v2 -A "$clean_album" "$file" > /dev/null 2>&1
        changed=true
    fi

    ####### ОБРАБОТКА АЛЬБОМНОГО ИСПОЛНИТЕЛЯ (TPE2) ########
    album_artist=$(id3v2 -l "$file" | grep -E "TPE2" | sed -E 's/.*: (.*)/\1/')
    if [[ "$album_artist" =~ Various ]]; then
        id3v2 --TPE2 "Various Artists" "$file" > /dev/null 2>&1
        changed=true
    fi

    ####### ОБРАБОТКА ЖАНРА (TCON) ########
    genre=$(id3v2 -l "$file" | grep -E "TCON" | sed -E 's/.*: (.*)/\1/')
    if [[ "$genre" =~ (Hip[- ]?Hop|Trap|Rap) ]]; then
        id3v2 -g "Hip-Hop" "$file" > /dev/null 2>&1
        changed=true
    fi

    ####### УДАЛЕНИЕ ОБЛОЖКИ (APIC) ########
    # Если обложка существует — удаляем
    if id3v2 -d "$file" | grep -q "APIC"; then
        id3v2 -D "$file" > /dev/null 2>&1
        changed=true
    fi

    ####### ИТОГ ДЛЯ ФАЙЛА ########
    if [ "$changed" = true ]; then
        CHANGED_FILES+=("$file")
        echo -e "  ${GREEN}${CHECK} Очищено и обновлено${NC}"
    else
        echo -e "  ${YELLOW}${ARROW} Без изменений${NC}"
    fi
done

########## СВОДКА ##########
echo -e "\n${BLUE}== Готово ==${NC}"

# Если не было изменений ни в одном файле
if [ ${#CHANGED_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}${ARROW} Ни один файл не был изменён.${NC}"
else
    echo -e "${GREEN}${CHECK} Изменены файлы:${NC}"
    for file in "${CHANGED_FILES[@]}"; do
        echo -e "  ${CYAN}${file}${NC}"
    done
    echo -e "${GREEN}${CHECK} Всего: ${#CHANGED_FILES[@]}${NC}"
fi
