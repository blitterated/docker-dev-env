#!/bin/bash

# prep indexes for apt and install available upgrades
source ./provision/apt_prep.sh

# install manpages first so later packages will install their own manpages
source ./provision/manpages.sh

source ./provision/apt_install.sh
