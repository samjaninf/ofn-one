#!/bin/bash

set -e

#echo "-----> Enabling Zammad"
#chkconfig zammad on
echo "-----> Starting Zammad"
systemctl start zammad
# fetch locales
#contrib/packager.io/fetch_locales.rb

# assets precompile
#bundle exec rake assets:precompile

# delete assets precompile cache
#rm -r tmp/cache

# set user & group to zammad
#chown -R zammad:zammad "${ZAMMAD_DIR}"