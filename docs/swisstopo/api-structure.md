## Structure de l'API (mf-chsdi3)

L'API est responsable de :
- donner au frontend les configurations des couches
- donner les services possibles (langues, sujets, …)
- imprimer la carte visionnée par l'utilisateur (via mapfish-print)
- donner le catalogue, ie la liste des couches correctement classées avec leur
  nom compréhensible


### Lien API/Frontend

1. On configure l'interface (dans mf-geoadmin3) pour qu'elle renvoie un fichier
   index avec qui donne la configuration pour se connecter à l'API.
2. On récupère le json de traduction (par exemple `en.json`) du frontend. Ce
   fichier est donné par le frontend. Il est de la forme `cle_standard: "Clé
   standard"` (fichier donné par le frontend).
3. Récupération du JSON qui définit les topics (fichier `service`). Il permet de
   connaître les couches de fonds disponibles, les langues possibles, les
   couches sélectionnées dès le choix du topic, son identifiant et s'il faut
   montrer ou non le catalogue.
4. Récupération du JSON qui contient la liste des couches. C'est un objet avec
   pour clés le nom de la couche et ses paramètres.
5. Récupération de `info.json` qui contient des informations pour l'impression
   (formats de page possibles, dbi, échelle).
6. Récupération du catalogue, ie liste des couches avec leur hiérarchie et leur
   label.
7. Le front traite ensuite ces JSON pour mettre à jour son affichage.
8. Fait les requêtes aux serveurs WMS ou WMTS pour récupérer les images de la
   carte.


### Entrée dans l'API

Tout ce passe dans le module `chsdi`.

#### __init__.py

Contient la liste des routes et la vue associée. Points intéressants :
- wmtscapabilities : donne ce que peut faire le serveur, notamment :
    - Liste des couches
    - Liste des thèmes
- layersConfig : donne la liste des couches possibles.
- mapservice : donne les métadonnées pour chaque couche.

#### Fonctions utiles

- `filter_by_geodata_staging` sert à différencier les données pour la production
  (prod), le développement (dev) ou l'intégration (int).

#### layersConfig

