# A Self Hosted Planetary Vector Tile Set

## Elevator Pitch

* Built on OpenStreetMap data (and data (c) OpenStreetMap Contributors under the ODBL)
* All components Open Source so no license fees!
* Simple architecture (see below)
* Includes all the tooling to create and style vector tiles.
* 99% More awesome!

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

## Usage

These notes are still to come...

## Credits

In September 2022, it was finally my turn to contract covid. Besides being quite sick, I spent my free time to make this!

Tim Sutton
@timlinux on GitHub and Twitter
