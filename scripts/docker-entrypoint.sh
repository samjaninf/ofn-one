#!/bin/bash

set -e

if [ "$1" = 'ofn' ]; then
    export PGPASSWORD=$OFN_DB_PASS
    export rakeSecret=$(rake secret)
    echo "===> Configuring Openfoodnetwork for production please wait..."
    sed -e "s#production:#${RAILS_ENV}:#" -e "s#.*adapter:.*#  adapter: postgresql#" -e "s#.*username:.*#  username: ${OFN_DB_USER}#" -e "s#.*password:.*#  password: ${OFN_DB_PASS}#" -e "s#.*database:.*#  database: ${OFN_DB}\n  host: ${OFN_DB_HOST}#" < /database.yml.pkgr > ${OFN_DIR}/config/database.yml
    cd ${OFN_DIR}
    echo "==> Testing if database exists. if not, then populate database"
    if ! psql -lqtA -h ${OFN_DB_HOST} -U ${OFN_DB_USER} | grep -qw ${OFN_DB} ; then
      echo "===> Running db:drop..."
      bundle exec rake db:drop
      echo "===> Running db:create..."
      bundle exec rake db:create
      echo "===> Running db:schema:load..."
      bundle exec rake db:schema:load || echo "<== Schema already loaded..."
      echo "===> Running db:migrate..."
      bundle exec rake db:migrate || echo "<== already migrated..."
      echo "===> Running db:seed..."
      bundle exec rake db:seed || echo "<== Already seeded"
    fi

    # assets precompile
    echo "===> Running assets:precompile..."
    bundle exec rake assets:precompile

    # echo "==> setting hostname now..."
    # sed -e "s#.*server_name.*#    server_name ${OFN_URL};#" < /ofn.conf.pkgr > /etc/nginx/sites-enabled/ofn.conf

    # echo "==> starting nginx, postfix and memcached..."
    # service nginx start; service postfix start; service memcached start
    echo "==> starting postfix and memcached..."
    service postfix start; service memcached start

  cat << EOF > /opt/ofn/config/unicorn.rb
app_path = File.expand_path(File.dirname(__FILE__) + '/..')

# amount of unicorn workers to spin up
worker_processes (ENV['RAILS_ENV'] == 'production' ? 2 : 1)

# restarts workers that hang for 30 seconds
#timeout 120
timeout 300

listen app_path + '/tmp/unicorn.sock', backlog: 64

listen(3000, backlog: 64) if ENV['RAILS_ENV'] == 'development'

# Set the working directory of this unicorn instance.
working_directory app_path

pid app_path + '/tmp/unicorn.pid'

preload_app true

# Garbage collection settings.
GC.respond_to?(:copy_on_write_friendly=) &&
  GC.copy_on_write_friendly = true

# If using ActiveRecord, disconnect (from the database) before forking.
before_fork do |server, worker|
  defined?(ActiveRecord::Base) &&
    ActiveRecord::Base.connection.disconnect!
end

# After forking, restore your ActiveRecord connection.
after_fork do |server, worker|
  defined?(ActiveRecord::Base) &&
    ActiveRecord::Base.establish_connection
end
EOF

  sed -i -e "s#.*config.force_ssl.*#  config.force_ssl = false#" /opt/ofn/config/environments/production.rb
  sed -i -e "s#.*config.log_level.*#  config.log_level = :info#" /opt/ofn/config/environments/production.rb

  echo "===> Starting openfoodnetwork...."
  if [ "${RAILS_SERVER}" == "puma" ]; then
    bundle exec puma -b tcp://0.0.0.0:3000 -e ${RAILS_ENV} &>> ${OFN_DIR}/log/ofn.log &
  elif [ "${RAILS_SERVER}" == "unicorn" ]; then
    bundle exec unicorn -p 3000 -c config/unicorn.rb -E ${RAILS_ENV} &>> ${OFN_DIR}/log/ofn.log &
  fi

  # wait for openfoodnetwork processe coming up
  until (echo > /dev/tcp/localhost/3000) &> /dev/null; do
    echo "==> waiting for openfoodnetwork to be ready..."
    sleep 10
  done

  echo "==> Starting jobs..."
  chmod +x script/delayed_job
  script/delayed_job -n 2 start

  # show url
  echo -e "===> Openfoodnetwork is ready! Visit the url in your browser to configure!"

  # run shell
  #tail -f ${OFN_DIR}/log/production.log
  tail -n 0 -f ${OFN_DIR}/log/*
  /bin/bash

fi
