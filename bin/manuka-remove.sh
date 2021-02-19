#!/bin/bash
## services
# systemd
systemctl disable manuka
rm /etc/systemd/system/manuka.service
systemctl daemon-reload
# logrotate
rm /etc/logrotate.d/manuka
# fail2ban
rm /etc/fail2ban/filter.d/traefik-auth.conf
rm /etc/fail2ban/jail.d/traefik-auth.conf
printf "[sshd]\nenabled = true" > /etc/fail2ban/jail.d/defaults-debian.conf
fail2ban-client reload
# opt
rm -r /opt/manuka
# ssh
sed -i 's|Port 50220|#Port 22|' "/etc/ssh/sshd_config"