This is a patched version of OpenWrt 21.02.1, in order to enable support to specific V2X (Vehicle-to-everything) features, including 802.11p channel usage and EDCA priority queueus. 

**It is designed to work with NICs supported by the ath5k and ath9k drivers (e.g. UNEX DHXA-222, UNEX DCMA 86P2, ...). We are working in enabling more NICs to be supported: for instance, ath10k support is planned.**

Several patches are heavily based on patches provided by the OpenC2X-embedded platform, by Florian Klingler, Gurjashan Singh Pannu and the CCS Labs team in University of Paderborn: http://www.ccs-labs.org/software/openc2x/

It has been successfully tested, in Politecnico di Torino, using PC Engines APU1D boards, together with Unex DHXA-222 WLAN cards, supported by the *ath9k* driver (AR9642 chip); other platforms should be correctly supported too.
It has also been tested on APU2 boards and few other AR9642-based mPCIe 802.11a/b/g/n chips.

A patch to the iPerf 2 network measurement tool is included, enabling support to the 4 MAC layer EDCA queues. The -A option, which is client specific, can now be used to specify a traffic class at which the outcoming flow should be sent at (-A BK or -A BE or -A VI or -A VO). Not specifying any traffic class leaves the options as if a standard iPerf 2 package was used (i.e. effectively using AC_BE).

**Notice**: you may need up to 60 GB of free space for the OpenWrt build system.

In order to build the system:
* Clone the default branch (OpenWrt-V2X-21.02.1) of the repository with git clone on a Linux machine (Linux Mint 18 and 19, Ubuntu 18 LTS, 20 LTS and 22 LTS have been successfully tested):
```
git clone https://github.com/francescoraves483/OpenWrt-V2X.git
cd OpenWrt-V2X
```
* Update, install and patch the feeds:
```
./scripts/feeds update -a
./scripts/feeds install -a
./feedpatches/install.sh
```
* If you are using APU1D boards, you can select our tested configuration, by doing:
```
cp configs/config_APU.config .config
```
* Or, if you are using APU2 boards (e.g., APU2E4), you can select the following tested configuration (you can also opt for configuration with less pre-included packages, by copying the file `config_APU2.config`):
```
cp configs/config_APU2_full_v5.config .config
```
This configuration builds a final image which already includes several packages, for instance for LTE modules and CAN bus/GNSS support.
If you need a ligher set of pre-included packages (for instance without full LTE modules and CAN bus support), but with more packages than `config_APU2.config`, you can also copy the file `config_APU2_full.config`.
* Run "make menuconfig" and select a target (for instance, x86/x86_64, as when targeting the APU1D or APU2 boards), then set a default config (the target should be already selected if you are using the "config_APU.config"/"config_APU2_full.config" configuration):
```
make menuconfig
make defconfig
```
* If needed, select any additional package using again (some useful packages should be already selected if you are using the "config_APU.config" configuration):
```
make menuconfig
```
* "Download all dependency source files before final make":
```
make download
```
* Build (the build command for a multi-core verbose compilation is shown, using a quad-core eigth-thread Intel Core i7 CPU)
```
make -j10 V=s
```
* Please note that the build process may take from few tens of minutes to up to several hours, depeding on the development PC characteristics; you will find the compiled images inside "/bin/targets/x86/64/"