1. On récupère les paramètres `params` des couches depuis l'objet
   `LayersParams`. Cette objet se construit à partir de la requête et permet
   d'accéder facilement à certains paramètres comme le nom de la carte, la
   langue, le texte de la recherche (s'il y a lieu), … et la requête en elle
   même.
2. On initialise la requête de base de données `query`. C'est un objet qui vient
   de SQLAlchemy. Il est construit à partir du modèle `LayersConfig` qui
   contient notamment l'identifiant de la couche, son opacité, ses résolutions
   minimale et maximales. C'est à partir de cet objet, via sa méthode `filter`
   que l'on ne va récupérer que les couches qui nous intéresse.
3. On boucle sur un itérateur qui filtre les couches à partir `param`, du modèle
   `LayersConfig` et de `query`. La fonction `get_layers_config_for_params`
   filtre la table `LayersConfig` puis pour chaque couche restantes "yield" sa
   cofiguration. Dans `libs.filters`, les deux fonctions utilisées
   (`filter_by_map_name` et `filter_by_geodata_staging`) ont un fonctionnement
   similaire à savoir trouver une ou des clauses de filtrage et les passer à
   `query.filter` éventuellement via `or_` qui fait un `OU` logique entre ces
   clauses.
4. Les couches renvoyées par l'itérateur sont ajoutées à l'objet renvoyé par la
   fonction.


#### topics

Via l'URL `/rest/services`.

Lié à la table `Topics`. On ne prend que les topics pour lesquels on montre le
catalogue et on les trie dans un ordre défini dans une colonne de la
table. Ensuite, on les filtre avec `filter_by_geodata_staging`. Les résultats
sont enfin mis en forme dans un tableau de dictionnaires.

##### La table `Topics`

- id : Text
- orderKey : Integer
- availableLangs : Text
- selectedLayers : postgresql.ARRAY(Text)
- backgroundLayers : postgresql.ARRAY(Text)
- showCatalog : Boolean
- staging : Text

#### mapservice

Fonctionnement analogue à `layersConfig` mais permet de faire des recherches
textuelles.

#### wmtscapabilities

1. Utilise la table `GetCap` pour faire sa requête.
2. Filtre avec `filter_by_geodata_staging` et éventuellement par nom de carte.
3. Renvoie le résultat au format JSON.


#### layersConfig

Donne la configuration des couches au frontend. Stocké dans une table
`LayersConfig`. Actuellement, on utilise un script (`initializedb.py`) pour
générer cette table automatiquement. Celle-ci est remplie à la main par
swisstopo.

Les couches sont décrites dans le tag `Layer` du XML.

##### Attributs récupérables via GetCapapilities

Voir http://wms.geo.admin.ch/?REQUEST=GetCapabilities&SERVICE=WMS&VERSION=1.0.0
et le JSON

| Nom dans le XML | Nom dans la base | Remarque |
|-----------------|------------------|----------|
| <Name>          | layerId ou wmsLayer | |
| <abstract> | label | Pas toujours le cas, parfois le label est beaucoup plus court que l'abstract |
| <Layer queryable="1"> | queryable | |
| <Keywords> | topics | Je suppose une relation indirect, on a un identifiant dans le XML et une liste de mots dans topics |
| <Format> | format | Rarement présent, PNG pour la plupart, rarement JPEG |

##### Autres attributs

- opacity : beaucoup à 0.75, remplissage automatique avec liste d'exception ?
- gutter : vient de `wmsgutter` en base.
- attribution : "prevonance", *swisstopo*, *FOAG*, *FOEN*
- background : tout me semble à `false`
- searchable : la plupart à `true`
- selectByRectangle : boolean
- attributionUrl : bureau en charge de la couche
- timeBehaviour : `"last"`
- singleTide
- hilightable
- chargeable : plupart à `false`
- hasLegend :
- type : `"wms"` ou `"wmts"` ou `"aggregate"`
- timeEnabled : tout me semble à `false`
- wmsurl : tout me semble à
  `"http://wms.geo.admin.ch/?REQUEST=GetCapabilities&SERVICE=WMS&VERSION=1.0.0"`

##### Nos attributs GetCapabilities

Les couches sont décrites dans le tag `FeatureType` du XML.

- <Name> : Name
- <Format> (fils de <OutputFormat>) : format
- topics : depuis <ows:Keywords> (identique pour chaque couche) ?

##### Minimun requis pour mocker les topics

Voir ci-dessous pour les justifications.

```javascript
	var layer = {
		wmsUrl: 'http://mapserver.local/wms/geojbwms?SERVICE=wfs&REQUEST=GetCapabilities',
		wmsLayers: 'COUVERTUREDUSOL',
		format: 'PNG',
		attributionUrl: '',
		attribution: ''
		label: ''COUVERTUREDUSOL',
		type: 'wms'
	}
```

- Le label est utilisé pour l'affichage dans l'interface.
- Le type est nécessaire à la création de la couche OpenLayer

###### `ol.layer.Tile`

Voir : http://openlayers.org/en/master/apidoc/ol.layer.Tile.html

- source : de type `ol.source`. Se construit avec :
    - url: layer.wmsUrl (l'URL de GetCapabilities)
    - params: wmsParams. Se construit à partir de :
        - `layer.wmsLayers` (nom de la couche).
        - `layer.format` le format d'image (ajouté à 'images/').
	- attributions: attributions. Se construit avec :
        - `layer.attributionUrl`
        - `layer.attribution`
    - crossOrigin: crossOrigin. Fixé à `'anonymous'`.

###### `ol.layer.Image`

Voir : http://openlayers.org/en/master/apidoc/ol.layer.Image.html


### Autres

#### Déploiement avec mod_wsgi

En cas d'erreur d'import d'un module ou d'extraction `ExtractionError: Can't extract file(s) to egg cache`, ajouter au fichier wsgi de l'application :

```python
import os
os.environ['PYTHON_EGG_CACHE'] = '/tmp'
```

#### Renderers
Vers EsriJSON et CSV.
