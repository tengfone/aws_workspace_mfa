#!/bin/bash

#################
## PrivacyIDEA ##
#################
# Installing packages, ensure python3 is 3.6.x
yum install httpd mod_ssl python3 vim mysql -y

# Installing mod_wsgi for python3, adapted from https://stackoverflow.com/questions/42004986/how-to-install-mod-wgsi-for-apache-2-4-with-python3-5-on-centos-7
yum install -q -y centos-release-scl
yum install -q -y rh-python36-mod_wsgi
cp /opt/rh/httpd24/root/usr/lib64/httpd/modules/mod_rh-python36-wsgi.so /lib64/httpd/modules
cp /opt/rh/httpd24/root/etc/httpd/conf.modules.d/10-rh-python36-wsgi.conf /etc/httpd/conf.modules.d

systemctl enable --now httpd
mkdir /etc/privacyidea
mkdir /opt/privacyidea
mkdir /var/log/privacyidea

# Add user & perms
useradd -r -M -d /opt/privacyidea privacyidea
chown privacyidea:privacyidea /opt/privacyidea /etc/privacyidea /var/log/privacyidea

su - privacyidea <<'EOFD'

# note that this part, i change to python3 instead of py2. i use venv instead of virtualenv
python3 -m venv /opt/privacyidea
source /opt/privacyidea/bin/activate
cd /opt/privacyidea
pip3 install -U pip setuptools
pip3 install mysql-connector
export PI_VERSION=3.7.1
pip3 install -r https://raw.githubusercontent.com/privacyidea/privacyidea/v${PI_VERSION}/requirements.txt
pip3 install privacyidea==${PI_VERSION}
cat <<EOF >>/etc/privacyidea/pi.cfg
import logging
# The realm, where users are allowed to login as administrators
SUPERUSER_REALM = ['super']
# Your database
SQLALCHEMY_DATABASE_URI = 'mysql+pymysql://username:password@xxx.rds.amazonaws.com:3306/mfa'
# This is used to encrypt the auth_token
#SECRET_KEY = 't0p s3cr3t'
# This is used to encrypt the admin passwords
#PI_PEPPER = "Never know..."
# This is used to encrypt the token data and token passwords
PI_ENCFILE = '/etc/privacyidea/enckey'
# This is used to sign the audit log
PI_AUDIT_KEY_PRIVATE = '/etc/privacyidea/private.pem'
PI_AUDIT_KEY_PUBLIC = '/etc/privacyidea/public.pem'
PI_AUDIT_SQL_TRUNCATE = True
# The Class for managing the SQL connection pool
PI_ENGINE_REGISTRY_CLASS = "shared"
PI_AUDIT_POOL_SIZE = 20
PI_LOGFILE = '/var/log/privacyidea/privacyidea.log'
PI_LOGLEVEL = logging.INFO
EOF
chmod 640 /etc/privacyidea/pi.cfg

#############################################################
## Please execute these below as needed (Check encryption) ##
#############################################################
# export PEPPER="$(tr -dc A-Za-z0-9_ </dev/urandom | head -c24)"
# echo "PI_PEPPER = \"${PEPPER}\" " >>/etc/privacyidea/pi.cfg
# export SECRET="$(tr -dc A-Za-z0-9_ </dev/urandom | head -c24)"
# echo "SECRET_KEY = \"${SECRET}\" " >>/etc/privacyidea/pi.cfg

###################
## On First load ##
###################
# pi-manage create_enckey                                                 # encryption key for the database
# pi-manage create_audit_keys                                             # key for verification of audit log entries
# pi-manage createdb                                                      # create the database structure
# pi-manage db stamp head -d /opt/privacyidea/lib/privacyidea/migrations/ # stamp the db
# pi-manage admin add admin --password password
EOFD

# This part is to config the ports, instead of disabling SELinux
semanage fcontext -a -t httpd_sys_rw_content_t "/var/log/privacyidea(/.*)?"
restorecon -R /var/log/privacyidea
setsebool -P httpd_can_network_connect_db 1
setsebool -P httpd_can_connect_ldap 1
cd /etc/httpd/conf.d
mv ssl.conf ssl.conf.inactive
mv welcome.conf welcome.conf.inactive
curl -o /opt/privacyidea/lib/python3.6/site-packages/privacyidea/privacyideaapp.wsgi https://raw.githubusercontent.com/NetKnights-GmbH/centos7/master/SOURCES/privacyideaapp.wsgi

cat <<EOF >>privacyidea.conf
Listen 0.0.0.0:443 https
TraceEnable off
ServerSignature Off
ServerTokens Prod
WSGISocketPrefix /var/run/wsgi
<VirtualHost _default_:443>
ServerAdmin webmaster@localhost
ServerName localhost
DocumentRoot /var/www
<Directory />
Require all granted
Options FollowSymLinks
AllowOverride None
</Directory>
ErrorLog logs/ssl_error_log
TransferLog logs/ssl_access_log
LogLevel warn
SSLCertificateFile /etc/pki/tls/certs/localhost.crt
SSLCertificateKeyFile /etc/pki/tls/private/localhost.key

