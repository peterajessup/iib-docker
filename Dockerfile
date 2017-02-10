# © Copyright IBM Corporation 2015.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

FROM ubuntu:14.04

MAINTAINER Sam Rogers srogers@uk.ibm.com

# Install curl
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
	apt-get dist-upgrade -y
	

# Install IIB V10 Developer edition
RUN mkdir /opt/ibm && \
    curl http://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/integration/10.0.0.7-IIB-LINUX64-DEVELOPER.tar.gz \
    | tar zx --exclude iib-10.0.0.7/tools --directory /opt/ibm && \
    /opt/ibm/iib-10.0.0.7/iib make registry global accept license silently

# Configure system
COPY kernel_settings.sh /tmp/
RUN echo "IIB_10:" > /etc/debian_chroot  && \
    touch /var/log/syslog && \
    chown syslog:adm /var/log/syslog && \
    chmod +x /tmp/kernel_settings.sh;sync && \
    /tmp/kernel_settings.sh

# Create user to run as
RUN useradd --create-home --home-dir /home/iibuser -G mqbrkrs,sudo iibuser && \
    sed -e 's/^%sudo	.*/%sudo	ALL=NOPASSWD:ALL/g' -i /etc/sudoers

# Copy in script files
COPY iib_manage.sh /usr/local/bin/
COPY iib-license-check.sh /usr/local/bin/
COPY iib_env.sh /usr/local/bin/
COPY login.defs /etc/login.defs
COPY sqljdbc4.jar /opt/ibm/iib-10.0.0.7/common/classes
COPY odbc.ini /etc
COPY odbcinst.ini /etc
COPY agentx.json /home/iibuser
COPY switch.json /home/iibuser
RUN chgrp mqbrkrs /home/iibuser/agentx.json
RUN chown iibuser /home/iibuser/agentx.json
RUN chgrp mqbrkrs /home/iibuser/switch.json
RUN chown iibuser /home/iibuser/switch.json
RUN chmod +r /home/iibuser/agentx.json
RUN chmod +r /home/iibuser/switch.json
RUN chgrp mqbrkrs /etc/odbc.ini
RUN chown iibuser /etc/odbc.ini
RUN chmod 664 /etc/odbc.ini
RUN chmod +rx /usr/local/bin/*.sh

# Set BASH_ENV to source mqsiprofile when using docker exec bash -c
ENV BASH_ENV=/usr/local/bin/iib_env.sh
ENV ODBCINI=/etc/odbc.ini


# Expose default admin port and http port
EXPOSE 4414 7800 7883

USER iibuser

# Set entrypoint to run management script
ENTRYPOINT ["iib_manage.sh"]
