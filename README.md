# A Self Hosted Planetary Vector Tile Set

![image](https://user-images.githubusercontent.com/178003/191925782-c096f641-ae21-415b-8300-5ea13a0e8180.png)

## Elevator Pitch

* Built on OpenStreetMap data (and data (c) OpenStreetMap Contributors under the ODBL)
* All components Open Source so no license fees!
* Simple architecture (see below)
* Includes all the tooling to create and style vector tiles.
* Bundled starter style to get you going.
* 99% More awesome!

![image](https://user-images.githubusercontent.com/178003/191925997-33f8c6e6-f8ab-41ea-9a16-cbcd80e0a863.png)

## Architecture

These are the components used:

* [Kartoza's](https://kartoza.com) [Docker OSM](https://github.com/kartoza/docker-osm) (and thanks to Ettiene Trimaille, original author)
* [Kartoza's](https://kartoza.com) Imposm [mappings.yml](conf/osm_conf/mapping.yml) which determines which features are extracted from the OSM planet.pbf.
* [Kartoza's](https://kartoza.com) [PostGIS Docker](https://github.com/kartoza/docker-postgis) image.
* [Tegola](https://github.com/go-spatial/tegola/), an easy to configure and deploy vector tile server with built in cache seeding capabilities.
* [Maputnik-Editor](https://github.com/maputnik/editor), a powerful and user friendly web UI for authoring MapLibre compatible json style files.

That's it! Well almost - we use a couple of other things:

* [MapTiler's]() efficient planet.pbf [downloader tool](https://github.com/openmaptiles/openmaptiles-tools) which fetches the OSM planet.pbf without placing excessive load on the OSM infrastructure.
* The [water polygons dataset](https://osmdata.openstreetmap.de/data/water-polygons.html) from OSM which gives you a good set of coastlines.

## Background reading

* It is helpful to know the basis of Docker and docker-compose - there are many tutorials on YouTube or easily found by Googling.
* Knowing a bit of PostgreSQL and PostGIS can be helpful: Try the [introductory tutorial](https://docs.qgis.org/3.22/en/docs/training_manual/database_concepts/index.html) I wrote if you are starting from scratch, otherwise read the [PostgreSQL documentation](https://www.postgresql.org/docs/) and [PostGIS documentation](https://postgis.net/documentation/).
* Read the [Tegola Documentation](https://tegola.io/documentation/) - it is really concise and clear.
* Consult the [Maputnik Editor Documentation](https://github.com/maputnik/editor/wiki) - also make sure to use the little (i) hints all over the user interface.

## Workflow overview

Here is the outline of the steps to getting set up with your own planetary tile server:

1️⃣ 🖥 **You need a good computer and lots of disk fast space.** The import process will consume probably in excess of 150GB of your storage for the planet.pbf and the imposm cache files. Then when you start rendering and seeding tiles they can consume a lot of disk space. Plus you need to be able to responsively retrieve data from the database. For reference, on my developer maching, I have 64GB RAM, and AMD CPU with 24 threads and I had 1TB free space to work with. You can for sure get by with less but the better the spec your machine is, the better experience you will have.

2️⃣ 📦 **Install basic requirements** It is assumed you are using Linux in these notes, but the steps should work similarly in macOS and Windows. You do need to have a git client installed and docker + docker-compose installed and ready to use.

3️⃣ 🌎 **Download the planet.pbf** In this step we download the global OSM dataset snapshot using a clever tool from MapTiler. From this pbf we will import a subset of the global features and attributes into our database.

4️⃣ 🏃‍♀️ **Start the stack**. This will immediately begin the very lengthy process of extracting all the items defined in ``conf/osm_conf/mapping.yml`` from the PBF into your database. It is going to take a loooooong time (probably about 8 hours on my system), so be patient!

5️⃣ 🖍 **Start designing**. Once the import is done, the ´´osm´´ schema in your database will be populated and you can run Tegola and Maputnik Editor (both provided in our docker-compose.yml) to start designing your tileset.

6️⃣ 🗺 **Use your tiles**. Your tiles can then be used from QGIS and web mapping applications. You can optionally start seeding your tile cache (again this will take a long time depending on what level you seed to) using the tooling provided, then host them on a cloud native storage platform like Amazon S3.

## Downloading the planet

First we are going to download the planet file. Run this, then go have a cup of tea, watch a movie or play a game of Rocket League.....it's around 70gb to download:

```
docker-compose run planet-downloader
```

When it is done, you should find the downloaded file in ``conf/osm_conf/``. You must keep the planet file in that directory but rename it to ```country.pbf```.

## Start the database

The database needs to be running before you can run in the import. Copy the ``.env.template`` file to .env, then edit it, replacing the placeholders with proper values as indicated.

Then start the database:

```
docker-compose up -d db
```

Now watch the logs until you see confirmation that the database is up and ready to accept connections.

```
docker-compose logs -f db
```

## Start docker-osm and imposm

This is the magic that loads your OSM planet file (since renamed to country.pbf) into the postgres database. It is going to take a loooooooooong time - around 8 hours on my system if I recall correctly. If your machine is slower, it could take even longer.

```
docker-compose up -d imposm osmupdate
```

You can again watch the progress using:

```
docker-compose logs -f
```

While the import runs you will regularly see messages like this in the logs:

```
osmplanet-imposm-1           | [2022-09-23T19:51:43Z] 0:00:01 [progress]     0s C:       0/s (3188) N:       0/s (128) W:       0/s (632) R:      0/s (9)
```

This can be broken down into:

* C: Centroids?
* N: Node
* W: Ways
* R: Routes

With the planet import there will eventually be very large numbers of each to import. Once they are all at 100%, you need to do more waiting again. Now is a good time to watch the osm schema in the database.

Keep listing the tables there until you see them appear:

´´´
docker-compose exec -u postgres db psql gis -c "\dt osm.*"

gis=# \dt osm.*
                      List of relations
 Schema |                Name                | Type  | Owner  
--------+------------------------------------+-------+--------
 osm    | osm_admin                          | table | docker
 osm    | osm_aeroway_linestring             | table | docker
 osm    | osm_aeroway_points                 | table | docker
...
...
...
 osm    | osm_waterways_manmade              | table | docker
 osm    | osm_waterways_points               | table | docker
 osm    | osm_waterways_rivers               | table | docker
 osm    | osm_waterways_streams              | table | docker
(33 rows)

´´´

> Note that the specific list of which tables are created, and which features they contain is defined in `conf/osm_conf/mapping.yml`. The format for that mapping file is described in the [Imposm documentation](https://imposm.org/docs/imposm3/latest/mapping.html). The default mapping.yml we provide was develop for our work so includes things like healthsites, electrical infrastructure (don't confuse 'bay' with  beaches, it is an electrical [infrastructure construct](https://wiki.openstreetmap.org/wiki/Tag:line%3Dbay)) and other things that may not be relevant for your map.

## Prepare extra context layers

There are two additional tables that need to be loaded into the database before the provided configuration file will work. Both should be placed in the public schema. The first are low resolution boundaries of the world.

### World Layer

1. Open QGIS
2. Use the 'world' easter egg (1) to quickly load the layer in QGIS
3. ![image](https://user-images.githubusercontent.com/178003/192056969-d8531a2a-e66b-436e-8588-1681078b56e1.png)
4. Then rename the 'World Map' layer to simply 'world' (2)
5. Then drag and drop the layer into your database (3) - you need to have a PG connection set up to the docker database in order to do that.

### Water Bodies Layer

1. Download the water bodies layer from the [water polygons dataset](https://osmdata.openstreetmap.de/data/water-polygons.html) from OSM which gives you a good set of coastlines.
2. Add the layer to QGIS
3. Drag & drop the layer into the public schema of your database

## Create spatial indexs

There is a script in `conf/osm_conf/post-pbf-import.sql` which will build spatial and text based indexes on the various tables. However the above imported world and water_bodies layers will not have been covered so it is a good idea to run those commands again.

## Start your tile server

The file `conf/tegola_conf/tegola.conf` contains a default tegola configuration which will take various of the above tables and incorporate them into a map. To start tegola do:

``docker-compose up -d tegola``

After starting, tegola should provide a web interface to the published layers in the map.

<http://localhost:9090/#2.96/-9.41/40.51>

You may need to zoom in to start seeing the layers drawing.

## Start Maputnik-editor

The file `kartoza_osm_mapbox_style.json` contains a default maputnik configuration which will take various of the above tables and incorporate them into a cartographic product. To start maputnik editor do:

``docker-compose up -d maputnik-editor``

After starting, maputnik-editor should provide a web interface to the published layers in the map.

<http://localhost:8888/>

To use the starting `kartoza_osm_mapbox_style.json`, click the load button and the default set of cartographic rules we provide should load.

## What next?

From here on it is a process of editing your maputnik rules and then exporting the json file to use in your web mapping project.

If we wish to use the tiles in QGIS, it will do a pretty good job of converting and rendering the styles. You can see the ``qgis-tegola-world-tile-layer.qlr`` file as an example of this (just drag and drop it into QGIS).

If you wish to seed the cache, there is an example docker-compose service for doing that - you can tweak the options there to determine how many levels should be cached.

``docker-compose run tegola-seed``

If you are going to use your tiles in production, you may want to seed down to a certain level (e.g. level 15), and then use the vector tile rendering '[overzoom](https://docs.mapbox.com/help/glossary/overzoom/)' function so just show the same tiles at increasing levels. Just choose a level where the last details are added to your tiles.

Lastly, take a look [at this MapLibre](https://maplibre.org/maplibre-gl-js-docs/example/simple-map/) example which shows how to create a web map with both your tiles and your custom cartography.

I have tried to give you all the building blocks in this example to be able to see that you don't need to pay MapBox / ESRI or other vendors for the honor of using their vector tiles, you can do it all yourself with minimal effort.

## Credits

In September 2022, it was finally my turn to contract covid. Besides being quite sick, I spent my free time to make this!

Tim Sutton
@timlinux on GitHub and Twitter
