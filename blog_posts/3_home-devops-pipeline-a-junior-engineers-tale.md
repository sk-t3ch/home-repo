# Home DevOps Pipeline: A junior engineer’s tale (3/4)

Contents: 1, 2, (3), 4

In this series of articles, I will explain how I built my own home development environment using a couple of Raspberry Pis and a lot of software. The code referenced in these articles can be found [here](https://github.com/sk-t3ch/home-repo). In this article I will cover the deployment section of the pipeline.

## Deployment

### Ansible

Another great thing about Drone is the [plugins available](http://plugins.drone.io) — we will use the [Ansible](https://docs.ansible.com/ansible/latest/user_guide/basic_concepts.html) plugin as a tool to run ssh commands on multiple machines. We will as well make use of [Drone secrets](https://docs.drone.io/secret/repository/) as a method of securely deploying certain configuration values.

The general methods of deployment I have seen usually consist of publishing to AWS and then magic happens using cloud formation templating and your stack is created.

However, we want to keep the home in home repo. To do this, we want to deploy to specific machines on our local network. For me, this is a load of other Raspberry Pis which do many things, from control my 3D printer, to work as a network of CCTV cameras.

To do this we will be using Ansible like this:

    kind: pipeline
    name: commitPipeline

    trigger:
      event:
         - push

    platform:
      os: linux
      arch: arm

    steps:
      - name: trigger-rebuild-of-image
        image: plugins/ansible:1
        environment:
          repo_username:
            from_secret: repo_username
          repo_password:
            from_secret: repo_password
        settings:
          private_key:
            from_secret: ansible_private_key
          playbook: ansible/playbook.yml
          inventory: ansible/inventory.yml

The actions Ansible performs are found in the `playbook.yml` and the machines we want to perform on are described in `inventory.yml` :

    - hosts: cameras

    tasks:

    - name: .ssh directory
      file:
        path: ~/.ssh
        owner: pi
        group: pi
        state: directory

    - name: put key in
      copy:
        content: "{{ lookup('env','ansible_private_key') }}"
        dest: ~/.ssh/deploy_key
        owner: pi
        group: pi
        mode: 0600
        become: pi

    - name: clone the repo
      git:  
        repo: ssh://git@git.<domain>/<username>/cctv.git
        dest: /home/pi/cctv
        key_file: ~/.ssh/deploy_key
        accept_hostkey: yes
        force: yes

    - name: Rebuild docker image
       shell:
       cmd: docker-compose up --remove-orphans --force-recreate --build -d
      chdir: /home/pi/cctv

    - name: remove private key
       shell:
       cmd: rm ~/.ssh/deploy_key

;

    all:
      hosts:
        drone.<domain>:
      children:
        cameras:
          hosts:
            192.168.0.41:
            192.168.0.42:
          vars:
            ansible_ssh_user: pi

Thanks to ansible my deployment process for updates to my CCTV cameras has been greatly simplified.



### Deploying to AWS

Deploying at home is fun and great n all, but the training wheels must come off. Developing in the real world involves the cloud, and at the company I work for, this means AWS.

Deploying your service to an AWS EC2 machine should have a testing step too, however the most common architecture (x86) is very different to the arm architecture on Raspberry Pi. We shouldn’t test our builds using an arm machine if they will be deployed to an x86 machine. We must deploy an x86 Drone runner.

However, the plot twists again and in order to deploy a drone x86 runner using our environment, we need to use the Drone/cloud formation image which is only built for x86, not arm. But we can rebuild it ourselves like I have demonstrated in my [code](https://github.com/sk-t3ch/home-repo). Like a good boy, I published the [image](https://hub.docker.com/r/t3chflicks/aws-cfn) on dockerhub for others to use, too.

![Photo by [Andreas Wagner](https://unsplash.com/@waguluz_?utm_source=medium&utm_medium=referral) on [Unsplash](https://unsplash.com?utm_source=medium&utm_medium=referral)](https://cdn-images-1.medium.com/max/10368/0*MvIcm-Vt6cAwJ__y)*

Photo by [Andreas Wagner](https://unsplash.com/@waguluz_?utm_source=medium&utm_medium=referral) on [Unsplash](https://unsplash.com?utm_source=medium&utm_medium=referral)*

Using this we can now deploy an AWS machine like this:

    kind: pipeline
    name: commitPipeline

    trigger:
      event:
        - push

    platform:
      os: linux
      arch: arm

    steps:
      - name: validate-seeder-infrastructure
        image: registry.<domain>/aws-cfn
        settings:
          mode: validate
          template: infrastructure.yml
        environment:
          AWS_ACCESS_KEY_ID:
            from_secret: aws_id
          AWS_SECRET_ACCESS_KEY:
            from_secret: aws_key

Once this is deployed, we can run x86 builds with it by either specifying the architecture in the .drone.yml or by removing any architecture declaration because x86 is the default.

I have also rebuilt an AWS-CLI image [here](https://hub.docker.com/r/t3chflicks/aws-cli).

We have now covered the deployment part of the pipeline and in the next article in this series we will cover the monitoring methods and discuss a few gotchas. Check it out [here](https://medium.com/@t3chflicks/home-devops-pipeline-a-junior-engineers-tale-4-4-5db7c1610e3e).

*Contents: [1](https://medium.com/@t3chflicks/home-devops-pipeline-a-junior-engineers-tale-1-4-336ed07a6ec0), [2](https://medium.com/@t3chflicks/home-devops-pipeline-a-junior-engineers-tale-2-4-7be3e3c292c),([3](https://medium.com/@t3chflicks/home-devops-pipeline-a-junior-engineers-tale-3-4-5f61c5245934)), [4](https://medium.com/@t3chflicks/home-devops-pipeline-a-junior-engineers-tale-4-4-5db7c1610e3e)*

## Thanks for reading

I hope you have enjoyed this article. If you like the style, check out [T3chFlicks.org](https://t3chflicks.org/Projects/home-devops-pipeline) for more tech-focused educational content ([YouTube](https://www.youtube.com/channel/UC0eSD-tdiJMI5GQTkMmZ-6w), [Instagram](https://www.instagram.com/t3chflicks/), [Facebook](https://www.facebook.com/t3chflicks), [Twitter](https://twitter.com/t3chflicks)).

