# Home DevOps Pipeline: A junior engineer’s tale (1/4)

Contents: (1), 2, 3, 4


![](https://cdn-images-1.medium.com/max/3840/1*bCBDSt_m0q5Cgirh4SjaaQ.png)


I’ve been working as a software engineer for just over a year whilst simultaneously working on many of my own side projects such as [T3chFlicks](https://www.youtube.com/channel/UC0eSD-tdiJMI5GQTkMmZ-6w?view_as=subscriber) (an edutainment channel). During this period, I have picked up many different technologies & skills, however one role I managed to stay away from until the past couple of months is DevOps.

In this series of articles, I will explain how I applied this new-found knowledge by building my own home development environment using a couple of Raspberry Pis.

This environment allows me to do things like:

* Host my own reliable Git Repo ([Gitea](http://gitea.io))

* Effortlessly work with large media files using git ([LFS](https://git-lfs.github.com))

* Access my Git Repo remotely with SSL ([Traefik](https://git-lfs.github.com))

* Work with [docker](https://www.docker.com) containers

* Build, test and deploy with a git push ([Drone](https://drone.io))

* Monitor all parts of the system ([Portainer](https://www.portainer.io))

* Deploy builds to groups of devices locally and on the internet ([Ansible](https://www.ansible.com))

I am still inexperienced with this tech and am more big ideas than skill, but I’ve come a long way since I first began and I want to share my journey and process. **I do this to learn**.

The code referenced in these articles can be found [here](https://github.com/sk-t3ch/home-repo).

## Home Repo

To follow the rest of these blog posts, you must have a basic knowledge of Docker and Git, so let’s take a brief detour…

### Docker

My introduction to DevOps was after I built a service which was going to be deployed on an AWS ECS ([Elastic Container Service](https://aws.amazon.com/ecs/)) cluster. This service needed to be “dockerised”. This means it needed to be created within a reliably recreatable environment known as a container.

Docker is the containerisation software which enables us to do the above by building environments with a YAML template known as a `Dockerfile`. We can build our environments on top of base images such as Ubuntu e.g.

    **FROM** ubuntu:18.04
    **RUN** apk update

and you can run it like this:

    `docker build -t myFirstDockerContainer . && docker run myFirstDockerContainer`

The Docker CLI enables you to control containers and push and pull images from registries such as [DockerHub](https://hub.docker.com). However, you can use it to control a lot more, including networks, volumes, and even collections of containers working together as part of a swarm.

In my opinion, Docker is great. The main reason for this is that I spend less time debugging… I hate debugging. Software engineering to me is all about creating and I shouldn’t spend my time being a software mechanic.



Go ahead and explore [DockerHub](https://hub.docker.com). If there isn’t an image for your favourite software, why not make it and publish it (preferably using alpine — the smallest base image).

### Docker-Compose

After you’ve explored Docker, you’ll soon want to connect your separate services. For example, if you want to run a web app with a database. To set this up in a single file there exists [docker-compose](https://docs.docker.com/compose/).

    version: "3"

    networks:
      someNetwork:

    volumes:
      someVolume:

    services:
      webapp:
        image: someWebAppImage

    database:
        image: someDatabaseImage

Docker-compose is elegant, simple and a big upgrade to my developing practice.

![Photo by [chuttersnap](https://unsplash.com/@chuttersnap?utm_source=medium&utm_medium=referral) on [Unsplash](https://unsplash.com?utm_source=medium&utm_medium=referral)](https://cdn-images-1.medium.com/max/7982/0*AKkE9RlpAu233-IT)*

Photo by [chuttersnap](https://unsplash.com/@chuttersnap?utm_source=medium&utm_medium=referral) on [Unsplash](https://unsplash.com?utm_source=medium&utm_medium=referral)*

### Git

For me, git is a must, even when you are working on your own projects at home. It’s just so damn useful. I can’t tell you how many times I have gone through git log to find that magical piece of code that actually works. Hammer! Hammer! Hammer! (one day i will get good enough at TDD).

![Photo by [Sean Stratton](https://unsplash.com/@seanstratton?utm_source=medium&utm_medium=referral) on [Unsplash](https://unsplash.com?utm_source=medium&utm_medium=referral)](https://cdn-images-1.medium.com/max/10944/0*lN-f7HFa7bDae2zI)*

Photo by [Sean Stratton](https://unsplash.com/@seanstratton?utm_source=medium&utm_medium=referral) on [Unsplash](https://unsplash.com?utm_source=medium&utm_medium=referral)*

The way you fell in love with git is probably by putting your code online onto a website such as Github and collaborating with others on it. You probably then went on to think that what you made was so amazing that you thought someone else might come along and steal it and you’d never get to be the next Facebook. So you decided to make it a private repository.

Gitlab is an open source alternative to Github. It’s also pretty great and offers loads of awesome features for free. An alternative to a managed service is to host your own git repository server, such as the one [Gitlab](https://docs.gitlab.com/ee/install/README.html) provide (the software requires 4GB of RAM for 1000 concurrent users), which the Raspberry Pi 4 contains, but I’d rather run smaller and separate services. Instead, I opted for [Gitea](http://gitea.io).

Right. Slight detour over, now onto the proper stuff — check out the second article in this series [here](https://medium.com/@t3chflicks/home-devops-pipeline-a-junior-engineers-tale-2-4-7be3e3c292c).

*Contents: ([1](https://medium.com/@t3chflicks/home-devops-pipeline-a-junior-engineers-tale-1-4-336ed07a6ec0)), [2](https://medium.com/@t3chflicks/home-devops-pipeline-a-junior-engineers-tale-2-4-7be3e3c292c), [3](https://medium.com/@t3chflicks/home-devops-pipeline-a-junior-engineers-tale-3-4-5f61c5245934), [4](https://medium.com/@t3chflicks/home-devops-pipeline-a-junior-engineers-tale-4-4-5db7c1610e3e)*

## Thanks for reading

I hope you have enjoyed this article. If you like the style, check out [T3chFlicks.org](https://t3chflicks.org/Projects/home-devops-pipeline) for more tech-focused educational content ([YouTube](https://www.youtube.com/channel/UC0eSD-tdiJMI5GQTkMmZ-6w), [Instagram](https://www.instagram.com/t3chflicks/), [Facebook](https://www.facebook.com/t3chflicks), [Twitter](https://twitter.com/t3chflicks)).