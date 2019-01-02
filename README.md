This is a patched version of OpenWrt 18.06.1, in order to enable support to specific V2X (Vehicle-to-everything) features, including 802.11p channel usage and EDCA priority queueus.

Several patches are heavily based on patches provided by the OpenC2X-embedded platform, by Florian Klingler and the CCS Labs team in University of Paderborn: http://www.ccs-labs.org/software/openc2x/

It has been successfully tested, in Politecnico di Torino, using PC Engines APU1D boards, together with Unex DHXA-222 WLAN cards, supported by the "ath9k" driver; other platforms should be correctly supported too.

A patch to the iPerf 2 network measurement tool is included, enabling support to the 4 MAC layer EDCA queues. The -A option, which is client specific, can now be used to specify a traffic class at which the outcoming flow should be sent at (-A BK or -A BE or -A VI or -A VO). Not specifying any traffic class leaves the options as if a standard iPerf 2 package was used (i.e. effectively using AC_BE).

Inside the "testedplatform" folder you will also find a pre-compiled image (the one which we used for most, if not all, our tests), targeted at x86_64 systems and in particular at the APU1D boards. It can be used in case you encounter problems with the compilation and you need a readily available image. It may also work on other x86_64 platforms, but it has not been tested.

In order to build the system:
* Clone the default branch (OpenWrt-V2X-18.06.1) of the repository with git clone on a Linux machine (Linux Mint 18 and 19 have been tested):
```
git clone https://github.com/francescoraves483/OpenWrt-V2X.git
cd OpenWrt-V2X
```
* Update and install the feeds:
```
./scripts/feeds update -a
./scripts/feeds install -a
```
* If you are using the APU1D boards, you can select our tested configuration, by doing:
```
cp configs/config_APU.config .config
```
* Run "make menuconfig" and select a target (for instance, x86/x86_64, as when targeting the APU1D boards), then set a default config (the target should be already selected if you are using the "config_APU.config" configuration):
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
* Please note that the build process may take up to several hours, depeding on the development PC characteristics; you will find the compiled images inside "/bin/targets/x86/64/"

Once the system has been downloaded into the target embedded board and after rebooting at least once, do the following operations. They are all related to the APU1D boards, but we think that they could be easily adapted to other platforms as well:
* Connect the serial cable to the board and to your development PC and open a new connection with baud rate 115200
* Edit the "/etc/config/network" configuration file:
```
vi /etc/config/network
```
* Comment out the lines about 'bridge' and 'ip6assign' adding a # in front of them
* Add the following line, replacing '192.168.1.1' with your gateway IP address. This is needed to let the boards connect to the Internet through Ethernet, for instance to run "opkg" and update/install packages.
```
option gateway '192.168.1.1'
```
* Choose an Ethernet port, if more than one is available, by writing its name after "option ifname" (we chose the "eth2" port for our APU1D boards):
```
option ifname 'eth2'
```
* Choose an IP address, belonging to a proper subnet, for the Ethernet port: this is the address that you will need to specify when connecting a development PC to the boards using SSH (for instance, with PuTTY):
```
option ipaddr '192.168.1.182'
```
* The following steps can then be performed through serial console or by opening an SSH connection with the aforementioned IP address; in the second case, you will need to connect the boards directly to the PC or (better) to a local network at which the PC is connected too. You will then have to login with "root" as user name (no password has been set, you should choose one with "passwd" later on).
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
* If you used the pre-compiled image only, replace "/root/iw_startup" with the one included in "/files/root/iw_startup", as it is a more up-to-date version.
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
If bash is available (as in the included APU1D configuration), you can start using it by simply launching:
```
bash
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