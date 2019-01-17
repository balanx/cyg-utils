#!/usr/bin/env bash

#
# Map Current Windows User to root user
#

# Check if current Windows user is in /etc/passwd
USER_SID="$(mkpasswd -c | cut -d':' -f 5)"
if ! grep -F "$USER_SID" /etc/passwd &>/dev/null; then
    echo "Mapping Windows user '$USER_SID' to cygwin '$USERNAME' in /etc/passwd..."
    GID="$(mkpasswd -c | cut -d':' -f 4)"
    echo $USERNAME:unused:1001:$GID:$USER_SID:$HOME:/bin/bash >> /etc/passwd
fi

exit 0
# already set in cygwin-portable.cmd:
# export CYGWIN_ROOT=$(cygpath -w /)

#
# adjust Cygwin packages cache path
#
pkg_cache_dir=$(cygpath -w "$CYGWIN_ROOT/../cygwin-pkg-cache")
sed -i -E "s/.*\\\cygwin-pkg-cache/"$'\t'"${pkg_cache_dir//\\/\\\\}/" /etc/setup/setup.rc

#
# Installing apt-cyg package manager if required
#
if [[ ! -x /usr/local/bin/apt-cyg ]]; then
    echo "Installing apt-cyg..."
    wget -O /usr/local/bin/apt-cyg https://raw.githubusercontent.com/transcode-open/apt-cyg/master/apt-cyg
    chmod +x /usr/local/bin/apt-cyg
fi
