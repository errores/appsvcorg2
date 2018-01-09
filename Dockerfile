#
# Dockerfile for Apache/PHP/MySQL
#
FROM ubuntu:16.04
MAINTAINER a <a@gmail.com>


# ========
# ENV vars
# ========

# apache httpd
ENV HTTPD_VERSION "2.4.25"
ENV HTTPD_DOWNLOAD_URL "http://archive.apache.org/dist/httpd/httpd-$HTTPD_VERSION.tar.gz"
ENV HTTPD_SHA1 "377c62dc6b25c9378221111dec87c28f8fe6ac69"
ENV HTTPD_SOURCE "/usr/src/httpd"
ENV HTTPD_HOME "/usr/local/httpd"
ENV HTTPD_CONF_DIR "$HTTPD_HOME/conf"
ENV HTTPD_CONF_FILE "$HTTPD_CONF_DIR/httpd.conf"
ENV HTTPD_LOG_DIR="/home/LogFiles/httpd"
ENV PATH "$HTTPD_HOME/bin":$PATH






















# ssh
ENV SSH_PASSWD "root:Docker!"

# app
ENV APP_HOME "/home/site/wwwroot"
#
ENV DOCKER_BUILD_HOME "/dockerbuild"


# ====================
# Download and Install
# ~. tools
# 1. essentials
# 2. apache httpd
# 3. mariadb
# 4. php
# 5. phpmyadmin
# 6. ssh
# ====================

WORKDIR $DOCKER_BUILD_HOME
RUN set -ex \
	# --------
	# ~. tools
	# --------
	&& tools=" \
		g++ \
		gcc \
		make \
		pkg-config \
		wget \
	" \
	&& apt-get update \
	&& apt-get install -y -V --no-install-recommends $tools \
	&& rm -r /var/lib/apt/lists/* \

	# ------------------------
	# 1. essentials
	# ------------------------
	&& essentials=" \
		ca-certificates \
	" \
	&& apt-get update \
	&& apt-get install -y -V --no-install-recommends $essentials \
	&& rm -r /var/lib/apt/lists/* \

	# ------------------------
	# 2. apache httpd
	# ------------------------
	&& mkdir -p $HTTPD_SOURCE \
	&& mkdir -p $HTTPD_HOME \
	## runtime and buildtime deps
	&& httpdBuildtimeDeps=" \
		libpcre++-dev \
		libssl-dev \
	" \
	&& httpdRuntimeDeps="\
		libapr1 \
		libaprutil1 \
		libaprutil1-ldap \
		libapr1-dev \
		libaprutil1-dev \
	" \
	&& apt-get update \
	&& apt-get install -y -V --no-install-recommends $httpdBuildtimeDeps $httpdRuntimeDeps \		
	&& rm -r /var/lib/apt/lists/* \
	## download, validate, extract
	&& cd $DOCKER_BUILD_HOME \
	&& wget -O httpd.tar.gz "$HTTPD_DOWNLOAD_URL" --no-check-certificate \
	&& echo "$HTTPD_SHA1 *httpd.tar.gz" | sha1sum -c - \
	&& tar -xf httpd.tar.gz -C $HTTPD_SOURCE --strip-components=1 \
	## configure, make, install
	&& cd $HTTPD_SOURCE \
	&& ./configure \
		--prefix=$HTTPD_HOME \
		### using prefork for PHP. see http://php.net/manual/en/install.unix.apache2.php
		--with-mpm=prefork \
		--enable-mods-shared=reallyall \
		--enable-ssl \
		--enable-deflate \
	&& make -j "$(nproc)" \
	&& make install \
	&& make clean \
	## clean up
	&& rm -rf $HTTPD_SOURCE \
		$HTTPD_HOME/man \
		$HTTPD_HOME/manual \
	&& rm $DOCKER_BUILD_HOME/httpd.tar.gz \
	&& apt-get purge -y -V -o APT::AutoRemove::RecommendsImportant=false --auto-remove $httpdBuildtimeDeps \

































































































	# ------------------------
	# 6. ssh
	# ------------------------
	&& apt-get update \
	&& apt-get install -y --no-install-recommends openssh-server \
	&& echo "$SSH_PASSWD" | chpasswd \

	# ------------------------
	# ~. clean up
	# ------------------------
	&& apt-get purge -y -V -o APT::AutoRemove::RecommendsImportant=false --auto-remove $tools \
	&& apt-get autoremove -y	


# =========
# Configure
# =========












# ssh
COPY sshd_config /etc/ssh/



















# =====
# final
# =====
COPY entrypoint.sh /usr/local/bin/
RUN chmod u+x /usr/local/bin/entrypoint.sh
EXPOSE 2222 80
ENTRYPOINT ["entrypoint.sh"]
