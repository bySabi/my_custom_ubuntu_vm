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
	case ${1} in
		unistall)
			uninstall
			;;
		*)
			install	
			;;
	esac
	exit 0
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
			apt-get install -y --no-install-recommends git
		fi
		git clone https://github.com/bySabi/my_custom_ubuntu_vm.git
		cd ${project_dir}
	fi
}

_b() {
	echo ${1}
}
_e() {
	local _exitcode=${1}
	if [ $_exitcode == 0 ]; then 
		echo -e "\e[00;32mOK\e[00m "
	else 
		echo -e "\e[00;31mFAIL\e[00m"
	fi
	echo
}

set_network_interface() {

}

blacklist_unneeded_modules() {

}

remove_floppy_mount() {
	
}
install() {

	_b ">> Install custom network interface"
		install -o root -m 644 conf/interfaces /etc/network/interfaces
	_e $?

	-b ">> blacklist unneeded modules"
		install -o root -m 644 conf/blacklist_bySabi.conf /etc/modprobe.d/blacklist_bySabi.conf
	_e $?
	## if not desktop ->
	if ! dpkg -l ubuntu-desktop 1>/dev/null 2>&1
	then
		-b ">> blacklist unneeded modules - server only"
			cat conf/blacklist-server_bySabi.conf >> /etc/modprobe.d/blacklist_bySabi.conf
		_e $?
	fi

	-b ">> remove floppy from mount"
		sed -i '/^\/dev\/fd/d' /etc/fstab
	_e $?

	-b ">> disable unneeded services on init"
		source conf/unneeded-services-on-init
	_e $?	

	-b ">> set /etc/default of some unneeded services"
		source conf/set-etc-default
	_e $?	

	-b ">> remove no needed modules"
		sed -i '/lp/d' /etc/modules
	_e $?	

	-b ">> install packages"
		source conf/package-needed
	_e $?
	## if desktop ->
	if dpkg -l ubuntu-desktop 1>/dev/null 2>&1
	then
		true
	fi

	-b ">> unistall packages"
		source conf/package-unneeded
	_e $?	

	-b ">> unload modules"
		source conf/unload-modules
	_e $?

	-b ">> reconfigure linux-image"	
		dpkg-reconfigure linux-image-$(uname -r)
	_e $?
}

uninstall() {
	true
}

main "$@"
