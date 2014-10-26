#!/bin/sh

yum -y install redis hiredis hiredis-devel pcre-devel
gem install rake

SRC_ROOT=/usr/local/src
NGINX_VER="1.7.6"
NGINX_SRC=$SRC_ROOT/nginx-$NGINX_VER
NGX_MRUBY_SRC=$SRC_ROOT/ngx_mruby

cd $SRC_ROOT
wget http://nginx.org/download/nginx-$NGINX_VER.tar.gz
tar -zxvf nginx-$NGINX_VER.tar.gz

cd $SRC_ROOT
git clone https://github.com/matsumoto-r/ngx_mruby.git
cd ngx_mruby
git submodule init
git submodule update
./configure --with-ngx-src-root=$NGINX_SRC
make build_mruby
make generate_gems_config

cd $NGINX_SRC
git clone https://github.com/calio/form-input-nginx-module.git
./configure --prefix=/usr/local/nginx \
--add-module=$NGX_MRUBY_SRC \
--add-module=$NGX_MRUBY_SRC/dependence/ngx_devel_kit \
--add-module=$NGINX_SRC/form-input-nginx-module \
--with-http_realip_module \
--with-pcre-jit

make
make install
