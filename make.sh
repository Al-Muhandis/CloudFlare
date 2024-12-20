#!/usr/bin/env bash

function priv_clippit
(
    cat <<EOF
Usage: bash ${0} [OPTIONS]
Options:
    build   Build program
EOF
)

function priv_lazbuild
(
    if ! (which lazbuild); then
        source '/etc/os-release'
        case ${ID:?} in
            debian | ubuntu)
                printf '\x1b[32mInstall Lazarus.\x1b[0m\n' 1>&2
                sudo apt-get update
                sudo apt-get install -y lazarus{-ide-qt5,}
                ;;
        esac
    fi
    declare -r COMPONENTS='use/components.txt'
    if [[ -d "${COMPONENTS%%/*}" ]]; then
        #if [[ -f '.gitmodules' ]]; then
        #    git submodule update --init --recursive --force --remote
        #fi
        if [[ -f "${COMPONENTS}" ]]; then
            printf '\x1b[32mDownload packages:\x1b[0m\n' 1>&2
            while read -r; do
                if [[ -n "${REPLY}" ]] &&
                    ! (lazbuild --verbose-pkgsearch "${REPLY}") &&
                    ! (lazbuild --add-package "${REPLY}") &&
                    ! [[ -d "${COMPONENTS%%/*}/${REPLY}" ]]; then
                        printf '\x1b[32m\tdownwoad package %s\x1b[0m\n' "${REPLY}" 1>&2
                        declare -A VAR=(
                            [url]="https://packages.lazarus-ide.org/${REPLY}.zip"
                            [out]=$(mktemp)
                        )
                        wget --output-document "${VAR[out]}" "${VAR[url]}" >/dev/null
                        unzip -o "${VAR[out]}" -d "${COMPONENTS%%/*}/${REPLY}"
                        rm --verbose "${VAR[out]}"
                    fi
            done < "${COMPONENTS}"
        fi
        printf '\x1b[32mAdd dependencies:\x1b[0m\n' 1>&2
        while read -r; do
            printf '\x1b[32m\tadd dependence %s\x1b[0m\n' "${REPLY}" 1>&2
            lazbuild --add-package "${REPLY}" ||
                lazbuild --add-package-link "${REPLY}"
        done < <(find "${COMPONENTS%%/*}" -type 'f' -name '*.lpk' | sort)
    fi
    printf '\x1b[32mBuild projects:\x1b[0m\n' 1>&2
    declare -i errors=0
    while read -r; do
        declare -A VAR=(
            [out]=$(mktemp)
        )
        if (lazbuild --no-write-project --recursive --no-write-project --widgetset=qt5 --build-mode=release "${REPLY}" > "${VAR[out]}"); then
            printf '\x1b[32m\t[SUCCESS]\tbuild project\t%s.\x1b[0m\n' "${REPLY}" 1>&2
        else
            printf '\x1b[31m\t[FAILED!]\tbuild project\t%s\x1b[0m\n' "${REPLY}" 1>&2
            cat "${VAR[out]}" 1>&2
            ((errors+=1))
        fi
    done < <(find 'src' -type 'f' -name '*.lpi' | sort)
    exit "${errors}"
)

function priv_main
(
    set -euo pipefail
    if ((${#})); then
        case ${1} in
            build) priv_lazbuild ;;
            *) priv_clippit ;;
        esac
    else
        priv_clippit
    fi
)

priv_main "${@}" >/dev/null
