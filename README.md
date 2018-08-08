
[![Docker Pulls](https://img.shields.io/docker/pulls/itzg/minecraft-server.svg)](https://hub.docker.com/r/itzg/minecraft-server/)
[![Docker Stars](https://img.shields.io/docker/stars/itzg/minecraft-server.svg?maxAge=2592000)](https://hub.docker.com/r/itzg/minecraft-server/)
[![GitHub Issues](https://img.shields.io/github/issues-raw/itzg/dockerfiles.svg)](https://github.com/itzg/dockerfiles/issues)

This docker image provides a Minecraft Server that will automatically download the latest stable
version at startup. You can also run/upgrade to any specific version or the
latest snapshot. See the *Versions* section below for more information.

To simply use the latest stable version, run

    docker run -d -p 25565:25565 --name mc itzg/minecraft-server

where the standard server port, 25565, will be exposed on your host machine.

If you want to serve up multiple Minecraft servers or just use an alternate port,
change the host-side port mapping such as

    docker run -p 25566:25565 ...

will serve your Minecraft server on your host's port 25566 since the `-p` syntax is
`host-port`:`container-port`.

Speaking of multiple servers, it's handy to give your containers explicit names using `--name`, such as

    docker run -d -p 25565:25565 --name mc itzg/minecraft-server

With that you can easily view the logs, stop, or re-start the container:

    docker logs -f mc
        ( Ctrl-C to exit logs action )

    docker stop mc

    docker start mc

## Interacting with the server

[RCON](http://wiki.vg/RCON) is enabled by default, so you can `exec` into the container to
access the Minecraft server console:

```
docker exec -i mc rcon-cli
```

Note: The `-i` is required for interactive use of rcon-cli.

To run a simple, one-shot command, such as stopping a Minecraft server, pass the command as
arguments to `rcon-cli`, such as:

```
docker exec mc rcon-cli stop
```

_The `-i` is not needed in this case._

In order to attach and interact with the Minecraft server, add `-it` when starting the container, such as

    docker run -d -it -p 25565:25565 --name mc itzg/minecraft-server

With that you can attach and interact at any time using

    docker attach mc

and then Control-p Control-q to **detach**.

For remote access, configure your Docker daemon to use a `tcp` socket (such as `-H tcp://0.0.0.0:2375`)
and attach from another machine:

    docker -H $HOST:2375 attach mc

Unless you're on a home/private LAN, you should [enable TLS access](https://docs.docker.com/articles/https/).

## EULA Support

Mojang now requires accepting the [Minecraft EULA](https://account.mojang.com/documents/minecraft_eula). To accept add

        -e EULA=TRUE

such as

        docker run -d -it -e EULA=TRUE -p 25565:25565 --name mc itzg/minecraft-server

## Attaching data directory to host filesystem

In order to readily access the Minecraft data, use the `-v` argument
to map a directory on your host machine to the container's `/data` directory, such as:

    docker run -d -v /path/on/host:/data ...

When attached in this way you can stop the server, edit the configuration under your attached `/path/on/host`
and start the server again with `docker start CONTAINERID` to pick up the new configuration.

## Versions

To use a different Minecraft version, pass the `VERSION` environment variable, which can have the value

* LATEST
* SNAPSHOT
* (or a specific version, such as "1.7.9")

For example, to use the latest snapshot:

    docker run -d -e VERSION=SNAPSHOT ...

or a specific version:

    docker run -d -e VERSION=1.7.9 ...

## Healthcheck

This image contains [Dinnerbone's mcstatus](https://github.com/Dinnerbone/mcstatus) and uses
its `ping` command to continually check on the container's. That can be observed
from the `STATUS` column of `docker ps`

```
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                    PORTS                                 NAMES
b418af073764        mc                  "/start"            43 seconds ago      Up 41 seconds (healthy)   0.0.0.0:25565->25565/tcp, 25575/tcp   mc
```

You can also query the container's health in a script friendly way:

```
> docker container inspect -f "{{.State.Health.Status}}" mc
healthy
```

Finally, since `mcstatus` is on the `PATH` you can exec into the container
and use mcstatus directly and invoke any of its other commands:

```
> docker exec mc mcstatus localhost status
version: v1.12 (protocol 335)
description: "{u'text': u'A Minecraft Server Powered by Docker'}"
players: 0/20 No players online
```

## Running a Forge Server

Enable Forge server mode by adding a `-e TYPE=FORGE` to your command-line.
By default the container will run the `RECOMMENDED` version of [Forge server](http://www.minecraftforge.net/wiki/)
but you can also choose to run a specific version with `-e FORGEVERSION=10.13.4.1448`.

    $ docker run -d -v /path/on/host:/data -e VERSION=1.7.10 \
        -e TYPE=FORGE -e FORGEVERSION=10.13.4.1448 \
        -p 25565:25565 -e EULA=TRUE --name mc itzg/minecraft-server

To use a pre-downloaded Forge installer, place it in the attached `/data` directory and
specify the name of the installer file with `FORGE_INSTALLER`, such as:

    $ docker run -d -v /path/on/host:/data ... \
        -e FORGE_INSTALLER=forge-1.11.2-13.20.0.2228-installer.jar ...

To download a Forge installer from a custom location, such as your own file repository, specify
the URL with `FORGE_INSTALLER_URL`, such as:

    $ docker run -d -v /path/on/host:/data ... \
        -e FORGE_INSTALLER_URL=http://HOST/forge-1.11.2-13.20.0.2228-installer.jar ...

In both of the cases above, there is no need for the `VERSION` or `FORGEVERSION` variables.

In order to add mods, you have two options.

### Using the /data volume

This is the easiest way if you are using a persistent `/data` mount.

To do this, you will need to attach the container's `/data` directory
(see "Attaching data directory to host filesystem”).
Then, you can add mods to the `/path/on/host/mods` folder you chose. From the example above,
the `/path/on/host` folder contents look like:

```
/path/on/host
├── mods
│   └── ... INSTALL MODS HERE ...
├── config
│   └── ... CONFIGURE MODS HERE ...
├── ops.json
├── server.properties
├── whitelist.json
└── ...
```

If you add mods while the container is running, you'll need to restart it to pick those
up:

    docker stop mc
    docker start mc

### Using separate mounts

This is the easiest way if you are using an ephemeral `/data` filesystem,
or downloading a world with the `WORLD` option.

There are two additional volumes that can be mounted; `/mods` and `/config`.  
Any files in either of these filesystems will be copied over to the main
`/data` filesystem before starting Minecraft.

This works well if you want to have a common set of modules in a separate
location, but still have multiple worlds with different server requirements
in either persistent volumes or a downloadable archive.

## Running a Bukkit/Spigot server

Enable Bukkit/Spigot server mode by adding a `-e TYPE=BUKKIT -e VERSION=1.8` or `-e TYPE=SPIGOT -e VERSION=1.8` to your command-line.

    docker run -d -v /path/on/host:/data \
        -e TYPE=SPIGOT -e VERSION=1.8 \
        -p 25565:25565 -e EULA=TRUE --name mc itzg/minecraft-server

If you are hosting your own copy of Bukkit/Spigot you can override the download URLs with:
* -e BUKKIT_DOWNLOAD_URL=<url>
* -e SPIGOT_DOWNLOAD_URL=<url>

You can build spigot from source by adding `-e BUILD_FROM_SOURCE=true`

__NOTE: to avoid pegging the CPU when running Spigot,__ you will need to
pass `--noconsole` at the very end of the command line and not use `-it`. For example,

    docker run -d -v /path/on/host:/data \
        -e TYPE=SPIGOT -e VERSION=1.8 \
        -p 25565:25565 -e EULA=TRUE --name mc itzg/minecraft-server --noconsole


You can install Bukkit plugins in two ways...

### Using the /data volume

This is the easiest way if you are using a persistent `/data` mount.

To do this, you will need to attach the container's `/data` directory
(see "Attaching data directory to host filesystem”).
Then, you can add plugins to the `/path/on/host/plugins` folder you chose. From the example above,
the `/path/on/host` folder contents look like:

```
/path/on/host
├── plugins
│   └── ... INSTALL PLUGINS HERE ...
├── ops.json
├── server.properties
├── whitelist.json
└── ...
```

If you add plugins while the container is running, you'll need to restart it to pick those
up:

    docker stop mc
    docker start mc

### Using separate mounts

This is the easiest way if you are using an ephemeral `/data` filesystem,
or downloading a world with the `WORLD` option.

There is one additional volume that can be mounted; `/plugins`.  
Any files in this filesystem will be copied over to the main
`/data/plugins` filesystem before starting Minecraft.

This works well if you want to have a common set of plugins in a separate
location, but still have multiple worlds with different server requirements
in either persistent volumes or a downloadable archive.

## Running a PaperSpigot server

Enable PaperSpigot server mode by adding a `-e TYPE=PAPER -e VERSION=1.9.4` to your command-line.

    docker run -d -v /path/on/host:/data \
        -e TYPE=PAPER -e VERSION=1.9.4 \
        -p 25565:25565 -e EULA=TRUE --name mc itzg/minecraft-server

__NOTE: to avoid pegging the CPU when running PaperSpigot,__ you will need to
pass `--noconsole` at the very end of the command line and not use `-it`. For example,

    docker run -d -v /path/on/host:/data \
        -e TYPE=PAPER -e VERSION=1.9.4 \
        -p 25565:25565 -e EULA=TRUE --name mc itzg/minecraft-server --noconsole

If you are hosting your own copy of PaperSpigot you can override the download URL with:
* -e PAPER_DOWNLOAD_URL=<url>

You can install Bukkit plugins in two ways...

### Using the /data volume

This is the easiest way if you are using a persistent `/data` mount.

To do this, you will need to attach the container's `/data` directory
(see "Attaching data directory to host filesystem”).
Then, you can add plugins to the `/path/on/host/plugins` folder you chose. From the example above,
the `/path/on/host` folder contents look like:

```
/path/on/host
├── plugins
│   └── ... INSTALL PLUGINS HERE ...
├── ops.json
├── server.properties
├── whitelist.json
└── ...
```

If you add plugins while the container is running, you'll need to restart it to pick those
up:

    docker stop mc
    docker start mc

### Using separate mounts

This is the easiest way if you are using an ephemeral `/data` filesystem,
or downloading a world with the `WORLD` option.

There is one additional volume that can be mounted; `/plugins`.  
Any files in this filesystem will be copied over to the main
`/data/plugins` filesystem before starting Minecraft.

This works well if you want to have a common set of plugins in a separate
location, but still have multiple worlds with different server requirements
in either persistent volumes or a downloadable archive.

## Running a Server with a Feed-The-Beast (FTB) modpack

Enable this server mode by adding a `-e TYPE=FTB` to your command-line,
but note the following additional steps needed...

You need to specify a modpack to run, using the `FTB_SERVER_MOD` environment
variable. An FTB server modpack is available together with its respective
client modpack on https://www.feed-the-beast.com under "Additional Files."
Because of the interactive delayed download mechanism on that web site, you
must manually download the server modpack. Copy the modpack to the `/data`
directory (see "Attaching data directory to host filesystem”).

Now you can add a `-e FTB_SERVER_MOD=name_of_modpack.zip` to your command-line.

    $ docker run -d -v /path/on/host:/data -e TYPE=FTB \
        -e FTB_SERVER_MOD=FTBPresentsSkyfactory3Server_3.0.6.zip \
        -p 25565:25565 -e EULA=TRUE --name mc itzg/minecraft-server

Instead of explicitly downloading a modpack from the Feed the Beast site, you
can you set `FTB_SERVER_MOD` to the **server** URL of a modpack, such as

    $ docker run ... \
      -e TYPE=FTB \
      -e FTB_SERVER_MOD=https://www.feed-the-beast.com/projects/ftb-infinity-lite-1-10/files/2402889

### Using the /data volume

You must use a persistent `/data` mount for this type of server.

To do this, you will need to attach the container's `/data` directory
(see "Attaching data directory to host filesystem”).

If the modpack is updated and you want to run the new version on your
server, you stop and remove the container:

    docker stop mc
    docker rm mc

Do not erase anything from your /data directory (unless you know of
specific mods that have been removed from the modpack). Download the
updated FTB server modpack and copy it to `/data`. Start a new container
with `FTB_SERVER_MOD` specifying the updated modpack file.

    $ docker run -d -v /path/on/host:/data -e TYPE=FTB \
        -e FTB_SERVER_MOD=FTBPresentsSkyfactory3Server_3.0.7.zip \
        -p 25565:25565 -e EULA=TRUE --name mc itzg/minecraft-server

### Fixing "unable to launch forgemodloader"

If your server's modpack fails to load with an error [like this](https://support.feed-the-beast.com/t/cant-start-crashlanding-server-unable-to-launch-forgemodloader/6028/2):

    unable to launch forgemodloader

then you apply a workaround by adding this to the run invocation:

    -e FTB_LEGACYJAVAFIXER=true

## Running a SpongeVanilla server

Enable SpongeVanilla server mode by adding a `-e TYPE=SPONGEVANILLA` to your command-line.
By default the container will run the latest `STABLE` version.
If you want to run a specific version, you can add `-e SPONGEVERSION=1.11.2-6.1.0-BETA-19` to your command-line.

    docker run -d -v /path/on/host:/data -e TYPE=SPONGEVANILLA \
        -p 25565:25565 -e EULA=TRUE --name mc itzg/minecraft-server

You can also choose to use the `EXPERIMENTAL` branch.
Just change it with `SPONGEBRANCH`, such as:

    $ docker run -d -v /path/on/host:/data ... \
        -e TYPE=SPONGEVANILLA -e SPONGEBRANCH=EXPERIMENTAL ...

## Using Docker Compose

Rather than type the server options below, the port mappings above, etc
every time you want to create new Minecraft server, you can now use
[Docker Compose](https://docs.docker.com/compose/). Start with a
`docker-compose.yml` file like the following:

```
minecraft-server:
  ports:
    - "25565:25565"

  environment:
    EULA: "TRUE"

  image: itzg/minecraft-server

  container_name: mc

  tty: true
  stdin_open: true
  restart: always
```

and in the same directory as that file run

    docker-compose up -d

Now, go play...or adjust the  `environment` section to configure
this server instance.    

## Server configuration

### Server port

The server port can be set like:
    docker run -d -e SERVER_PORT=25565 ...

### Difficulty

The difficulty level (default: `easy`) can be set like:

    docker run -d -e DIFFICULTY=hard ...

Valid values are: `peaceful`, `easy`, `normal`, and `hard`, and an
error message will be output in the logs if it's not one of these
values.

### Whitelist Players

To whitelist players for your Minecraft server, pass the Minecraft usernames separated by commas via the `WHITELIST` environment variable, such as

	docker run -d -e WHITELIST=user1,user2 ...

If the `WHITELIST` environment variable is not used, any user can join your Minecraft server if it's publicly accessible.

### Op/Administrator Players

To add more "op" (aka adminstrator) users to your Minecraft server, pass the Minecraft usernames separated by commas via the `OPS` environment variable, such as

	docker run -d -e OPS=user1,user2 ...

### Server icon

A server icon can be configured using the `ICON` variable. The image will be automatically
downloaded, scaled, and converted from any other image format:

    docker run -d -e ICON=http://..../some/image.png ...

### Rcon

To use rcon use the `ENABLE_RCON` and `RCON_PASSORD` variables.
By default rcon port will be `25575` but can easily be changed with the `RCON_PORT` variable.

    docker run -d -e ENABLE_RCON=true -e RCON_PASSWORD=testing

### Query

Enabling this will enable the gamespy query protocol.
By default the query port will be `25565` (UDP) but can easily be changed with the `QUERY_PORT` variable.

    docker run -d -e ENABLE_QUERY=true


### Max players

By default max players is 20, you can increase this with the `MAX_PLAYERS` variable.

    docker run -d -e MAX_PLAYERS=50


### Max world size

This sets the maximum possible size in blocks, expressed as a radius, that the world border can obtain.

    docker run -d -e MAX_WORLD_SIZE=10000   

### Allow Nether

Allows players to travel to the Nether.

    docker run -d -e ALLOW_NETHER=true

### Announce Player Achievements

Allows server to announce when a player gets an achievement.

    docker run -d -e ANNOUNCE_PLAYER_ACHIEVEMENTS=true   

### Enable  Command Block

Enables command blocks

     docker run -d -e ENABLE_COMMAND_BLOCK=true

### Force Gamemode

Force players to join in the default game mode.

* false - Players will join in the gamemode they left in.
* true - Players will always join in the default gamemode.

    `docker run -d -e FORCE_GAMEMODE=false`

### Generate Structures

Defines whether structures (such as villages) will be generated.

* false - Structures will not be generated in new chunks.
* true - Structures will be generated in new chunks.

    `docker run -d -e GENERATE_STRUCTURES=true`

### Hardcore

If set to true, players will be set to spectator mode if they die.

    docker run -d -e HARDCORE=false

### Snooper

If set to false, the server will not send data to snoop.minecraft.net server.

    docker run -d -e SNOOPER_ENABLED=false

### Max Build Height

The maximum height in which building is allowed.
Terrain may still naturally generate above a low height limit.

    docker run -d -e MAX_BUILD_HEIGHT=256

### Max Tick Time

The maximum number of milliseconds a single tick may take before the server watchdog stops the server with the message, A single server tick took 60.00 seconds (should be max 0.05); Considering it to be crashed, server will forcibly shutdown. Once this criteria is met, it calls System.exit(1).
Setting this to -1 will disable watchdog entirely

    docker run -d -e MAX_TICK_TIME=60000

### Spawn Animals

Determines if animals will be able to spawn.

    docker run -d -e SPAWN_ANIMALS=true

### Spawn Monsters

Determines if monsters will be spawned.

    docker run -d -e SPAWN_MONSTERS=true

### Spawn NPCs

Determines if villagers will be spawned.

    docker run -d -e SPAWN_NPCS=true

### View Distance
Sets the amount of world data the server sends the client, measured in chunks in each direction of the player (radius, not diameter).
It determines the server-side viewing distance.

    docker run -d -e VIEW_DISTANCE=10

### Level Seed

If you want to create the Minecraft level with a specific seed, use `SEED`, such as

    docker run -d -e SEED=1785852800490497919 ...

### Game Mode

By default, Minecraft servers are configured to run in Survival mode. You can
change the mode using `MODE` where you can either provide the [standard
numerical values](http://minecraft.gamepedia.com/Game_mode#Game_modes) or the
shortcut values:

* creative
* survival
* adventure
* spectator (only for Minecraft 1.8 or later)

For example:

    docker run -d -e MODE=creative ...

### Message of the Day

The message of the day, shown below each server entry in the UI, can be changed with the `MOTD` environment variable, such as

    docker run -d -e 'MOTD=My Server' ...

If you leave it off, a default is computed from the server type and version, such as

    A Paper Minecraft Server powered by Docker

when `TYPE` is `PAPER`. That way you can easily differentiate between several servers you may have started.

_The example shows how to specify a server message of the day that contains spaces by putting quotes
around the whole thing._

### PVP Mode

By default, servers are created with player-vs-player (PVP) mode enabled. You can disable this with the `PVP`
environment variable set to `false`, such as

    docker run -d -e PVP=false ...

### Level Type and Generator Settings

By default, a standard world is generated with hills, valleys, water, etc. A different level type can
be configured by setting `LEVEL_TYPE` to

* DEFAULT
* FLAT
* LARGEBIOMES
* AMPLIFIED
* CUSTOMIZED
* BUFFET

Descriptions are available at the [gamepedia](http://minecraft.gamepedia.com/Server.properties).

When using a level type of `FLAT`, `CUSTOMIZED`, and `BUFFET`, you can further configure the world generator
by passing [custom generator settings](http://minecraft.gamepedia.com/Superflat).
**Since generator settings usually have ;'s in them, surround the -e value with a single quote, like below.**

For example (just the `-e` bits):

    -e LEVEL_TYPE=flat -e 'GENERATOR_SETTINGS=3;minecraft:bedrock,3*minecraft:stone,52*minecraft:sandstone;2;'

### World Save Name

You can either switch between world saves or run multiple containers with different saves by using the `LEVEL` option,
where the default is "world":

    docker run -d -e LEVEL=bonus ...

**NOTE:** if running multiple containers be sure to either specify a different `-v` host directory for each
`LEVEL` in use or don't use `-v` and the container's filesystem will keep things encapsulated.

### Downloadable world

Instead of mounting the `/data` volume, you can instead specify the URL of
a ZIP file containing an archived world.  This will be downloaded, and
unpacked in the `/data` directory; if it does not contain a subdirectory
called `world/` then it will be searched for a file `level.dat` and the
containing subdirectory renamed to `world`.  This means that most of the
archived Minecraft worlds downloadable from the Internet will already be in
the correct format.

The ZIP file may also contain a `server.properties` file and `modules`
directory, if required.

    docker run -d -e WORLD=http://www.example.com/worlds/MySave.zip ...

**NOTE:** Unless you also mount `/data` as an external volume, this world
will be deleted when the container is deleted.

**NOTE:** This URL must be accessible from inside the container.  Therefore,
you should use an IP address or a globally resolveable FQDN, or else the
name of a linked container.

### Downloadable mod/plugin pack for Forge, Bukkit, and Spigot Servers

Like the `WORLD` option above, you can specify the URL of a "mod pack"
to download and install into `mods` for Forge or `plugins` for Bukkit/Spigot.
To use this option pass the environment variable `MODPACK`, such as

    docker run -d -e MODPACK=http://www.example.com/mods/modpack.zip ...

**NOTE:** The referenced URL must be a zip file with one or more jar files at the
top level of the zip archive. Make sure the jars are compatible with the
particular `TYPE` of server you are running.

### Remove old mods/plugins

When the option above is specified (`MODPACK`) you can also instruct script to
delete old mods/plugins prior to installing new ones. This behaviour is desirable
in case you want to upgrade mods/plugins from downloaded zip file.
To use this option pass the environment variable `REMOVE_OLD_MODS="TRUE"`, such as

    docker run -d -e REMOVE_OLD_MODS="TRUE" -e MODPACK=http://www.example.com/mods/modpack.zip ...

**NOTE:** This option will be taken into account only when option `MODPACK` is also used.

**WARNING:** All content of the `mods` or `plugins` directory will be deleted
before unpacking new content from the zip file.

### Online mode

By default, server checks connecting players against Minecraft's account database. If you want to create an offline server or your server is not connected to the internet, you can disable the server to try connecting to minecraft.net to authenticate players with environment variable `ONLINE_MODE`, like this

    docker run -d -e ONLINE_MODE=FALSE ...

### Allow flight

Allows users to use flight on your server while in Survival mode, if they have a mod that provides flight installed.

    -e ALLOW_FLIGHT=TRUE|FALSE

## Miscellaneous Options

### Running as alternate user/group ID

By default, the container will switch to user ID 1000 and group ID 1000;
however, you can override those values by setting `UID` and `GID`, respectively.
The container will also skip user switching if the `--user`/`-u` argument
is passed to `docker run`.

### Memory Limit

By default, the image declares a Java initial and maximum memory limit of 1 GB. There are several
ways to adjust the memory settings:

* `MEMORY`, "1G" by default, can be used to adjust both initial (`Xms`) and max (`Xmx`)
  memory settings of the JVM
* `INIT_MEMORY`, independently sets the initial heap size
* `MAX_MEMORY`, independently sets the max heap size

The values of all three are passed directly to the JVM and support format/units as
`<size>[g|G|m|M|k|K]`.

### JVM Options

General JVM options can be passed to the Minecraft Server invocation by passing a `JVM_OPTS`
environment variable. Options like `-X` that need to proceed general JVM options can be passed
via a `JVM_XX_OPTS` environment variable.

### HTTP Proxy

You may configure the use of an HTTP/HTTPS proxy by passing the proxy's URL via the `PROXY`
environment variable. In [the example compose file](docker-compose-proxied.yml) it references
a companion squid proxy by setting the equivalent of

    -e PROXY=proxy:3128
