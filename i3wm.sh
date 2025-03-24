#!/bin/bash

# Configurações de depuração
set -e  # Encerra o script se algum comando falhar
set -x  # Habilita o modo de depuração
LOGFILE="script.log"
exec > >(tee -a "$LOGFILE") 2>&1  # Redireciona saída e erros para o arquivo de log

# Função para verificar erros
check_error() {
    if [ $? -ne 0 ]; then
        echo "Erro: Comando falhou - $1"
        echo "Consulte o arquivo de log para mais detalhes: $LOGFILE"
        exit 1  # Encerra o script em caso de erro crítico
    fi
}

# Configuração básica do sistema
sudo timedatectl set-ntp true
sudo hwclock --systohc

# Fstrim
sudo systemctl enable --now fstrim.timer

# Ativar VerbosePkgLists, ParallelDownloads, Color e ILoveCandy
sudo sed -i '/^#VerbosePkgLists/s/^#//' /etc/pacman.conf
sudo sed -i 's/^#\(ParallelDownloads *= *\).*/\110/; s/^ParallelDownloads *= *.*/ParallelDownloads = 10/' /etc/pacman.conf
sudo sed -i '/^#Color/s/^#//' /etc/pacman.conf

# Adicionar ILoveCandy logo após ParallelDownloads
if ! grep -q "ILoveCandy" /etc/pacman.conf; then
    sed -i '/ParallelDownloads/a ILoveCandy' /etc/pacman.conf
fi

# Descomentar o repositório multilib
sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf && sudo pacman -Sy

# Atualizar mirrorlist para obter os melhores mirrors
sudo pacman -S --noconfirm --needed reflector
sudo systemctl enable --now reflector.timer
sudo reflector -l 7 -a 24 -p https --sort rate --save /etc/pacman.d/mirrorlist
sudo pacman -Sy

# Configuração do firewall (opcional)
#sudo firewall-cmd --add-port=1025-65535/tcp --permanent
#sudo firewall-cmd --add-port=1025-65535/udp --permanent
#sudo firewall-cmd --reload

# Instalação do YAY (helper AUR)
sudo pacman -S --noconfirm --needed go
if ! command -v yay &> /dev/null; then
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg --noconfirm -s
    sudo pacman -U --noconfirm yay*.pkg.tar.zst
    cd ..
    rm -rf yay
fi

# Instalação do Xorg e i3wm
sudo pacman -S --noconfirm --needed xorg xorg-xinit i3-wm dmenu feh rofi rofi-emoji picom dunst autorandr polybar brightnessctl playerctl lxappearance-gtk3 mission-center xclip xdg-desktop-portal-gnome mugshot numlockx python-pywal qt5ct 

# Instalação de aplicações essenciais
sudo pacman -S --noconfirm --needed kitty kitty-terminfo man-db man-pages-pt_br tmate thunar thunar-archive-plugin thunar-media-tags-plugin thunar-shares-plugin thunar-volman ranger firefox firefox-i18n-pt-br qbittorrent atril flameshot keepassxc geany neovim neofetch htop arc-gtk-theme arc-icon-theme mpv vlc amberol obs-studio 

# Fontes para melhorar a aparência e compatibilidade
sudo pacman -S --noconfirm --needed ttf-dejavu ttf-liberation ttf-ubuntu-font-family ttf-fira-code ttf-font-awesome noto-fonts noto-fonts-emoji

# Suporte a sistema de arquivos e ferramentas para manipulação de dispositivos de armazenamento
sudo pacman -S --noconfirm --needed os-prober intel-ucode dosfstools mtools freetype2 libisoburn fuse2 ntfs-3g e2fsprogs gvfs-{mtp,gphoto2,afc,smb} udisks2 polkit-gnome ifuse

# Compactadores e descompactadores
sudo pacman -S --noconfirm --needed file-roller cabextract zip lhasa p7zip unrar unarchiver unzip unace xz arj unarj tar gzip bzip2 ncompress

# Áudio
sudo pacman -S --noconfirm --needed pipewire pipewire-{alsa,pulse,jack} wireplumber helvum pavucontrol sof-firmware

# Codecs de mídia
sudo pacman -S --noconfirm --needed gst-libav gst-plugins-{base,good,bad,ugly} gstreamer-vaapi x265 x264 dvd+rw-tools dvdauthor dvgrab libmad libde265 libdv libdvdcss libdvdread libdvdnav libvorbis lame faac faad2 flac a52dec 

# Bluetooth
sudo pacman -S --noconfirm --needed bluez bluez-utils blueman
sudo systemctl enable --now bluetooth

# Impressão e scan
sudo pacman -S --noconfirm --needed avahi nss-mdns cups cups-pdf libcups print-manager system-config-printer simple-scan

# ADB & SCRCPY
sudo pacman -S --noconfirm --needed scrcpy android-tools android-udev
sudo usermod -aG adbusers $USER

# ZSH
sudo pacman -S --noconfirm --needed zsh zsh-completions 
sudo chsh -s /usr/bin/zsh $USER 

# Ferramentas de desenvolvimento (opcional)
sudo pacman -S --noconfirm --needed git base-devel python python-pip nodejs npm

# Suíte de escritório
sudo pacman -S --noconfirm --needed libreoffice-still libreoffice-still-pt-br jre8-openjdk libmythes breeze-gtk 

# LightDM (gerenciador de login leve)
sudo pacman -S --noconfirm --needed --needed lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
sudo systemctl enable lightdm

# Configuração do i3wm
if ! grep -q "exec i3" ~/.xinitrc; then
    cp /etc/X11/xinit/xinitrc ~/.xinitrc
    echo "exec i3" >> ~/.xinitrc
    chmod +x ~/.xinitrc
fi

# Mensagem final
echo "Instalação concluída! Verifique o arquivo de log para detalhes: $LOGFILE"
read -p "Reiniciar agora? (s/n): " resposta
if [[ "$resposta" =~ ^[sS]$ ]]; then
    sudo reboot
fi
