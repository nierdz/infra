This repo contains parts of roles I use in my daily routines as a sysadmin working at [MNT-TECH](https://mnt-tech.fr/)
For the moment, only Debian/Ubuntu is supported as I only work with those distributions.
You can use it at your own risk and do whathever you want with it.

# Roles #
## NRPE ##
> Be aware that this role name is not very well chosen cause it configures nrpe server AND nagios !

This role will install nrpe server and configure it with some parameters. It will also configure nagios server according to those parameters. You can add those parameters inside a file named after the hostname of your server in a folder named host_vars. This is only a suggestion and there is some other ways to add those variables in ansible. Here is an example of those variables :
First you need to set the hostname of your server which will be used in nagios configuration
```mnttech_fqdn: webserver1.example.com```

Then you need to add the fqdn of your nagios server (maybe in group_vars as it will be used by several servers)
It will be used to configure nagios server, by default, configuration files are generated inside /etc/nagios3/servers/ (on file per host)
```nagios_fqdn: nagios.example.com```

Of course, ansible server need to be able to connect to your nagios server.

Then you need to add your nagios IP server as it will be used in nrpe configuration file to enable nagios to connect to it.
```nagios_ip: 192.168.1.1```

And now you need to configure nagios group and nagios type.
Nagios group is the group you want to add this server in. No need to create this group in nagios, it will be automatically added to /etc/nagios3/conf.d/hostgroups_nagios2.cfg if it doesn't exist.
```nagios_group: MY-GROUP```

The nagios type is the service template which will be used by service definition. For example, I have one service definition in nagios named HNO (in french Heures non ouvrées). It means that I can be alerted 24/7 for this host. Here is the service definition:
```
define service {
    name                            HNO-services
    use                             generic-service
    check_period                    HNO
    notification_period             HNO
}
```
Here is the timeperiod definition attached to this service:
```
define timeperiod{
    timeperiod_name HNO
    alias           Heures non ouvrees
    sunday          00:00-24:00
    monday          00:00-24:00
    tuesday         00:00-24:00
    wednesday       00:00-24:00
    thursday        00:00-24:00
    friday          00:00-24:00
    saturday        00:00-24:00
}
```
So if I want to use this template for all services on my host I use:
```nagios_type : HNO```
> Notice that a -service is automatically added so you need to take care of that

Now comes all the service you want to add in nagios, no need to explain, it's pretty self explanatory:

```
check_users:
  warning: 10
  critical: 50

check_load:
  warning: 8,4,2
  critical: 16,8,4
  max_check_attempts: 30

check_disk:
  _ROOT:
    path: /
    warning: 20
    critical: 10

check_zombie_procs:
  warning: 5
  critical: 10

check_total_procs:
  warning: 150
  critical: 200

check_swap:
  warning: 20
  critical: 10

check_memory:
  warning: 20
  critical: 10

check_ping:
  warning: 100.0,20%
  critical: 500.0,60%

check_mailq:
  warning: 50
  critical: 80
```

Ther is a special service added in this role which is not listed here, [Integrit](https://github.com/ecashin/integrit). You need to add this service definition in nagios to only check for it every hour cause it consumes a lot of IO:
```
define service{
    name                            integrit-services
    use                             HO-services
    max_check_attempts              1
    normal_check_interval           60
    check_interval                  60
    notification_interval           60
}
```
You can even launch only one check per day if you want.

The role will add some basic configuration of integrit used by nrpe inside /etc/integrit/nagios.conf. You need to edit this file according to your needs.
It will add another file to reset the database : /opt/integrit/db_update.sh. Launch this script after you acknowledge a problem.

For a full explanation of the way intergrit works and how this ansible role deploy it, you can read this [blog post](https://mnt-tech.fr/blog/presentation-de-loutil-integrit-integration-nagios/) (FRENCH)


## Integrit ##
This role is pretty simple, it only launches this script : /opt/integrit/db_update.sh. It's usefull after you upgrade or you change configuration files.
