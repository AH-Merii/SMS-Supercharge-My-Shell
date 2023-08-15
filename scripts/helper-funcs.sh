# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"
INSTLOG="install.log"

######
# functions go here

# function that would show a progress bar to the user
show_progress() {
    while ps | grep $1 &> /dev/null;
    do
        echo -n "."
        sleep 2
    done
    echo -en "Done!\n"
    sleep 2
}

# function that will test for a package and if not found it will attempt to install it
install_software() {
    # First lets see if the package is there
    if yay -Q $1 &>> /dev/null ; then
        echo -e "$COK - $1 is already installed."
    else
        # no package found so installing
        echo -en "$CNT - Now installing $1 ."
        yay -S --noconfirm $1 &>> $INSTLOG &
        show_progress $!
        # test to make sure package installed
        if yay -Q $1 &>> /dev/null ; then
            echo -e "\e[1A\e[K$COK - $1 was installed."
        else
            # if this is hit then a package is missing, exit to review log
            echo -e "\e[1A\e[K$CER - $1 install had failed, please check the install.log"
            exit
        fi
    fi
}

install_software_paru() {
    # First lets see if the package is there
    if paru -Q $1 &>> /dev/null ; then
        echo -e "$COK - $1 is already installed."
    else
        # no package found so installing
        echo -en "$CNT - Now installing $1 ."
        
        # Check if package is 'antibody' and disable checks if so
        if [[ $1 == "antibody" ]]; then
            paru -S --noconfirm --nocheck $1 &>> $INSTLOG &
        else
            paru -S --noconfirm $1 &>> $INSTLOG &
        fi
        
        show_progress $!
        # test to make sure package installed
        if paru -Q $1 &>> /dev/null ; then
            echo -e "\e[1A\e[K$COK - $1 was installed."
        else
            # if this is hit then a package is missing, exit to review log
            echo -e "\e[1A\e[K$CER - $1 install had failed, please check the install.log"
            exit
        fi
    fi
}

install_paru_if_not_found() {
    #### Check for paru package manager ####
    if [ ! -f /usr/bin/paru ]; then  
        echo -en "$CNT - Configuring paru."
    
        # Clone the paru repository
        git clone https://aur.archlinux.org/paru.git &>> $INSTLOG
        cd paru
    
        # Build and install paru
        makepkg -si --noconfirm &>> ../$INSTLOG &
        show_progress $!
    
        if [ -f /usr/bin/paru ]; then
            echo -e "\e[1A\e[K$COK - paru configured"
            cd ..
        
            # Update the paru database
            echo -en "$CNT - Updating paru."
            paru -Syu --noconfirm &>> $INSTLOG &
            show_progress $!
            echo -e "\e[1A\e[K$COK - paru updated."
        else
            # If this is hit then a package is missing, exit to review log
            echo -e "\e[1A\e[K$CER - paru install failed, please check the install.log"
            exit
        fi
    fi
}
