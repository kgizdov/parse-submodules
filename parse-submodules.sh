#!/bin/bash
# Copyright (c) 2021 Konstantin Gizdov

# current working directory
__CWKDIR="${PWD}"
# script directory
__SCRDIR="$(cd "$(dirname "$0")" && pwd)"

__PRSSUB_VERSION_MAJOR__="0"
__PRSSUB_VERSION_MINOR__="0"
__PRSSUB_VERSION_PATCH__="1"
__PRSSUB_VERSION__="${__PRSSUB_VERSION_MAJOR__}.${__PRSSUB_VERSION_MINOR__}.${__PRSSUB_VERSION_PATCH__}"
__VERBOSE_MODE=0

function err_echo {
    >&2 echo "${*}"
}

function verbose_echo {
    # only print to screen when second argument is 1
    [[ ${2} == 1 ]] && err_echo "${1}"
    return 0
}

function fail {
    # fail with error message
    err_echo "${1}"
    exit "${2-1}"  # return a code specified by $2 or $1
}

function version {
    echo "parse-submodules.sh version ${__PRSSUB_VERSION__}"
    echo ""
    echo "Copyright (c) 2021 Konstantin Gizdov"
}

function help {
    # print info & help
    version
    echo ""
    echo "Usage: $0 [options] <GIT REPO REMOTE URL> [<GIT REF>]

note: This is work in progress.

    A utility to parse and print out useful information about
    a Git repository's submodule paths and URLs.

helper options:
    -v  verbose mode

    -h  print this help message and exit
"
}

function check-submodules {
    git ls-tree --full-name --name-only -r ${1:-HEAD} | grep .gitmodules &>/dev/null
}

function check-existance {
    git ls-remote "${1}" CHECK_GIT_REMOTE_URL_REACHABILITY >/dev/null 2>&1
}

function check-git-archive {
    git archive --remote="${1}" --list &>/dev/null
}

function get-file-from-archive {
    local gmf="$(git archive --remote="${1}" "${2}" "${3}" 2>/dev/null)"
    echo "${gmf}" | tar -x
}

function get-submodules-file {
    git ls-tree --full-name --name-only -r ${1:-HEAD} | grep .gitmodules | head -n1
}

function shallow_clone {
    git clone --no-checkout --depth 1 "${1}" "${2:-.}"
}

function get-module-names {
    git config --file "${1}" --get-regexp path | awk -F'.' '{print $2}'
}

function get-module-urls {
    git config --file "${1}" --get-regexp url | awk '{print $2}'
}

function get-module-url {
    git config --file "${1}" --get-regexp url | grep "${2}" | awk '{print $2}'
}

function get-module-paths {
    git config --file "${1}" --get-regexp path | awk '{print $2}'
}

function get-proto {
    # Extract the protocol (includes trailing "://").
    local __PROTO="$(echo "${1}" | sed -nr 's,^(.*://).*,\1,p')"
    verbose_echo "URL protocol: ${__PROTO}" ${__VERBOSE_MODE}
    echo "${__PROTO}"
}

function get-url-noproto {
    # Remove the protocol from the URL.
    local __URL="$(echo ${1/$(get-proto "${1}")/})"
    verbose_echo "URL without protocol: ${__URL}" ${__VERBOSE_MODE}
    echo "${__URL}"
}

function get-url-noproto-nouser {
    # Remove the protocol from the URL.
    local __noproto="$(get-url-noproto "${1}")"
    local __URL="$(echo ${__noproto/$(get-user "${1}")/})"
    verbose_echo "URL without protocol and user: ${__URL}" ${__VERBOSE_MODE}
    echo "${__URL}"
}

function get-url-noproto-nouser-noport {
    # Remove the protocol from the URL.
    local __noproto_nouser="$(get-url-noproto-nouser "${1}")"
    local __URL="$(echo ${__noproto_nouser/$(get-port "${1}")/})"
    verbose_echo "URL without protocol, user and port: ${__URL}" ${__VERBOSE_MODE}
    echo "${__URL}"
}

function get-user {
    # Extract the user (includes trailing "@").
    local __USER="$(echo "$(get-url-noproto "${1}")" | sed -nr 's,^(.*@).*,\1,p')"
    verbose_echo "USER: ${__USER}" ${__VERBOSE_MODE}
    echo "${__USER}"
}

function get-port {
    local __noproto_nouser="$(get-url-noproto-nouser "${1}")"
    local __PORT="$(echo "${__noproto_nouser}" | sed -nr 's,.*(:[0-9]+).*,\1,p')"
    verbose_echo "PORT: ${__USER}" ${__VERBOSE_MODE}
    echo "${__PORT}"
}

