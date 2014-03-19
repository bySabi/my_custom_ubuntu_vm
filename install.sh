#!/bin/bash
set -e
set +x

project_dir="my_custom_ubuntu_vm"


## goto script dir
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

script_dir_parent=${PWD##*/}


main() {
	isrootuser
	setup_script ${script_dir_parent}

	set_network_interface
	blacklist_unneeded_modules
	remove_floppy_mount
	disable_unneeded_services
	set_etc_default_s
	remove_modules
	install_packages
	uninstall_packages
	unload_modules
	reconfigure_linux_image
}

set_network_interface() {
	echo ">> Install custom network interface"
		install -o root -m 644 conf/interfaces /etc/network/interfaces
	exit_func $?
}

blacklist_unneeded_modules() {
	echo ">> blacklist unneeded modules"
		install -o root -m 644 conf/blacklist_bySabi.conf /etc/modprobe.d/blacklist_bySabi.conf
	exit_func $?
	## if not desktop ->
	if ! dpkg -l ubuntu-desktop 1>/dev/null 2>&1
	then
		echo ">> blacklist unneeded modules - server only"
			cat conf/blacklist-server_bySabi.conf >> /etc/modprobe.d/blacklist_bySabi.conf
		exit_func $?
	fi
}

remove_floppy_mount() {
	echo ">> remove floppy from mount"
		sed -i '/^\/dev\/fd/d' /etc/fstab
	exit_func $?	
}

disable_unneeded_services() {
	echo ">> disable unneeded services on init"
		source conf/unneeded-services-on-init
	exit_func $?
}

set_etc_default_s() {
	echo ">> set /etc/default of some unneeded services"
		source conf/set-etc-default
	exit_func $?
}

remove_modules() {
	echo ">> remove no needed modules"
		sed -i '/lp/d' /etc/modules
	exit_func $?
}

install_packages() {
	echo ">> install packages"
		source conf/package-needed
	exit_func $?
	## if desktop ->
	if dpkg -l ubuntu-desktop 1>/dev/null 2>&1
	then
		true
	fi
}

uninstall_packages() {
	echo ">> unistall packages"
		source conf/package-unneeded
	exit_func $?
}

unload_modules() {
	echo ">> unload modules"
		source conf/unload-modules
	exit_func $?
}

reconfigure_linux_image(){
	echo ">> reconfigure linux-image"
		dpkg-reconfigure linux-image-$(uname -r)
	exit_func $?
}


isrootuser() {
	[ $(id -u) = 0 ] || {
		echo "This script must be run as root" 1>&2
		exit 1
	}
}

setup_script() {
	if [ "$1" != ${project_dir} ]; then
		if ! which git > /dev/null
		then
			echo ">> Install git"
				apt-get install -y --no-install-recommends git 1>/dev/null
			exit_func $?
		fi
		echo ">> clone \"${project_dir}\" repo"
			git clone https://github.com/bySabi/my_custom_ubuntu_vm.git
		exit_func $?
		cd ${project_dir}
		chmod +x install.sh && sudo ./install.sh &
		exit 0
	fi
}

exit_func() {
	local exitcode=${1}
	if [ $exitcode == 0 ]; then 
		echo -e "\e[00;32mOK\e[00m"
	else 
		echo -e "\e[00;31mFAIL\e[00m"
	fi
}


main "$@"
