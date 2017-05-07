#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
   echo "install.sh must be run as root. try: sudo install.sh"
   exit 1
fi

function install_bluetooth {
    echo "**** Installing bluetooth packages for Raspberry Pi 3 & Zero W ****"
    ARCH=`dpkg --print-architecture`
    apt install bluez-firmware

    ## Install dependencies
    PKG_STATUS=$(dpkg-query -W --showformat='${Status}\n' libreadline6|grep "install ok installed")
    echo "Checking for libreadline6:" $PKG_STATUS
    if [ "" == "$PKG_STATUS" ]; then
        echo "Fixing unmet dependencies. Installing libreadline6."
        if [ "armel" == "$ARCH" ]; then
            dpkg -i ./repo/libreadline6_6.3-8+b3_armel.deb
        else
            dpkg -i ./repo/libreadline6_6.3-8+b3_armhf.deb
        fi
    fi

    if [ "armel" == "$ARCH" ]; then
        dpkg -i ./repo/bluez_5.39-1+rpi1+re4son_armel.deb
    else
        dpkg -i ./repo/bluez_5.23-2+rpi2_armhf.deb
    fi
    dpkg -i ./repo/pi-bluetooth_0.1.4+re4son_all.deb
    apt-mark hold bluez-firmware bluez pi-bluetooth

    systemctl unmask bluetooth.service
    systemctl enable bluetooth
    systemctl enable hciuart
    if [ ! -f  /lib/udev/rules.d/50-bluetooth-hci-auto-poweron.rules ]; then
      cp firmware/50-bluetooth-hci-auto-poweron.rules /lib/udev/rules.d/50-bluetooth-hci-auto-poweron.rules
    fi
    ## Above rule runs /bin/hciconfig but its found in /usr/bin under kali, lets create a link
    if [ ! -f  /bin/hciconfig ]; then
      ln -s /usr/bin/hciconfig /bin/hciconfig
    fi
    echo "**** Bluetooth packages for Raspberry Pi 3 & Zero W installed ****"
}
function install_firmware {
    echo "**** Installing firmware for RasPi bluetooth chip ****"
    #Raspberry Pi 3 & Zero W
    if [ ! -f /lib/firmware/brcm/BCM43430A1.hcd ]; then
        cp firmware/BCM43430A1.hcd /lib/firmware/brcm/BCM43430A1.hcd
    fi
    if [ ! -f  /etc/udev/rules.d/99-com.rules ]; then
      cp firmware/99-com.rules /etc/udev/rules.d/99-com.rules
    fi

    #Raspberry Pi Zero W
    if [ ! -f /lib/firmware/brcm/brcmfmac43430-sdio.bin ]; then
        cp firmware/brcmfmac43430-sdio.bin /lib/firmware/brcm/brcmfmac43430-sdio.bin
    fi
    if [ ! -f /lib/firmware/brcm/brcmfmac43430-sdio.txt ]; then
        cp firmware/brcmfmac43430-sdio.txt /lib/firmware/brcm/brcmfmac43430-sdio.txt
    fi
    echo
    echo "**** Firmware installed ****"
    return
}

echo "**** Installing bluetooth firmware and packages for Raspberry Pi 3 ****"

install_firmware
install_bluetooth
