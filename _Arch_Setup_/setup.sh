#!/bin/bash

#######################
### Functions below ###
#######################

# Print the logo
print_logo() {
    cat << "EOF"
#####################################################
#      _       _  ____ _____                        #
#     / \     | |/ ___|_   _|                       #
#    / _ \ _  | | |     | |                         #
#   / ___ \ |_| | |___  | |    Set up Arch Linux    #
#  /_/   \_\___/ \____| |_|    by AJCT              #
#                                                   #
#####################################################

EOF
}

# Function to check if a package is installed
is_group_installed() {
  pacman -Qg "$1" &> /dev/null
}

# Function to check if a package is installed
is_installed() {
  pacman -Qi "$1" &> /dev/null
}

# Function to install packages if not already installed
install_packages() {
  local packages=("$@")
  local to_install=()

  for pkg in "${packages[@]}"; do
    if ! is_installed "$pkg" && ! is_group_installed "$pkg"; then
      to_install+=("$pkg")
    else
      echo "$pkg is already installed."
    fi
  done

  if [ ${#to_install[@]} -ne 0 ]; then
    echo "Installing: ${to_install[*]}"
    yay -Syu --noconfirm "${to_install[@]}"
  fi
} 

# Function to replace a line in a file
replace_line_in_file() {
  local file="$1"
  local search="$2"
  local replacement="$3"

  if [ ! -f "$file" ]; then
    echo "Error: File '$file' not found."
    return 1
  fi

  # Escape slashes and special characters
  local escaped_search
  escaped_search=$(printf '%s\n' "$search" | sed -e 's/[]\/$*.^[]/\\&/g')

  local escaped_replacement
  escaped_replacement=$(printf '%s\n' "$replacement" | sed -e 's/[&/\]/\\&/g')

  # Replace the matching line
  sudo sed -i.bak "s/^$escaped_search\$/$escaped_replacement/" "$file"

  printf "Line replaced in '$file'. \n $escaped_search was replaced with $escaped_replacement. \nBackup saved as '$file.bak'.\n\n"
}

#####################
### Start of code ###
#####################

# print vanity logo
clear
print_logo

#TODO - confirm what system is running




#TODO move to function depending on what type of system is running
# Update the system first
echo "Updating system..."
sudo pacman -Syu --noconfirm


#TODO check if arch and install AUR if not present. 
# Install yay AUR helper if not present
if ! command -v yay &> /dev/null; then
  echo "Installing yay AUR helper..."
  sudo pacman -S --needed git base-devel --noconfirm
  if [[ ! -d "yay" ]]; then
    echo "Cloning yay repository..."
  else
    echo "yay directory already exists, removing it..."
    rm -rf yay
  fi

  git clone https://aur.archlinux.org/yay.git

  cd yay
  echo "building yay.... yaaaaayyyyy"
  makepkg -si --noconfirm
  cd ..
  rm -rf yay
else
  echo "yay is already installed"
fi


#set up pacman 
install_packages "reflector"
printf "\nconfiguring pacman for speed....\n"
sudo reflector --country '' --latest 50 --sort rate --save /etc/pacman.d/mirrorlist

printf "\nChanges to pacman mirror list:\n\n"
cat /etc/pacman.d/mirrorlist
printf "\n"

#replace settings in pacman conf 

replace_line_in_file "/etc/pacman.conf" "#Color" "Color"
replace_line_in_file "/etc/pacman.conf" "# Misc options" "ILoveCandy"
replace_line_in_file "/etc/pacman.conf" "#VerbosePkgLists" "VerbosePkgLists"



#TODO split up into base utils for all then distro specific tools
# import data from pacages config file
source packages.conf

#start installing packages
echo "Installing system utilities..."
install_packages "${PACKAGES[@]}"

read -p "Do you want to install Hyprland specific packages? (y/n): " yn
case $yn in
  [Yy]* ) echo "Continuing..." && install_packages "${HYPRLAND[@]}";; 
  [Nn]* ) echo "Setup Complete" ;;
  * ) echo "Please answer yes or no.";;
esac

read -p "Do you want to customise SDDM as a login manager? (y/n): " yn
case $yn in
        [Yy]* )
                {
                        sudo sddm --example-config | sudo tee /etc/sddm.conf > /dev/null
                        replace_line_in_file "/etc/sddm.conf" "Current=" "Current=sddm-sugar-dark"
                }
                ;;
        [Nn]* ) ;;
        * ) echo "Please enter 'y' or 'n'.";;
esac

read -p "Do you want to select the services to start? (y/n): " yn
case $yn in
        [Yy]* )
                {
                echo "Starting Syncthing..."
                systemctl --user enable syncthing.service
                systemctl --user start syncthing.service
                printf "Please configure Syncthing to bring down the 'stow' folder to this machine. "
                sleep 4 
                xdg-open "http://127.0.0.1:8384/"
                } ;;

        [Nn]* ) ;;
        * ) echo "please enter yes or no.";;
esac


read -p "Do you want to set up stow config linking now? (y/n): " yn
case $yn in
        [Yy]* )
                {
                if command -v stow >/dev/null 2>&1; then
                    printf "Stow is now installed, checked for local directory..."
                    if [ -d "~/stow" ]; then
                        cd "~/stow"
                        rm ~/.bashrc
                        stow bash
                        stow starship
                        stow fastfetch
                        stow nvim
                        stow vim
                        stow wallpaper
                        stow kitty
                        stow hypr
                        stow waybar
                        stow yay
                        stow reaper
                        stow ranger
                        stow wofi
                    fi
                fi
                };;
        [Nn]* ) ;;
        * ) echo "Please enter 'y' or 'no'.";;
esac


