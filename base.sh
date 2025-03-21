#!/bin/bash

ln -sf /usr/share/zoneinfo/America/Recife /etc/localtime
hwclock --systohc
#sed -i '387s/.//' /etc/locale.gen
sed -i '/^#pt_BR.UTF-8/s/^#//' /etc/locale.gen
locale-gen
echo "LANG=pt_BR.UTF-8" >> /etc/locale.conf
echo "KEYMAP=br-abnt2" >> /etc/vconsole.conf
echo "arch" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 arch.localdomain arch" >> /etc/hosts
echo root:password | chpasswd
passwd -e root

# Você pode adicionar o xorg aos pacotes de instalação, eu geralmente adiciono no script de instalação do DE ou WM
# Você pode remover o pacote tlp se estiver instalando em um Desktop ou VM

pacman -S --noconfirm --needed grub efibootmgr networkmanager network-manager-applet dialog wpa_supplicant mtools dosfstools base-devel linux-headers avahi xdg-user-dirs xdg-utils gvfs gvfs-smb nfs-utils inetutils dnsutils bluez bluez-utils cups hplip alsa-utils pipewire pipewire-alsa pipewire-pulse pipewire-jack bash-completion openssh rsync reflector acpi acpi_call tlp virt-manager qemu-full edk2-ovmf bridge-utils dnsmasq vde2 openbsd-netcat iptables-nft ipset firewalld flatpak sof-firmware nss-mdns acpid os-prober ntfs-3g terminus-font

# Só decomente a proxima linha se seu PC for legado, for usar modo BIOS/MBR (legado),
# pacman -S --noconfirm --needed grub net workmanager network-manager-applet dialog wpa_supplicant mtools dosfstools reflector base-devel linux-headers avahi xdg-user-dirs xdg-utils gvfs gvfs-smb nfs-utils inetutils dnsutils bluez bluez-utils cups hplip alsa-utils pulseaudio bash-completion openssh rsync reflector acpi acpi_call tlp virt-manager qemu-full edk2-ovmf bridge-utils dnsmasq vde2 openbsd-netcat iptables-nft ipset firewalld flatpak sof-firmware nss-mdns acpid os-prober ntfs-3g terminus-font

# Instalação do driver de vídeo para GPUs AMD
# pacman -S --noconfirm xf86-video-amdgpu
# Instalação dos drivers e utilitários da NVIDIA
# pacman -S --noconfirm nvidia nvidia-utils nvidia-settings

# Instala o GRUB no modo UEFI. Altere o diretório para /boot/efi se você montou a partição EFI em /boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB 

# Só decomente a proxima linha se desejar instalar o GRUB no modo BIOS/MBR (legado), substituindo sdX pelo nome do disco,não pela partição
# grub-install --target=i386-pc /dev/sdX .
 
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable sshd
systemctl enable avahi-daemon
systemctl enable tlp # Você pode comentar este comando se não instalou o tlp, veja acima
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable libvirtd
systemctl enable firewalld
systemctl enable acpid

useradd -mG wheel sidiclei
echo sidiclei:password | chpasswd
passwd -e sidiclei
usermod -aG libvirt sidiclei

echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/sidiclei

printf "\e[1;32mDone! Type exit, umount -a and reboot.\e[0m"




