#!/bin/bash

# Fonction pour afficher un message d'erreur détaillé et quitter
function handle_error {
    whiptail --msgbox "Erreur: $1" 10 60
    exit 1
}

# Désactiver SELinux
function disable_selinux {
    whiptail --infobox "Désactivation de SELinux..." 8 40
    sudo sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config || handle_error "Échec de la modification de la configuration SELinux"
    whiptail --msgbox "SELinux a été désactivé. Un redémarrage est nécessaire pour appliquer les modifications." 8 60
    
    # Redémarrage proposé uniquement si cette fonction est appelée individuellement
    if [[ "$1" != "batch" ]]; then
        ask_for_reboot
    fi
}

# Mettre à jour le système
function update_system {
    whiptail --infobox "Mise à jour du système..." 8 40
    sudo dnf -y update || handle_error "Échec de la mise à jour du système"
    
    # Redémarrage proposé uniquement si cette fonction est appelée individuellement
    if [[ "$1" != "batch" ]]; then
        ask_for_reboot
    fi
}

# Vérifier si un outil est déjà installé
function check_if_installed {
    if rpm -q "$1" > /dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

# Installer les outils sélectionnés
function install_tools {
    local options=(
        wget "Downloader" OFF
        curl "Command-line URL tool" OFF
        unzip "Unarchiver" OFF
        tar "Archiver" OFF
        nano "Text Editor" OFF
        vim "Advanced Text Editor" OFF
        python3 "Programming Language" OFF
        net-tools "Network Tools" OFF
        nmap "Network Mapper" OFF
        telnet "Telnet Client" OFF
        mlocate "File Locator" OFF
        open-vm-tools "VMware Tools" OFF
    )

    choices=$(whiptail --title "Choix des outils" --checklist \
    "Sélectionnez les outils à installer:" 20 78 12 "${options[@]}" 3>&1 1>&2 2>&3)

    if [ -z "$choices" ]; then
        whiptail --msgbox "Aucun outil sélectionné pour l'installation." 8 40
    else
        local tools_to_install=($choices)
        local already_installed_tools=()
        for tool in "${tools_to_install[@]}"; do
            if check_if_installed "$tool"; then
                whiptail --infobox "Installation de $tool..." 8 40
                if ! sudo dnf install -y "$tool"; then
                    handle_error "Échec de l'installation de $tool"
                fi
            else
                already_installed_tools+=("$tool")
            fi
        done

        if [ ${#already_installed_tools[@]} -gt 0 ]; then
            whiptail --msgbox "Les outils suivants sont déjà installés:\n\n${already_installed_tools[*]}" 12 60
        fi
    fi
}

# Installer tous les outils
function install_all_tools {
    local tools=("wget" "curl" "unzip" "tar" "nano" "vim" "python3" "net-tools" "nmap" "telnet" "mlocate" "open-vm-tools" "gh")
    local already_installed_tools=()
    
    for tool in "${tools[@]}"; do
        if check_if_installed "$tool"; then
            whiptail --infobox "Installation de $tool..." 8 40
            if ! sudo dnf install -y "$tool"; then
                handle_error "Échec de l'installation de $tool"
            fi
        else
            already_installed_tools+=("$tool")
        fi
    done

    if [ ${#already_installed_tools[@]} -gt 0 ]; then
        whiptail --msgbox "Les outils suivants sont déjà installés:\n\n${already_installed_tools[*]}" 12 60
    fi
}

# Cloner le dépôt et configurer Git
function setup_git_repo {
    whiptail --infobox "Configuration du gestionnaire de paquets et clonage du dépôt..." 8 40

    # Installer le plugin de gestionnaire de paquets
    sudo dnf install -y 'dnf-command(config-manager)' || handle_error "Échec de l'installation du gestionnaire de configurations DNF"

    # Ajouter le dépôt
    sudo dnf config-manager --add-repo git@github.com:Sakazuya/ScriptBash.git || handle_error "Échec de l'ajout du dépôt"

    # Ajouter la clé privée SSH
    mkdir -p ~/.ssh
    echo "-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACAQhnAwuC3gI8LqFDGWZDbftX05eyt6K07bLLv3CZ3kqQAAAKCComsSgqJr
EgAAAAtzc2gtZWQyNTUxOQAAACAQhnAwuC3gI8LqFDGWZDbftX05eyt6K07bLLv3CZ3kqQ
AAAEAL8f18PvQnOmHAcxYIvti+AC+VzA3wPjwOZbRSwvvWzBCGcDC4LeAjwuoUMZZkNt+1
fTl7K3orTtssu/cJneSpAAAAFnNhYWRiZWxmcXVpaEBnbWFpbC5jb20BAgMEBQYH
-----END OPENSSH PRIVATE KEY-----" > ~/.ssh/id_ed25519
    chmod 600 ~/.ssh/id_ed25519

    # Configurer Git
    git config --global user.email "saadbelfquih@gmail.com"
    git config --global user.name "sakazuya"

    # Cloner le dépôt
    git clone git@github.com:Sakazuya/ScriptBash.git || handle_error "Échec du clonage du dépôt"
}

# Mettre à jour la base de données locate
function update_locate_db {
    whiptail --infobox "Mise à jour de la base de données locate..." 8 40
    sudo updatedb || handle_error "Échec de la mise à jour de la base de données locate"
}

# Demander un redémarrage si nécessaire
function ask_for_reboot {
    if whiptail --yesno "Voulez-vous redémarrer maintenant ?" 8 40; then
        sudo reboot
    else
        whiptail --msgbox "Veuillez redémarrer le système ultérieurement pour appliquer les modifications." 8 60
    fi
}

# Fonction principale
function main {
    local choice
    choice=$(whiptail --title "Menu Principal" --menu "Choisissez une option:" 20 60 10 \
    "1" "Mettre à jour le système" \
    "2" "Désactiver SELinux" \
    "3" "Installer les outils" \
    "4" "Mettre à jour la base de données locate" \
    "5" "Tout faire" \
    "6" "Configurer Git et cloner le dépôt" \
    "7" "Quitter" 3>&1 1>&2 2>&3)

    case "$choice" in
        1)
            update_system
            ;;
        2)
            disable_selinux
            ;;
        3)
            install_tools
            ;;
        4)
            update_locate_db
            ;;
        5)
            update_system batch
            disable_selinux batch
            install_all_tools
            setup_git_repo
            update_locate_db
            ask_for_reboot
            ;;
        6)
            setup_git_repo
            ;;
        7)
            whiptail --msgbox "Quitter." 8 40
            exit 0
            ;;
        *)
            whiptail --msgbox "Option invalide. Veuillez choisir une option valide." 8 40
            ;;
    esac
}

# Boucle pour garder l'interface active jusqu'à ce que l'utilisateur choisisse de quitter
while true; do
    main
done
