#!/bin/bash
#############################################################
# post engintron install for automated HTTP/2 configuration #
#       by Xtudio Networks SL - https://sered.net	    #
#############################################################

ACTION=$1
RED='\033[01;31m'
GREEN='\033[01;32m'
RESET='\033[0m'
nginx_path="/etc/nginx"

options() {
echo $"
   ____                             ___
  6MMMMb\    Xtudio Networks SL      MM
 6M            engintron HTTP/2      MM
 MM     ____   ___  __   ____    ____MM
 YM.   6MMMMb   MM 6MM  6MMMMb  6MMMMMM
 "

echo -e "Options:

	-install
    	-uninstall"
	
	printf "\n"
    
 exit 0
 }

function apache_ssl_change_port {
 
 	echo "[+] Switch Apache SSL to port 1443, distill changes & restart Apache"
 
 	if [ -f /usr/local/cpanel/bin/whmapi1 ]; then
 		/usr/local/cpanel/bin/whmapi1 set_tweaksetting key=apache_ssl_port value=0.0.0.0:1443 &> /dev/null
 	else
 		if grep -Fxq "apache_ssl_port=" /var/cpanel/cpanel.config
 		then
 			sed -i 's/^apache_ssl_port=.*/apache_ssl_port=0.0.0.0:1443/' /var/cpanel/cpanel.config
 			/usr/local/cpanel/whostmgr/bin/whostmgr2 --updatetweaksettings &> /dev/null
 		else
 			echo "apache_ssl_port=0.0.0.0:1443" >> /var/cpanel/cpanel.config
 		fi
 	fi
 
 	echo "[+] Distill changes in Apache's configuration and restart Apache"
 	/usr/local/cpanel/bin/apache_conf_distiller --update &> /dev/null
 	/scripts/rebuildhttpdconf &> /dev/null
 	/scripts/restartsrv httpd &> /dev/null
}


