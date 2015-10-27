#!/bin/bash -e

trap '{ echo -e "error ${?}\nthe command executing at the time of the error was\n${BASH_COMMAND}\non line ${BASH_LINENO[0]}" && tail -n 10 ${INSTALL_LOG} && exit $? }' ERR

export DEBIAN_FRONTEND="noninteractive"

export CUR_USER="$(id -un)"
export CUR_UID="$(id -u)"

# Packages
export PACKAGES=(
    'apt-utils'
	'curl'
	'sudo'
	'git'
	'zsh'

 # The following are needed for using RVM
	'patch'
	'bzip2'
	'gawk'
	'g++'
	'gcc'
	'make'
	'libc6-dev'
	'patch'
	'libreadline6-dev'
	'zlib1g-dev'
	'libssl-dev'
	'libyaml-dev'
	'libsqlite3-dev'
	'sqlite3'
	'autoconf'
	'libgdbm-dev'
	'libncurses5-dev'
	'automake'
	'libtool'
	'bison'
	'pkg-config'
	'libffi-dev'
)

pre_install() {
    if [ "${CUR_UID}" -ne 0 ]
	then
		echo "Need to be root to run ${FUNCNAME[0]} (running as ${CUR_USER})"
		return 1
	fi

	apt-get update -q 2>&1 || return 1
	apt-get install -yq ${PACKAGES[@]} || return 1

    chmod +x /usr/local/bin/* || return 1

    return 0
}

create_users() {
    if [ "${CUR_UID}" -ne 0 ]
	then
		echo "Need to be root to run ${FUNCNAME[0]} (running as ${CUR_USER})"
		return 1
	fi

    if ! getent passwd ${APP_USER} > /dev/null 2>&1; then
		echo "Creating user ${APP_USER}..."

		useradd -d "${APP_HOME}" -m -s "/bin/zsh" "${APP_USER}" || return 1
		echo "${APP_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${APP_USER} || return 1
	fi

	return 0
}

configure_zsh() {
    git clone https://github.com/tarjoilija/zgen.git /usr/share/zgen

    cat >> /etc/zsh/zshrc \
<<'EOF'

# DISABLE AUTOCORRECTION
DISABLE_CORRECTION="true"

source /usr/share/zgen/zgen.zsh

ZGEN_RESET_ON_CHANGE=(/etc/zsh/zshrc)
if ! zgen saved; then
    # Load prezto
    zgen prezto

    # Config
    zgen prezto '*:*' color 'yes'
    zgen prezto 'editor' key-bindings 'vi'
    zgen prezto 'editor' dot-expansion 'yes'
    zgen prezto 'editor:info:completing' format '...'
    zgen prezto 'history-substring-search:color' found 'bg=6,fg=0,bold'
    zgen prezto 'history-substring-search:color' not-found 'bg=1,fg=0,bold'
    zgen prezto 'prompt' theme 'skwp'
    zgen prezto 'ruby:info:version' format 'version:%v'
    zgen prezto 'syntax-highlighting' highlighters \
            'main' \
            'brackets' \
            'pattern' \
            'root'

    # prezto and modules
    zgen prezto 'completion'
    zgen prezto 'directory'
    zgen prezto 'editor'
    zgen prezto 'environment'
    zgen prezto 'git'
    zgen prezto 'history'
    zgen prezto 'utility'
    zgen prezto 'spectrum'
    zgen prezto 'syntax-highlighting'
    zgen prezto 'history-substring-search'

    zgen prezto 'prompt'

    zgen save

    prompt 'skwp'
fi
EOF

    sudo -u ${APP_USER} -s /bin/zsh -l -c 'source /etc/zsh/zshrc'
}

install_rvm() {
    if [[ "${CUR_USER}" != "${APP_USER}" ]]
	then
		if [ "${CUR_UID}" -eq 0 ]
		then
		    sudo -E -H -u "${APP_USER}" ${0} ${FUNCNAME[0]}
			return $?
		else
			echo "Need to be ${APP_USER} to run ${FUNCNAME[0]} (running as ${CUR_USER})"
			return 1
		fi
	fi

    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 > /dev/null || return 1
    curl -sSL https://get.rvm.io | bash -s stable --ruby --with-default-gems='bundler rails'  || return 1

    return 0
}

post_install() {
    if [ "${CUR_UID}" -ne 0 ]
	then
		echo "Need to be root to run ${FUNCNAME[0]} (running as ${CUR_USER})"
		return 1
	fi

    apt-get autoremove 2>&1 || return 1
	apt-get autoclean 2>&1 || return 1
	rm -fr /var/lib/apt 2>&1 || return 1

	return 0
}

if [ $# -eq 0 ]
then
    echo "Available function(s):"
    echo $(compgen -A function)

    exit 1
fi

if [[ "${@}" == "build" ]]; then
    tasks=(
        'pre_install'
        'create_users'
        'configure_zsh'
        'install_rvm'
        'post_install'
    )
else
    tasks=${@}
fi

for task in ${tasks[@]}
do
    if ! declare -F ${task} > /dev/null; then
        echo "${task} does not exist fail..."
        exit 1
    fi

    echo "Running ${task}..."

    if ! tty -s; then
        if [ ! -f "${INSTALL_LOG}" ]; then
            touch ${INSTALL_LOG}
        fi

        if ! ${task} > ${INSTALL_LOG} 2>&1; then
            tail ${INSTALL_LOG}
            exit 1
        fi
    else
        if ! ${task} 2>&1; then
            exit 1
        fi
    fi
done

exit 0
