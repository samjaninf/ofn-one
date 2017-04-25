FROM ruby:2.1.5
MAINTAINER Zammad.org <info@zammad.org>
ARG BUILD_DATE

ENV DEBIAN_FRONTEND noninteractive
ENV OFN_DIR /opt/ofn
ENV RAILS_ENV production
ENV GIT_URL https://github.com/openfoodfoundation/openfoodnetwork.git
ENV GIT_BRANCH master
ENV RAILS_SERVER unicorn

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

RUN apt-get update -y && apt-get install -y --no-install-recommends apt-transport-https libterm-readline-perl-perl locales mc net-tools nginx postfix build-essential chrpath libssl-dev libxft-dev libfreetype6 libfreetype6-dev libfontconfig1 libfontconfig1-dev

RUN gem install bundler
RUN bundle config git.allow_insecure true
COPY openfoodnetwork/. /opt/ofn
WORKDIR /opt/ofn
RUN bundle install --without test development mysql
# Start postfix and nginx because I am scrub.
RUN service postfix start && service nginx start

RUN useradd -M -d /opt/ofn -s /bin/bash ofn

# install zammad
COPY scripts/install-ofn.sh /tmp
RUN chmod +x /tmp/install-ofn.sh;/bin/bash -l -c /tmp/install-ofn.sh

RUN wget -q https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 -O phantomjs-2.1.1.tar.bz2
RUN tar xvjf phantomjs-2.1.1.tar.bz2
RUN mv phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/bin/phantomjs

# docker init
COPY scripts/docker-entrypoint.sh /
RUN chown ofn:ofn -R /opt/ofn;chown ofn:ofn /docker-entrypoint.sh;chmod +x /docker-entrypoint.sh


#USER ofn
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["ofn"]
