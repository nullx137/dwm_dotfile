#!/bin/bash
#==========================================#
#  DWM RICER — Установщик из Niri/Wayland  #
#==========================================#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DWM_SOURCE="$SCRIPT_DIR/dwm-source"
BACKUP_DIR="$HOME/.dwm_backup_$(date +%Y%m%d_%H%M%S)"

echo "╔════════════════════════════════════════╗"
echo "║     DWM RICER — INSTALLER               ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Функция цветного вывода
info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $1"; }
ok() { echo -e "\033[1;32m[OK]\033[0m $1"; }

# Проверка зависимостей
check_deps() {
    info "Проверка зависимостей..."
    
    local deps=("gcc" "make" "libx11" "libxft" "libxinerama" "imlib2")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! pacman -Q "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        warn "Отсутствуют пакеты: ${missing[*]}"
        read -p "Установить? (y/n): " confirm
        if [ "$confirm" = "y" ]; then
            sudo pacman -S "${missing[@]}" --noconfirm
        else
            error "Установка прервана"
            exit 1
        fi
    fi
    
    ok "Все зависимости установлены"
}

# Резервное копирование
backup() {
    if [ -e "$HOME/.local/bin/dwm" ]; then
        info "Резервное копирование старого dwm..."
        mkdir -p "$BACKUP_DIR"
        cp -r "$HOME/.local/bin/dwm" "$BACKUP_DIR/" 2>/dev/null || true
        cp -r "$HOME/.config/dwm" "$BACKUP_DIR/" 2>/dev/null || true
        ok "Резервная копия: $BACKUP_DIR"
    fi
}

# Компиляция dwm
compile_dwm() {
    info "Компиляция dwm..."
    
    cd "$DWM_SOURCE"
    
    # Проверяем наличие исходников
    if [ ! -f "Makefile" ]; then
        error "Makefile не найден. Скачайте исходники dwm в dwm-source/"
        exit 1
    fi
    
    # Очистка и компиляция
    sudo make clean
    sudo make
    
    ok "dwm скомпилирован"
}

# Установка dwm
install_dwm() {
    info "Установка dwm..."
    
    cd "$DWM_SOURCE"
    sudo make install
    
    # Копируем config.h для перекомпиляции
    mkdir -p "$HOME/.config/dwm"
    cp "$DWM_SOURCE/config.h" "$HOME/.config/dwm/"
    
    ok "dwm установлен в /usr/local/bin/"
}

# Установка скриптов
install_scripts() {
    info "Установка скриптов..."

    mkdir -p "$HOME/.local/bin"

    # Делаем исполняемыми
    chmod +x "$SCRIPT_DIR/autostart.sh"
    chmod +x "$SCRIPT_DIR/dwm_status.sh"

    # Копируем
    cp "$SCRIPT_DIR/autostart.sh" "$HOME/.local/bin/"
    cp "$SCRIPT_DIR/dwm_status.sh" "$HOME/.local/bin/"

    # Добавляем export в .profile если нужно
    if ! grep -q '~/.local/bin' "$HOME/.profile" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.profile"
    fi

    ok "Скрипты установлены в ~/.local/bin/"
}

