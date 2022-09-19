SHELL := /bin/bash

#----------------- Postgres --------------------------
run-maputnik:
	# TODO - move to docker compose rather
	@docker run -it --rm -p 8888:8888 maputnik/editor

deploy-postgres: enable-postgres configure-postgres start-postgres

enable-postgres:
	@make check-env
	@echo "db" >> enabled-profiles

configure-timezone:
	@make check-env
	@if grep "#TIMEZONE CONFIGURED" .env; then echo "Timezone already configured";  exit 0; else \
	echo "Please enter the timezone for your server"; \
	echo "See https://en.wikipedia.org/wiki/List_of_tz_database_time_zones"; \
	echo "Follow exactly the format of the TZ Database Name column"; \
	read -p "Server Time Zone (e.g. Etc/UTC):" TZ; \
	   rpl TIMEZONE=Etc/UTC TIMEZONE=$$TZ .env; \
	echo "#TIMEZONE CONFIGURED" >> .env; \
	fi

configure-postgres: configure-timezone 
	@make check-env
	@echo "=========================:"
	@echo "Postgres configuration:"
	@echo "=========================:"
	@export PASSWD=$$(pwgen 20 1); \
		rpl POSTGRES_PASSWORD=docker POSTGRES_PASSWORD=$$PASSWD .env; \
		echo "Postgres password set to $$PASSWD"
	@echo "We are going to enable access to Postgres on your host."
	@echo "Typically you would do this when you want to access the database"
	@echo "from software such as QGIS that can directly connect to a Postgres"
	@echo "database. There are some security implications to running on "
	@echo "a publicly accessible port. People with credentials to access your "
	@echo "database may use those credentials to launch arbitrary applications "
	@echo "inside the database container if you do not manage the permissions carefully."
	@echo "Note that the database is configured to require"
	@echo "SSL secure encryption on all connections to the database. This includes"
	@echo "internally between docker containers and from an external client. So be sure"
	@echo "to set your client SSL mode to 'REQUIRE' (e.g. in QGIS  / GeoServer / Node-Red etc.)."
	@echo 
	@echo "If you want to allow/disallow access to this service from other hosts, please use"
	@echo "firewall software such as ufw (uncomplicated firewall) to allow traffic on"
	@echo "your chosen public port."
	@echo
	@echo "Enter to the public port to access PG from the host."
	@echo
	@read -p "Postgis Public Port (e.g. 5432):" PORT; \
	   rpl POSTGRES_PUBLIC_PORT=5432 POSTGRES_PUBLIC_PORT=$$PORT .env; 

start-postgres:
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Starting Postgres"
	@echo "------------------------------------------------------------------"
	@docker-compose up -d db

stop-postgres:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Stopping Postgres"
	@echo "------------------------------------------------------------------"
	-@docker-compose kill db
	@docker-compose rm db

restart-postgres:
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Restarting Postgres"
	@echo "------------------------------------------------------------------"
	@docker-compose kill db
	@docker-compose rm db
	@docker-compose up -d db
	@docker-compose logs -f db

disable-postgres:
	@make check-env
	@echo "This is currently a stub"	
	# Remove from enabled-profiles
	@sed -i '/db/d' enabled-profiles

db-logs:
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Polling db logs. Press Ctrl-c to exit."
	@echo "------------------------------------------------------------------"
	@docker-compose logs -f db

db-shell: ## Create a bash shell in the db container
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Creating db bash shell"
	@echo "------------------------------------------------------------------"
	@docker-compose exec -u postgres db bash

db-psql-shell: ## Create a psql session in the db container connected to the gis database
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Creating db psql shell"
	@echo "------------------------------------------------------------------"
	@docker-compose exec -u postgres db psql gis

backup-db-qgis-styles: ## Backup QGIS Styles in the gis database
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Backing up QGIS styles stored in the gis database"
	@echo "------------------------------------------------------------------"
	-@mkdir -p backups
	@docker-compose exec -u postgres db pg_dump --clean -f /tmp/qgis-styles.sql -t public.layer_styles gis
	@docker cp osmmirror_db_1:/tmp/qgis-styles.sql backups
	@docker-compose exec -u postgres db rm /tmp/qgis-styles.sql
	@cp backups/qgis-styles.sql backups/qgis-styles-$$(date +%Y-%m-%d).sql
	@ls -lah backups/qgis-styles*.sql

