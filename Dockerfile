FROM python:3.10-slim

ENV ANSIBLE_CONFIG=./ansible.cfg
ENV PYTHONUNBUFFERED=1

RUN apt-get update && \
    apt-get install -y \
    sshpass \
    openssh-client \
    git \
    sudo \
    vim \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /k3s-ansible

COPY . .

RUN python3 -m venv env && \
    . env/bin/activate && \
    pip install --upgrade pip && \
    pip install ansible-core==2.16.4 distlib netaddr jsonschema ipaddr  jmespath && \
    ansible-galaxy install -r requirements.yml && \
    ansible-config dump --only-changed \

CMD ["/bin/bash"]