# Компиляция и установка dwmblocks
install_dwmblocks() {
    info "Компиляция dwmblocks..."

    local dwmblocks_src="/tmp/dwmblocks"

    # Клонируем/обновляем dwmblocks
    if [ ! -d "$dwmblocks_src" ]; then
        git clone --depth 1 https://github.com/torrinfail/dwmblocks.git "$dwmblocks_src" 2>/dev/null || {
            warn "Не удалось клонировать dwmblocks, пропускаем"
            return 0
        }
    fi

    # Копируем blocks.def.h
    if [ -f "$SCRIPT_DIR/dwmblocks.def.h" ]; then
        cp "$SCRIPT_DIR/dwmblocks.def.h" "$dwmblocks_src/blocks.def.h"
    fi

    # Исправляем signal handler
    sed -i 's/void termhandler()/void termhandler(int sig)/g' "$dwmblocks_src/dwmblocks.c"

    # Компилируем
    cd "$dwmblocks_src"
    make clean 2>/dev/null
    make 2>/dev/null || {
        warn "Компиляция dwmblocks не удалась"
        return 0
    }

    # Копируем dwmblocks
    cp "$dwmblocks_src/dwmblocks" "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/dwmblocks"

    # Копируем блоки
    mkdir -p "$HOME/.local/bin/blocks"
    for block in ram cpu kbd vol net time; do
        if [ -f "$SCRIPT_DIR/blocks/$block" ]; then
            cp "$SCRIPT_DIR/blocks/$block" "$HOME/.local/bin/blocks/"
            chmod +x "$HOME/.local/bin/blocks/$block"
        fi
    done

    # Копируем скрипты
    mkdir -p "$HOME/.local/bin/scripts"
    for script in kbd-toggle vol-toggle; do
        if [ -f "$SCRIPT_DIR/scripts/$script" ]; then
            cp "$SCRIPT_DIR/scripts/$script" "$HOME/.local/bin/scripts/"
            chmod +x "$HOME/.local/bin/scripts/$script"
        fi
    done

    ok "dwmblocks установлен"
}

# Установка polybar
install_polybar() {
    info "Установка polybar..."
    
    # Проверяем установлен ли polybar
    if command -v polybar &>/dev/null; then
        ok "polybar уже установлен"
        return 0
    fi
    
    # Установка из репозитория
    if command -v pacman &>/dev/null; then
        sudo pacman -S polybar --noconfirm
    fi
    
    # Копируем конфиг
    mkdir -p "$HOME/.config/polybar"
    if [ -f "$SCRIPT_DIR/config/polybar/config.ini" ]; then
        cp "$SCRIPT_DIR/config/polybar/config.ini" "$HOME/.config/polybar/"
    fi
    
    # Копируем скрипт запуска
    if [ -f "$SCRIPT_DIR/scripts/polybar-launch" ]; then
        cp "$SCRIPT_DIR/scripts/polybar-launch" "$HOME/.local/bin/scripts/"
        chmod +x "$HOME/.local/bin/scripts/polybar-launch"
    fi
    
    # Установка шрифтов
    if command -v pacman &>/dev/null; then
        sudo pacman -S ttf-font-awesome --noconfirm 2>/dev/null || true
    fi
    
    ok "polybar установлен"
}

# Установка зависимостей для статуса
install_status_deps() {
    info "Проверка зависимостей для статуса..."
    
    local deps=("wpctl" "brightnessctl" "playerctl" "lm_sensors")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            warn "Не найдено: $dep — статус-бар может не работать"
        fi
    done
}

# Создание .xinitrc
setup_xinitrc() {
    info "Настройка .xinitrc..."
    
    local xinitrc="$HOME/.xinitrc"
    local xsession="$HOME/.xsession"
    
    # Создаём/обновляем .xinitrc
    cat > "$xinitrc" << 'EOF'
#!/bin/bash

# Загрузка переменных
[ -f ~/.profile ] && . ~/.profile

# Запуск автостарта
if [ -f ~/.local/bin/autostart.sh ]; then
    ~/.local/bin/autostart.sh &
fi

# Запуск dwm
exec dwm
EOF
    
    chmod +x "$xinitrc"
    cp "$xinitrc" "$xsession"
    
    ok ".xinitrc настроен"
}

# Основная функция
main() {
    echo "Директория проекта: $SCRIPT_DIR"
    echo ""

    check_deps
    backup
    compile_dwm
    install_dwm
    install_scripts
    install_dwmblocks
    install_status_deps
    install_polybar
    setup_xinitrc
    
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║     ✅ УСТАНОВКА ЗАВЕРШЕНА              ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "Далее:"
    echo "  1. Выйдите из текущей сессии"
    echo "  2. Выберите 'dwm' в sddm/lightdm"
    echo "  3. Или запустите: startx"
    echo ""
    echo "Горячие клавиши:"
    echo "  Super+Enter — терминал (alacritty)"
    echo "  Super+D     — лаунчер (rofi)"
    echo "  Super+1-9   — рабочие столы"
    echo "  Alt+Shift   — переключение RU/EN"
}

main "$@"