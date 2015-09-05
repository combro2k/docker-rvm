FROM combro2k/debian-debootstrap:8
MAINTAINER Martijn van Maurik <docker@vmaueik.nl>

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update -qy && apt-get install -yq curl && \
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 && \
    curl -sSL https://get.rvm.io | bash -s stable --ruby --with-default-gems='bundler rails'

CMD ["/bin/bash", "-l"]