function get-path {
    local __PATH="$(echo "$(get-url-noproto-nouser-noport "${1}")" | sed -nr 's,[^/:]*([/:].*),\1,p')"
    verbose_echo "PATH: ${__USER}" ${__VERBOSE_MODE}
    echo "${__PATH}"
}

function get-host {
    local __noproto_nouser_noport="$(get-url-noproto-nouser-noport "${1}")"
    local __HOST="$(echo ${__noproto_nouser_noport/$(get-path "${1}")/})"
    verbose_echo "HOST: ${__USER}" ${__VERBOSE_MODE}
    echo "${__HOST}"
}

function get-repo-name {
    echo "$(basename ${1} .git)"
}

function get-repo-suffix-path {
    local __url_path="$(get-path "${1}")"
    local __PATH="$(realpath -m //"${__url_path}"/"${2}")"
    if [[ "${__url_path:0:1}" == ':' ]]; then
        __PATH=":${__PATH:1}"
    fi
    echo "${__PATH}"
}

if ! command -v git &> /dev/null; then
    fail "'git' command not found. Exiting..." 1
fi

if [[ $# < 1 ]]; then
    fail "$(help)" 1
fi

tempdir="$(mktemp -d)"
gcldir="${tempdir}/gitdir"
gmdfile="${tempdir}/found_gitmodules"
trap "rm -rf ${tempdir}; cd ${__CWKDIR}" EXIT

cd "${tempdir}"

while getopts "Vvh" opt; do
    case $opt in
        v)
            __VERBOSE_MODE=1
            ;;
        V)
            version
            exit 0
            ;;
        h)
            help
            exit 0
            ;;
        :)
            help
            fail "Option -${OPTARG} needs an argument." 1
            ;;
        \?)
            help
            fail "Invalid option -- '${OPTARG:-${!OPTIND:-${opt:-}}}'" 1
            ;;
    esac
done

__GIT_REMOTE=${@:$OPTIND:1}
__GIT_REF=${@:$OPTIND+1:1}
if [ -z $__GIT_REMOTE ]; then
    fail "$(help)" 1
fi
if [ -z $__GIT_REF ]; then
    __GIT_REF='HEAD'
fi

verbose_echo "Checking repository ${__GIT_REMOTE} with ref ${__GIT_REF}..." ${__VERBOSE_MODE}

if ! check-existance "${__GIT_REMOTE}"; then
    fail "Git repository ${__GIT_REMOTE} not found or not accessible. Exiting..." 1
fi

# can we use git archive
__USE_ARCHIVE=1
if ! check-git-archive "${__GIT_REMOTE}"; then
    verbose_echo "Git remote of ${__GIT_REMOTE} does not support git-archive. Cloning entire repository..." __VERBOSE_MODE
    __USE_ARCHIVE=0
fi

if [[ ${__USE_ARCHIVE} == 1 ]]; then
    # get .gitmodules with git archive
    get-file-from-archive "${__GIT_REMOTE}" "${__GIT_REF}" '.gitmodules'
    cp '.gitmodules' "${gmdfile}"
else
    # shallow clone repository locally
    shallow_clone "${__GIT_REMOTE}" "${gcldir}"
    cd "${gcldir}"
    if ! check-submodules "${__GIT_REF}"; then
        fail "'.gitmodules' file does not exist in repo. Exiting..." 1
    fi
    __SUBMOD_FILE=$(get-submodules-file "${__GIT_REF}")
    git --no-pager --git-dir "${gcldir}/.git" show "${__GIT_REF}":"${__SUBMOD_FILE}" >"${gmdfile}"
fi
cd "${tempdir}"
cat "${gmdfile}"
for path in $(get-module-paths "${gmdfile}"); do
    echo git submodule."${path}".url
done

for url in $(get-module-urls "${gmdfile}"); do
    echo ${url}
done
echo '# Your sources array should look something like:
sources=(
  "${pkgname}::'${__GIT_REMOTE}'#[commit/tag]='${__GIT_REF}'"'
__REMOTE_PREFIX="$(get-proto "${__GIT_REMOTE}")$(get-user "${__GIT_REMOTE}")$(get-host "${__GIT_REMOTE}")$(get-port "${__GIT_REMOTE}")"
for name in $(get-module-names "${gmdfile}"); do
    echo "  ${__REMOTE_PREFIX}$(get-repo-suffix-path "${__GIT_REMOTE}" "$(get-module-url "${gmdfile}" "${name}")")"
done
echo ')'

echo '# Put the following in your PKGBUILD prepare function:
prepare() {
  cd "${srcdir}/${pkgname}"
  git submodule init
'
for name in $(get-module-names "${gmdfile}"); do
    echo "  git config submodule.\"${name}\".url "'"${srcdir}"/'"$(get-repo-name "$(get-module-url "${gmdfile}" "${name}")")"
done
echo '}'
