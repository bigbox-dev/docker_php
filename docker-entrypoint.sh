#!/usr/bin/env bash

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

SSH_DIR=/root/.ssh

execTpl() {
    if [[ -f "/etc/gotpl/$1" ]]; then
        gotpl "/etc/gotpl/$1" > "$2"
    fi
}

execInitScripts() {
    shopt -s nullglob
    for f in /docker-entrypoint-init.d/*.sh; do
        echo "$0: running $f"
        . "$f"
    done
    shopt -u nullglob
}

fixPermissions() {
    chown root:root "${APP_ROOT}"

    if [[ -n "${PHP_XDEBUG_TRACE_OUTPUT_DIR}" ]]; then
        mkdir -p "${PHP_XDEBUG_TRACE_OUTPUT_DIR}"
        chown root:root "${PHP_XDEBUG_TRACE_OUTPUT_DIR}"
    fi

    if [[ -n "${PHP_XDEBUG_PROFILER_OUTPUT_DIR}" ]]; then
        mkdir -p "${PHP_XDEBUG_PROFILER_OUTPUT_DIR}"
        chown root:root "${PHP_XDEBUG_PROFILER_OUTPUT_DIR}"
    fi
}

addPrivateKey() {
    if [[ -n "${SSH_PRIVATE_KEY}" ]]; then
        mkdir -p "${SSH_DIR}"
        execTpl "id_rsa.tpl" "${SSH_DIR}/id_rsa"
        chmod -f 600 "${SSH_DIR}/id_rsa"
        chown -R root:root "${SSH_DIR}"
        unset SSH_PRIVATE_KEY
    fi
}

initSSH() {
    mkdir -p "${SSH_DIR}"

    if [[ -n "${SSH_PUBLIC_KEYS}" ]]; then
        execTpl "authorized_keys.tpl" "${SSH_DIR}/authorized_keys"
        unset SSH_PUBLIC_KEYS
    fi

    su-exec root printenv | xargs -I{} echo {} | awk ' \
        BEGIN { FS = "=" }; { \
            if ($1 != "HOME" \
                && $1 != "PWD" \
                && $1 != "PATH" \
                && $1 != "SHLVL") { \
                \
                print ""$1"="$2"" \
            } \
        }' > /root/.ssh/environment

    chown -R root:root "${SSH_DIR}"
}

processConfigs() {
  #  execTpl "docker-php.ini.tpl" "${PHP_INI_DIR}/conf.d/docker-php.ini"
    execTpl "docker-php-ext-opcache.ini.tpl" "${PHP_INI_DIR}/conf.d/docker-php-ext-opcache.ini"
    execTpl "docker-php-ext-xdebug.ini.tpl" "${PHP_INI_DIR}/conf.d/docker-php-ext-xdebug.ini"


    sed -i '/^$/d' "${PHP_INI_DIR}/conf.d/docker-php-ext-xdebug.ini"
}

initGitConfig() {
    su-exec root git config --global user.email "root@bigbox.by"
    su-exec root git config --global user.name "root"
}

addPrivateKey
fixPermissions
execInitScripts
initGitConfig
processConfigs


    if [[ $1 == "/usr/sbin/sshd" ]]; then
        initSSH
	ssh-keygen -A
        ssh-keygen -b 2048 -t rsa -N "" -f /etc/ssh/ssh_host_rsa_key -q
    fi

    exec /usr/local/bin/docker-php-entrypoint "${@}"

