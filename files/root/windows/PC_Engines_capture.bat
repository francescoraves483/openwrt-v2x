@echo off
title Wireshark PC Engines capture
color F0
set /p monIP="Insert the IP address of the board (use the Ethernet interface IP here!): "
set /p iface="Insert the monitor interface (for ex. 'wlan0'): "
echo "IP: %monIP%   Port: 22   Interface: %iface%"
:: using tcpdump on:
::  -i <specified interface>
::  -w <standard output, '-' is used to indicate stdout>
:: piping to wireshark with:
::  -k (start capture immediately)
::  -i - (read from stdin ('-'))
plink.exe -l root %monIP% -P 22 "tcpdump -i %iface% -w -" | "C:\Program Files\Wireshark\Wireshark.exe" -k -i -
echo "Script terminated"
pause