#!/bin/bash

script_dir=$(dirname "$(type -p "$0")")

echo "Install script directory: $script_dir"

cd ${script_dir}

if [ ! -d "../feeds/packages/net/iperf/patches" ]; then
	echo "Error! Patches directory not found! Have you run \"./scripts/feeds update -a\" and \"./scripts/feeds install -a\" before launching this script?"
	exit 1
fi

cp ./iperf/*.patch ../feeds/packages/net/iperf/patches
yes | cp -rf ./python-cryptography/*.patch ../feeds/packages/lang/python/python-cryptography/patches

echo "Patches copied. Thank you!"
