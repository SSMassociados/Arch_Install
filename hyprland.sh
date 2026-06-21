#!/bin/bash

# =============================================================================
# hyprland.sh — Instalação do Hyprland para Arch Linux
# Executar como usuário comum com sudo disponível (NÃO como root direto)
#
# Referências:
#   Dotfiles:  https://github.com/devk0n/fyrefiles
#   Config:    https://github.com/gaurav23b/simple-hyprland
#   Guia:      https://tiesen.id.vn/blogs/arch-linux-hyprland-setup
# =============================================================================

set -euo pipefail
LOGFILE="$HOME/hyprland-install.log"
exec > >(tee -a "$LOGFILE") 2>&1

# -----------------------------------------------------------------------------
# Verificação: não rodar como root puro
# -----------------------------------------------------------------------------
if [ "$EUID" -eq 0 ] && [ -z "${SUDO_USER:-}" ]; then
    echo "Erro: Execute este script como usuário comum com sudo, não como root."
    echo "Exemplo: bash hyprland.sh"
    exit 1
fi

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
    sudo pacman -S --noconfirm --needed git base-devel
    BUILD_DIR=$(sudo -u "$TARGET_USER" mktemp -d)
    sudo -u "$TARGET_USER" git clone https://aur.archlinux.org/yay.git "$BUILD_DIR/yay"
    cd "$BUILD_DIR/yay"
    sudo -u "$TARGET_USER" makepkg --noconfirm -si
    cd /
    rm -rf "$BUILD_DIR"
fi

# -----------------------------------------------------------------------------
# Hyprland e componentes Wayland
# -----------------------------------------------------------------------------
log "Instalando Hyprland..."
sudo pacman -S --noconfirm --needed \
    hyprland hyprlock hypridle hyprcursor hyprpaper hyprpicker hyprpolkitagent \
    waybar rofi-wayland \
    qt5-wayland qt6-wayland \
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
    wl-clipboard cliphist \
    xdg-user-dirs-gtk \
    mako \        # notificações nativas Wayland (substituiu dunst)
    swaync        # alternativa ao mako com painel de notificações

# Nota: hyprpolkitagent precisa ser iniciado na config do Hyprland:
# exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
# ou, para hyprpolkitagent:
# exec-once = systemctl --user start hyprpolkitagent

# -----------------------------------------------------------------------------
# Aplicações essenciais
# -----------------------------------------------------------------------------
log "Instalando aplicações..."
sudo pacman -S --noconfirm --needed \
    kitty kitty-terminfo \
    man-db man-pages-pt_br \
    tmate \
    dolphin dolphin-plugins \
    ranger \
    firefox firefox-i18n-pt-br \
    qbittorrent atril flameshot keepassxc \
    geany neovim fastfetch htop \
    mpv vlc amberol \
    obs-studio

# -----------------------------------------------------------------------------
# Aparência e temas
# -----------------------------------------------------------------------------
log "Instalando temas e ferramentas de aparência..."
sudo pacman -S --noconfirm --needed \
    qt5ct qt6ct kvantum nwg-look brightnessctl

# -----------------------------------------------------------------------------
# Fontes
# -----------------------------------------------------------------------------
log "Instalando fontes..."
sudo pacman -S --noconfirm --needed \
    noto-fonts noto-fonts-cjk noto-fonts-emoji \
    ttf-dejavu ttf-droid \
    ttf-fira-code ttf-fira-sans ttf-firacode-nerd \
    ttf-font-awesome \
    ttf-jetbrains-mono-nerd \
    ttf-liberation ttf-opensans ttf-roboto \
    ttf-ubuntu-font-family

# -----------------------------------------------------------------------------
# Filesystem e dispositivos de armazenamento
# -----------------------------------------------------------------------------
log "Instalando suporte a filesystems..."
sudo pacman -S --noconfirm --needed \
    os-prober intel-ucode dosfstools mtools \
    freetype2 libisoburn fuse2 ntfs-3g e2fsprogs \
    gvfs gvfs-mtp gvfs-gphoto2 gvfs-afc gvfs-smb \
    udisks2 ifuse

# -----------------------------------------------------------------------------
# Compactadores
# (ark é apenas o frontend — os backends abaixo são necessários para
#  que os formatos apareçam como suportados na interface)
# -----------------------------------------------------------------------------
log "Instalando compactadores..."
sudo pacman -S --noconfirm --needed \
    ark \
    p7zip unrar unzip zip lhasa \
    cabextract unace xz arj unarj \
    tar gzip bzip2 ncompress

# -----------------------------------------------------------------------------
# Áudio
# -----------------------------------------------------------------------------
log "Configurando áudio..."
sudo pacman -S --noconfirm --needed \
    pipewire pipewire-alsa pipewire-pulse pipewire-jack \
    wireplumber helvum pavucontrol sof-firmware

# Habilitar serviços de áudio para o usuário atual
sudo -u "$TARGET_USER" systemctl --user enable --now \
    pipewire pipewire-pulse wireplumber

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
sudo pacman -S --noconfirm --needed python python-pip nodejs npm jq

# -----------------------------------------------------------------------------
# Suíte de escritório
# -----------------------------------------------------------------------------
log "Instalando LibreOffice..."
sudo pacman -S --noconfirm --needed \
    libreoffice-still libreoffice-still-pt-br \
    jre8-openjdk libmythes breeze-gtk

# -----------------------------------------------------------------------------
# Pacotes AUR (descomente quando quiser instalar)
# -----------------------------------------------------------------------------
# sudo -u "$TARGET_USER" yay -S --noconfirm \
#     hyprshot \
#     wlogout \
#     gview \
#     visual-studio-code-bin \
#     brave-bin

# -----------------------------------------------------------------------------
# SDDM — display manager
# -----------------------------------------------------------------------------
log "Instalando SDDM..."
sudo pacman -S --noconfirm --needed sddm
sudo systemctl enable sddm.service

# -----------------------------------------------------------------------------
# Fim
# -----------------------------------------------------------------------------
log "Instalação concluída! Log salvo em: $LOGFILE"
read -rp "Reiniciar agora? (s/n): " resposta
if [[ "$resposta" =~ ^[sS]$ ]]; then
    sudo reboot
fi
