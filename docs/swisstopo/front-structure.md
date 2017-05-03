## Structure du front (mf-geoadmin3)

Ce document contient des informations complémentaires qui ne tiennent pas sur le
schéma.

### gaLayers (service, src/components/map/MapService.js)

1. Les URLs de configuration sont données sous la forme d'un template avec des
   valeurs de langue à remplacer. Le service commence donc par générer les
   URLs.
2. Charge les tuiles demandées (celle de la couche de fond au départ) depuis le
   cache local ou les charge depuis le serveur. Passe par l'objet *imageTile*.
3. Retourne la liste des couches sélectionnées.
4. Retourne un tableau pour les couches de fond. Ce tableau contient des objets
   *ol.layer.Layer*.
5. Récupère une couche de type *ol.layer.Layer* à partir de son id et du type
   (wmts, wms, aggregate).
6. Peut donner une propriété d'une couche, ses métadonnées, …
