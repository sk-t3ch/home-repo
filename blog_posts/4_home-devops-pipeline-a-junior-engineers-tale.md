# Home DevOps Pipeline: A junior engineer’s tale (4/4)

Contents: 1, 2, 3, (4)

In this series of articles, I will explain how I built my own home development environment using a couple of Raspberry Pis and a lot of software. The code referenced in these articles can be found [here](https://github.com/sk-t3ch/home-repo). In this article I will cover the monitoring of my pipeline, as well as discuss a few gotchas.

## Monitoring

My initial thought for monitoring uptime of my development pipeline was [UpTimeRobot](https://uptimerobot.com), a free service which pings periodically and if failures alerts via email.

![Example email](https://cdn-images-1.medium.com/max/2800/1*P3Fo0Q2f0Lj6tdMc2jlp-g.png)*

Example email*

However, being able to monitor and repair your development pipeline in a web app is just great and [portainer](https://www.portainer.io) have really aced this one.

This application is great and many more features than I want to explain. But it allows for inspection of container logs, ssh into containers, and even deployment of new images — controlling and monitoring multiple hosts.

![Portainer running](https://cdn-images-1.medium.com/max/6668/1*k-xqPs9IjWgKjlfXLq1pxQ.png)*

Portainer running*

To get portainer running I added this to my code docker-compose template:

    portainer:
      image: portainer/portainer
      command: -H unix:///var/run/docker.sock
      restart: always
      networks:
      - homereponet
      ports:
      - 9000:9000
      - 8000:9000
      volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /mnt/hdd/portainer:/data
      labels:
      - "traefik.enable=true"
      - traefik.backend=portainer
      - traefik.portainer.frontend.rule=Host:portainer.<domain>
      - traefik.docker.network=homereponet
      - traefik.portainer.port=9000

### The End

This is where this story ends for now. I think that this is a great starter set up for anyone looking to have a industry style development pipeline. As a recap this final setup is:

[Gitea](https://gitea.io/) Repository for storing code, using [git LFS](https://git-lfs.github.com) for large media files. [Drone CI](https://docs.drone.io/) to build containers, store them in [Docker Registry](https://docs.docker.com/registry/deploying/), and deploy using an [Ansible](http://plugins.drone.io/drone-plugins/drone-ansible/) plugin to a local set of machines as well as [cloudformation plugin ](https://hub.docker.com/r/t3chflicks/aws-cfn)for AWS deployment. [Portainer](https://www.portainer.io/) for monitoring and control over containers in a UI. [Traefik](https://docs.traefik.io/) for a reverse proxy with [let’s encrypt](https://letsencrypt.org/docs/) free https certificate on a free [duckdns](https://www.duckdns.org/) domain. All storage is done on a hard drive and there are periodic backups to [AWS s3](https://aws.amazon.com/s3/).

![](https://cdn-images-1.medium.com/max/3840/0*GvyXyJ4Z3xJ4vIcN.png)

I hope you have enjoyed this series of articles. I also make many more projects including other hardware, 3D printing, smart-home applications, and machine learning in video form over at [T3chFlicks](https://www.youtube.com/channel/UC0eSD-tdiJMI5GQTkMmZ-6w?view_as=subscriber) — check us out.

### Appendix

Code: [https://github.com/sk-t3ch/home-repo](https://github.com/sk-t3ch/home-repo)

Random Things I learned along the way:

* Docker-compose has to be controlled inside the same directory as it was started

* policy creation for aws s3 is needed because you only want the pi and the root aws user to be able to access the bucket also add encryption

* need to look more into backup techniques

* s3 backups to glacier after 10 days meaning storage cost stays low

* Raspberry Pi 4 has two usb 3.0 ports and two 2.0 ones.

* Using an EXFAT drive instead of HFS+ resulted in failures for the Postgres container

* ssh on Gitea cannot use port 22 due to permissions problem that i am yet to solve. to work around this i changed the router forward port to allow for an ssh port in the accepted range (1065+)

*Contents: [1](https://medium.com/@t3chflicks/home-devops-pipeline-a-junior-engineers-tale-1-4-336ed07a6ec0), [2](https://medium.com/@t3chflicks/home-devops-pipeline-a-junior-engineers-tale-2-4-7be3e3c292c), [3](https://medium.com/@t3chflicks/home-devops-pipeline-a-junior-engineers-tale-3-4-5f61c5245934), ([4](https://medium.com/@t3chflicks/home-devops-pipeline-a-junior-engineers-tale-4-4-5db7c1610e3e))*

## Thanks for reading

I hope you have enjoyed this article. If you like the style, check out [T3chFlicks.org](https://t3chflicks.org/Projects/home-devops-pipeline) for more tech-focused educational content ([YouTube](https://www.youtube.com/channel/UC0eSD-tdiJMI5GQTkMmZ-6w), [Instagram](https://www.instagram.com/t3chflicks/), [Facebook](https://www.facebook.com/t3chflicks), [Twitter](https://twitter.com/t3chflicks)).