Once the system has been downloaded into the target embedded board and after rebooting at least once, do the following operations. They are all related to the APU1D/APU2 boards, but we think that they could be easily adapted to other platforms as well:
* Connect the serial cable to the board and to your development PC and open a new connection with baud rate 115200
* Edit the "/etc/config/network" configuration file:
```
vi /etc/config/network
```
* Comment out the Ethernet bridge section by adding # in front of all the lines belonging to the same section:
```
#config device
#       option name 'br-lan'
#       option type 'bridge'
#       list ports 'eth1'
#       list ports 'eth2'
```
* Locate the section `config interface 'lan'` and comment out the lines about 'bridge' (if present) and 'ip6assign' adding a # in front of them
* In the same section, choose an Ethernet interface to be configured for SSH access, by writing its name after "option ifname" (we chose the "eth2" port for our APU boards), and replacing the actual interface name:
```
option ifname 'eth2'
```
* You have now two options: you can either comment out the `ipaddr` and `netmask` lines, and specify `option proto 'dhcp'` to use DHCP and automatically get an IP address, if applicable, or keep these two lines, making sure that `option proto 'static'` is specified. In this case the IP address will be manually set.
* In case of manual IP address configuration, add the following line, replacing '192.168.1.1' with your gateway IP address. This is needed to let the boards connect to the Internet through Ethernet, for instance to run "opkg" and update/install packages.
```
option gateway '192.168.1.1'
```
* In case of manual IP address configuration, choose an IP address, belonging to a proper subnet, for the Ethernet port: this is the address that you will need to specify when connecting a development PC to the boards using SSH (for instance, with PuTTY on Windows, or directly with `ssh` on Linux):
```
option ipaddr '192.168.1.182'
```
* The following steps can then be performed through serial console or by opening an SSH connection with the proper Ethernet port IP address; in the second case, you will need to connect the boards directly to the PC or (better) to a local network at which the PC is connected too. You will then have to login with "root" as user name (no password has been set, you can choose one with "passwd" later on).
* Enable Wi-Fi in "/etc/config/wireless" by editing the file and setting:
```
option disabled '0'
```
* Optionally, you can also set a starting txpower in dBm, for instance by adding the line:
```
option txpower '3'
```
after:
```
option disabled '0'
```
in section:
```
config wifi-device 'radio0' (or similar)
```
* Add some DNS servers to let the boards resolve IP addresses when connected to the Internet: when using, for instance, the Google servers, add these two lines to "/etc/dnsmasq.conf":
```
# DNS servers for the APU boards (Google)
server=8.8.8.8
server=8.8.4.4
```
* **If you use the pre-compiled images only**, replace "/root/iw_startup" with the one included in "/files/root/iw_startup", as it is a more up-to-date version.
* Edit "/root/iw_startup" by setting the proper Wi-Fi IP address (and netmask, such as 255.255.0.0, for instance) in the line:
```
ifconfig wlan0 <your-IP-address> netmask <your-netmask>
```
* Run the following commands:
```
chmod +x iptables_route
chmod +x iw_startup
```
* Shutdown the system:
```
poweroff
```
Now, everytime you connect the target board to the development PC, you can login to an SSH session with "root". Before running any V2X application or test, always initialize the wireless system by launching (we highly recommend to launch this as soon as the system is up and you have logged in):
```
./iw_startup
```
If bash is available (as in the included APU configuration files), you can start using it by simply launching:
```
bash
```

**Automating the initial iw_startup setup**

The script to initialize the wireless system can be automatically launched at startup, together with any other custom command, allowing the boards to start using 802.11p frequencies without any explicit call to an initialization script.

To do so, edit the "/etc/rc.local" file and add the line:
```
/root/iw_startup
```
This line should be added before `exit 0`.

The iw_startup script is set to initially configure the system to use channel 178 (the IEEE "CCH"), with a transmission power (_txpower_) of 15 dBm and a physical data rate of 3 Mbit/s.

You can freely customize this behaviour by editing the lines (please note that the power is specified in mBm and the bitrate as the double of the desired one, due to patched half rate operations in 802.11p):
```
echo "Set Frequency 5890 MHz (CCH) and channel width 10MHz (802.11p)"
iw dev wlan0 ocb join 5890 10MHz
echo "IP address set to 10.10.6.102"
ifconfig wlan0 10.10.6.102 netmask 255.255.0.0
echo "Set Rate 3M and Power 15 dBm, using iw"
iw dev wlan0 set bitrates legacy-5 6
iw dev wlan0 set txpower fixed 1500
```

**Setting an IEEE 802.11p physical data rate/modulation**

Normally, the user can set the physical data rate by leveraging the `iw` tool, and specifying:
```
iw dev wlan0 set bitrates legacy-5 <double of the desired bitrate value in Mbit/s>
```
This is also the procedure implemented in `iw_startup` to set an initial data rate to 3 Mbit/s, and this command can also be used in standard OpenWrt installations to set a desidered data rate with, for instance, other 802.11n or 802.11ac cards.

Unfortunately, we found out that this is not always possible with 802.11p and OCB mode, at least for certain desidered physical data rates, due to `iw` returning "Invalid argument (-22)" errors.
These errors, and thus the selectable physical data rates, seem also to be dependant on the actual hardware and chipset revision, and on how it "reacts" after the physical data rate change request.

Concerning the DHXA-222 cards, `iw dev wlan0 set bitrates legacy-5` lets the user select any of the mandatory physical data rates for IEEE 802.11p, as specified in IEEE 802.11-2020, i.e., either 3 Mbit/s (`iw dev wlan0 set bitrates legacy-5 6`), or 6 Mbit/s (`iw dev wlan0 set bitrates legacy-5 12`), or 12 Mbit/s (`iw dev wlan0 set bitrates legacy-5 24`).

