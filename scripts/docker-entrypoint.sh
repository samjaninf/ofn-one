#!/bin/bash

set -e

if [ "$1" = 'zammad' ]; then

  # starting services
  #service postgresql start
  #service elasticsearch start

  # wait for postgres processe coming up
  #until su - postgres -c 'psql -c "select version()"' &> /dev/null; do
  #until
  #  echo "waiting for postgres to be ready..."
  #  sleep 2
  #done


  #until $(mysql -s -N -e -u${ZAMMAD_DB_USER} -p${ZAMMAD_DB_PASS} -h ${ZAMMAD_DB_HOST} "SELECT schema_name FROM information_schema.schemata WHERE SCHEMA_NAME = '${ZAMMAD_DB}'"); do
  #  echo "=> Waiting for MariaDB to be ready..."
  #done
  export tableExists=$(mysql -s -N -e -u${ZAMMAD_DB_USER} -p${ZAMMAD_DB_PASS} -h ${ZAMMAD_DB_HOST} "SELECT * FROM information_schema.tables WHERE table_schema = '${ZAMMAD_DB}' AND table_name = 'users'")
  if [[ -z "${tableExists}" ]]; then
    echo "==> Configuring Zammad for production please wait..."
    sed -e "s#production:#${RAILS_ENV}:#" -e "s#.*adapter:.*#  adapter: mysql2#" -e "s#.*username:.*#  username: ${ZAMMAD_DB_USER}#" -e "s#.*password:.*#  password: ${ZAMMAD_DB_PASS}#" -e "s#.*database:.*#  database: ${ZAMMAD_DB}\n  host: ${ZAMMAD_DB_HOST}#" < ${ZAMMAD_DIR}/config/database.yml.pkgr > ${ZAMMAD_DIR}/config/database.yml
    cd ${ZAMMAD_DIR}
    # populate database
    echo "==> Running db:migrate..."
    bundle exec rake db:migrate
    echo "==> Running db:seed..."
    bundle exec rake db:seed

    # assets precompile
    echo "==> Running assets:precompile..."
    bundle exec rake assets:precompile

    # delete assets precompile cache
    rm -r tmp/cache

    # create es searchindex
    # bundle exec rails r "Setting.set('es_url', 'http://localhost:9200')"
    echo "==> Running searchindex:rebuild..."
    bundle exec rails r "Setting.set('es_url', 'http://${ZAMMAD_ES_URL}:9200')"
    bundle exec rake searchindex:rebuild

    # copy nginx zammad config
    cp ${ZAMMAD_DIR}/contrib/nginx/zammad.conf /etc/nginx/sites-enabled/zammad.conf
  fi

  service postfix start
  service nginx start

# set user & group to zammad
chown -R zammad:zammad "${ZAMMAD_DIR}"

  cd ${ZAMMAD_DIR}
  echo "starting zammad...."
  su -c "bundle exec script/websocket-server.rb -b 0.0.0.0 start &>> ${ZAMMAD_DIR}/log/zammad.log &" zammad
  su -c "bundle exec script/scheduler.rb start &>> ${ZAMMAD_DIR}/log/zammad.log &" zammad

  if [ "${RAILS_SERVER}" == "puma" ]; then
    su -c "bundle exec puma -b tcp://0.0.0.0:3000 -e ${RAILS_ENV} &>> ${ZAMMAD_DIR}/log/zammad.log &" zammad
  elif [ "${RAILS_SERVER}" == "unicorn" ]; then
    su -c "bundle exec unicorn -p 3000 -c config/unicorn.rb -E ${RAILS_ENV} &>> ${ZAMMAD_DIR}/log/zammad.log &" zammad
  fi

  # wait for zammad processe coming up
  until (echo > /dev/tcp/localhost/3000) &> /dev/null; do
    echo "waiting for zammad to be ready..."
    sleep 2
  done

  # show url
  echo -e "==> \nZammad is ready! Visit the url in your browser to configure!"
  #echo -e "If you like to use Zammad from somewhere else edit servername directive in /etc/nginx/sites-enabled/zammad.conf!\n"

  # run shell
  /bin/bash

fi
