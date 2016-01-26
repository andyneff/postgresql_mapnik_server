IMAGE_NAME = andyneff/openstreetmap_database
CONTAINER_NAME = osm_server
DOCKERFILE = Dockerfile
GENERATE_IMAGE_NAME = andyneff/mapnik_generate
GENERATE_DOCKERFILE = Dockerfile.generate

DATA_DIR = $$(pwd)/data

MOUNTS = $(DATA_DIR):/var/lib/postgresql/data \
         $$(pwd)/style:/style:ro

GENERATE_MOUNTS = $$(pwd)/context/generate_image.py:/geneate_image.py:ro
                  $$(pwd)/output:/output

MOUNTS := $(addprefix -v ,$(MOUNTS))
GENERATE_MOUNTS := $(addprefix -v ,$(GENERATE_MOUNTS))

RESTART_POLICY = always
#The restart policy used when you start_service. Can be (on-failure[:max-retry],
#always, unless-stopped). It can also be no, but then you might as well use
#start/stop instead of start_service/stop_service

.PHONY: build clean clobber run start enter stop kill australia status \
	      start_service stop_service wait

build:
	docker build -t $(IMAGE_NAME) context
	docker build -t $(GENERATE_IMAGE_NAME) -f context/Dockerfile.generate context

pull:
	docker pull $(IMAGE_NAME)
	docker pull $(GENERATE_IMAGE_NAME)

push:
	docker push $(IMAGE_NAME)
	docker push $(GENERATE_IMAGE_NAME)

clean:
	if docker inspect $(CONTAINER_NAME) > /dev/null 2>&1; then \
	  docker rm $(CONTAINER_NAME); \
	fi
	mkdir -p $(DATA_DIR)

clobber: kill
	docker rm $(CONTAINER_NAME)

run: clean
	docker run -it $(MOUNTS) --rm --name $(CONTAINER_NAME) $(IMAGE_NAME) bash

start: clean
	docker run -d $(MOUNTS) --name $(CONTAINER_NAME) $(IMAGE_NAME)

status:
	docker ps --filter name=$(CONTAINER_NAME)

start_service:
	docker run -d $(MOUNTS) --restart=$(RESTART_POLICY) --name $(CONTAINER_NAME) $(IMAGE_NAME)

stop_service:

wait:
	@while docker inspect $(CONTAINER_NAME) > /dev/null 2>&1; do \
	  sleep 0.3; \
	done

enter:
	docker exec -it $(CONTAINER_NAME) bash

stop:
	docker exec $(CONTAINER_NAME) gosu postgres pg_ctl stop || \
	$(MAKE) wait
	docker rm $(CONTAINER_NAME)

restart: stop start
	@echo Restarted

kill:
	docker kill $(CONTAINER_NAME)

install:
	docker run -v $$(pwd)/openstreetmap-carto:/style -it --rm $(IMAGE_NAME) /style/get-shapefiles.sh

australia:
	if [ ! -f australia-oceania-latest.osm.pbf ]; then \
	  curl -LO http://download.geofabrik.de/australia-oceania-latest.osm.pbf; \
	fi
	docker cp australia-oceania-latest.osm.pbf $(CONTAINER_NAME):/
	docker exec -it $(CONTAINER_NAME) gosu postgres osm2pgsql -d gis /australia-oceania-latest.osm.pbf
	#--style /openstreetmap-carto-2.37.1/openstreetmap-carto.style
	docker exec -it $(CONTAINER_NAME) rm /australia-oceania-latest.osm.pbf