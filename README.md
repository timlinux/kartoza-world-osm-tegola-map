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

# Workflow overview

Here are the steps to getting set up with your own planetary tile server:

1) **You need a good computer and lots of disk fast space.** The import process will consume probably in excess of 150GB of your storage for the planet.pbf and the imposm cache files. Then when you start rendering and seeding tiles they can consume a lot of disk space. Plus you need to be able to responsively retrieve data from the database. For reference, on my developer maching, I have 64GB RAM, and AMD CPU with 24 threads and I had 1TB free space to work with. You can for sure get by with less but the better the spec your machine is, the better experience you will have.
2) **Install basic requirements** It is assumed you are using Linux in these notes, but the steps should work similarly in macOS and Windows. You do need to have a git client installed and docker + docker-compose installed and ready to use.
3) **Download the planet.pbf** In this step we download the global OSM dataset snapshot using a clever tool from MapTiler. From this pbf we will import a subset of the global features and attributes into our database.
4) **Start the stack**. This will immediately begin the very lengthy process of extracting all the items defined in ``conf/osm_conf/mapping.yml`` from the PBF into your database. It is going to take a loooooong time (probably about 8 hours on my system), so be patient!
5) **Start designing**. Once the import is done, the ´´osm´´ schema in your database will be populated and you can run Tegola and Maputnik Editor (both provided in our docker-compose.yml) to start designing your tileset.
6) **Use your tiles**. Your tiles can then be used from QGIS and web mapping applications. You can optionally start seeding your tile cache (again this will take a long time depending on what level you seed to) using the tooling provided, then host them on a cloud native storage platform like Amazon S3.

These notes are still to come...

## Credits

In September 2022, it was finally my turn to contract covid. Besides being quite sick, I spent my free time to make this!

Tim Sutton
@timlinux on GitHub and Twitter
