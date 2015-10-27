FROM combro2k/debian-debootstrap:8
MAINTAINER Martijn van Maurik <docker@vmaueik.nl>

# Environment variables
ENV INSTALL_LOG="/var/log/build.log" \
    APP_USER="app" \
    APP_HOME="/home/app" \
    HOME="${APP_HOME}"

# Add first the scripts to the container
ADD resources/bin/ /usr/local/bin/

# Run the installer script
RUN /bin/bash -c "bash /usr/local/bin/setup.sh build"

USER ${APP_USER}

CMD ["/usr/local/bin/run"]