WSGIDaemonProcess privacyidea processes=1 threads=15 display-name=%{GROUP} user=privacyidea python-path=/opt/privacyidea/lib/python3.6/site-packages python-home=/opt/privacyidea/
WSGIProcessGroup privacyidea
WSGIPassAuthorization On
WSGIScriptAlias / /opt/privacyidea/lib/python3.6/site-packages/privacyidea/privacyideaapp.wsgi
SSLEngine On
SSLProtocol All -SSLv2 -SSLv3
SSLHonorCipherOrder On
SSLCipherSuite EECDH+AES256:DHE+AES256:EECDH+AES:EDH+AES:-SHA1:EECDH+RC4:EDH+RC4:RC4-SHA:AES256-SHA:!aNULL:!eNULL:!EXP:!LOW:!MD5

BrowserMatch "MSIE [2-5]" \
         nokeepalive ssl-unclean-shutdown \
         downgrade-1.0 force-response-1.0

CustomLog logs/ssl_request_log \
          "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"

</VirtualHost>
EOF
chmod -R 775 /opt/privacyidea/
systemctl restart httpd

# Finally use this to test
# curl https://localhost:443 --insecure
## Error Logs ##
# cat /etc/httpd/logs/error_log
# vim /etc/httpd/conf.d/privacyidea.conf

#################
## FREE RADIUS ##
#################

# Installing dependencies, requires epel for some perl protocols
yum install epel-release -y
yum install gcc libjpeg-devel freeradius freeradius-utils freeradius-perl perl-JSON \
    openldap-devel perl-libwww-perl perl-Try-Tiny perl-Data-Dump perl-Config-IniFiles perl-URI-Encode perl-LWP-Protocol-https perl-Crypt-SSLeay -y
curl -o /etc/raddb/mods-config/perl/privacyidea_radius.pm https://raw.githubusercontent.com/privacyidea/FreeRADIUS/master/privacyidea_radius.pm
chmod -R 775 /etc/raddb/mods-config/perl/privacyidea_radius.pm

# Ensure all auth is done by perl
sed -i '1s/^/DEFAULT Auth-Type := perl \n/' /etc/raddb/users
sed -i "/filename = /c \ \ \ \ \ \ \ \ filename = /etc/raddb/mods-config/perl/privacyidea_radius.pm" /etc/raddb/mods-available/perl

# To note, mods-enabled are symbolic links, if require edit, edit file from mods-available
ln -s /etc/raddb/mods-available/perl /etc/raddb/mods-enabled/

# Clients for each workspace, please change here accordingly
cat <<EOT >/etc/raddb/clients.conf
client localhost {
ipaddr = 127.0.0.1
secret = password
netmask = 32
}
# AD Connector, insert AD DNS here
client microsoftad{
ipaddr  = 100.1.1.0
netmask = 24
secret  = 'MICROSOFTAD'
}
EOT

cat <<EOF >>/etc/raddb/sites-available/privacyidea

server default {
listen {
type = auth
ipaddr = *
port = 0
limit {
max_connections = 16
lifetime = 0
idle_timeout = 30
}
}
listen {
ipaddr = *
port = 0
type = acct
}authorize {
preprocess
IPASS
suffix
ntdomain
files
expiration
logintime
update control {
Auth-Type := Perl
}
pap
}authenticate {
Auth-Type Perl {
perl
}
}preacct {
preprocess
acct_unique
suffix
files
}accounting {
detail
unix
-sql
exec
attr_filter.accounting_response
}session {
}
post-auth {
update {
&reply: += &session-state:
}
-sql
exec
remove_reply_message_if_eap
}
}

EOF

ln -s /etc/raddb/sites-available/privacyidea /etc/raddb/sites-enabled/
rm /etc/raddb/sites-enabled/default -f
rm /etc/raddb/sites-enabled/inner-tunnel -f
rm /etc/raddb/mods-enabled/eap -f

# Perl configs, note REALM input.
cat <<EOF >>/etc/privacyidea/rlm_perl.ini
[Default]
URL = https://127.0.0.1/validate/check
# REALM = test
SSL_CHECK = false
#RESCONF = someResolver
#DEBUG = true
EOF

chmod 755 /etc/privacyidea/rlm_perl.ini
sed -i '/our $CONFIG_FILE =/c\our $CONFIG_FILE = "/etc/privacyidea/rlm_perl.ini";' /etc/raddb/mods-config/perl/privacyidea_radius.pm
yes | cp -rf /opt/privacyidea/etc/privacyidea/dictionary /etc/raddb/
systemctl restart radiusd

#################
## FOR TESTING ##
#################
# service radiusd stop
# radiusd -X
# echo "User-Name=admin, User-Password=password" | radclient -sx localhost auth testing123
# radtest USERNAME MFACODE PRIVATERADIUSIP:1812 10 SECRETWORD
# systemctl restart radiusd

#################
## References  ##
#################
# from https://privacyidea.readthedocs.io/en/latest/installation/centos.html#py3 , pls note i using python3 instead of the guide py2
# https://www.privacyidea.org/two-factor-authentication-with-otp-on-centos-7/
# https://www.howtoforge.com/two-factor-authentication-with-otp-using-privacyidea-and-freeradius-on-centos
# https://privacyidea.readthedocs.io/en/latest/application_plugins/rlm_perl.html
