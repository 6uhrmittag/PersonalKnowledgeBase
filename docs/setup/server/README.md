# Ubuntu Server

Simple script to setup some basic stuff. It doesn't follow any rules or best practices, it's just to quickly set up an Ubuntu server to safely leave it running for a while.

````shell
#!/bin/bash
set -e
set -u
set -o pipefail

# Ensure running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# ask for email
echo "Enter your email address for certs via acme: "
read email

# Update and upgrade system packages
echo "Updating system packages..."
apt-get update -qq && apt-get dist-upgrade -y -qq

# SSH Configuration
echo "Configuring SSH..."
sed -i '/^#PermitRootLogin prohibit-password/c\PermitRootLogin prohibit-password' /etc/ssh/sshd_config
echo "AllowUsers root" >> /etc/ssh/sshd_config

# Restart SSH service
systemctl restart ssh

# Install Fail2Ban
echo "Installing Fail2Ban..."
apt-get install fail2ban -y -qq

# Creating a custom Fail2Ban filter for non-root login attempts
cat > /etc/fail2ban/filter.d/sshd-notroot.conf <<EOF
[INCLUDES]
before = common.conf

[Definition]
_daemon = sshd

failregex = ^%(__prefix_line)sFailed \S+ for invalid user .* from <HOST>( port \d+)?( ssh\d*)?$
            ^%(__prefix_line)sFailed \S+ for illegal user .* from <HOST>( port \d+)?( ssh\d*)?$
            ^%(__prefix_line)sFailed \S+ for (?!root).* from <HOST>( port \d+)?( ssh\d*)?$

ignoreregex =
EOF

# Configuring a jail for the custom filter without email notifications
cat > /etc/fail2ban/jail.d/sshd-notroot.conf <<EOF
[sshd-notroot]
enabled  = true
filter   = sshd-notroot
action   = iptables[name=SSH, port=ssh, protocol=tcp]
logpath  = /var/log/auth.log
maxretry = 5
EOF

# Restart Fail2Ban to apply the changes
systemctl restart fail2ban

# Install and configure Nginx
echo "Installing Nginx..."
apt-get install nginx -y -qq

# Install necessary packages
echo "Installing necessary packages..."
apt-get install nginx snapd -y

# Initial configuration of Nginx for the domain without SSL
echo "Setting up Nginx for initial HTTP access..."
cat > /etc/nginx/sites-available/ssh.slashlog.org <<EOF
server {
    listen 80;
    server_name ssh.slashlog.org w.slashlog.org home.slashlog.org;

    root /var/www/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# Enable the site by creating a symlink
ln -s /etc/nginx/sites-available/ssh.slashlog.org /etc/nginx/sites-enabled/

# Check Nginx configuration and reload service
nginx -t && systemctl reload nginx

echo "Creating Certificates with acme.sh..."
apt-get install -y socat curl
# Ensure the SSL directory exists
mkdir -p /etc/nginx/ssl

curl https://get.acme.sh | sh -s email=$email

source ~/.acme.sh/acme.sh.env

# Issue and install certificates using acme.sh with webroot mode
echo "Obtaining SSL certificates with acme.sh..."
~/.acme.sh/acme.sh --issue -d ssh.slashlog.org -d w.slashlog.org -d home.slashlog.org -w /var/www/html --keylength ec-256
~/.acme.sh/acme.sh --install-cert -d ssh.slashlog.org -d w.slashlog.org -d home.slashlog.org --ecc \
--key-file       /etc/nginx/ssl/ssh.slashlog.org.key \
--fullchain-file /etc/nginx/ssl/ssh.slashlog.org.cer \
--reloadcmd     "systemctl reload nginx"

# Automatically update Nginx configuration for HTTPS
echo "Updating Nginx configuration for HTTPS..."
cat > /etc/nginx/sites-available/ssh.slashlog.org <<EOF
server {
    listen 80;
    server_name ssh.slashlog.org w.slashlog.org home.slashlog.org;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ssh.slashlog.org w.slashlog.org home.slashlog.org;

    ssl_certificate /etc/nginx/ssl/ssh.slashlog.org.cer;
    ssl_certificate_key /etc/nginx/ssl/ssh.slashlog.org.key;

    root /var/www/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# Reload Nginx to apply SSL configuration
nginx -t && systemctl reload nginx


# Enable automatic security updates
echo "Configuring automatic security updates..."
apt-get install unattended-upgrades -y -qq
cat > /etc/apt/apt.conf.d/50unattended-upgrades <<EOF
Unattended-Upgrade::Allowed-Origins {
        "Ubuntu xenial-security";
};
Unattended-Upgrade::Automatic-Reboot "true";
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

# Configure UFW
echo "Configuring UFW..."
apt-get install ufw -y
ufw default deny incoming
ufw default allow outgoing

# Configure UFW to allow necessary services
echo "Configuring UFW..."
ufw allow 22/tcp    # Allow SSH
ufw allow 80/tcp    # Allow HTTP for Certbot verification and optional HTTP access
ufw allow 443/tcp   # Allow HTTPS
ufw deny out 25     # Block outgoing SMTP
ufw deny out 587    # Block outgoing Submission
ufw deny out 465    # Block outgoing SMTPS
ufw --force enable

# Enable UFW
ufw --force enable

# Cleanup unnecessary packages
echo "Removing unnecessary packages..."
apt-get autoremove -y -qq
apt-get autoclean -y -qq

echo "Setup complete. Please review any manual steps and configurations."
````
