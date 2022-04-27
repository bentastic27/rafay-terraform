#!/bin/sh
grep -v REJECT /etc/iptables/rules.v4 > /tmp/withoutreject
mv -f /tmp/withoutreject /etc/iptables/rules.v4
chmod 644 /etc/iptables/rules.v4
iptables-restore < /etc/iptables/rules.v4