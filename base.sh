#!/bin/bash

# Configurações de depuração
set -euo pipefail  # Garante que o script pare em qualquer erro
set -x  # Ativa modo de depuração para ver comandos executados

LOGFILE="script.log"
exec > >(tee -a "$LOGFILE") 2>&1  # Salva logs da execução

# Função para verificar se um comando falhou
check_error() {
    if [ $? -ne 0 ]; then
        echo "Erro: Comando falhou - $1"
        echo "Consulte o log: $LOGFILE"
        exit 1
    fi
}

# Configuração do fuso horário
ln -sf /usr/share/zoneinfo/America/Recife /etc/localtime
hwclock --systohc

# Descomentar pt_BR.UTF-8 no locale.gen
sed -i '/^#pt_BR.UTF-8/s/^#//' /etc/locale.gen
locale-gen

# Garantir que LANG esteja correto sem duplicar
echo "LANG=pt_BR.UTF-8" | tee /etc/locale.conf

# Garantir que KEYMAP esteja correto sem duplicar
echo "KEYMAP=br-abnt2" | tee /etc/vconsole.conf

# Configurar hostname sem duplicar
echo "arch" | tee /etc/hostname

# Configurar /etc/hosts sem duplicação
grep -qxF "127.0.0.1 localhost" /etc/hosts || echo "127.0.0.1 localhost" >> /etc/hosts
grep -qxF "::1       localhost" /etc/hosts || echo "::1       localhost" >> /etc/hosts
grep -qxF "127.0.1.1 arch.localdomain arch" /etc/hosts || echo "127.0.1.1 arch.localdomain arch" >> /etc/hosts

# Configurar senha root apenas se não estiver definida
if [ "$(passwd -S root | awk '{print $2}')" != "P" ]; then
    echo "root:password" | chpasswd
    passwd -e root
fi

# Você pode adicionar o xorg aos pacotes de instalação, eu geralmente adiciono no script de instalação do DE ou WM
# Você pode remover o pacote tlp se estiver instalando em um Desktop ou VM
# Instalar pacotes necessários sem reinstalar desnecessariamente
pacman -S --noconfirm --needed grub efibootmgr networkmanager network-manager-applet \
dialog wpa_supplicant mtools dosfstools base-devel linux-headers avahi xdg-user-dirs \
xdg-utils gvfs gvfs-smb nfs-utils inetutils dnsutils bluez bluez-utils cups hplip \
alsa-utils pipewire pipewire-alsa pipewire-pulse pipewire-jack bash-completion openssh \
rsync reflector acpi acpi_call tlp virt-manager qemu-full edk2-ovmf bridge-utils dnsmasq \
vde2 openbsd-netcat iptables ipset firewalld flatpak sof-firmware nss-mdns acpid \
os-prober ntfs-3g terminus-font

# Só decomente a proxima linha se seu PC for legado, for usar modo BIOS/MBR (legado),
#pacman -S --noconfirm --needed grub networkmanager network-manager-applet dialog \
#wpa_supplicant mtools dosfstools reflector base-devel linux-headers avahi xdg-user-dirs xdg-utils \
#gvfs gvfs-smb nfs-utils inetutils dnsutils bluez bluez-utils cups hplip alsa-utils pulseaudio bash-completion \
#openssh rsync reflector acpi acpi_call tlp virt-manager qemu-full edk2-ovmf bridge-utils dnsmasq vde2 \
#openbsd-netcat iptables ipset firewalld flatpak sof-firmware nss-mdns acpid os-prober ntfs-3g terminus-font

# Instalação do driver de vídeo para GPUs AMD
# pacman -S --noconfirm xf86-video-amdgpu
# Instalação dos drivers e utilitários da NVIDIA
# pacman -S --noconfirm nvidia nvidia-utils nvidia-settings

# Grub DualBoot
sed -i 's/^#*GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub

# Instala o GRUB no modo UEFI. Altere o diretório para /boot/efi se você montou a partição EFI em /boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB 

# Só decomente a proxima linha se desejar instalar o GRUB no modo BIOS/MBR (legado), substituindo sdX pelo nome do disco,não pela partição
# grub-install --target=i386-pc /dev/sdX .

grub-mkconfig -o /boot/grub/grub.cfg

# Habilitar serviços (não há problema em rodar várias vezes)
systemctl enable NetworkManager bluetooth cups.service sshd avahi-daemon tlp \
reflector.timer fstrim.timer libvirtd firewalld acpid

# Criar usuário "sidiclei" apenas se ele ainda não existir
if ! id "sidiclei" &>/dev/null; then
    useradd -mG wheel,libvirt sidiclei
    echo "sidiclei:password" | chpasswd
    passwd -e sidiclei
fi

# Adicionar sudo ao usuário do grupo wheel
# Adicionar ao sudoers privilégio de sudo para um comando e um usário específico
cat << EOF | sudo tee /etc/sudoers.d/sidiclei
%wheel ALL=(ALL:ALL) ALL
sidiclei ALL=(ALL) NOPASSWD: /usr/bin/grub-reboot, /usr/bin/systemctl reboot
EOF

# Mensagem final
echo "Instalação concluída! Verifique o arquivo de log para detalhes: $LOGFILE"
printf "\e[1;32mPronto! Digite exit, umount -a e reinicie.\e[0m\n"
