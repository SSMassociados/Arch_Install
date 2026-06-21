# Arch_Install

Scripts para instalação e pós-instalação do Arch Linux, com suporte a múltiplos ambientes gráficos.

## 📜 Sobre

Este repositório contém scripts para facilitar a instalação do Arch Linux, cobrindo desde a configuração base do sistema até a instalação de ambientes gráficos completos.

## 📂 Estrutura do Repositório

```
Arch_Install/
├── base.sh        # Configuração base pós-chroot (obrigatório)
├── i3wm.sh        # Pós-instalação com i3wm (X11)
├── hyprland.sh    # Pós-instalação com Hyprland (Wayland)
└── README.md      # Este arquivo
```

## 🚀 Como Usar

### 1️⃣ Instalação do sistema base (Live USB)

Siga o [Arch Installation Guide](https://wiki.archlinux.org/title/Installation_guide) até o passo de `arch-chroot`. Após entrar no chroot, clone o repositório e execute o script base:

```bash
git clone https://github.com/SSMassociados/Arch_Install.git
cd Arch_Install
chmod +x base.sh
./base.sh
```

O `base.sh` configura:
- Fuso horário (`America/Recife`) e locale (`pt_BR.UTF-8`)
- Hostname, `/etc/hosts` e teclado (`br-abnt2`)
- Pacotes essenciais (rede, áudio, Bluetooth, impressão, virtualização, firewall)
- GRUB em modo UEFI (ajuste a variável `EFI_DIR` se necessário)
- Serviços do sistema habilitados
- Usuário `sidiclei` com senha temporária (expirada no primeiro login)

Ao final:
```bash
exit
umount -a
reboot
```

---

### 2️⃣ Pós-instalação — escolha seu ambiente gráfico

Execute **apenas um** dos scripts abaixo após reiniciar e logar com seu usuário.

> ⚠️ Execute como usuário comum com `sudo` disponível — **não como root**.

#### i3wm (X11)
```bash
chmod +x i3wm.sh
./i3wm.sh
```

#### Hyprland (Wayland)
```bash
chmod +x hyprland.sh
./hyprland.sh
```

---

## ⚙️ O que cada script instala

### `base.sh`
| Categoria | Pacotes |
|---|---|
| Boot | grub, efibootmgr |
| Rede | networkmanager, openssh, avahi, dnsutils |
| Áudio | pipewire, pipewire-alsa, pipewire-pulse, pipewire-jack |
| Bluetooth | bluez, bluez-utils |
| Impressão | cups, hplip |
| Virtualização | virt-manager, qemu-full, libvirt |
| Firewall | firewalld, iptables |
| Sistema | base-devel, reflector, tlp, flatpak |

### `i3wm.sh`
| Categoria | Destaques |
|---|---|
| WM | i3-wm, polybar, rofi, picom, dunst |
| Terminal | kitty |
| Arquivos | thunar + plugins |
| Display Manager | lightdm + gtk-greeter |
| Shell | zsh |
| AUR | yay |

### `hyprland.sh`
| Categoria | Destaques |
|---|---|
| Compositor | hyprland, hyprlock, hypridle, hyprpaper |
| Bar / Launcher | waybar, rofi-wayland |
| Notificações | mako, swaync |
| Terminal | kitty |
| Arquivos | dolphin + plugins |
| Display Manager | sddm |
| Shell | zsh |
| AUR | yay |

---

## 📌 Requisitos

- Conexão com a internet
- Boot em modo UEFI (partição EFI montada — padrão em `/boot/efi`)
- Live USB do Arch Linux
- Para `i3wm.sh` e `hyprland.sh`: usuário com `sudo` configurado

## ⚠️ Atenção

- As senhas definidas pelo `base.sh` são temporárias (`password`) e **expiram no primeiro login**
- O `base.sh` instala o GRUB apontando para `/boot/efi` por padrão — edite a variável `EFI_DIR` no topo do script se sua partição EFI estiver em `/boot`
- Para GPUs AMD ou NVIDIA, descomente o bloco de drivers correspondente no `base.sh`
- O bloco de pacotes AUR no `hyprland.sh` está comentado por padrão — descomente o que quiser instalar

## 🤝 Contribuição

Abra uma **issue** ou envie um **pull request** com sugestões e melhorias.

## 📜 Licença

Este projeto está sob a licença MIT. Consulte o arquivo `LICENSE` para mais detalhes.
