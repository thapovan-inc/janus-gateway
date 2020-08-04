FROM ubuntu:bionic

RUN apt update && apt install -y build-essential libmicrohttpd-dev libjansson-dev libssl-dev libsofia-sip-ua-dev libglib2.0-dev libopus-dev libogg-dev libcurl4-openssl-dev liblua5.3-dev libconfig-dev pkg-config gengetopt libtool automake git python3-pip cmake && pip3 install meson ninja
RUN mkdir -p /usr/src
RUN cd /usr/src && git clone https://gitlab.freedesktop.org/libnice/libnice && cd libnice && meson --prefix=/usr build && ninja -C build && ninja -C build install && cd / && rm -rf /usr/src/libnice
RUN cd /usr/src/ && git clone https://libwebsockets.org/repo/libwebsockets && cd libwebsockets && mkdir build && cd build && cmake -DLWS_MAX_SMP=1 -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" .. && make && make install && cd / && rm -rf /usr/src/libwebsockets
RUN cd /usr/src && git clone https://github.com/cisco/libsrtp.git && cd libsrtp && git checkout v2.3.0 && ./configure --prefix=/usr --enable-openssl && make shared_library && make install && cd / && rm -rf /usr/src/libsrtp
RUN mkdir /usr/src/janus-gateway
COPY . /usr/src/janus-gateway/
RUN cd /usr/src/janus-gateway && sh autogen.sh && ./configure --prefix=/opt/janus && make && make install && make configs
CMD /opt/janus/bin/janus