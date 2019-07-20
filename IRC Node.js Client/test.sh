# Not tested yet
# Not tested yet
# Not tested yet
# Not tested yet

# Rapbarian Install
# Write OS to the sd card
# Add files from "Downloads\USB Gadget Mode\" to the sd card
# Depending on the network, add the "wpa_supplicant.conf" to the boot aswell

# Expand file system , and wait until network on boot options
# Change pass as well
sudo raspi-config

mkdir .ssh
chmod 700 ~/.ssh
chmod go-w ~
cd .ssh

# Generate Pub and Private keys. Add a password aswell.
# Add the ppk to auth and save it
# Put pub key from text box (remember :( )
touch authorized_keys
echo "key" >> authorized_keys

# Changes default port
sudo sed -ri 's/#?Port 22/Port 3121/' /etc/ssh/sshd_config
sudo echo "LogLevel DEBUG3" >>  /etc/ssh/sshd_config

apt-get update && apt-get -y upgrade

# Auto update
sudo su
apt-get install -y unattended-upgrades && sudo dpkg-reconfigure -plow unattended-upgrades 
echo 'Unattended-Upgrade::Automatic-Reboot "true";' >> /etc/apt/apt.conf.d/50unattended-upgrades

# Install programs needed
#select yes option for macchanger.
apt-get install -y fail2ban git firejail ufw clamtk rkhunter macchanger tor #proxychains nginx torsocks 
systemctl enable --now tor

# Fail2ban conf
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.conf.bak
sudo sed -ri 's/bantime  = 600/bantime  = 15552000/' /etc/fail2ban/jail.conf
sudo sed -ri 's/maxretry = 5/maxretry = 3/' /etc/fail2ban/jail.conf

# Firewall conf
ufw allow 3333
ufw allow 3121
ufw allow 443
ufw enable
iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 3333
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 3333
exit

#Set up node, and install thelounge
cd ~ && wget https://nodejs.org/dist/v9.9.0/node-v9.9.0-linux-armv6l.tar.gz
cd /usr/local && sudo tar xzvf ~/node-v9.9.0-linux-armv6l.tar.gz --strip=1
node -v
sudo npm i npm@latest -g
sudo npm install -g thelounge
thelounge install thelounge-theme-zenburn

# Proxychains
git clone https://github.com/rofl0r/proxychains-ng.git
cd proxychains-ng
# configure and install 
./configure --prefix=/usr --sysconfdir=/etc
make
sudo make install
sudo make install-config # installs /etc/proxychains.conf

# Find irc server ip
dig irc.subhacker.net 
# Returns 104.156.250.98

# Config thelounge
thelounge add [user]

# Create https files
cd .lounge
cp config.js config.bkp
mkdir ssl
cd ssl
openssl genrsa 1024 > key.pem
openssl req -x509 -new -key key.pem > key-cert.pem

# Enable https in the conf
sed '0,/enable: false,/s//enable: true,/' ~/.lounge/config.js > config
mv config config.js

sed -ri 's/port: 9000,/port: 3333,/' ~/.lounge/config.js
sed -ri 's/name: "Freenode",/name: "Subhacker",/' ~/.lounge/config.js
sed -ri 's/host: "chat.freenode.net",/host: "104.156.250.98",/' ~/.lounge/config.js
sed -ri 's/nick: "lounge-user",/nick: "BlankFace",/' ~/.lounge/config.js
sed -ri 's/username: "lounge-user",/username: "BlankFace",/' ~/.lounge/config.js
sed -ri 's/realname: "The Lounge User",/realname: "BlankFace",/' ~/.lounge/config.js
sed -ri 's/join: "#thelounge"/join: "#lobby"/' ~/.lounge/config.js
sed -ri 's/password: "",/password: "pass",/' ~/.lounge/config.js

line_old='key: "",'
line_new='key: "/home/pi/.lounge/ssl/key.pem",'
sed -i "s%$line_old%$line_new%g" ~/.lounge/config.js

line_old='certificate: "",'
line_new='certificate: "/home/pi/.lounge/ssl/key-cert.pem",'
sed -i "s%$line_old%$line_new%g" ~/.lounge/config.js

sed -ri 's/theme: "example",/theme: "thelounge-theme-zenburn",/' ~/.lounge/config.js
sed -ri 's/prefetch: false,/prefetch: true,/' ~/.lounge/config.js
sed -ri 's/prefetchStorage: false,/prefetchStorage: true,/' ~/.lounge/config.js

# DON'T NEED TO RUN, WAS TESTING, BUT USEFUL FOR ANOTHER PROJECT
###########################################################################################
# Torsock conf
#sudo sed -ri 's/#?AllowInbound 1/AllowInbound 1/' /etc/tor/torsocks.conf
#sudo sed -ri 's/#?AllowOutboundLocalhost 1/AllowOutboundLocalhost 2/' /etc/tor/torsocks.conf

# How to reverse proxy, not needed for the project anymore
#sudo systemctl enable nginx
#sudo rm /etc/nginx/sites-available/default
#sudo nano /etc/nginx/sites-available/default

#input:
#for reverse proxy do 

#server {
#  listen       80 default_server;
#
#  location / {
#    proxy_set_header X-Real-IP $remote_addr;
#    proxy_pass      http://127.0.0.1:3333;
#  }
#}

#sudo nginx -t
#if ok, then
#sudo /etc/init.d/nginx reload
###########################################################################################

firejail proxychains4 thelounge start
# Select zenburn theme

# Add starup file
cd /home/pi/
mkdir startup
cd startup
touch start.sh
echo "firejail proxychains4 thelounge start" >> start.sh

touch autoup
echo "#!/bin/bash" >> autoup
echo "apt-get update" >> autoup
echo "apt-get upgrade -y" >> autoup
echo "apt-get autoclean" >> autoup
echo "su pi -c '/home/pi/startup/start.sh &'" >> autoup

# Add it to run on boot
sudo su
chmod +x /home/pi/startup/start.sh
sed -ri 's/exit 0//' /etc/rc.local
echo "iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 3333" >> /etc/rc.local
echo "iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 3333" >> /etc/rc.local
echo "su pi -c '/home/pi/startup/start.sh &'" >> /etc/rc.local
echo "exit 0" >> /etc/rc.local
chmod +x rc.local

sudo cp home/pi/startup/autoup /etc/cron.daily
sudo chmod 755 /etc/cron.daily/autoup
exit

# See what's going wrong with sshd, if it isn't working right
sudo tail -50 /var/log/auth.log

# Fix ssh then do this:
sudo sed -ri 's/#?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

#Not sure to add knockd or not
