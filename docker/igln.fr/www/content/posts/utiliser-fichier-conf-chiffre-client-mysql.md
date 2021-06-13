+++
date = "2017-07-21TO8:00:00+02:00"
author = "Kévin Met"
title = "Utiliser un fichier de conf chiffré pour le client mysql"
slug = "utiliser-fichier-conf-chiffre-client-mysql"
description = "Ce tutoriel explique la configuration de lsyncd sur Debian en utilisant rsync via SSH."
categories = ["blog"]
tags = ["mysql"]
+++

### Introduction

Ça faisait un bon moment que je n'avais pas publié sur le blog alors je reviens avec un petit billet un peu court sur une découverte que j'ai faites il y a peu. Il s'agit de l'option **--login-path** du client **mysql**.

Cela permet de chiffrer un fichier de config qui reprend un peu la même syntaxe qu'un fichier **.my.cnf**. On peut ensuite utiliser ce fichier avec l'option **--login-path** en ciblant un groupe qui peut comprendre les éléments suivants :

* host
* user
* password
* port
* socket

<!--more-->

On voit de suite le côté pratique de ce genre de fonctionnalité pour les scripts car cela permet enfin de se passer du fichier **.my.cnf** et on peut enfin être sur que le password ne va ni traîner dans le script en lui même, ni dans un fichier **.my.cnf** sur lequel on aura oublié de mettre les bons droits. Par contre, il ne faut pas oublier que ce fichier est un simple fichier chiffré qui peut être plus ou moins simplement déchiffré et qu'il faut donc y faire aussi attention que si il s'agissait d'un **.my.cnf**. J'aborderai ce point dans une troisième partie.

La génération et l'édition du fichier se fait avec l'utilitaire **mysql_config_editor** et rien de tel qu'un cas d'utilisation concrète pour en comprendre le fonctionnement.

### Un exemple concret d'utilisation

Pour commencer, on va créer notre fichier avec un premier groupe que l'on va nommer **bob** :

* host : 127.0.0.1
* user : bob
* port : 3306

```shell
mysql_config_editor set -G bob -u bob -h 127.0.0.1 -P 3306 -p
Enter password:
```

Une fois qu'on a rentré notre password, le fichier **.mylogin.cnf** est créé à la racine de notre dossier utilisateur et on peut l'utiliser pour se connecter :

```shell
mysql --login-path=bob
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 34096
Server version: 5.6.36-82.0 Percona Server (GPL), Release 82.0, Revision 58e846a

Copyright (c) 2009-2017 Percona LLC and/or its affiliates
Copyright (c) 2000, 2017, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> quit
Bye
```

Maintenant qu'on a vu ça, on va ajouter un groupe avec les éléments suivants :

* host : 127.0.0.1
* user : alice
* socket : /var/run/mysqld/mysqld.sock

```shell
mysql_config_editor set -G alice -u alice -S /var/run/mysqld/mysqld.sock -p
Enter password:
```

On peut maintenant se connecter avec le groupe alice :

```shell
mysql --login-path=alice
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 34288
Server version: 5.6.36-82.0 Percona Server (GPL), Release 82.0, Revision 58e846a

Copyright (c) 2009-2017 Percona LLC and/or its affiliates
Copyright (c) 2000, 2017, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> quit
Bye
```

Si on veut afficher les différents groupes, il faut utiliser le paramètre **print** avec le flag **--all** :

```shell
mysql_config_editor print --all
[bob]
user = bob
password = *****
host = 127.0.0.1
port = 3306
[alice]
user = alice
password = *****
socket = /var/run/mysqld/mysqld.sock
```

Et maintenant, on va supprimer le groupe bob :

```shell
mysql_config_editor remove -G bob
```

Et du coup, quand on affiche le contenu de **.mylogin.cnf**

```shell
mysql_config_editor print --all
[alice]
user = alice
password = *****
socket = /var/run/mysqld/mysqld.sock
```

Bref, vous avez compris comment ça marche, c'est facile à mettre en place et à utiliser mais il ne faut pas penser que c'est totalement sécurisé car le fichier est chiffré.

### Sécurité

Comme on peut le voir, le fichier **.mylogin.cnf** est chiffré :

```shell
cat .mylogin.cnf

R1�ei�RFU���A4U*������lb��� u�O@|�=�͐�TȰ�d���9��dJ�ƁL0޽��S�!�{}r8<)�f[]c��Ƅ�L�H�O݆��|=Ւ��D�
```

Il s'agit d'un chiffrement symétrique utilisant un cipher [AES-128 ECB](https://github.com/mysql/mysql-server/blob/3e90d07c3578e4da39dc1bce73559bbdf655c28c/client/mysql_config_editor.cc#L1171). La clé est générée aléatoirement lors de la création du fichier **.mylogin.cnf** et est stockée dans l'entête de ce fichier. Il est donc très simple de le déchiffrer si on cherche un peu dans le code source de **MySQL**. Mais il existe une solution encore plus simple ! Il suffit d'utiliser l'utilitaire **my_print_defaults** avec l'option **-s** qui permet d'afficher les mots de passe.

Dans notre cas, voici ce que cela donne en spécifiant le groupe alice :

```shell
my_print_defaults -s alice
--user=alice
--password=monpassword
--socket=/var/run/mysqld/mysqld.sock
```

Il s'agit donc d'une bonne alternative au fait de laisser les mots des passe en clair dans des scripts ou dans l'historique **bash** mais si ce fichier est compromis, il faut considérer que toutes les connexions stockées sont compromises, et donc, à changer. Il est donc important de continuer à appliquer des droits très strictes sur ce fichier, `0400` quand c'est possible ou `0600`.

Source : [https://www.percona.com/blog/2016/09/07/get-passwords-plain-text-mylogin-cnf/](https://www.percona.com/blog/2016/09/07/get-passwords-plain-text-mylogin-cnf/)
