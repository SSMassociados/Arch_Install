#!/bin/bash

# =============================================================================
# i3wm.sh — Instalação do i3wm e ambiente gráfico para Arch Linux
# Executar como usuário comum com sudo disponível (NÃO como root direto)
# =============================================================================

set -euo pipefail
LOGFILE="$HOME/i3wm-install.log"
exec > >(tee -a "$LOGFILE") 2>&1

# -----------------------------------------------------------------------------
# Verificação: não rodar como root puro
# -----------------------------------------------------------------------------
if [ "$EUID" -eq 0 ] && [ -z "${SUDO_USER:-}" ]; then
    echo "Erro: Execute este script como usuário comum com sudo, não como root."
    echo "Exemplo: bash i3wm.sh"
    exit 1
fi

# Usuário real (funciona com ou sem sudo)
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(eval echo "~$TARGET_USER")

# -----------------------------------------------------------------------------
# Funções auxiliares
# -----------------------------------------------------------------------------
log() { echo "[$(date '+%H:%M:%S')] $*"; }

# -----------------------------------------------------------------------------
# Sistema base
# -----------------------------------------------------------------------------
log "Sincronizando horário..."
sudo timedatectl set-ntp true
sudo hwclock --systohc
sudo systemctl enable --now fstrim.timer

# -----------------------------------------------------------------------------
# Pacman — otimizações
# -----------------------------------------------------------------------------
log "Configurando pacman..."
sudo sed -i \
    -e 's/^#\(CleanMethod\)/\1/' \
    -e 's/^#\(VerbosePkgLists\)/\1/' \
    -e 's/^#\(Color\)/\1/' \
    -e 's/^#\(ParallelDownloads *= *\).*/\1 10/' \
    -e 's/^ParallelDownloads *= *.*/ParallelDownloads = 10/' \
    /etc/pacman.conf

grep -q '^ILoveCandy$' /etc/pacman.conf \
    || sudo sed -i '/^ParallelDownloads = 10$/ a ILoveCandy' /etc/pacman.conf

# Habilitar multilib
sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
sudo pacman -Sy

# -----------------------------------------------------------------------------
# Mirrors
# -----------------------------------------------------------------------------
log "Atualizando mirrors..."
sudo pacman -S --noconfirm --needed reflector
sudo systemctl enable --now reflector.timer
sudo reflector -l 7 -a 24 -p https --sort rate --save /etc/pacman.d/mirrorlist
sudo pacman -Sy

# -----------------------------------------------------------------------------
# YAY — AUR helper (deve rodar como usuário, não root)
# -----------------------------------------------------------------------------
log "Instalando yay..."
if ! command -v yay &>/dev/null; then
    sudo pacman -S --noconfirm --needed go git base-devel
    BUILD_DIR=$(sudo -u "$TARGET_USER" mktemp -d)
    sudo -u "$TARGET_USER" git clone https://aur.archlinux.org/yay.git "$BUILD_DIR/yay"
    cd "$BUILD_DIR/yay"
    sudo -u "$TARGET_USER" makepkg --noconfirm -si
    cd /
    rm -rf "$BUILD_DIR"
fi

# -----------------------------------------------------------------------------
# Xorg e i3wm
# -----------------------------------------------------------------------------
log "Instalando Xorg e i3wm..."
sudo pacman -S --noconfirm --needed \
    xorg xorg-xinit \
    i3-wm dmenu feh rofi rofi-emoji picom dunst \
    autorandr polybar brightnessctl playerctl \
    lxappearance-gtk3 xclip numlockx \
    xdg-desktop-portal xdg-desktop-portal-gtk \  # gtk em vez de gnome (evita deps desnecessárias)
    mission-center mugshot python-pywal qt5ct

# -----------------------------------------------------------------------------
# Aplicações essenciais
# -----------------------------------------------------------------------------
log "Instalando aplicações..."
sudo pacman -S --noconfirm --needed \
    kitty kitty-terminfo \
    man-db man-pages-pt_br \
    tmate \
    thunar thunar-archive-plugin thunar-media-tags-plugin \
    thunar-shares-plugin thunar-volman \
    ranger \
    firefox firefox-i18n-pt-br \
    qbittorrent atril flameshot keepassxc \
    geany neovim fastfetch btop \
    mpv vlc amberol

# -----------------------------------------------------------------------------
# Fontes
# -----------------------------------------------------------------------------
log "Instalando fontes..."
sudo pacman -S --noconfirm --needed \
    ttf-dejavu ttf-liberation ttf-ubuntu-font-family \
    ttf-fira-code ttf-font-awesome \
    noto-fonts noto-fonts-emoji

