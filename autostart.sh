#!/bin/bash
# autostart.sh — Автозапуск при старте dwm

# ========== КОМПОЗИТОР (прозрачность) ==========
# picom для прозрачности и эффектов (аналог Niri shadow)
if command -v picom &> /dev/null; then
    picom -b &
fi

# ========== ОБОИ ==========
if command -v nitrogen &> /dev/null; then
    nitrogen --set-zoom-fill ~/Pictures/wallpeper/space.png &
elif command -v feh &> /dev/null; then
    feh --bg-scale ~/Pictures/wallpeper/space.png &
fi

# ========== РАСКЛАДКА КЛАВИАТУРЫ ==========
# Alt+Shift переключение RU/EN (как в Niri)
setxkbmap -layout "us,ru" -option "grp:alt_shift_toggle" &

# ========== NUMLOCK ==========
if command -v numlockx &> /dev/null; then
    numlockx on &
fi

# ========== СТАТУС-БАР (polybar) ==========
~/.local/bin/scripts/polybar-launch &

# ========== ДОПОЛНИТЕЛЬНЫЕ УТИЛИТЫ ==========
# Утилита для клипборда (опционально)
if command -v greenclip &> /dev/null; then
    greenclip daemon &
fi

# Правила xrandr (если несколько мониторов) — раскомментируй и настрой
# xrandr --output HDMI-1 --mode 1920x1080 --right-of eDP-1 &

echo "autostart.sh: done"