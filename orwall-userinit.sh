#!/system/bin/sh

IP6TABLES=/system/bin/ip6tables
IPTABLES=/system/bin/iptables

$IPTABLES -P OUTPUT DROP
$IPTABLES -I OUTPUT -j REJECT
$IPTABLES -I OUTPUT -o lo -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

$IPTABLES -P INPUT DROP
$IPTABLES -I INPUT -j REJECT
$IPTABLES -I INPUT -i lo -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

$IPTABLES -P FORWARD ACCEPT

$IPTABLES -N witness
$IPTABLES -A witness -j RETURN

## Block all traffic at boot ##
$IP6TABLES -t nat -F
$IP6TABLES -F
$IP6TABLES -A INPUT -j LOG --log-prefix "Denied bootup IPv6 input: "
$IP6TABLES -A INPUT -j DROP
$IP6TABLES -A OUTPUT -j LOG --log-prefix "Denied bootup IPv6 output: "
$IP6TABLES -A OUTPUT -j DROP
