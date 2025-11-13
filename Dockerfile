FROM alpine:3.22

LABEL maintainer="Zwei Chen <hi@zweichen.com>"
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/:/usr/lib/pkgconfig/
ENV OC_VERSION=1.3.0
ENV RADCLI_VERSION=1.4.0

RUN buildDeps=" \
		curl \
		g++ \
		gnutls-dev \
		gpgme \
		libev-dev \
		libnl3-dev \
		libseccomp-dev \
		linux-headers \
		linux-pam-dev \
		lz4-dev \
		make \
		readline-dev \
		tar \
		xz \
		autoconf \
		libtool \
		automake \
		abi-compliance-checker \
	"; \
	set -x \
	&& apk update \
	&& apk add gnutls gnutls-utils iptables libev libintl libnl3 libseccomp linux-pam lz4 lz4-libs openssl readline sed \
	&& apk add $buildDeps \
	&& curl -SL "https://github.com/radcli/radcli/releases/download/$RADCLI_VERSION/radcli-$RADCLI_VERSION.tar.gz" -o radcli.tar.gz \
	&& mkdir -p /usr/src/radcli \
	&& tar -xf radcli.tar.gz -C /usr/src/radcli --strip-components=1 \
	&& rm radcli.tar.gz* \
	&& cd /usr/src/radcli \
	&& ./configure --sysconfdir=/etc/ \
	&& make \
	&& make install \
	&& cd / \
	&& rm -fr /usr/src/radcli \
	&& curl -SL "https://www.infradead.org/ocserv/download/ocserv-$OC_VERSION.tar.xz" -o ocserv.tar.xz \
	&& curl -SL "https://www.infradead.org/ocserv/download/ocserv-$OC_VERSION.tar.xz.sig" -o ocserv.tar.xz.sig \
	&& gpg --keyserver pgp.mit.edu --recv-key 7F343FA7 \
	&& gpg --keyserver pgp.mit.edu --recv-key 96865171 \
	&& gpg --verify ocserv.tar.xz.sig \
	&& mkdir -p /usr/src/ocserv \
	&& tar -xf ocserv.tar.xz -C /usr/src/ocserv --strip-components=1 \
	&& rm ocserv.tar.xz* \
	&& cd /usr/src/ocserv \
	&& ./configure \
	&& make \
	&& make install \
	&& mkdir -p /etc/ocserv \
	&& cp /usr/src/ocserv/doc/sample.config /etc/ocserv/ocserv.conf \
	&& cd / \
	&& rm -fr /usr/src/ocserv \
	&& apk del $buildDeps \
	&& rm -rf /var/cache/apk/*

# Setup config

WORKDIR /etc/ocserv

# COPY All /etc/ocserv/config-per-group/All
# COPY cn-no-route.txt /etc/ocserv/config-per-group/Route
# COPY Local /etc/ocserv/config-per-group/Local

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 443

VOLUME ["/etc/ocserv", "/etc/radcli"]

CMD ["ocserv", "-c", "/etc/ocserv/ocserv.conf", "-f"]
