+++
date = "2017-02-01T14:54:37+02:00"
author = "Kévin Met"
title = "Fonctionnement et configuration d'OPcache"
slug = "opcache-configuration-et-fonctionnement"
description = "Fonctionnement et configuration d'OPcache de PHP."
categories = ["blog"]
tags = ["php", "opcache"]
+++

Aujourd’hui on va parler de **Zend OPcache**, un sujet qui peut sembler un peu fade car c’est quelque chose qu’on manipule assez régulièrement depuis qu’il est inclus dans PHP mais finalement, j’ai quand même trouvé pas mal de chose à raconter et je vais essayer d’aller un peu en profondeur au long de cet article. C’est bien d’avoir de l’ambition en début d’article, on verra si je tiens mes promesses... 😉

<!--more-->

### Historique

A la base, OPcache se nommait **Zend Optimizer+** et était payant donc assez peu utilisé surtout qu’il avait des concurrents gratuits et qui fonctionnaient très bien. Il y avait, entre autres **APC**, **eAccelerator**, **Xcache** et j’en oublie volontairement d’autres... APC devait même être intégré à la version 6 de PHP qui n’a jamais vu le jour. Par la suite Zend Optimizer+ a été rendu open source et intégré à partir de la **version 5.5** dans le core de PHP ce qui fait qu’il domine maintenant très largement le marché.

### Différences entre APC et OPcache

