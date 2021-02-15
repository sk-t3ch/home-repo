# Home DevOps Pipeline: A junior engineer’s tale (2/4)

Contents: 1, (2), 3, 4

In this series of articles, I will explain how I built my own home development environment using a couple of Raspberry Pis and a lot of software. In this article I will cover the development / CI part of the pipeline, starting with the Git Repository. The code referenced in these articles can be found [here](https://github.com/sk-t3ch/home-repo).

### Gitea

![](https://cdn-images-1.medium.com/max/2400/1*JiRexLOf79xRWQXBz62Pog.png)

[Gitea](https://gitea.io/) is a git repository application that can be installed on a machine. This means that the storage of the repositories is done on the machine itself as standard. However, as mistakes **do** happen, I have upgraded this to an external hard drive with routine backups to AWS S3.

There are major benefits to hosting your own repo at home. If like me, you often edit videos or batches of large images, then downloading stuff from the internet with cheap WiFi is slow (10mb/s) and uploading is just plain daft (500kb/s). Local network storage, however, allows much higher transfer speeds (to be measured).

You may be thinking large files and git doesn’t make any sense. You are absolutely right. Any edits involving large binaries cause your git repo to explode in size. Enter stage left to solve all git/large file problems: the [Git LFS](https://git-lfs.github.com) (Large File Storage) — a git plugin that stores specified files in a sensible way.

*“Git Large File Storage (LFS) replaces large files such as audio samples, videos, datasets, and graphics with text pointers inside Git, while storing the file contents on a remote server like GitHub.com or GitHub Enterprise.”*

Git LFS means I have all the benefits of using the beloved git with my necessary large files and enjoy those high speed transfers of local network! Hooray!

![Photo by [Alexander Sinn](https://unsplash.com/@swimstaralex?utm_source=medium&utm_medium=referral) on [Unsplash](https://unsplash.com?utm_source=medium&utm_medium=referral)](https://cdn-images-1.medium.com/max/12048/0*7GalwN7QnHbmcq5Q)*

Photo by [Alexander Sinn](https://unsplash.com/@swimstaralex?utm_source=medium&utm_medium=referral) on [Unsplash](https://unsplash.com?utm_source=medium&utm_medium=referral)*

I’ve introduced Gitea’s use case without giving you much of an explanation of what it is and offers. For that, you should take a look at [this](https://docs.gitea.io/en-us/comparison/) comparison between Gitea and other Git repository providers.

To create your own gitea application, use `docker-compose` to run this template which has a gitea and postgres image (production ready db):

    version: “2”

    networks:
      appnet:
        external: false

    volumes:
      gitea-app:
      gitea-db:

    services:

    gitea-app:
        image: webhippie/gitea
        env_file:
          - gitea.env
        container_name: gitea-app
        restart: always
        networks
          - appnet
        volumes:
          - ./volumes/gitea_data:/data
          - ./custom:/data/gitea
        ports:
          - "222:22"
          - "3000:3000"
         depends_on:
          - gitea-db

    gitea-db:
        image: postgres:alpine
        container_name: gitea-db
        ports:
          - 5432:5432
        restart: always
        volumes:
          - ./volumes/gitea_db:/var/lib/postgresql/data
        environment:
          - POSTGRES_USER=gitea
          - POSTGRES_PASSWORD=gitea
          - POSTGRES_DB=gite
        networks:
          - appnet

In this file, the gitea service references a file `gitea.env`. This is the configuration file for gitea, which allows us to set up this home repo in such a way that we don’t need to any set up inside the application itself — meaning we can run straight from a backup.

After running `docker-compose up` , you should be able to access this on your local network under `raspberrypi.local:3000` and use it. Happy days.

![Photo by [Harrison Broadbent](https://unsplash.com/@hbtography?utm_source=medium&utm_medium=referral) on [Unsplash](https://unsplash.com?utm_source=medium&utm_medium=referral)](https://cdn-images-1.medium.com/max/9184/0*5MOqu-ArI9QekHos)*

Photo by [Harrison Broadbent](https://unsplash.com/@hbtography?utm_source=medium&utm_medium=referral) on [Unsplash](https://unsplash.com?utm_source=medium&utm_medium=referral)*

### External Hard Drive

With gitea up and running, I want to add a larger storage device than the Micro SD card. To do so, we need only mount a hard drive like this:

    sudo mount /dev/sda1 /media/hdd

Once mounted, you can reference the location `/media/hdd` just like you would any other folder. Now we want to be able to routinely backup the contents of this drive. Handily, someone has made a docker image which does just that [https://github.com/istepanov/docker-backup-to-s3](https://github.com/istepanov/docker-backup-to-s3). However, as expected this image isn’t for ARM architecture so I rebuilt the image using a Raspbian base on my Pi.

Adding this to our current `docker-compose.yml` like:

    services:
      backup:
        image: t3chflicks/backuper
        environment:
          - ACCESS_KEY=
          - SECRET_KEY=
          - S3_PATH=
          - CRON_SCHEDULE=0 12 * * *
        volumes:
          - /media/hd:/data:ro
        container_name: backup
        restart: always

    gitea-app:
        image: webhippie/gitea
        env_file:
          - gitea.env
        container_name: gitea-app
        restart: always
        networks
          - appnet
        volumes:
          - /media/hd/gitea_data:/data
        ports:
          - "222:22"
          - "3000:3000"
        depends_on:
          - gitea-db

After enabling Git LFS in your Gitea Config, we can also install the git plugin on our repo as simple as `git lfs install` and subsequently tagging files like this: `git lfs track "*.mp4"`.

Now you can use your git repo to work with large media files and that is awesome.

### Traefik

Having a home repository is great. But, since I am not a complete hermit and want to collaborate with others, I then went on to add external access to my repo. I did this using [Traefik](https://traefik.io/), the reverse proxy which gives automatic SSL encryption with certificates from [Let’s Encrypt](http://letsencrypt.org) and I used a free domain from [duckdns](https://www.duckdns.org/).

I found the Traefik docs a little bit confusing but it turned out to be super simple to add into the current docker-compose.

    version: “2”
    networks:
      appnet:
        external: false
      homereponet:
        external: true

    volumes:
      gitea-app:
      gitea-db:
      traefik:

    services:
      gitea-app:
        image: webhippie/gitea
        env_file:
          - gitea.env
        container_name: gitea-app
        restart: always
        networks
          - appnet
        volumes:
          - /media/hdd/gitea_data:/data
        ports:
          - "222:22"
          - "3000:3000"
        depends_on:
          - gitea-db
      depends_on:
        - gitea-db
        - traefik
      labels:
        - "traefik.enable=true"
        - traefik.backend=gitea-app
        - traefik.git.frontend.rule=Host:git.<your_domain>
        - traefik.docker.network=homereponet
        - traefik.git.port=3000

    gitea-db:
        image: postgres:alpine
        container_name: gitea-db
        ports:
          - 5432:5432
        restart: always
        volumes:
          - /media/hdd/gitea_db:/var/lib/postgresql/data
        environment:
          - POSTGRES_USER=gitea
          - POSTGRES_PASSWORD=gitea
          - POSTGRES_DB=gitea
        networks:
         - appnet
      
      traefik:
        image: traefik:1.7-alpine
        container_name: “traefik”
        ports:
          - “80:80”
          - “443:443”
        networks:
          - homereponet
        volumes:
          - /var/run/docker.sock:/var/run/docker.sock
          - ./traefik/traefik.toml:/traefik.toml 
          - ./traefik/acme:/etc/traefik/acme
        restart: always

And this requires some extra steps of creating the acme folder and editing permissions as well as adding this traefik.toml file

    debug = false
    logLevel = “ERROR”
    defaultEntryPoints = [“https”,”http”]

    [entryPoints]

    [entryPoints.http]
    address = “:80”
    [entryPoints.http.redirect]
    entryPoint = “https”
    [entryPoints.https]
    address = “:443”
    [entryPoints.https.tls]

    [retry]

    [docker]
    endpoint = “unix:///var/run/docker.sock”
    domain = “<your domain>”
    watch = true
    exposedByDefault = false

    [acme]
    email = “<your email>”
    caServer = “https://acme-v02.api.letsencrypt.org/directory"
    storage = “acme.json”
    entryPoint = “https”
    onHostRule = true

    [acme.httpChallenge]
    entryPoint = “http”

But now as long as you have exposed port 443 and forwarded the traffic to your Pi, you should be able to access your home repository via your duckdns address and it will encrypted on *https*. How great!

![Alt Tea Theme (Dark Mode)](https://cdn-images-1.medium.com/max/6720/1*TPubvAkPg-kKi150QLzkGg.png)*

Alt Tea Theme (Dark Mode)*

### Drone

We now have our own private Git repo setup in a Docker environment with Postgres, Git LFS, external hard drive storage and external SSL encrypted access. This is great: we can work happily on our project, knowing that we can easily work with large files and work with git from anywhere.

However, this isn’t exactly DevOps. Using git provides you with the continuous integration of your code via pull requests etc., but it does not provide continuous delivery. For that, we look to a software called [Drone](https://drone.io/).

![Photo by [Iewek Gnos](https://unsplash.com/@imkirk?utm_source=medium&utm_medium=referral) on [Unsplash](https://unsplash.com?utm_source=medium&utm_medium=referral)](https://cdn-images-1.medium.com/max/8064/0*hPTZq_bDHmlLIBLr)*

Photo by [Iewek Gnos](https://unsplash.com/@imkirk?utm_source=medium&utm_medium=referral) on [Unsplash](https://unsplash.com?utm_source=medium&utm_medium=referral)*

We’ll be using Drone to manage pipelines in which we build Docker containers, test and deploy to machines.

Like all the other services discussed so far, Drone has an [image](https://hub.docker.com/r/drone/drone) on DockerHub. To add this to our current setup, we need to add the following to our *docker-compose* file:

    services:
      drone:
        image: drone/drone:1-linux-arm
        container_name: drone
        volumes:
          - /media/hdd/drone:/var/lib/drone/
        restart: always
        depends_on:
          - gitea-app
        environment:
          - DRONE_OPEN=true
          - DRONE_GITEA_CLIENT_ID=<gitea_auth_id>
          - DRONE_GITEA_CLIENT_SECRET=<gitea_auth_secret>
          - DRONE_GITEA_SERVER=http://git.<your_domain>
          - DRONE_SERVER_HOST=drone.<your_domain>
          - DRONE_SERVER_PROTO=https
          - DRONE_TLS_AUTOCERT=false
          - DRONE_RPC_SECRET=<drone_runner_secret>
          - DRONE_AGENTS_ENABLED=true
        networks:
          - homereponet
          - appnet
        labels:
          - “traefik.enable=true”
          - traefik.backend=drone
          - traefik.drone.frontend.rule=Host:drone.<your_domain>
          - traefik.drone.port=80
          - traefik.docker.network=homereponet

    runner:
        container_name: runner
        image: drone/drone-runner-docker:1
        volumes:
          - /var/run/docker.sock:/var/run/docker.sock
        depends_on:
          - drone
        environment:
          - DRONE_RPC_HOST=drone.<your_domain>
          - DRONE_RPC_PROTO=https
          - DRONE_RPC_SECRET=<drone_runner_secret>
        restart: always
        ports:
          - “3000:3000”
        networks:
          - appnet
          - homereponet

Now, when starting up the system you and visiting `https://drone.<domain> `you will get an error when trying to login. This is because you need to have Gitea running and create the OAuth application first and then rebuild your containers, setting `DRONE_GITEA_CLIENT_SECRET` to the new value — this is described [here](https://docs.drone.io/installation/providers/gitea/).

You will now be able to login to Drone using your Gitea credentials. Following this, you should sync the repositories of your Gitea by clicking the big button. The next thing you’ll want to try is doing a build, for this you should add a `.drone.yml` file to your repo and on push, it should trigger a build.

![](https://cdn-images-1.medium.com/max/3200/1*-QEZBWRVw9FbsdTsuetzIQ.png)

Each step is a build in an isolated environment and executed on the Drone-runner. Drone-runners build for one architecture so we will only build Raspberry Pi (arm v7) images on a Pi runner but for x86 builds we will need to deploy an EC2 on AWS (more about that later). My example drone file looks like this:

    kind: pipeline
    name: commitPipeline

    trigger:
      event:
        - push

    platform:
      os: linux
      arch: arm

    steps:
      - name: buildsomething
        image: python:alpine
        commands:
          - echo ‘hello world’

Voila, you are now the proud owner of a home repo! We’ll ignore the fact that it probably still can’t do as much as Gitlab out of the box, but it is yours (woo, capitalism!).

### Registry

DockerHub is great, just like Github is great. This is because they provide a place for people to share their work. However, just as the argument for the private repo is not wanting to share and for fast local speed, the same applies to Docker registries.

We will be creating our own place to store the images we’ve made using Docker’s own registry image. To add this into our existing Docker-compose file, we just need to add this extra service:

    registry:
      image: registry:2
      container_name: registry
      restart: always
      networks:
        - homerepone
      volumes:
        - ./volumes/registry:/var/lib/registr
        - ./auth:/auth
      labels:
        - “traefik.enable=true”
        - traefik.registry.frontend.rule=Host:registry.<your_domain>
        - traefik.backend=registry
        - traefik.docker.network=homereponet
        - traefik.registry.port=5000
      environment:
        - REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/data
        - REGISTRY_AUTH=htpasswd
        - REGISTRY_AUTH_HTPASSWD_REALM=Registry
        - REGISTRY_AUTH_HTPASSWD_PATH=/auth/registry.password

This references an `auth/registry.password` file which we create using apache2-utils bcrypt hash password like described [here](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-private-docker-registry-on-ubuntu-18-04).

Running our new `docker-compose.yml` means you can access the registry by logging in using the docker cli using `docker login [https://registry.<](https://registry.homerepo4.duckdns.org)your_domain>` .

We have now covered the development part of the pipeline and in the next article in this series we will cover the deployment methods. Check it out [here](https://medium.com/@t3chflicks/home-devops-pipeline-a-junior-engineers-tale-3-4-5f61c5245934).

*Contents: [1](https://medium.com/@t3chflicks/home-devops-pipeline-a-junior-engineers-tale-1-4-336ed07a6ec0), ([2](https://medium.com/@t3chflicks/home-devops-pipeline-a-junior-engineers-tale-2-4-7be3e3c292c)), [3](https://medium.com/@t3chflicks/home-devops-pipeline-a-junior-engineers-tale-3-4-5f61c5245934), [4](https://medium.com/@t3chflicks/home-devops-pipeline-a-junior-engineers-tale-4-4-5db7c1610e3e)*

## Thanks for reading

I hope you have enjoyed this article. If you like the style, check out [T3chFlicks.org](https://t3chflicks.org/Projects/home-devops-pipeline) for more tech-focused educational content ([YouTube](https://www.youtube.com/channel/UC0eSD-tdiJMI5GQTkMmZ-6w), [Instagram](https://www.instagram.com/t3chflicks/), [Facebook](https://www.facebook.com/t3chflicks), [Twitter](https://twitter.com/t3chflicks)).

