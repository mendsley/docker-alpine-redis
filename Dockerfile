FROM mendsley/alpine-gosu
MAINTAINER Matthew Endsley <mendsley@gmail.com>

# add our user/group first to ensure my get consistent ids
RUN addgroup redis \
	&& adduser -H -D -s /bin/false -G redis redis

# Patches for Alpine compatibility \
ENV REDIS_VERSION="2.8.24" \
	REDIS_DOWNLOAD_URL="http://download.redis.io/releases/redis-2.8.24.tar.gz" \
	REDIS_DOWNLOAD_SHA1="636efa8b522dfbf7f3dba372237492c11181f8e0" \
	REDIS_BACKTRACE_PATCH_URL="https://raw.githubusercontent.com/alpinelinux/aports/115f0915bb5bb7c9c36b43c7fbfe0dd11435580c/main/redis/redis-no-backtrace.patch" \
	REDIS_BACKTRACE_PATCH_SHA1="ea9961e702c8e07056e8278f22208f2f7bf0daf9"

# Download and build redis
RUN buildDeps='curl tar patch make gcc musl-dev linux-headers' \
	&& set -x \
	&& apk add --update $buildDeps \
	&& curl -sSL "$REDIS_DOWNLOAD_URL" -o redis.tar.gz \
	&& echo "$REDIS_DOWNLOAD_SHA1 *redis.tar.gz" | sha1sum -c - \
	&& mkdir -p /usr/src/redis \
	&& tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 \
	&& rm -f redis.tar.gz \
	&& cd /usr/src/redis \
	&& curl -sSL "$REDIS_BACKTRACE_PATCH_URL" -o redis-no-backtrace.patch \
	&& echo "$REDIS_BACKTRACE_PATCH_SHA1 *redis-no-backtrace.patch" | sha1sum -c - \
	&& patch -p1 < redis-no-backtrace.patch \
	&& make \
	&& make install \
	&& cd / \
	&& rm -rf /usr/src \
	&& apk del $buildDeps \
	&& rm -rf /var/cache/apk/* \
	;

RUN mkdir /data \
	&& chown redis:redis /data \
	;
VOLUME /data
WORKDIR /data

COPY docker-entry-point.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 6379
CMD ["redis-server"]
