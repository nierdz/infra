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
On va commencer par le début, j'avais écris en **php** un moteur de blog qui était assez dégueulasse, tellement dégueulasse que je n'ai jamais osé le mettre sur github :flushed: Ça faisait donc un moment que je regardais les générateurs de site statique pour le remplacer et mon choix s'est arrêté sur [hugo](https://gohugo.io/) car il semblait assez mâture et que j'avais envie d'apprendre le **go**. Ce blog sera donc entièrement sous [github](https://github.com/nierdz/igln.fr) et je vais expliquer ici les étapes pour passer du développement à la production.

### Docker
Mon idée de base avec un site entièrement statique était que je pouvais embarquer le site, une fois généré, dans une image **docker nginx** de base. C'est donc ce que j'ai fait en utilisant [docker multi-stage](https://docs.docker.com/develop/develop-images/multistage-build/) afin de produire une image légère ne contenant que le code et l'image nginx. Voici à quoi ressemble le **Dockerfile** au global et on va prendre le temps de détailler un peu les différentes étapes pas à pas. Si le Dockerfile change entre l'écriture de l'article et maintenant, vous pouvez jeter un œil à la version actuelle sur [github](https://github.com/nierdz/igln.fr/blob/master/Dockerfile).

{{< gist nierdz 20ee8324932d19b036b26d5b24c61245 >}}

On commence par la première ligne :

```dockerfile
FROM debian:stable-slim as build
```

Cela va nous permettre de faire un premier container nommé **build** dans lequel on va installer **hugo** et générer le site. On pourra l'utiliser dans notre image finale à l'aide du flag `--from` de la commande `COPY`.

Pour la suite, c'est assez classique :

```dockerfile
ENV HUGO_VERSION 0.61.0
ENV HUGO_BINARY hugo_${HUGO_VERSION}_Linux-64bit.tar.gz
```

On set quelques variables qui seront utiles pour spécifier la version d'hugo.

```dockerfile
ARG LOCAL=0
```

Ensuite, on set l'argument `LOCAL` qui sera utile pour le cas du développement et donc du build en local. On verra ça plus loin.

```dockerfile
RUN apt-get update \
    && apt-get install -y \
    wget=1.20.1-1.1 \
    && rm -rf /var/lib/apt/lists/*

RUN wget -qO- -SL https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${HUGO_BINARY} \
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

Là, on construit le site et le contenu sera donc dans `/www/public/`. La condition sur la variable `LOCAL` permet de spécifier l'option `--baseUrl` qui sera en **http** si le site est en local pour éviter les soucis de certificats. En prod, on sera bien sur du **https** avec **letsencrypt** mais on verra cela plus loin.

```dockerfile
FROM nginx:1.17
COPY ./igln.conf /etc/nginx/conf.d
```

On utilise une image **nginx** upstream que l'on va enrichir avec [une conf basique](https://github.com/nierdz/igln.fr/blob/master/igln.conf) qui pointe sur le bon `root` et avec le code produit dans le container `build`. Pour cela :

```dockerfile
COPY --from=build /www/public /var/www
```

On définit le `COPY` depuis le container nommé `build`. On a donc copié les fichiers produits dans le container précédent sans les sources et l'installation d'hugo.

Maintenant, on va voir comment on déploie cette image sur docker hub pour l'utiliser par la suite en production.

### Déploiement sur docker hub

Pour déployer l'image sur **docker hub**, on va utiliser 2 composants :

 - [travis CI](https://travis-ci.org/)
 - les [tags](https://git-scm.com/book/en/v2/Git-Basics-Tagging) git

L'idée est que lorsqu'on va créer un tag dans git, cela va faire en sorte de construire et pousser l'image dans **docker hub** avec ce tag particulier et le tag `latest`. Cela permettra de faire le changement de tag en prod et d'initier un **rolling update** pour faire le changement d'image. Bon en vrai j'ai un seul serveur sur lequel je fais du **docker compose** donc je fais un simple restart du container mais c'est parce que je m'en bats les couilles d'avoir une indisponibilité sur ce blog en carton :metal:

Voici le contenu du `.travis.yml` qui est également dispo sur [github](https://github.com/nierdz/igln.fr/blob/master/.travis.yml) :

{{< gist nierdz 1681fffcfff5dc0da30cb16672cf960f >}}

Certains éléments ne sont pas forcément intéressants pour le sujet qui nous préoccupe, on va donc s'attarder sur les morceaux qui nous intéressent. On commence par les variables d'environnement.

On voit que j'ai chiffré mon password docker hub à l'aide de travis et qu'il est contenu dans la variable `secure`. Ça et la variable `DOCKER_USERNAME` vont me permettre de me connecter au docker hub pour pousser mon image. Pour le chiffrement de la variable, tout est expliqué [ici](https://docs.travis-ci.com/user/environment-variables/#encrypting-environment-variables)

Dans la partie `deploy` de travis CI, j'utilise 3 conditions pour ne déployer qu'en certains cas :

 - `tags: true` : permet de ne déployer que si le commit est taggé
 - `branch: master` : permet de ne déployer que sur la branche master
 - `repo: nierdz/igln.fr` : permet de ne déployer qu'à partir du repo principale (utile en cas de fork par exemple mais pas trop quand même, on va pas se mentir, je vois pas qui aurait envie de fork cette merde :shit:)

Et pour le déploiement, on fournit un script à travis (`travis-to-docker.sh`):

{{< gist nierdz cffdea31a5aee7c30dc83b4d845d9438 >}}

Petit script sans prétention qui va simplement se connecter (`docker login`), tagger les images (`docker tag`) et les pousser sur docker hub (`docker push`).

Voilà, maintenant qu'on a vu cela, on va voir le workflow complet pour écrire un nouvel article, le pousser sur github et on va vérifier que l'image est bien créée sur docker hub, il ne restera plus qu'à changer le tag de l'image en prod ou d'abord en preprod si vous avez ça sous le coude (c'est mieux !)

### Workflow : de l'écriture d'un article jusqu'à la prod

On commence par cloner le dépôt :

```shell
git clone git@github.com:nierdz/igln.fr.git
```

On fait une nouvelle branche dans laquelle on écrit notre article en **markdown** :

```shell
git checkout -b feat/mon-super-article
vim www/content/posts/mon-super-article.md
```

Pour tester l'article en local, il faut ajouter une entrée dans son `/etc/hosts` qui fait pointer le nom de domaine vers `127.0.0.1` :

```shell
127.0.0.1       localhost igln.fr
```

Il faut ensuite construire l'image et lancer le container en bindant sur le port 80. Pour cela, j'ai fait un `Makefile` qui évite de retaper la même commande plusieurs fois. Il suffit donc de faire :

```shell
make build-run-local
```

Il ne reste plus qu'à aller voir le résultat sur son navigateur. Quand on modifie le contenu, il faut ensuite stopper le container, le reconstruire et le relancer. Pour cela aussi j'ai une tâche **make** :

```shell
make stop && make build-run-local
```

Une fois qu'on est satisfait de l'article, il ne reste plus qu'à merger la branche dans **master** sur github et ajouter un tag :

```shell
git tag v1.0
git push --tags origin master
```

Maintenant que le tag est poussé, **travis** va s'occuper de construire et pousser l'image dans **docker hub**.

### Conclusion

Comment ça conclusion ? C'est pas fini là ! Où est la prod ? Et ben on va en parler dans la conclusion justement.
Il y aurait plein de façon d'utiliser l'image ainsi produite et je vais en citer quelques unes puis vous décrire la façon dont je procède.

 - On pourrait utiliser l'image dans un cluster **Kubernetes**
 - On pourrait utiliser l'image dans une machine virtuelle dédié aux containers comme par exemple les [container optimized os de gcloud](https://cloud.google.com/container-optimized-os/docs/)
 - On pourrait également utiliser un cluster [nomad](https://www.nomadproject.io/)

Bref, je ne vais pas citer toutes les possibilités car il en existe beaucoup trop. Je vais vous expliquer comment je procède, étant donné que je ne dispose que d'un serveur physique chez **soyoustart**. Ce serveur héberge déjà plusieurs containers organisés ensemble à l'aide de **docker-compose**. Tout le code à ce sujet est disponible sur [github](https://github.com/nierdz/infra-docker). J'utilise donc une solution très simple car je n'ai pas envie de mettre plus d'argent que ça dans mon infra perso.

Voici donc le fichier **docker-compose** que j'utilise pour ce blog et que je dois mettre à jour à chaque nouvelle version du blog :

{{< gist nierdz 0fa0dae5d7a55f3d6960881d663a35b2 >}}

Rien de bien compliqué sur cette partie donc je ne vais pas m'attarder dessus. La seule chose notable est le volume dédié au renouvellement du certificat :

```yaml
- ./certbot:/var/www/certbot:rw
```

Pour faire fonctionner **certbot** sur ce volume, j'utilise ce petit snippet dans ma conf **nginx** :

```nginx
location /.well-known/acme-challenge/ {
    root /var/www/certbot;
}
```

Cela permet de faire tomber les requêtes **letsencrypt** dans le bon dossier car lors de la première création du certificat j'utilise l'option `--webroot-path` de **certbot** qui pointe sur le volume `./certbot`.
Voilà, je pense avoir fait le tour de la question.
