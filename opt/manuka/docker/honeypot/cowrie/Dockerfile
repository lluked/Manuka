# Base Image
FROM debian:buster-slim AS base-image
#
ENV STDOUT=yes
#
RUN groupadd -r -g 1000 cowrie && \
    useradd -r -u 1000 -d /home/cowrie -m -g 1000 cowrie && \
    apt-get update && \
    apt-get install -y \
        -o APT::Install-Suggests=false \
        -o APT::Install-Recommends=false \
      python3
#
# Builder Image
FROM base-image AS builder
#
ARG COWRIE_VERSION
#
RUN apt-get install -y \
      build-essential \
      default-libmysqlclient-dev \
      gcc \
      git \
      libffi-dev \
      libsnappy-dev \
      libssl-dev \
      python3-dev \
      python3-pip \
      python3-venv \
      python3-virtualenv
#
USER cowrie
#
RUN cd /home/cowrie && \
    git clone --depth=1 https://github.com/cowrie/cowrie -b v2.2.0 && \
    python3 -m venv /home/cowrie/cowrie-env && \
    . /home/cowrie/cowrie-env/bin/activate && \
    pip install --no-cache-dir --upgrade \
        cffi \
        pip \
        setuptools \
        -r /home/cowrie/cowrie/requirements.txt \
        -r /home/cowrie/cowrie/requirements-output.txt && \
    rm -rf /home/.cache
#
# Final Image
FROM base-image as runtime
#
RUN apt-get install -y \
        -o APT::Install-Suggests=false \
        -o APT::Install-Recommends=false \
      libffi6 \      
      libssl1.1 \
      procps && \
    rm -rf /var/lib/apt/lists/* && \
    ln -s /usr/bin/python3 /usr/local/bin/python
#
COPY --from=builder /home /home
#
USER cowrie
#
ENV PATH=/home/cowrie/cowrie/bin:$PATH
#
WORKDIR /home/cowrie/cowrie
#
CMD [ "cowrie", "start", "-n" ]