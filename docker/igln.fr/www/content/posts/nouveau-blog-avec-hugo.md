+++
date = "2019-05-08T15:07:00+02:00"
author = "Kévin Met"
title = "Nouveau blog avec hugo"
slug = "nouveau-blog-avec-hugo"
description = "Dans ce premier billet j'explique comment j'utilise hugo et docker sur ce nouveau blog."
categories = ["blog"]
tags = ["hugo", "go", "docker", "nginx"]
+++

Bienvenue sur ce nouveau blog qui utilise [hugo](https://gohugo.io/) dans lequel je vais parler des découvertes que je fais autour du sujet **devops**. Mes articles seront toujours écrits en français car les ressources en anglais sont déjà très nombreuses. J'espère que je serai un peu plus productif que sur mon ancien [blog](https://mnt-tech.fr/blog/)... D'ailleurs, une sélection totalement arbitraire d'articles sera réintégrée sur ce nouveau blog avec une réécriture si besoin. Dans ce premier article, je vais justement expliquer comment je déploie ce blog en utilisant **hugo**, **docker** et **docker-compose**.

<!--more-->

### Introduction
On va commencer par le début, j'avais écris en **php** un moteur de blog qui était assez dégueulasse, tellement dégueulasse que je n'ai jamais osé le mettre sur github :flushed: Ça faisait donc un moment que je regardais les générateurs de site statique pour le remplacer et mon choix s'est arrêté sur [hugo](https://gohugo.io/) car il semblait assez mâture et que j'avais envie d'apprendre le **go**. Ce blog sera donc entièrement sous [github](https://github.com/nierdz/infra/tree/master/docker/igln.fr) et je vais expliquer ici les étapes pour passer du développement à la production.

### Docker
Mon idée de base avec un site entièrement statique était que je pouvais embarquer le site, une fois généré, dans une image **docker nginx** de base. C'est donc ce que j'ai fait en utilisant [docker multi-stage](https://docs.docker.com/develop/develop-images/multistage-build/) afin de produire une image légère ne contenant que le code et l'image nginx. Voici à quoi ressemble le **Dockerfile** au global et on va prendre le temps de détailler un peu les différentes étapes pas à pas.

{{< gist nierdz 20ee8324932d19b036b26d5b24c61245 >}}

On commence par la première ligne :

```dockerfile
FROM debian:stable-slim as build
```

Cela va nous permettre de faire un premier container nommé **build** dans lequel on va installer **hugo** et générer le site. On pourra l'utiliser dans notre image finale à l'aide du flag `--from` de la commande `COPY`.

Pour la suite, c'est assez classique :

```dockerfile
ENV HUGO_VERSION X.XX.X
```

On définit une variable qui spécifie la version d'hugo.

```dockerfile
ARG LOCAL=0
```

Ensuite, on définit l'argument `LOCAL` qui sera utile pour le cas du développement et donc du build en local. On verra ça plus loin.

```dockerfile
RUN apt-get update \
  && apt-get install -y \
  wget \
  && rm -rf /var/lib/apt/lists/*
RUN wget -qO- -SL "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz" \
    | tar -xzC /bin \
    && rm -f /bin/README.md /bin/LICENSE
```

Il s'agit de l'installation d'hugo.

```dockerfile
COPY ./www /www
WORKDIR /www
```

On copie les fichiers sources du site et on ajoute une directive `WORKDIR` pour spécifier le dossier de base à utiliser dans ce container.

```dockerfile
RUN if [[ $LOCAL -eq 1 ]]; then \
  /bin/hugo --baseUrl=http://igln.fr/; \
else \
  /bin/hugo --baseUrl=https://igln.fr/; \
fi
```

Là, on construit le site, le contenu sera donc dans `/www/public/`. La condition sur la variable `LOCAL` permet de spécifier l'option `--baseUrl` qui sera **https://igln.local** si le site est en local. En prod, on sera sur **https://igln.fr** (le domaine sur lequel vous êtes actuellement).

```dockerfile
FROM nginx:X.XX
LABEL version=X.X.X
```

On utilise une image **nginx** upstream et on ajoute un label contenant la version de l'image docker. Cela sera utilisé par la suite pour générer un **tag** sur l'image docker. Les fichiers générés par hugo sont dans le dossier `/www/public` on va donc devoir les déplacer dans `/var/www` qui sera configuré comme le **root** dans la configuration nginx :

```dockerfile
COPY --from=build /www/public /var/www
```

On définit le `COPY` depuis le container nommé `build`. On a donc copié les fichiers produits dans le container précédent sans les sources et l'installation d'hugo.

Maintenant, on va voir comment on déploie cette image sur docker hub pour l'utiliser par la suite en production.

### Déploiement sur docker hub

Pour déployer l'image sur **docker hub**, on va utiliser [Github actions](https://github.com/features/actions). Dans toutes mes images docker j'insère un **LABEL** avec la version. Ce label sera lu par les scripts de **build** et de **push** docker pour poser un tag sur docker hub. Cela me permet de versionner simplement, sans avoir besoin de poser de tags sur mon repository git.

Voici donc le fichier contenant le job pour construire et pousser mes images sur docker hub :


{{< gist nierdz d433dcb98457d343ec51986005edd538 >}}

Le déclenchement de ce job ne se fait que sur la branche **master** lorsque des modifications ont été faîtes sur les fichiers dans le dossier `docker` (dossier contenant toutes mes images docker). Le job se décompose en deux étapes qui sont gérées par deux scripts distincts :

1. Étape de build gérée par le script `docker-build.sh` :

{{< gist nierdz 07469cc4d744615f6cb9335210cf2942 >}}

2. Étape de push gérée par le script `docker-push.sh` :

{{< gist nierdz a9392c8586350b6f1d31c78aee16f2ff >}}

### Workflow : de l'écriture d'un article jusqu'à la prod

On commence par cloner le dépôt :

```shell
git clone git@github.com:nierdz/igln.fr.git
```

On fait une nouvelle branche dans laquelle on écrit notre article en **markdown** :

```shell
git checkout -b feat/mon-super-article
vim docker/igln.fr/www/content/posts/mon-super-article.md
```

Pour tester l'article en local, il faut ajouter une entrée dans son `/etc/hosts` qui fait pointer le nom de domaine vers `127.0.0.1` :

```shell
127.0.0.1 igln.local
```

Il faut ensuite construire l'image et lancer le container. Pour cela, il existe une target  **docker-run-igln-local**  dans le `Makefile` qui va construire l'image en local, supprimer le précédent conteneur s'il en existait un et lancer le conteneur :

```shell
make docker-run-igln-local
```

Il ne reste plus qu'à aller voir le résultat sur son navigateur sur https://igln.local. Quand on modifie le contenu, il faut ensuite relancer la target make **docker-run-igln-local** :

```shell
make docker-run-igln-local
```

Une fois qu'on est satisfait de l'article, il ne reste plus qu'à modifier la version dans le **Dockerfile**, merger notre branche dans **master** et laisser github actions travailler à notre place.

Ce n'est néanmoins pas tout à fait fini car il faut ensuite utiliser cette image quelque part pour afficher notre blog. Pour cela, j'utilise **docker-compose** pour la facilité et la souplesse de cet outil. Ce choix est motivé par le fait que ce site est hebergé sur un simple serveur et que si le service tombe, ce n'est absolument pas grave donc je n'ai pas besoin de mécanisme de redondance.

Voici donc le fichier `docker-compose-igln.yml` qui permet de faire tourner l'image docker :

{{< gist nierdz 0fa0dae5d7a55f3d6960881d663a35b2 >}}
