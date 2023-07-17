{ pkgs, ... }:

{
  # Set up docker network
  systemd.services.immich-network = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${pkgs.docker}/bin/docker network create --driver bridge immich||:
    '';
    after = [ "docker.service" ];
    before = [
      "docker-immich-machine_learning.service"
      "docker-immich-microservices.service"
      "docker-immich-postgres.service"
      "docker-immich-proxy.service"
      "docker-immich-redis.service"
      "docker-immich-server.service"
      "docker-immich-typesense.service"
      "docker-immich-web.service"
    ];
  };


  #networking.firewall = { allowedTCPPorts = [ 3000 3001 3002 ]; };
  /*


    services.nginx.enable = true;
    services.nginx.virtualHosts."localhost" = {
    addSSL = false;
    enableACME = false;

    listen = [
      {
        addr = "127.0.0.1";
        port = 8080;
      }
    ];

    locations."/api/(.*)/" = {
      extraConfig = ''
        rewrite /api/(.*) /$1 break;
        proxy_pass http://127.0.0.1:3001;
      '';
    };

    locations."/" = {
      proxyPass = "http://127.0.0.1:3000";
    };
    };
  */

  #security.acme = {
  #  acceptTerms = true;
  #  email = "foo@bar.com";
  #};


  virtualisation.oci-containers.containers =
    let
      IMMICH_VERSION = "release";
      UPLOAD_LOCATION = "/var/lib/immich";

      environment = {
        # Database

        DB_HOSTNAME = "immich-postgres";
        DB_USERNAME = "immich";
        DB_PASSWORD = "immich";
        DB_DATABASE_NAME = "immich";

        # Optional Database settings:
        # DB_PORT=5432

        # Redis

        REDIS_HOSTNAME = "immich-redis";

        # Optional Redis settings:

        # Note: these parameters are not automatically passed to the Redis Container
        # to do so, please edit the docker-compose.yml file as well. Redis is not configured
        # via environment variables, only redis.conf or the command line

        # REDIS_PORT=6379
        # REDIS_DBINDEX=0
        # REDIS_PASSWORD=
        # REDIS_SOCKET=

        # Upload File Location

        UPLOAD_LOCATION = "/var/lib/immich";


        # Log message level - [simple|verbose]
        LOG_LEVEL = "simple";

        # Typesense
        TYPESENSE_ENABLED = "false";
        #TYPESENSE_API_KEY=some-random-text
        # TYPESENSE_HOST: typesense
        # TYPESENSE_PORT: 8108
        # TYPESENSE_PROTOCOL: http

        ###################################################################################
        # Reverse Geocoding
        #
        # Reverse geocoding is done locally which has a small impact on memory usage
        # This memory usage can be altered by changing the REVERSE_GEOCODING_PRECISION variable
        # This ranges from 0-3 with 3 being the most precise
        # 3 - Cities > 500 population: ~200MB RAM
        # 2 - Cities > 1000 population: ~150MB RAM
        # 1 - Cities > 5000 population: ~80MB RAM
        # 0 - Cities > 15000 population: ~40MB RAM
        ####################################################################################

        # DISABLE_REVERSE_GEOCODING=false
        # REVERSE_GEOCODING_PRECISION=3

        ####################################################################################
        # WEB - Optional
        #
        # Custom message on the login page, should be written in HTML form.
        # For example:
        # PUBLIC_LOGIN_PAGE_MESSAGE="This is a demo instance of Immich.<br><br>Email: <i>demo@demo.de</i><br>Password: <i>demo</i>"
        ####################################################################################

        PUBLIC_LOGIN_PAGE_MESSAGE = "My Family Photos and Videos Backup Server";

        ####################################################################################
        # Alternative Service Addresses - Optional
        #
        # This is an advanced feature for users who may be running their immich services on different hosts.
        # It will not change which address or port that services bind to within their containers, but it will change where other services look for their peers.
        # Note: immich-microservices is bound to 3002, but no references are made
        ####################################################################################

        #        IMMICH_WEB_URL = "http://127.0.0.1:3000";
        #        IMMICH_SERVER_URL = "http://127.0.0.1:3001";
        #IMMICH_MACHINE_LEARNING_URL = "http://127.0.0.1:3003";

        ####################################################################################
        # Alternative API's External Address - Optional
        #
        # This is an advanced feature used to control the public server endpoint returned to clients during Well-known discovery.
        # You should only use this if you want mobile apps to access the immich API over a custom URL. Do not include trailing slash.
        # NOTE: At this time, the web app will not be affected by this setting and will continue to use the relative path: /api
        # Examples: http://localhost:3001, http://immich-api.example.com, etc
        ####################################################################################

        #IMMICH_API_URL_EXTERNAL=http://localhost:3001

        ###################################################################################
        # Immich Version - Optional
        #
        # This allows all immich docker images to be pinned to a specific version. By default,
        # the version is "release" but could be a specific version, like "v1.59.0".
        ###################################################################################

        #IMMICH_VERSION=

        #   TYPESENSE_API_KEY = "${TYPESENSE_API_KEY}";
        #   TYPESENSE_DATA_DIR = "/data";



        POSTGRES_PASSWORD = "immich"; # TODO
        POSTGRES_USER = "immich";
        POSTGRES_DB = "immich";
        PG_DATA = "/var/lib/postgresql/data";
      };
    in
    {

      # version: "3.8"
      # 
      # services:
      #   immich-server:
      #     container_name: immich_server
      #     image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}
      #     command: [ "start.sh", "immich" ]
      #     volumes:
      #       - ${UPLOAD_LOCATION}:/usr/src/app/upload
      #     env_file:
      #       - .env
      #     depends_on:
      #       - redis
      #       - database
      #       - typesense
      #     restart: always
      immich-server = {
        inherit environment;

        extraOptions = [ "--network=immich" ];
        autoStart = true;
        cmd = [ "start.sh" "immich" ];
        image = "ghcr.io/immich-app/immich-server:${IMMICH_VERSION}";
        volumes = [
          "${UPLOAD_LOCATION}:/usr/src/app/upload"
        ];

        ports = [ "3001:3001" ];
        dependsOn = [
          "immich-redis"
          "immich-postgres"
          "immich-typesense"
        ];
      };

      #   immich-microservices:
      #     container_name: immich_microservices
      #     image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}
      #     command: [ "start.sh", "microservices" ]
      #     volumes:
      #       - ${UPLOAD_LOCATION}:/usr/src/app/upload
      #     env_file:
      #       - .env
      #     depends_on:
      #       - redis
      #       - database
      #       - typesense
      #     restart: always

      immich-microservices = {
        extraOptions = [ "--network=immich" ];

        autoStart = true;
        cmd = [ "start.sh" "microservices" ];
        image = "ghcr.io/immich-app/immich-server:${IMMICH_VERSION}";

        inherit environment;
        volumes = [
          "${UPLOAD_LOCATION}:/usr/src/app/upload"
        ];
        dependsOn = [
          "immich-redis"
          "immich-postgres"
          "immich-typesense"
        ];
      };

      # 
      #   immich-machine-learning:
      #     container_name: immich_machine_learning
      #     image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}
      #     volumes:
      #       - model-cache:/cache
      #     env_file:
      #       - .env
      #     restart: always
      # 

      immich-machine-learning = {
        extraOptions = [ "--network=immich" ];
        autoStart = true;
        image = "ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION}";
        volumes = [ "model-cache:/cache" ];
        inherit environment;
      };

      #   immich-web:
      #     container_name: immich_web
      #     image: ghcr.io/immich-app/immich-web:${IMMICH_VERSION:-release}
      #     env_file:
      #       - .env
      #     restart: always
      # 

      immich-web = {
        extraOptions = [ "--network=immich" ];
        autoStart = true;

        ports = [ "3000:3000" ];
        image = "ghcr.io/immich-app/immich-web:${IMMICH_VERSION}";
        inherit environment;
      };

      #   typesense:
      #     container_name: immich_typesense
      #     image: typesense/typesense:0.24.1@sha256:9bcff2b829f12074426ca044b56160ca9d777a0c488303469143dd9f8259d4dd
      #     environment:
      #       - TYPESENSE_API_KEY=${TYPESENSE_API_KEY}
      #       - TYPESENSE_DATA_DIR=/data
      #     logging:
      #       driver: none
      #     volumes:
      #       - tsdata:/data
      #     restart: always

      immich-typesense = {
        extraOptions = [ "--network=immich" ];

        autoStart = true;
        image = "typesense/typesense:0.24.1@sha256:9bcff2b829f12074426ca044b56160ca9d777a0c488303469143dd9f8259d4dd";

        inherit environment;

        log-driver = "none";

        volumes = [ "tsdata:/data" ];
      };


      #   redis:
      #     container_name: immich_redis
      #     image: redis:6.2-alpine@sha256:70a7a5b641117670beae0d80658430853896b5ef269ccf00d1827427e3263fa3
      #     restart: always
      # 

      immich-redis = {
        extraOptions = [ "--network=immich" ];
        autoStart = true;
        image = "redis:6.2-alpine@sha256:70a7a5b641117670beae0d80658430853896b5ef269ccf00d1827427e3263fa3";
      };



      #   database:
      #     container_name: immich_postgres
      #     image: postgres:14-alpine@sha256:28407a9961e76f2d285dc6991e8e48893503cc3836a4755bbc2d40bcc272a441
      #     env_file:
      #       - .env
      #     environment:
      #       POSTGRES_PASSWORD: ${DB_PASSWORD}
      #       POSTGRES_USER: ${DB_USERNAME}
      #       POSTGRES_DB: ${DB_DATABASE_NAME}
      #       PG_DATA: /var/lib/postgresql/data
      #     volumes:
      #       - pgdata:/var/lib/postgresql/data
      #     restart: always
      # 

      immich-postgres = {
        extraOptions = [ "--network=immich" ];

        autoStart = true;
        image = "postgres:14-alpine@sha256:28407a9961e76f2d285dc6991e8e48893503cc3836a4755bbc2d40bcc272a441";

        inherit environment;
        volumes = [ "pgdata:/var/lib/postgresql/data" ];
      };

      immich-proxy = {
        extraOptions = [ "--network=immich" ];

        workdir = "/var/lib/immich/proxy-workdir";

        image = "ghcr.io/immich-app/immich-proxy:${IMMICH_VERSION}";
        inherit environment;
        ports = [
          "2283:8080"
        ];

        dependsOn = [
          "immich-server"
          "immich-web"
        ];
      };



      #   immich-proxy:
      #     container_name: immich_proxy
      #     image: ghcr.io/immich-app/immich-proxy:${IMMICH_VERSION:-release}
      #     environment:
      #       # Make sure these values get passed through from the env file
      #       - IMMICH_SERVER_URL
      #       - IMMICH_WEB_URL
      #     ports:
      #       - 2283:8080
      #     depends_on:
      #       - immich-server
      #       - immich-web
      #     restart: always
      # 
      # volumes:
      #   pgdata:
      #   model-cache:
      #   tsdata:
    };
}

