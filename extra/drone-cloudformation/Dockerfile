FROM alpine:latest

RUN apk update \
    && apk add jq python3 python3-dev groff curl \
    && curl -O https://bootstrap.pypa.io/get-pip.py \
    && python3 get-pip.py \
    && pip3 install --upgrade awscli

RUN pip3 show awscli

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY ssm-params /usr/local/bin/ssm-params

ENTRYPOINT ["entrypoint.sh"]