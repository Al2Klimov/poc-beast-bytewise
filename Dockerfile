FROM debian:9 as boost-wget
SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

RUN apt-get update ;\
	DEBIAN_FRONTEND=noninteractive apt-get install --no-install-{recommends,suggests} -y \
		wget ca-certificates bzip2 ;\
	apt-get clean ;\
	rm -vrf /var/lib/apt/lists/*

RUN wget https://dl.bintray.com/boostorg/release/1.69.0/source/boost_1_69_0.tar.bz2

RUN tar -xaf boost_1_69_0.tar.bz2


FROM debian:9 as boost-build
SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

RUN apt-get update ;\
	DEBIAN_FRONTEND=noninteractive apt-get install --no-install-{recommends,suggests} -y \
		g++ ;\
	apt-get clean ;\
	rm -vrf /var/lib/apt/lists/*

COPY --from=boost-wget /boost_1_69_0 /boost

RUN cd /boost ;\
	./bootstrap.sh ;\
	./b2


FROM debian:9 as app-build
SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

RUN apt-get update ;\
	DEBIAN_FRONTEND=noninteractive apt-get install --no-install-{recommends,suggests} -y \
		g++ libssl-dev ;\
	apt-get clean ;\
	rm -vrf /var/lib/apt/lists/*

RUN mkdir -p /boost/stage/lib

COPY --from=boost-build /boost/boost /boost/boost
COPY --from=boost-build /boost/stage/lib/*.so* /boost/stage/lib/

ADD ./src /src

RUN g++ -I /boost -L /boost/stage/lib -lpthread -lboost_{coroutine,context,thread} -lssl -lcrypto -o /app /src/http_server_coro_ssl.cpp


FROM debian:9 as app
SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

RUN apt-get update ;\
	DEBIAN_FRONTEND=noninteractive apt-get install --no-install-{recommends,suggests} -y \
		libssl1.1 ;\
	apt-get clean ;\
	rm -vrf /var/lib/apt/lists/*

COPY --from=boost-build /boost/stage/lib/*.so.* /usr/lib/
COPY --from=app-build /app /app

CMD exec /app 0.0.0.0 443 / 1
