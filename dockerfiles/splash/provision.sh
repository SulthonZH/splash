#!/bin/bash

usage() {
    cat <<EOF
Splash docker image provisioner.

Usage: $0 COMMAND [ COMMAND ... ]

Available commands:
usage -- print this message
prepare_install -- prepare image for installation
install_deps -- install system-level dependencies
install_builddeps -- install system-level build-dependencies
install_python_deps -- install python-level dependencies
remove_builddeps -- remove build-dependencies
remove_extra -- remove files that are unnecessary to run Splash

EOF
}

prepare_install () {
    # Prepare docker image for installation of packages, docker images are
    # usually stripped and aptitude doesn't work immediately.
    sed 's/main$/main universe/' -i /etc/apt/sources.list && \
    apt-get update -q && \
    apt-get install -y --no-install-recommends \
        software-properties-common \
        python-software-properties
}

install_deps () {
    # Install package dependencies.
    add-apt-repository -y ppa:pi-rho/security && \
    apt-get update -q && \
    apt-get install -y --no-install-recommends \
        netbase \
        ca-certificates \
        xvfb \
        pkg-config \
        python \
        libqt4-webkit \
        python-qt4 \
        python-pip \
        libre2 \
        libicu48 \
        liblua5.2 \
        zlib1g
}

install_builddeps () {
    # Install build dependencies for package (and its pip dependencies).
    apt-get install -y --no-install-recommends \
        python-dev \
        build-essential \
        libre2-dev \
        liblua5.2-dev \
        libsqlite3-dev \
        zlib1g-dev
}

install_python_deps () {
    # Install python-level dependencies.
    pip install -U pip && \
    /usr/local/bin/pip install --no-cache-dir \
        Twisted==15.0.0 \
        qt4reactor==1.6 \
        psutil==2.2.1 \
        adblockparser==0.3 \
        https://github.com/axiak/pyre2/archive/master.zip#egg=re2 \
        xvfbwrapper==0.2.4 \
        lupa==1.1 \
        funcparserlib==0.3.6 \
        Pillow==2.7.0
}

remove_builddeps () {
    # Uninstall build dependencies.
    apt-get remove -y --purge \
        python-dev \
        build-essential \
        libre2-dev \
        liblua5.2-dev \
        zlib1g-dev \
        libc-dev \
        gcc cpp binutils perl && \
    apt-get autoremove -y && \
    apt-get clean -y
}

remove_extra () {
    # Remove unnecessary files.
    rm -rf \
       /usr/share/perl \
       /usr/share/perl5 \
       /usr/share/man \
       /usr/share/info \
       /usr/share/doc \
       /var/lib/apt/lists/*
}

if [ \( $# -eq 0 \) -o \( "$1" = "-h" \) -o \( "$1" = "--help" \) ]; then
    usage
    exit 1
fi

UNKNOWN=0
for cmd in "$@"; do
    if [ "$(type -t -- "$cmd")" != "function" ]; then
        echo "Unknown command: $cmd"
        UNKNOWN=1
    fi
done

if [ $UNKNOWN -eq 1 ]; then
    echo "Unknown commands encountered, exiting..."
    exit 1
fi

while [ $# -gt 0 ]; do
    echo "Executing command: $1"
    "$1" || { echo "Command failed (exitcode: $?), exiting..."; exit 1; }
    shift
done