restore-db-qgis-styles:
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Restoring the last back up of QGIS styles to the gis database"
	@echo "If you wish to restore an older backup, first copy it to /backups/qgis-styles.sql"
	@echo "Note: Restoring will OVERWRITE your current public.layer_styles table in the gis database."
	@echo "------------------------------------------------------------------"
	@echo -n "Are you sure you want to continue? [y/N] " && read ans && [ $${ans:-N} = y ]
	@docker cp backups/qgis-styles.sql osmmirror_db_1:/tmp/ 
	@docker-compose exec -u postgres db psql -f /tmp/qgis-styles.sql -d gis
	@docker-compose exec db rm /tmp/qgis-styles.sql
	@docker-compose exec -u postgres db psql -c "select stylename from layer_styles;" gis 

backup-db-qgis-projects:
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Backing up QGIS projects stored in the gis database"
	@echo "------------------------------------------------------------------"
	-@mkdir -p backups
	@docker-compose exec -u postgres db pg_dump --clean -f /tmp/qgis-projects.sql -t public.qgis_projects gis
	@docker cp osmmirror_db_1:/tmp/qgis-projects.sql backups
	@docker-compose exec -u postgres db rm /tmp/qgis-projects.sql
	@cp backups/qgis-projects.sql backups/qgis-projects-$$(date +%Y-%m-%d).sql
	@ls -lah backups/qgis-projects*.sql

restore-db-qgis-projects:
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Restoring the last back up of QGIS projects to the gis database"
	@echo "If you wish to restore an older backup, first copy it to /backups/qgis-projects.sql"
	@echo "Note: Restoring will OVERWRITE your current public.qgis_projects table in the gis database."
	@echo "------------------------------------------------------------------"
	@echo -n "Are you sure you want to continue? [y/N] " && read ans && [ $${ans:-N} = y ]
	@docker cp backups/qgis-projects.sql osmmirror_db_1:/tmp/ 	
	@docker-compose exec -u postgres db psql -f /tmp/qgis-projects.sql -d gis
	@docker-compose exec db rm /tmp/qgis-projects.sql
	@docker-compose exec -u postgres db psql -c "select name from public.qgis_projects;" gis

backup-db-gis: ## Backup the gis database
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Backing up the entire gis database"
	@echo "------------------------------------------------------------------"
	-@mkdir -p backups
	@docker-compose exec -u postgres db pg_dump --clean -f /tmp/osmmirror-gis-database.sql gis
	@docker cp osmmirror_db_1:/tmp/osmmirror-gis-database.sql backups
	@docker-compose exec -u postgres db rm /tmp/osmmirror-gis-database.sql
	@cp backups/osmmirror-gis-database.sql backups/osmmirror-gis-database-$$(date +%Y-%m-%d).sql
	@ls -lah backups/osmmirror-gis-database*.sql

restore-db-gis: ## Restore the gis database from a back up
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Restoring the last back up the entire gis database"
	@echo "If you wish to restore an older backup, first copy it to /backups/osmmirror-gis-database.sql"
	@echo "Note: Restoring will OVERWRITE your current gis database."
	@echo "------------------------------------------------------------------"
	@echo -n "Are you sure you want to continue? [y/N] " && read ans && [ $${ans:-N} = y ]
	@docker cp ./backups/osmmirror-gis-database.dmp osmmirror_db_1:/tmp/
	@docker-compose exec -u postgres db pg_restore -f /tmp/osmmirror-gis-database.dmp -d gis
	@docker-compose exec db rm /tmp/osmmirror-gis-database.dmp
	@docker-compose exec -u postgres db psql -c "\dn;" gis

list-database-sizes: ## Show the disk space used by each database
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Listing the sizes of all postgres databases"
	@echo "------------------------------------------------------------------"
	@docker-compose exec -u postgres db bash -c "psql -c '\l+' > /tmp/listing.txt; cat /tmp/listing.txt | sed 's/--//g'" | sed 's/ //g' | awk 'BEGIN { FS = "|" } {print $$1 ":" $$7}' | tail -n +4 | head -n -5

backup-all-databases: ## Backup all postgresql databases
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Backing up all postgres databases"
	@echo "------------------------------------------------------------------"
	-@mkdir -p backups
	@docker-compose exec -u postgres db pg_dumpall --clean -f /tmp/osmmirror-all-databases.sql
	@docker cp osmmirror_db_1:/tmp/osmmirror-all-databases.sql backups
	@docker-compose exec -u postgres db rm /tmp/osmmirror-all-databases.sql
	@cp backups/osmmirror-all-databases.sql backups/osmmirror-all-databases-$$(date +%Y-%m-%d).sql
	@ls -lah backups/osmmirror-all-databases*.sql

