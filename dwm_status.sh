#!/bin/bash
# dwm_status.sh — Статус-бар для dwm (миграция с Waybar)
# Выводит: [иконка][workspace] [RAM] [CPU°] ... [клава][🔊][сеть][время][⏻]

# Цвета Catppuccin Macchiato
COLOR_BG="#1e1e2e"
COLOR_FG="#cdd6f4"
COLOR_BLUE="#89b4fa"
COLOR_GREEN="#a6e3a1"
COLOR_YELLOW="#f9e2af"
COLOR_PINK="#f5c2e7"
COLOR_MAUVE="#cba6f7"
COLOR_TEAL="#94e2d5"
COLOR_RED="#f38ba8"
COLOR_PEACH="#fab387"

# Иконки (Nerd Font)
ICON_DISTRO=""      # Арка
ICON_RAM="󰍛"        # память
ICON_CPU=""         # температура
ICON_KBD=""         # раскладка
ICON_SPK_LOW=""     # звук
ICON_SPK_MED=""
ICON_SPK_HIGH=""
ICON_MUTED="婢"
ICON_WIFI=""
ICON_ETH="󰈀"
ICON_DISCON="⚠"
ICON_POWER="⏻"

# Обновление каждые 5 секунд
while true; do
    # --- RAM ---
    mem_used=$(free -m | awk '/Mem:/ {print $3}')
    ram="${ICON_RAM} ${mem_used}G"

    # --- CPU Temperature ---
    cpu_temp=$(sensors 2>/dev/null | grep 'Package id 0' | awk '{print $4}' | sed 's/+//;s/°C//' || echo "N/A")
    cpu="${ICON_CPU} ${cpu_temp}°C"

    # --- Keyboard Layout (setxkbmap) ---
    kbd=$(setxkbmap -query 2>/dev/null | grep layout | awk '{print $2}' | tr '[:lower:]' '[:upper:]' || echo "EN")
    kbd_icon="${ICON_KBD} ${kbd}"

    # --- Volume (pulseaudio) ---
    vol_status=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
    if echo "$vol_status" | grep -q "MUTED"; then
        volume="${ICON_MUTED}"
    else
        vol_val=$(echo "$vol_status" | awk '{print int($2*100)}')
        if [ "$vol_val" -lt 33 ]; then
            volume="${ICON_SPK_LOW} ${vol_val}%"
        elif [ "$vol_val" -lt 66 ]; then
            volume="${ICON_SPK_MED} ${vol_val}%"
        else
            volume="${ICON_SPK_HIGH} ${vol_val}%"
        fi
    fi

    # --- Network ---
    if ping -c 1 8.8.8.8 -W 1 >/dev/null 2>&1; then
        if command -v iwconfig &>/dev/null && iwconfig 2>/dev/null | grep -q "ESSID"; then
            network="${ICON_WIFI}"
        else
            network="${ICON_ETH}"
        fi
    else
        network="${ICON_DISCON}"
    fi

    # --- Time ---
    time_str=$(date "+%H:%M | %d %b")

    # --- Power (Battery) ---
    battery=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
    if [ -n "$battery" ]; then
        if [ "$battery" -lt 20 ]; then
            power="${ICON_POWER} ${battery}%"
        else
            power="${ICON_POWER}"
        fi
    else
        power="${ICON_POWER}"
    fi

    # --- Сборка строки ---
    # Левая часть: иконка дистро + workspaces (генерируется dwm)
    # Правая часть: RAM | CPU | KBD | VOL | NET | TIME | POWER
    status_right="  ${ram}  ${cpu}  ${kbd_icon}  ${volume}  ${network}  ${time_str}  ${power}"

    xsetroot -name "$status_right"

    sleep 5
done