function build_ssl_vhosts {

	echo "[+]Building SSL vhost for all cpanel users"
 
	cp -R scripts /etc/nginx/scripts
        chmod +x /etc/nginx/scripts/*
 	mkdir -p /etc/nginx/scripts /etc/nginx/vhost.ssl.d /etc/nginx/ssl.cert.d
 	/etc/nginx/scripts/build-ssl-vhosts
 	
 	echo ""
 	echo ""
}
 
nGinxConf (){
cat << 'EOF' > /etc/nginx/nginx.conf
# /**
#  * @version    1.7.3
#  * @package    Engintron for cPanel/WHM
#  * @author     Fotis Evangelou
#  * @url        https://engintron.com
#  * @copyright  Copyright (c) 2010 - 2016 Nuevvo Webware P.C. All rights reserved.
#  * @license    GNU/GPL license: http://www.gnu.org/copyleft/gpl.html
#  */

user nginx;
worker_processes auto;
worker_rlimit_nofile 65535;
pid /var/run/nginx.pid;

events {
    worker_connections 8192;
    multi_accept on;
}

http {
    ## Basic Settings ##
    client_body_timeout            20s; # Use 5s for high-traffic sites
    client_header_timeout          20s; # Use 5s for high-traffic sites
    client_max_body_size           1024m;
    keepalive_timeout              20s;
    port_in_redirect               off;
    sendfile                       on;
    server_names_hash_bucket_size  64;
    server_name_in_redirect        off;
    server_tokens                  off;
    tcp_nodelay                    on;
    tcp_nopush                     on;
    types_hash_max_size            2048;

    ## DNS Resolver ##
    # If in China, enable the OpenDNS entry that matches your network connectivity (IPv4 only or IPv4 & IPv6)
    # OpenDNS (IPv4 & IPv6)
    #resolver                      208.67.222.222 208.67.220.220 [2620:0:ccc::2] [2620:0:ccd::2];
    # OpenDNS (IPv4 only)
    #resolver                      208.67.222.222 208.67.220.220;
    # Google Public DNS (IPv4 & IPv)
    #resolver                      8.8.8.8 8.8.4.4 [2001:4860:4860::8888] [2001:4860:4860::8844];
    # Google Public DNS (IPv4 only)[default]
    resolver                       8.8.8.8 8.8.4.4;

    # CloudFlare
    # List from: https://www.cloudflare.com/ips-v4
    set_real_ip_from 103.21.244.0/22;
    set_real_ip_from 103.22.200.0/22;
    set_real_ip_from 103.31.4.0/22;
    set_real_ip_from 104.16.0.0/12;
    set_real_ip_from 108.162.192.0/18;
    set_real_ip_from 131.0.72.0/22;
    set_real_ip_from 141.101.64.0/18;
    set_real_ip_from 162.158.0.0/15;
    set_real_ip_from 172.64.0.0/13;
    set_real_ip_from 173.245.48.0/20;
    set_real_ip_from 188.114.96.0/20;
    set_real_ip_from 190.93.240.0/20;
    set_real_ip_from 197.234.240.0/22;
    set_real_ip_from 198.41.128.0/17;
    set_real_ip_from 199.27.128.0/21;
    # List from: https://www.cloudflare.com/ips-v6
    set_real_ip_from 2400:cb00::/32;
    set_real_ip_from 2405:8100::/32;
    set_real_ip_from 2405:b500::/32;
    set_real_ip_from 2606:4700::/32;
    set_real_ip_from 2803:f800::/32;
    set_real_ip_from 2c0f:f248::/32;
    set_real_ip_from 2a06:98c0::/29;
    # Replace with correct visitor IP
    real_ip_header X-Forwarded-For;

    ## MIME ##
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    ## Logging Settings ##
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    ## Gzip Settings ##
    gzip on;
    gzip_buffers 16 8k;
    gzip_comp_level 5;
    gzip_disable "msie6";
    gzip_min_length 256;
    gzip_proxied any;
    gzip_types
        application/atom+xml
        application/javascript
        application/json
        application/ld+json
        application/manifest+json
        application/rss+xml
        application/vnd.geo+json
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-javascript
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/opentype
        image/bmp
        image/svg+xml
        image/x-icon
        text/cache-manifest
        text/css
        text/javascript
        text/plain
        text/vcard
        text/vnd.rim.location.xloc
        text/vtt
        text/x-component
        text/x-cross-domain-policy
        text/x-js
        text/xml;
    gzip_vary on;

    # Proxy Settings
    proxy_cache_path /tmp/engintron_dynamic levels=1:2 keys_zone=engintron_dynamic:20m inactive=10m max_size=500m;
    proxy_cache_path /tmp/engintron_static levels=1:2 keys_zone=engintron_static:20m inactive=10m max_size=500m;
    proxy_temp_path /tmp/engintron_temp;

    ## Virtual Host Configs ##
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/vhost.ssl.d/*.conf;
}

EOF
}
 
function install() {
apache_ssl_change_port
build_ssl_vhosts
nGinxConf

echo "[+] Finished installing post-engintron-install!"
echo -e "[+] Add the following cronjob \"$GREEN * * * * * $nginx_path/scripts/apache-conf-check &>/dev/null $RESET\" to root's crontab."

echo "Restarting nginx"
service nginx restart
}

uninstall() {
 
 	echo "[+] Switch Apache SSL back to port 443"
 
 	if [ -f /usr/local/cpanel/bin/whmapi1 ]; then
 		/usr/local/cpanel/bin/whmapi1 set_tweaksetting key=apache_ssl_port value=0.0.0.0:443 &> /dev/null
 	else
 		if grep -Fxq "apache_ssl_port=" /var/cpanel/cpanel.config
 		then
 			sed -i 's/^apache_ssl_port=.*/apache_ssl_port=0.0.0.0:443/' /var/cpanel/cpanel.config
 			/usr/local/cpanel/whostmgr/bin/whostmgr2 --updatetweaksettings &> /dev/null
 		else
 			echo "apache_ssl_port=0.0.0.0:443" >> /var/cpanel/cpanel.config
 		fi
 	fi
 
 	echo "[+] Distill changes in Apache's configuration and restart Apache"
 	/usr/local/cpanel/bin/apache_conf_distiller --update &> /dev/null
 	/scripts/rebuildhttpdconf &> /dev/null
 	/scripts/restartsrv httpd &> /dev/null

	replace 'include /etc/nginx/vhost.ssl.d/*.conf;' '' -- /etc/nginx/nginx.conf &> /dev/null

	echo "[+] Finished removing post-engintron-install!"
	echo -e "[+] Please remove the following cronjob \"$GREEN * * * * * $nginx_path/scripts/apache-conf-check &>/dev/null $RESET\" from root's crontab if you set it up."
}

[ -z $ACTION ] && options && exit 1

case $ACTION in
	"-install")             	  install;;
	"-uninstall")         	  uninstall;;
	*)                    options;;
esac

exit 0