With other cards, however, this is not always guaranteed to work. If it happens that you card does not let you select at least the mandatory rates, you should be able to rely on a workaround, which involves forcing a fixed data rate index in the Minstrel rate adapation algorithm used by Linux.

You can set a desired fixed data rate with:
```
echo <index> > /sys/kernel/debug/ieee80211/phy0/rc/fixed_rate_idx
```

Finding the right indeces for the IEEE 802.11p rates may require a bit of work (the values are not so well documented, and may also be driver dependant - we are, however, investigating this point!). The following are some values we found, with the corresponding IEEE 802.11p data rates, for some AR9642-based mPCIe cards we tested (i.e., Atheros AR5B22):
```
  |INDEX|  -> |PHYS. DATA RATE|
4294967288 ->     3 Mbit/s
4294967289 ->   4.5 Mbit/s
4294967290 ->     6 Mbit/s
4294967291 ->     9 Mbit/s
4294967292 ->    12 Mbit/s
4294967293 ->    18 Mbit/s
4294967294 ->    24 Mbit/s
```

**Setting up chrony for NTP synchronization**

The included APU1D configuration already selects the "chrony" package to be included in the final image. It can be used to efficiently synchronize the date and time on the target boards thanks to NTP.
Here we report how we configured it, using an INRiM (Istituto Nazionale di Ricerca Metrologica) Italian sever as reference.
* Edit "/etc/config/chrony" by selecting the INRiM NTP server:
```
option hostname 'ntp1.inrim.it'
```
* Disable the system NTP client in "/etc/config/system", by setting, on line 10 (if it is not exactly on line 10, look for a similar line after "config timeserver 'ntp'"):
```
option enabled '0'
```
* From any SSH or serial session, run the following commands to start the chrony daemon with the default settings and reboot the system:
```
service sysntpd stop
service sysntpd disable
service chronyd enable
reboot
```

**Broadcast communication problem when using ACs different than AC_BE**

This system should work properly and let you transmit over different ACs using the DSRC frequencies.
There is still, however, one problem that has not been solved yet.

The problem is basically due to the fact that, when using recent versions of the Linux kernel (as in OpenWrt 18.06.1, with kernel 4.14.63 or in OpenWrt 21.02.1), only one priority queue can be used as far as broadcast communication is concerned, at least when a certain category of drivers is used.

When sending broadcasted data, only _AC_BE_ can be used, no matter the AC that the user is trying to set in his or her application; this seems to happen every time a broadcast destination MAC address is used (_FF:FF:FF:FF:FF:FF_), sending out packet which will not be acknowledged by any device, even though they are properly received.
Instead, when sending unicast data, everything works fine and all the queues should be used (when using **ath9k** you can view the queue status for each AC by querying the file "/sys/kernel/debug/ieee80211/phy0/ath9k/xmit").

The problem is due to the introduction of the so-called _intermediate software queues_ inside _mac80211_, for supported drivers (more details are available here: https://patchwork.kernel.org/patch/6111801/). **ath9k** is actually one of the drivers supporting the _intermediate software queues_.

This feature was introduced to move the queuing implementation more towards the software side of the wireless subsystem, allowing the hardware to keep only short queues and enabling also more fairness between stations which are communicating, since these queues, when in sending unicast data, are kept for each station or VIF entry.

However, only one intermediate queue is actually allocated for multicast and the supported drivers are coded in order to manage this single queue, making it impossible to send multicast packets over _AC_BK_, _AC_VI_, _AC_VO_ without coding additional, multi-level, patches. 
We are currently investigating and working on this problem.

**docs directory**

Inside this repository, you will find a **docs** directory, which contains short guides (typically, as PDF files) to perform additional setup steps with OpenWrt-V2X and enable additional features.

At the moment, the following guides are available:

- *Setting up relayd bridge 802_11p.pdf*: short guide to setup the *relayd* package, making the devices running OpenWrt-V2X act as 802.11p dongles with respect to other devices connected to them through an Ethernet interface. All the traffic will be transparently forwarded from the ethernet interface to the wireless 802.11p one (in OCB mode), allowing to extend the connectivity of devices which would otherwise be unable to communicate at 5.8/5.9 GHz, with 10 MHz wide channels and in OCB mode. Reference hardware: PC Engines APU1D boards (the same should apply to the newer APU2 boards too).
