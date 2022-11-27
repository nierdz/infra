+++
type = "page"
title = "Installation et configuration de lsyncd sur Debian"
slug = "installation-et-configuration-de-lsyncd-sur-debian"
+++

### Fonctionnement

Avant de se lancer dans l'installation, un peu de théorie, histoire de savoir pourquoi il est plus intéressant d'utiliser **lsyncd** plutôt qu'un simple **script rsync en cron**. Le gros avantage de lsyncd est qu'il va utiliser **inotify ou fsevevents** pour monitorer les dossiers à l'intérieur de votre dossier source. Cela permet de lancer un **rsync** uniquement lorsqu'un changement est détecté. De plus, il va lancer un rsync uniquement sur le ou les fichiers qui ont été modifiés ce qui **économise pas mal d'I/O**, surtout lorsqu'on veut synchroniser des dossiers très lourd et qu'on a des disques en cartons 😉

<!--more-->

Attention, ça ne remplace pas un FS distribué ou un DRBD qui seront bien plus gourmand en I/O mais qui, en contre-partie, offriront l'assurance de dossiers synchronisés en temps réel. En effet, lsyncd va générer une **latence** entre la synchronisation des dossiers qui va être plus ou moins longue (ce paramètre est réglable) et qui par défaut est de 15 secondes. Ce type de setup peut donc très bien être utilisé pour du failover par exemple mais ne se prêtera sûrement pas à du load-balancing ou du HA. Ceci est à définir en fonction de l'applicatif qui tourne derrière et de la criticité de celui-ci...

### Installation & Configuration

Alors comme d'habitude, je suis sous Debian donc je ne parlerai que de Debian dans ce tutoriel mais pour les autres, cela vous permettra de vous familiariser avec les options de configurations. Pour l'installation, on part sur un bon vieux **apt install** des familles :


```bash
apt install lsyncd
```


On va ensuite directement attaquer avec la création des dossiers nécessaires à la configuration et aux logs :


```bash
mkdir /etc/lsyncd
mkdir /var/log/lsyncd/
```


Je vais commencer par vous montrer un fichier de conf basique et je vous explique les options en dessous :


```lua
cat /etc/lsyncd/lsyncd.conf.lua
settings {
	logfile = "/var/log/lsyncd/lsyncd.log",
	statusFile = "/var/log/lsyncd/lsyncd-status.log",
	statusInterval = 1
}

sync {
	default.rsyncssh,
	source="/var/www",
	host="srv2.example.net",
	targetdir="/var/www",
	delay = 1,
	rsync = {
		archive = true,
		compress = true,
		whole_file = false
	},
	ssh = {
		port = 22
	}
}
```

Vous l'aurez compris, le fichier de configuration par défaut sur Debian est **/etc/lsyncd/lsyncd.conf.lua** (il est définit dans le script d'init). Le premier bloc **settings** permet de définir les paramètres généraux qui seront donc appliqués à tous les **dossiers synchronisés** et les blocs **sync** permettent de définir les dossiers synchronisés (vous pouvez en ajouter autant que vous le désirez).

Dans la partie **settings**, je n'utilise que 3 options car les autres ne me semblent pas forcément utiles mais vous pouvez voir la liste complète sur [cette page](https://axkibe.github.io/lsyncd/manual/config/file/).

* **logfile** : permet de définir le fichier de log
* **statusFile** : ce fichier décrit les dossiers qui sont monitorés par lsyncd
* **statusInterval** : permet de définir le nombre de secondes avant que le fichier status soit mis à jour

A noter que l'option **inotifyMode** permet de choisir le type de changement à écouter via inotify ("Modify", "CloseWrite" ou "CloseWrite or Modify"). Par défaut, il s'agit de **CloseWrite**.

Dans la partie **sync**, je n'utilise également que peu d'options car les options par défaut correspondent bien à ma situation. Il serait d'ailleurs temps que j'explique à quoi me sert lsyncd, vu qu'on arrive à la moitié du tuto... ~~Je l'utilise pour synchroniser des **DocumentRoot** d'un serveur vers un autre serveur en mode actif/passif. En cas de défaillance de ce serveur, je peux donc rapidement basculer vers le deuxième serveur qui est déjà configuré et qui contient donc **toutes les données à jour**. Dans mon exemple, il s'agit d'ailleurs du DocumentRoot du site sur lequel vous êtes actuellement que je réplique vers un serveur qui répond au doux nom de web3.mnt-tech.fr.~~ Je n'utilise plus du tout lsyncd et ce blog tourne tourne sur un simple serveur dans un conteneur comme expliqué [ici](https://igln.fr/nouveau-blog-avec-hugo/)

* **default.rsyncssh** : on définit les paramètres par défaut de rsync via ssh
* **source** : le dossier source
* **host** : la machine distante sur laquelle se trouve le dossier de destination
* **targetdir** : c'est bon, t'as compris, t'es pas con
* **delay** : cela définit un délai avant de spawn un process rsync

Le paramètre le plus important est **delay** qui va définir par défaut le nombre de secondes avant de spawner un process rsync. Dans mon cas, j'ai mis une seconde car je sais que les modifications sont assez peu fréquentes sur ce site (il n'y a qu'à voir la fréquence de mise à jour de ce blog pour s'en rendre compte 😉 ) mais dans le cas d'un dossier avec beaucoup de modifications par secondes, il est sûrement plus intéressant de monter ce délai qui par défaut est à 15 secondes. Si en l'espace de `delay` secondes il y a eu 1000 modifications, un process rsync sera de toute façon lancé par lsyncd.

On peut ensuite modifier les options de rsync via le bloc **rsync** et je vous invite à aller voir la liste complètes des options sur [cette page](https://axkibe.github.io/lsyncd/manual/config/layer4/). Sur la même page on trouve les options de **default.rsyncssh** permettant par exemple de modifier le port ou la clé SSH. A noter que par défaut l'option **\--delete** est utilisée et que l'option **\--whole-file** est désactivée, ce qui permet de tirer partie de l'algorithme de rsync pour n'envoyer qu'une partie d'un fichier si celui-ci n'a été modifié que partiellement.

Il faut ensuite ajouter la clé publique de root sur le serveur distant avec **ssh-copy-id** par exemple et il ne reste plus qu'à lancer le service via **systemctl** :

```bash
systemctl start lsyncd.service
```

Si vous souhaitez ajouter des dossiers synchronisés, il suffit d'ajouter des blocs **sync** dans votre fichier de configuration et de relancer **lsyncd**. Pour le moment lsyncd marche à merveille mais je n'ai fait que quelques tests sur des dossiers ne contenant pas énormément de fichiers. Je reviendrai éditer cet article quand ce sera le cas pour vous dire ce qu'il en est. Une dernière petite astuce avant de cloturer cet article, lorsque lsyncd ne se lance pas via systemd ou le script d'init, vous pouvez le **lancer directement à la main** pour voir ou se situe votre erreur. Un exemple avec un fichier de configuration mal édité :

```bash
lsyncd /etc/lsyncd/lsyncd.conf.lua
Error: error loading /etc/lsyncd/lsyncd.conf.lua: /etc/lsyncd/lsyncd.conf.lua:5: '}' expected (to close '{' at line 1) near 'plop'
```
