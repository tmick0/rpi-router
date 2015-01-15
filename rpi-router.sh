#!/bin/bash

#
# rpi-router.sh
# 15 Jan. 2015
#
# This shell script sets up your machine as a NAT to bridge two connections.
# Originally intended to serve a Raspberry Pi connected to eth0 through a
# loopback cable.
#
# Travis Mick
# tmick@cs.nmsu.edu
# github.com/le1ca
#
# Public Domain
#

# --- Start of configs ---

# Input interface (facing the Pi)
INPUT_IF="eth0"

# Input subnet - you must have already set up the static addresses for both
# your gateway machine and the Pi, and specified your machine's IP as the Pi's
# default gateway.
INPUT_SUBNET="192.168.0.0/24"

# output interface (facing WAN)
OUTPUT_IF="wlan0"

# --- End of configs ---

# Determine our public IP address
WIFI_IP=$(ifconfig $OUTPUT_IF | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}')

# Check our uid and verify that we are root
USER_ID=$(id -u)
if [ "$USER_ID" != "0" ]; then
	echo "This script must be run as root!"
	exit
fi

# If we are root we can proceed
echo "Setting up NAT from $INPUT_SUBNET -> $WIFI_IP..."

# Ensure that the kernel is enabled to forward packets
echo 1 > /proc/sys/net/ipv4/ip_forward

# Set iptables rules
iptables -A FORWARD -o $INPUT_IF -j ACCEPT
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -s $INPUT_SUBNET -j ACCEPT
iptables -A FORWARD -j REJECT
iptables -t nat -A POSTROUTING -s $INPUT_SUBNET -o $OUTPUT_IF -j MASQUERADE
iptables -t nat -A POSTROUTING -j SNAT --to-source $WIFI_IP

# We did it
echo "Done."
exit

