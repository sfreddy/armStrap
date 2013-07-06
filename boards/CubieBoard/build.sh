# Usage: buildOS
function installOS {

  BUILD_LC_ALL="" 
  BUILD_LANGUAGE="en_US:en" 
  BUILD_LANG="en_US.UTF-8"

  case "${ARMSTRAP_OS}" in
    "ubuntu")  
       BUILD_ARMBIAN_ROOTFS="http://armstrap.vls.beaupre.biz/rootfs/ubuntu-13.04-armv7l-hf.txz"
       BUILD_ARMBIAN_SUITE="rarring"
       ;;
      *)
       BUILD_ARMBIAN_ROOTFS="http://armstrap.vls.beaupre.biz/rootfs/debian-wheezy-armv7l-hf.log"
       BUILD_ARMBIAN_SUITE="wheezy"
       ;;
   esac
       
  BUILD_ARMBIAN_EXTRACT="tar -xJ"
  BUILD_ARMBIAN_KERNEL="http://armstrap.vls.beaupre.biz/kernel/cubieboard/install-cubieboard-kernel-desktop.sh"
  BUILD_ARMBIAN_UBOOT="http://armstrap.vls.beaupre.biz/uboot/cubieboard-u-boot.txz"
  
  BUILD_MNT_ROOT="${ARMSTRAP_MNT}"
  
  # Not all packages can be install this way.
  BUILD_DPKG_EXTRAPACKAGES="nvi ntp ssh build-essential u-boot-tools parted git binfmt-support libusb-1.0-0 libusb-1.0-0-dev pkg-config dosfstools libncurses5-dev ${ARMSTRAP_DEBIAN_EXTRAPACKAGES}"
  
  # Not all packages can be configured this way.
  BUILD_UBUNTU_RECONFIG="tzdata ${ARMSTRAP_DPKG_RECONFIG}"
  
  # Theses are packages included with or generated by the script. The script will automatically include .deb files in the dpkg directory
  BUILD_DPKG_LOCALPACKAGES=""
  
  BUILD_SERIALCON_ID="T0"
  BUILD_SERIALCON_RUNLEVEL="2345"
  BUILD_SERIALCON_TERM="ttyS0"
  BUILD_SERIALCON_SPEED="115200"
  BUILD_SERIALCON_TYPE="vt100"
  
  BUILD_FSTAB_ROOTDEV="/dev/root"
  BUILD_FSTAB_ROOTMNT="/"
  BUILD_FSTAB_ROOTFST="ext4"
  BUILD_FSTAB_ROOTOPT="defaults"
  BUILD_FSTAB_ROOTDMP="0"
  BUILD_FSTAB_ROOTPSS="1"
  
  BUILD_KERNEL_MODULES="sw_ahci_platform lcd hdmi ump disp mali mali_drm"
  
  BUILD_ROOT_DEV="/dev/mmcblk0p1"
  BUILD_MAC_VENDOR=0x000246
  
  BUILD_BOOT_CMD="${BUILD_MNT_ROOT}/boot/boot.cmd"
  BUILD_BOOT_SCR="${BUILD_MNT_ROOT}/boot/boot.scr"
  
  BUILD_CONFIG_CMDLINE="console=tty0 console=${BUILD_SERIALCON_TERM},${BUILD_SERIALCON_SPEED} hdmi.audio=EDID:0 disp.screen0_output_mode=EDID:1280x720p60 root=${BUILD_ROOT_DEV} rootwait panic=10"
  
  BUILD_BOOT_FEX="${BUILD_MNT_ROOT}/boot/cubieboard.fex"
  BUILD_BOOT_BIN="${BUILD_MNT_ROOT}/boot/script.bin"
  BUILD_BOOT_BIN_LOAD="mmc 0 0x43000000 boot/script.bin"
  BUILD_BOOT_KERNEL_LOAD="mmc 0 0x48000000 boot/${BUILD_KERNEL_NAME}"
  BUILD_BOOT_KERNEL_ADDR="0x48000000"
  
  #BUILD_BOOT_SPL="${BUILD_UBOOT_DIR}/spl/sunxi-spl.bin"
  BUILD_BOOT_SPL_SIZE="1024"
  BUILD_BOOT_SPL_SEEK="8"

  #BUILD_BOOT_UBOOT="${BUILD_UBOOT_DIR}/u-boot.bin"
  BUILD_BOOT_UBOOT_SIZE="1024"
  BUILD_BOOT_UBOOT_SEEK="32"
  
  BUILD_DISK_LAYOUT=("1:/:ext4:-1")
  


  httpExtract "${BUILD_MNT_ROOT}" "${BUILD_ARMBIAN_ROOTFS}" "${BUILD_ARMBIAN_EXTRACT}"
  
  setHostName "${BUILD_MNT_ROOT}" "${ARMSTRAP_HOSTNAME}"
  
  chrootUpgrade "${BUILD_MNT_ROOT}"
  
  if [ -n "${BUILD_DPKG_EXTRAPACKAGES}" ]; then
    chrootInstall "${BUILD_MNT_ROOT}" "${BUILD_DPKG_EXTRAPACKAGES}"
  fi
  
  if [ -n "${ARMSTRAP_SWAP}" ]; then
    printf "CONF_SWAPSIZE=%s" "${ARMSTRAP_SWAP_SIZE}" > "${BUILD_MNT_ROOT}/etc/dphys-swapfile"
  else
    printf "CONF_SWAPSIZE=0" > "${BUILD_MNT_ROOT}/etc/dphys-swapfile"
  fi

  chrootReconfig "${BUILD_MNT_ROOT}" "${BUILD_UBUNTU_RECONFIG}"
  
  BUILD_DPKG_LOCALPACKAGES="`find ${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}/dpkg/*.deb -maxdepth 1 -type f -print0 | xargs -0 echo` ${BUILD_DPKG_LOCALPACKAGES}"

  if [ ! -z "${BUILD_DPKG_LOCALPACKAGES}" ]; then
    for i in ${BUILD_DPKG_LOCALPACKAGES}; do
      chrootDPKG "${BUILD_MNT_ROOT}" ${i}
    done
  fi

  chrootPassword "${BUILD_MNT_ROOT}" "${ARMSTRAP_PASSWORD}"
  
  addTTY "${BUILD_MNT_ROOT}" "${BUILD_SERIALCON_ID}" "${BUILD_SERIALCON_RUNLEVEL}" "${BUILD_SERIALCON_TERM}" "${BUILD_SERIALCON_SPEED}" "${BUILD_SERIALCON_TYPE}"

  initFSTab "${BUILD_MNT_ROOT}" 
  addFSTab "${BUILD_MNT_ROOT}" "${BUILD_FSTAB_ROOTDEV}" "${BUILD_FSTAB_ROOTMNT}" "${BUILD_FSTAB_ROOTFST}" "${BUILD_FSTAB_ROOTOPT}" "${UILD_FSTAB_ROOTDMP}" "${BUILD_FSTAB_ROOTPSS}"

  for i in "${BUILD_KERNEL_MODULES}"; do
    addKernelModule "${BUILD_MNT_ROOT}" "${i}"
  done

  addIface "${BUILD_MNT_ROOT}" "eth0" "${ARMSTRAP_ETH0_MODE}" "${ARMSTRAP_ETH0_IP}" "${ARMSTRAP_ETH0_MASK}" "${ARMSTRAP_ETH0_GW}" "${ARMSTRAP_ETH0_DOMAIN}" "${ARMSTRAP_ETH0_DNS}"
  
  installLinux "${BUILD_MNT_ROOT}" "${BUILD_ARMBIAN_KERNEL}"
  
  httpExtract "${BUILD_MNT_ROOT}/boot" "${BUILD_ARMBIAN_UBOOT}" "${BUILD_ARMBIAN_EXTRACT}"
  
  ubootSetEnv "${BUILD_BOOT_CMD}" "bootargs" "${BUILD_CONFIG_CMDLINE}"
  ubootExt2Load "${BUILD_BOOT_CMD}" "${BUILD_BOOT_BIN_LOAD}"
  ubootExt2Load "${BUILD_BOOT_CMD}" "${BUILD_BOOT_KERNEL_LOAD}"
  ubootBootM "${BUILD_BOOT_CMD}" "${BUILD_BOOT_KERNEL_ADDR}"
  
  if [ "${ARMSTRAP_MAC_ADDRESS}" != "" ]; then
    sunxiSetMac "${BUILD_BOOT_FEX}" "${ARMSTRAP_MAC_ADDRESS}"
  fi
  
  sunxiMkImage ${BUILD_BOOT_CMD} ${BUILD_BOOT_SCR}
  
  chrootRun "${BUILD_MNT_ROOT}" "/usr/local/bin/fex2bin /boot/cubieboard.fex /boot/script.bin"
  
  ubootDDLoader "${BUILD_MNT_ROOT}/boot/sunxi-spl.bin" "${ARMSTRAP_DEVICE}" "${BUILD_BOOT_SPL_SIZE}" "${BUILD_BOOT_SPL_SEEK}"
  ubootDDLoader "${BUILD_MNT_ROOT}/boot/u-boot.bin" "${ARMSTRAP_DEVICE}" "${BUILD_BOOT_UBOOT_SIZE}" "${BUILD_BOOT_UBOOT_SEEK}"
  
}