Pour poursuivre un peu avec le dernier paragraphe on a souvent présenté OPcache comme le remplaçant direct d’APC, ce qui n’est pas tout à fait vrai car il ne reprend pas les même fonctionnalités. En effet, APC permettait de **cacher l’opcode** généré par PHP et de **gérer un cache utilisateur**, le **data store**, alors que Zend OPcache permet **d’optimiser et de cacher** l’opcode généré par PHP. La différence est donc de taille car on ne retrouve pas la fonction de data store dans OPcache et c’est pourquoi il existe une nouvelle extension PHP nommé [APCu](http://php.net/manual/en/book.apcu.php) qui reprend le code d’APC en ne conservant que la partie cache utilisateur. Par contre APC ne faisait pas d'optimisation du bytecode ce qu'ajoute OPcache.

### Principe de fonctionnement de Zend OPcache

Maintenant qu’on a vu ces différences on va rentrer un peu plus en détail dans le fonctionnement d’OPcache. Comme je l’expliquais précédemment, il permet de faire deux choses bien distinctes, une partie **optimise le bytecode** et l’autre le **met en cache dans la mémoire partagée**. Ces deux fonctions permettent donc d’apporter un gain non négligeable à votre applicatif PHP. Mais qu’est-ce que l’opcode exactement ? Et bien lorsque PHP interprète un fichier source il passe par plusieurs phases. Il commence par faire une **analyse syntaxique** (parser + lexer) du code source en PHP, il **compile ensuite en opcode** (la liste complète des opcodes [ici](http://php.net/manual/en/internals2.opcodes.php)) et enfin il **exécute cet opcode** qui donne le résultat.

Voici un superbe schéma que j’ai réalisé sur mon beau tableau blanc pour représenter tout cela et vous allez voir que mes talents de dessinateurs sont dignes de Van Gogh 😄

{{< figure src="/2017/02/php-opcode-compilation.jpg" title="php opcode compilation" alt="php opcode compilation" >}}

Maintenant que j’ai perdu toute crédibilité grâce à ce schéma on va voir où intervient le Zend OPcache avec... un autre schéma !

{{< figure src="/2017/02/php-opcache-opcode.jpg" title="php opcache opcode" alt="php opcache opcode" >}}

Bon, promis, j’arrête avec mes schémas dégueulasses. On voit donc qu’OPcache intervient **après la compilation en optimisant l’opcode et en le cachant en mémoire partagée**. Lors du prochain appel à ce script PHP, Zend Engine sera donc capable d’aller vérifier si le **bytecode** est dans la mémoire et directement l’exploiter si c’est le cas, ce qui représente un gain assez important car on s’évite une lecture du fichier sur le disque, une analyse syntaxique et une compilation. Dans la suite de l'article j'utiliserai **bytecode ou opcode** car c'est la même chose, du **code intermédiaire**

### La partie optimisation

L’optimisation est la partie qui ne demande aucun réglage car elle est activée par défaut au plus haut niveau et elle fonctionne parfaitement. En gros, cette partie s’occupe de **virer tout les opcodes inutiles** après que Zend Engine soit passé. Par exemple, les conditions qui ne seront jamais vraies, les exit superflus et tout un tas d’autres trucs. Si jamais vous avez envie de faire du tuning sur cette partie cela passe par l’utilisation de cette variable de configuration : **opcache.optimization_level**. Il faut également savoir que de nombreuses optimisations présentes dans OPcache sont directement passées dans Zend Engine dans la version 7 de PHP.

Concrètement cela donne quoi ? On va voir un petit exemple avec un script assez basique et l’extension [vld](https://pecl.php.net/package/vld) qui permet de dumper le bytecode avant qu’il soit exécuté. Voici le script en question :

```php
<?php
if (true) {
  echo 1 + 2;
} else {
  echo "KO";
}
?>
```

Voici le bytecode sans utilisation d’OPcache :

```
line     #* E I O op                           fetch          ext  return  operands
-------------------------------------------------------------------------------------
   2     0  E > > JMPZ                                                     <true>, ->3
   3     1    >   ECHO                                                     3
         2      > JMP                                                      ->4
   5     3    >   ECHO                                                     'KO'
   8     4    > > RETURN                                                   1
```

On voit qu’on a des opcodes qui ne servent à rien, le JPMZ, le JMP et le ECHO 'KO'. Voici la version avec OPcache activé :

```
    line     #* E I O op                           fetch          ext  return  operands
    -------------------------------------------------------------------------------------
       3     0  E >   ECHO                                                     3
       8     1      > RETURN                                                   1
```

On peut voir le **gain en efficacité qu’apporte OPcache** dans ce genre de situation assez caricaturale. En situation réelle, on s’accorde à dire que la partie optimisation n’apporte qu’un gain de 10 % (cf pas de sources mais tu peux me croire sur parole). Tout cela dépend bien évidemment de la façon dont votre code est écrit et optimisé à la base.

Il y a une seconde optimisation qui est faite via OPcache et qui concerne les **chaînes de caractères** dans votre code. Toutes les chaînes identiques vont être **stockées en mémoire dans un seul pointeur** et celui-ci sera appelé à chaque fois que le code utilise cette chaîne. Cela évite de faire une allocation mémoire à chaque fois qu’une chaîne similaire est détectée.

### La partie cache

Là on attaque le gros du sujet car c’est là que la configuration par défaut est vraiment moisie et qu’il faut faire le plus de changements. En plus de cela il faut faire des choix sur la façon dont on va fonctionner pour invalider le cache. Déjà on va bien distinguer entre la dev et la prod car on ne veut évidemment pas que les devs nous tombent dessus car l’environnement de dev ne reflète pas les changements qui sont apportés aux sources de l’applicatif. On va donc commencer par voir les différents mécanismes d’invalidation en listant quelques options de configuration relatives à ce sujet.

Il faut savoir qu’au lancement d’OPcache, que ce soit via le **mod_php d’apache** ou via un **pool php-fpm**, celui-ci va allouer une partie de la mémoire qu’il **divisera en plusieurs segments** lui même et qui ne sera **jamais libéré durant la vie du processus**. La taille de ce morceau de mémoire est défini par le paramètre **opcache.memory_consumption** et est donc invariable durant toute la vie du processus php mais on en reparlera plus en détail par la suite.

### Revalidation via timestamp

Ce type de revalidation du cache fonctionne avec deux paramètres :

*   **opcache.validate_timestamps**
*   **opcache.revalidate_freq**

**opcache.validate_timestamps** est un booléen qui active ou non la revalidation via timestamp (par défaut à true) et **opcache.revalidate_freq** est le temps en secondes avant lequel un script doit être revalidé (par défaut deux secondes). Si on met la valeur de **opcache.revalidate_freq** à zéro le fichier PHP sera revalidé à chaque requête.

Si je résume, par défaut, OPcache va vérifier au maximum 2 fois par secondes si le timestamp du fichier a changé avant de l’exécuter. Ce type de mécanisme n’est pas idéal en production et ce même si on met une grande valeur à **opcache.revalidate_freq** car on utilise des accès disques pour vérifier les timestamp des fichiers. Dans un environnement qu’on connaît bien, c’est à dire dans lequel on travaille avec les développeurs qui poussent en prod les mises à jour, il faut totalement **désactiver ce mécanisme de revalidation par timestamp** et recharger le cache via un autre mécanisme qu’on verra plus tard dans l’article.

Si par contre on est dans un environnement très hétérogène dans lequel on ne sait pas quand les majs seront poussées ni ce qui tourne sur le serveur, c’est typiquement le cas lorsqu’on bosse avec une agence web par exemple, qui a un tas de sites en prod, il est plus prudent de laisser **opcache.validate_timestamps** activé et de monter la valeur de **opcache.revalidate_freq**. On va perdre un peu en performances mais les mises à jour seront visibles en un maximum de **opcache.revalidate_freq secondes**.

Pour l’environnement de dev, on peut être tenter de désactiver complètement OPcache mais il est souvent intéressant de rester iso avec la prod pour éviter un bug qui lui serait lié. Dans ce cas on peut partir sur un **opcache.revalidate_freq** à 0 qui revalidera le fichier à chaque requête.

Dans la suite de l’article on va passer en revue les différents paramètres de configuration et voir comment ils fonctionnent et comment les adapter en fonction de la situation.

### opcache.enable

Là, c’est simple c’est ce qui indique si OPcache va être actif ou non. En effet, il ne suffit pas de charger l’extension dans votre **php.ini** pour que OPcache soit actif. (Depuis la version 7 de PHP c’est le contraire et **opcache.enable** est par défaut sur **1**.

Je conseille de laisser cette valeur sur 1 en prod, en dev et en test car on est sur de remonter le plus tôt possible un éventuel bug lié à OPcache.

### opcache.memory_consumption

C’est la mémoire utilisée pour le **cache d’opcode et le cache des clés**. Ça me donne une bonne occasion de vous parlez de la façon interne dont OPcache gère le stockage des chemins de scripts, ce qu’on appelle les clés. Il utilise une **table de hachage**, une hashTable si vous êtes perdu ;), qui contiendra une clé différente en fonction du paramètre **opcache.revalidate_path**. Si sa valeur est définit à 1, le hash contiendra uniquement le chemin complet vers le script PHP alors qu’en le définissant à 0 le hash contiendra également les chemins relatifs vers ce fichier. Mais pas de panique, le script php ne sera mis en cache une seule fois. On reviendra plus tard sur ce paramètre.

Maintenant que vous savez ce que sont ces fameuses clés, il faut donc prendre en compte ce paramètre lorsque vous allez définir opcache.memory_consumption. La valeur par défaut est de 64 en Mo et il faut généralement compter le double de votre espace en fichier php et y ajouter 50 % pour être tranquille. Par exemple, j’ai 20Mo de fichiers PHP, je compte donc 2x20Mo = 40Mo + 50 % = 50Mo. Ceci est un règle pour un premier réglage qu’il faudra affiner ensuite si besoin. A l’heure actuelle on a la chance d’avoir beaucoup de RAM donc il ne faut pas hésiter à mettre un peu trop sans toutefois exagérer.

Une chose très importante à avoir en tête lorsqu’on établit cette valeur est que **la mémoire est partagée entre les différents utilisateurs de PHP** ! Ceci est d’une importance CAPITALE car cela veut dire que dans un environnement d’hébergement partagé, le bytecode qui est mis en cache est partagé entre tous les utilisateurs PHP et ce, même si vous utilisez des utilisateurs unix différents pour vos pools php. Dans le contexte d’une agence web dont je parlais plus haut il est donc important de mettre une valeur assez haute et surtout, de **superviser ce cache dans votre outil d’alerting**. On verra plus bas comment procéder et quelles valeurs surveiller.

### opcache.max_accelerated_files

Par défaut sa valeur est à 2000, c’est le nombre de fichier php que Zend OPcache pourra mettre en cache. Il faut faire attention à une petite chose avec ce paramètre, il prendra comme **valeur réelle le premier nombre premier suivant la valeur du paramètre**. Par exemple à 2000, la valeur réelle est de 2069. Il est donc préférable de mettre directement un nombre premier. Une commande basique pour avoir le nombre de fichiers php dans un dossier :

```shell
find /home/mnttech/www/ -type f -name "*.php" | wc -l
```

### opcache.interned_strings_buffer

Par défaut à 4Mo, c’est la **taille en Mo de la mémoire allouée au stockage des chaînes**. Il est difficile de l’estimer et il vaut donc mieux allouer un peu trop de mémoire que pas assez à ce paramètre. Il faudra de toute façon le superviser et on pourra donc ajuster la taille à la baisse par la suite si nécessaire.

### opcache.revalidate_path

Comme on l’a vu précédemment ce paramètre impacte la **taille de la table de hachage contenant les index/clés des scripts mis en cache**. Par défaut il est désactivé, cela signifie que lorsqu’un fichier est déjà dans le cache et qu’il utilise **le même include_path et le même nom**, c'est le cache qui sera utilisé car OPcache n'ira pas vérifier le contenu du fichier source. En production, il est donc préférable de laisser cette valeur à 0 car sinon OPcache devra vérifier qu’il s’agit bien du même fichier et cela consommera des I/O. Dans un environnement partagé il est par contre plus prudent de laisser la valeur à 1.

Si vous utilisez un outil de déploiement tel que **Capistrano** qui utilise les **liens symboliques** pour faire un changement de release, il faudra donc bien penser à **vider le cache après une mise à jour**. De la même façon, si vous utilisez des liens symboliques dans votre structure, il faudra bien penser à vider OPcache après une nouvelle mise en prod.

### opcache.max_wasted_percentage

Par défaut à 5 %. Ce paramètre définit le **taux de mémoire gâchée avant de lancer un restart d’OPcache donc de PHP**. Pour comprendre comment ce taux de mémoire gâchée est calculé, il faut comprendre comment OPcache gère sa mémoire. C’est assez simple, pour éviter la **fragmentation de la mémoire**, lorsqu’un script qui est mis est cache est invalidé, OPcache va **reallouer de l’espace pour mettre en cache** la nouvelle version et marquer l’ancien espace mémoire comme wasted. Il suffit ensuite de faire un ratio entre la mémoire globale et la mémoire gâchée.

Si vous avez suivi les conseils que je vous ai donné précédemment, ce seuil de 5 % ne devrait jamais être un problème car en prod, les fichiers seront invalidés manuellement et non par OPcache. Dans le cas d’un environnement partagé, on peut monter un peu cette valeur pour éviter des redémarrages de PHP. Une fois de plus, il faut **monitorer le nombre de redémarrages** liés à cette variable.

### opcache.save_comments & opcache.load_comments

Par défaut ces paramètres sont activés. Ils permettent de définir si les commentaires sont inclus dans le bytecode en cache et si ils sont lus lors de l’exécution. On pourrait se dire qu’il n’est pas nécessaire de les activer mais de nombreux framework font usage des commentaires comme Doctrine ou PHPUnit. On garde donc ces valeurs activées partout, c’est plus sage.

### opcache.enable_file_override

Ce paramètre qui est par défaut désactivé permet lorsqu’il est activé d’utiliser le cache OPcache lors de l’appel des fonctions **file_exists()**, **is_file()** et **is_readable()**. Une fois de plus un paramètre à activer en prod quand on sait ce qu’on a derrière. Le mieux est donc de définir cela avec les développeurs. Quand on est dans un environnement partagé, on le laisse désactiver.

### file_update_protection

Un paramètre non documenté mais qui a son importance, il s’agit du nombre de secondes qu’un fichier doit avoir avant de pouvoir être mis en cache. Par défaut il est à deux secondes. Pour éviter qu’un script ne soit mis en cache il suffit donc de faire un touch avant de l’inclure. Cela n’est pas très utile mais c’est toujours bon à savoir. Il existe d’autres moyens pour éviter la mise en cache et on va tout de suite voir cela avec le paramètre suivant.

### opcache.blacklist_filename

On indique à ce paramètre un fichier (lisible par l’utilisateur PHP évidemment) qui contiendra une liste de fichiers à ne pas mettre en cache. On peut utiliser les **;** pour faire des commentaires dans le fichier et on peut également utiliser le wildcard avec **\***

Par exemple si on veut exclure tous les fichiers qui commencent par player on peut ajouter la ligne suivante dans notre liste :

```shell
/home/plop/player/player*.php
```

Par exemple si je veux exclure mon répertoire de dev qui est dans **/home/mnttech/dev** :

```shell
/home/mnttech/dev/
```

### opcache.fast_shutdown

Sur le papier c’est une bonne idée de l’activer car cela permet de libérer plus rapidement la mémoire après un restart et donc de reprendre de nouvelles requêtes plus rapidement mais il semble que cela soit à l’origine de problèmes divers. Je vous laisse chercher sur le net, on trouve un tas d’exemples... Mieux vaut laisser cette option désactivée.

### Vidage du cache

Maintenant qu’on a fait le tour des paramètres les plus importants, on va voir comment invalider le cache dans une logique de production. Pour faire simple, le mieux et le plus rapide est de reload votre pool fpm ou de faire un graceful d’apache.

Si vous utilisez mod_php avec apache :

```shell
service apache2 graceful
```

Si vous utilisez un pool fpm :

```shell
service php7.0-fpm reload
```

Il existe également une autre façon de faire en appelant la fonction **opcache_reset()** depuis un curl ou via votre navigateur. Pourquoi je précise via curl ou le navigateur ? Car il faut savoir que **la mémoire en CLI n’est pas partagée avec la mémoire de mod_php ou de votre pool fpm**, et ce, même si vous avez activé **opcache.enable_cli**. Il faut donc impérativement passer par le web pour invalidé le cache. Pour flusher le cache depuis un WordPress, j’ai écrit un plugin qui est disponible ici : [WP-OPcache](https://fr.wordpress.org/plugins/flush-opcache/)

Il existe une dernière méthode beaucoup plus fine, qui permet d’invalider le cache pour un unique script, la fonction **opcache_invalidate()**. Elle présente le même inconvénient que **opcache_reset()**, il faut la lancer depuis le web.

### TL;DR

**En prod avec un rafraîchissement manuel du cache à chaque déploiement :**

```ini
opcache.enable=1
opcache.enable_cli=1
opcache.validate_timestamps=0
opcache.revalidate_path=0
opcache.enable_file_override=1
```

**En dev :**

```ini
opcache.enable=1
opcache.enable_cli=1
opcache.validate_timestamps=1
opcache.revalidate_freq=0
opcache.revalidate_path=1
```

**Pour un hébergement partagé ou de recette/test :**

```ini
opcache.enable=1
opcache.enable_cli=1
opcache.validate_timestamps=1
opcache.revalidate_freq=300 ;(5 minutes de cache)
opcache.revalidate_path=1
opcache.max_wasted_percentage=25
```

### Supervision

Il y a différents points à superviser pour s’assurer du bon fonctionnement d’OPcache. Tous ces points sont à **ajouter dans votre outil d’alerting** :

*   Le ratio de chaînes utilisées / chaînes disponible
*   Le ratio de mémoire utilisée / mémoire totale
*   Le ratio de hits /misses
*   Le nombre de restart (oom_restarts et hash_restarts)

Voici un repo github contenant de quoi mettre en place une supervision [nagios/cacti](https://github.com/nierdz/OPcache-plugins-for-nagios-and-cacti). Il s'agit d'un repository archivé et n'étant donc plus mis à jour.


**Sources et liens utiles :**

*   [http://php.net/manual/en/book.opcache.php](http://php.net/manual/en/book.opcache.php)
*   [http://php.net/manual/en/intro.apcu.php](http://php.net/manual/en/intro.apcu.php)