# -----------------------------------------------------------------------------
# Filesystem e dispositivos de armazenamento
# -----------------------------------------------------------------------------
log "Instalando suporte a filesystems..."
sudo pacman -S --noconfirm --needed \
    os-prober intel-ucode dosfstools mtools \
    freetype2 libisoburn fuse2 ntfs-3g e2fsprogs \
    gvfs gvfs-mtp gvfs-gphoto2 gvfs-afc gvfs-smb \
    udisks2 polkit-gnome ifuse

# -----------------------------------------------------------------------------
# Compactadores
# -----------------------------------------------------------------------------
log "Instalando compactadores..."
sudo pacman -S --noconfirm --needed \
    file-roller cabextract zip lhasa p7zip unrar \
    unarchiver unzip unace xz arj unarj tar gzip bzip2 ncompress

# -----------------------------------------------------------------------------
# Áudio
# -----------------------------------------------------------------------------
log "Configurando áudio..."
sudo pacman -S --noconfirm --needed \
    pipewire pipewire-alsa pipewire-pulse pipewire-jack \
    wireplumber helvum pavucontrol sof-firmware

# -----------------------------------------------------------------------------
# Codecs de mídia
# -----------------------------------------------------------------------------
log "Instalando codecs..."
sudo pacman -S --noconfirm --needed \
    gst-libav \
    gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly \
    gstreamer-vaapi \
    x265 x264 libmad libde265 libdv \
    libdvdcss libdvdread libdvdnav libvorbis \
    lame faac faad2 flac a52dec \
    dvd+rw-tools dvdauthor dvgrab

# -----------------------------------------------------------------------------
# Bluetooth
# -----------------------------------------------------------------------------
log "Configurando Bluetooth..."
sudo pacman -S --noconfirm --needed bluez bluez-utils blueman
sudo systemctl enable --now bluetooth

# -----------------------------------------------------------------------------
# Impressão e scan
# -----------------------------------------------------------------------------
log "Instalando impressão..."
sudo pacman -S --noconfirm --needed \
    avahi nss-mdns cups cups-pdf libcups \
    print-manager system-config-printer simple-scan

# -----------------------------------------------------------------------------
# ADB e SCRCPY
# -----------------------------------------------------------------------------
log "Instalando ADB/SCRCPY..."
sudo pacman -S --noconfirm --needed scrcpy android-tools android-udev
sudo usermod -aG adbusers "$TARGET_USER"

# -----------------------------------------------------------------------------
# ZSH
# -----------------------------------------------------------------------------
log "Instalando ZSH..."
sudo pacman -S --noconfirm --needed zsh zsh-completions
sudo chsh -s /usr/bin/zsh "$TARGET_USER"

# -----------------------------------------------------------------------------
# Ferramentas de desenvolvimento
# -----------------------------------------------------------------------------
log "Instalando ferramentas de desenvolvimento..."
sudo pacman -S --noconfirm --needed git base-devel python python-pip nodejs npm

# -----------------------------------------------------------------------------
# Suíte de escritório
# -----------------------------------------------------------------------------
log "Instalando LibreOffice..."
sudo pacman -S --noconfirm --needed \
    libreoffice-still libreoffice-still-pt-br \
    jre8-openjdk libmythes breeze-gtk

# -----------------------------------------------------------------------------
# LightDM
# -----------------------------------------------------------------------------
log "Instalando LightDM..."
sudo pacman -S --noconfirm --needed \
    lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
sudo systemctl enable lightdm

# Nota: com LightDM ativo, o i3 é iniciado pela sessão do greeter.
# O ~/.xinitrc abaixo serve apenas para quem preferir usar `startx` manualmente
# sem display manager. Com LightDM habilitado, o bloco abaixo é ignorado.
if ! grep -q "exec i3" "$TARGET_HOME/.xinitrc" 2>/dev/null; then
    cp /etc/X11/xinit/xinitrc "$TARGET_HOME/.xinitrc"
    echo "exec i3" >> "$TARGET_HOME/.xinitrc"
    chmod +x "$TARGET_HOME/.xinitrc"
    chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.xinitrc"
fi

# -----------------------------------------------------------------------------
# Fim
# -----------------------------------------------------------------------------
log "Instalação concluída! Log salvo em: $LOGFILE"
read -rp "Reiniciar agora? (s/n): " resposta
if [[ "$resposta" =~ ^[sS]$ ]]; then
    sudo reboot
fi
