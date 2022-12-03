+++
type = "page"
title = "Supprimer des custom fields sous WordPress"
slug = "supprimer-custom-fields-wordpress"
+++

### Introduction

Quand on utilise **WordPress** depuis plusieurs années et qu'on a testé quelques plugins on se retrouve souvent avec beaucoup de [custom post fields](https://wordpress.org/support/article/custom-fields/) dans nos articles. C'était mon cas sur [mad-rabbit.com](https://mad-rabbit.com/) et j'ai décidé de faire un peu de ménage dans ce bordel en écrivant un petit script **bash** qui utilise **wp-cli**.

### wordpress-bulk-delete-custom-fields.sh

Voici le script bash :

{{< gist nierdz 6952539552b9ac9c8b6e93c0065b9a16 >}}

### Utilisation

{{% alert theme="danger" %}}**Attention !** Il faut impérativement faire une sauvegarde de sa base de données avant d'utiliser ce script.{{% /alert %}}

Il suffit de télécharger le script et de le rendre exécutable :

```bash
curl -o wordpress-bulk-delete-custom-fields.sh https://gist.githubusercontent.com/nierdz/6952539552b9ac9c8b6e93c0065b9a16/raw/244bd65e8c31e246df1a1520fc10116073720c64/wordpress-bulk-delete-custom-fields.sh
chmod +x wordpress-bulk-delete-custom-fields.sh
```

Il faut ensuite éditer le script pour ajouter ou supprimer les **custom post fields** que vous voulez supprimer. Pour cela il faut éditer les deux variables suivantes :

- **META_KEYS** : les custom post fields simples
- **META_KEYS_PATTERN** : les patterns de custom post fields (utilisation de wildcard dans la chaîne de caractères)

Et ensuite il faut le lancer avec la variable `WP_BINARY` qui permet d'indiquer où se trouve le binaire de **wp-cli**. Par exemple, moi qui fait tourner WordPress dans un conteneur docker qui se nomme **madrabbit-wordpress** dans lequel le binaire **wp-cli** est `/usr/bin/wp`, je lance le script comme ça :

```bash
WP_BINARY="docker exec madrabbit-wordpress /usr/bin/wp --allow-root" ./scripts/wordpress-bulk-delete-custom-fields.sh
```

En fonction du nombre d'articles et du nombre de **custom post fields** à supprimer, cela peut prendre plus ou moins de temps. A titre indicatif, pour environ 3000 articles cela m'a pris plus de 8 heures. Il peut donc être judicieux de lancer la commande dans un **screen**.
