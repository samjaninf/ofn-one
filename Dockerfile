FROM ruby:2.3.1
MAINTAINER Zammad.org <info@zammad.org>
ARG BUILD_DATE

ENV DEBIAN_FRONTEND=noninteractive
ENV RAILS_ENV production
ENV GIT_URL https://github.com/openfoodfoundation/openfoodnetwork.git
ENV GIT_BRANCH master

# Expose ports
EXPOSE 80

# fixing service start
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d
RUN echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4

# TODO: sed the database file to in put correct stuff
#       and the nginx file as well
# cleanup
RUN rm -rf /var/lib/apt/lists/* preseed.txt

RUN echo "postfix postfix/main_mailer_type string Internet site" > preseed.txt

RUN debconf-set-selections preseed.txt

RUN apt-get update -y && apt-get install --no-install-recommends install apt-transport-https libterm-readline-perl-perl locales mc net-tools nginx postfix

RUN gem install bundler

COPY openfoodnetwork/. /opt/ofn

# Start postfix and nginx because I am scrub.
RUN service postfix start && service nginx start

RUN useradd -M -d /opt/ofn -s /bin/bash ofn

# install zammad
COPY scripts/install-ofn.sh /tmp
RUN chmod +x /tmp/install-ofn.sh;/bin/bash -l -c /tmp/install-ofn.sh


# docker init
COPY scripts/docker-entrypoint.sh /
RUN chown ofn:ofn /docker-entrypoint.sh;chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
#CMD ["zammad"]
