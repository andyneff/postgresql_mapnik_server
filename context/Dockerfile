FROM postgres:9.5.0

MAINTAINER Andy Neff <andrew.neff@visionsystemsinc.com>

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y -q postgresql-9.5-postgis-2.2 postgresql-contrib postgresql-server-dev-9.5 \
                                                         node-carto osm2pgsql curl mapnik-utils libmapnik2.2 unzip && \
    rm -rf /var/lib/apt/lists/*

#RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
#    DEBIAN_FRONTEND=noninteractive apt-get install -y -q unzip

#RUN curl -L https://github.com/gravitystorm/openstreetmap-carto/archive/v2.37.1.tar.gz -o mapnik.tar.gz && \
#    tar zxf mapnik.tar.gz && \
#    rm mapnik.tar.gz

#RUN curl -L https://github.com/openstreetmap/mapnik-stylesheets/archive/master.tar.gz -o mapnik-style.tar.gz && \
#    tar zxf mapnik-style.tar.gz && \
#    rm mapnik-style.tar.gz

# Development python-yaml python-numpy libopenblas-base runy

# Look into using Nik4 for rendering https://github.com/Zverik/Nik4

ENV OSM_USER=osm \
    OSM_DB=gis

ADD openstreetmap-carto.sh /docker-entrypoint-initdb.d/
RUN chmod 755 /docker-entrypoint-initdb.d/*.sh

EXPOSE 5432

VOLUME /style
WORKDIR /style
