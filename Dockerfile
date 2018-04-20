FROM ruby:2.1.5-alpine
MAINTAINER Zammad.org <info@zammad.org>
ARG BUILD_DATE

ENV DEBIAN_FRONTEND noninteractive
ENV OFN_DIR /opt/ofn
ENV RAILS_ENV production
ENV GIT_URL https://github.com/openfoodfoundation/openfoodnetwork.git
ENV GIT_BRANCH master
ENV RAILS_SERVER unicorn

# Expose ports
EXPOSE 80 443 3000

# fixing service start
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d
RUN echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4

# cleanup
RUN rm -rf /var/lib/apt/lists/* preseed.txt

RUN echo "postfix postfix/main_mailer_type string Internet site" > preseed.txt

RUN debconf-set-selections preseed.txt

RUN apt-get update -y && apt-get install -y --no-install-recommends postgresql-client memcached apt-transport-https libterm-readline-perl-perl locales mc net-tools nginx postfix build-essential chrpath libssl-dev libxft-dev libfreetype6 libfreetype6-dev libfontconfig1 libfontconfig1-dev imagemagick

RUN gem install bundler && bundle config git.allow_insecure true
COPY openfoodnetwork/. /opt/ofn
WORKDIR /opt/ofn
RUN bundle install --without test development staging mysql
RUN SECRET_TOKEN="6f68c4c1da3ecd7adb2f9331786648ebfe6f824459ed80932f443b79cf15c6be52fa4d75e6e11db282d0a6e571b463f58416428d89eae5a2b564b9c7ad8d92e4" DB_ADAPTER=nulldb bundle exec assets:precompile

RUN useradd -M -d /opt/ofn -s /bin/bash ofn

# update certs and setup nginx config file
COPY scripts/install-ofn.sh /tmp
RUN chmod +x /tmp/install-ofn.sh;/bin/bash -l -c /tmp/install-ofn.sh

# docker init
COPY scripts/docker-entrypoint.sh /
RUN chown ofn:ofn -R /opt/ofn;chown ofn:ofn /docker-entrypoint.sh;chmod +x /docker-entrypoint.sh

# Yeah... this was stupid... should just copy the files where they need to be
COPY scripts/ofn.conf.pkgr /ofn.conf.pkgr
COPY scripts/database.yml.pkgr /database.yml.pkgr

#USER ofn
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["ofn"]