restore-all-databases: ## Backup all postgresql databases
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Restoring last back up of all postgres databases"
	@echo "If you wish to restore an older backup, first copy it to /backups/osmmirror-all-databases.sql"
	@echo "Note: Restoring will OVERWRITE all your current postgres databases."
	@echo "------------------------------------------------------------------"
	@echo -n "Are you sure you want to continue? [y/N] " && read ans && [ $${ans:-N} = y ]
	@docker cp backups/osmmirror-all-databases.sql osmmirror_db_1:/tmp/
	@docker-compose exec -u postgres db psql -f /tmp/osmmirror-all-databases.sql
	@docker-compose exec db rm /tmp/osmmirror-all-databases.sql
	@docker-compose exec -u postgres db psql -c "\l+"


#----------------- OSM Mirror --------------------------

deploy-osm-mirror: download-world-pbf start-osm-mirror 

download-world-pbf:
	# This is a nice way to get the planet file as it does a distributed download
	# note that at the time of writing this, the download is around 70gb
	@docker run --rm -it -v $$PWD:/download openmaptiles/openmaptiles-tools download-osm planet -- -d /download
	@mv planet-*.osm.pbf conf/osm_conf/country.pbf

start-osm-mirror:
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Starting OSM Mirror"
	@echo "------------------------------------------------------------------"
	@docker-compose up -d 

sleep5m:
	@echo "------------------------------------------------------------------"
	@echo "Sleep for 5 minutes"
	@echo "------------------------------------------------------------------"
	@sleep 5m

restart-osm-mirror: stop-osm-mirror
	@docker-compose up -d imposm osmupdate osmenrich 
	@docker-compose logs -f imposm osmupdate osmenrich

osm-to-mbtiles:
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Creating a vector tiles store from the docker osm schema"
	@echo "------------------------------------------------------------------"
# @docker-compose run osm-to-mbtiles
	@echo "we use below for now because the container aproach doesnt have a new enough gdal (2.x vs >=3.1 needed)"
	@ogr2ogr -f MBTILES osm.mbtiles PG:"dbname='gis' host='localhost' port='15432' user='docker' password='docker' SCHEMAS=osm" -dsco "MAXZOOM=10 BOUNDS=-7.389126,39.410085,-7.381439,39.415144"

osm-mirror-logs:
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Polling OSM Mirror logs"
	@echo "------------------------------------------------------------------"
	@docker-compose logs -f imposm osmupdate

osm-mirror-osmupdate-shell:
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Creating OSM Mirror osmupdate shell"
	@echo "------------------------------------------------------------------"
	@docker-compose exec osmupdate bash 

osm-mirror-imposm-shell:
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Creating OSM Mirror imposm shell"
	@echo "------------------------------------------------------------------"
	@docker-compose exec imposm bash 


up:
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Starting all configured services"
	@echo "------------------------------------------------------------------"
	@docker-compose up -d

kill:
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Killing all containers"
	@echo "------------------------------------------------------------------"
	@docker-compose kill

rm: kill
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Removing all containers"
	@echo "------------------------------------------------------------------"
	@docker-compose rm

restart:
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Restarting all containers"
	@echo "------------------------------------------------------------------"
	@docker-compose restart
	# Need to flush this completely for it to work on restart
	make stop-qgis-desktop
	make start-qgis-desktop
	@docker-compose logs -f

pull:
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Stopping, removing, updating and restarting all containers"
	@echo "------------------------------------------------------------------"
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@docker-compose kill
	@docker-compose rm
	@docker-compose pull
	@docker-compose up -d

nuke:
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Disabling services"
	@echo "This command will delete all your configuration and data permanently."
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo -n "Please type CONFIRM to proceed " && read ans && [ $${ans:-N} = CONFIRM ]
	@echo "------------------------------------------------------------------"
	@echo "Nuking Everything!"
	@echo "------------------------------------------------------------------"
	@docker-compose rm -v -f -s
	@echo -n "Deleting volumes will remove all previous application state!!"
	@echo -n "Please type DELETE to proceed " && read ans && [ $${ans:-N} = DELETE ]
	-@docker volume rm $(shell docker volume ls | grep osmmirror | awk '{print $2}')
	@rm .env
	@sudo rm -rf certbot/certbot
	
logs:
	@make check-env
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Tailing logs"
	@echo "------------------------------------------------------------------"
	@docker-compose logs -f

check-env: 
	@echo "Checking env"
	@if [ ! -f ".env" ]; then \
		echo "--------------------------------------------------"; \
	       	echo ""; echo ""; echo ".env does not exist yet."; echo ""; \
		echo "Please run either make configure-ssl-self-signed or make configure-letsencrypt-ssl to set up your stack!"; echo ""; \
		echo "--------------------------------------------------"; \
	       	exit 1; \
	fi
