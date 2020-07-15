FROM clearlinux:latest AS builder

RUN /bin/bash -c "swupd bundle-add dev-utils devpkg-libmicrohttpd devpkg-jansson devpkg-openssl \
                    devpkg-opus devpkg-libsrtp devpkg-libogg devpkg-curl \
                    devpkg-libconfig devpkg-lua c-basic devpkg-libffi devpkg-pcre \
                    wget package-utils go-basic sysadmin-basic && swupd clean && exit 0"

RUN mkdir -p /opt/src

WORKDIR /opt/src

RUN /bin/bash -c "git clone https://boringssl.googlesource.com/boringssl \
                    && cd boringssl \
                    && sed -i s/\" -Werror\"//g CMakeLists.txt \
                    && mkdir -p build \
                    && cd build \
                    && cmake -DCMAKE_CXX_FLAGS=\"-lrt\" .. \
                    && make -j 8 \
                    && cd .. \
                    && mkdir -p /opt/boringssl \
                    && cp -R include /opt/boringssl/ \
                    && mkdir -p /opt/boringssl/lib \
                    && cp build/ssl/libssl.a /opt/boringssl/lib/ \
                    && cp build/crypto/libcrypto.a /opt/boringssl/lib/ \
                    && cd build \
                    && cmake -DCMAKE_CXX_FLAGS=\"-lrt\" -DBUILD_SHARED_LIBS=1 .. \
                    && make -j 8 \
                    && cd .. \
                    && cp build/ssl/libssl.so /opt/boringssl/lib/ \
                    && cp build/crypto/libcrypto.so /opt/boringssl/lib/ \
                    && rm -rf /opt/src/boringssl"

RUN /bin/bash -c "git clone https://gitlab.freedesktop.org/libnice/libnice \
                  && cd libnice \
                  && meson --prefix=/usr build && ninja -C build && ninja -C build install \
                  && cd /opt/src \
                  && rm -rf /opt/src/libnice"

RUN /bin/bash -c "wget https://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/g/gengetopt-2.23-1.el7.x86_64.rpm \
                  && rpm --install --nodeps --force gengetopt-2.23-1.el7.x86_64.rpm \
                  && rm gengetopt-2.23-1.el7.x86_64.rpm"

RUN /bin/bash -c "git clone https://libwebsockets.org/repo/libwebsockets \
                  && cd libwebsockets \
                  && git checkout v3.2-stable \
                  && mkdir build \
                  && cd build \
                  && cmake -DLWS_MAX_SMP=1 -DLIB_SUFFIX=64 -DCMAKE_C_FLAGS=\"-fpic\" -DOPENSSL_LIBRARIES=\"/opt/boringssl/lib/libssl.so; /opt/boringssl/lib/libcrypto.so\" -DOPENSSL_INCLUDE_DIRS=/opt/boringssl/include -DLWS_WITH_BORINGSSL=1 .. \
                  && make -j 8 \
                  && make install \
                  && cd /opt/src \
                  && rm -rf /opt/src/libwebsockets"

RUN /bin/bash -c "git clone https://github.com/meetecho/janus-gateway.git \
                  && cd janus-gateway \
                  && sh autogen.sh \
                  && ./configure --prefix=/opt/janus --enable-plugin-lua --enable-boringssl --enable-dtls-settimeout \
                  && make -j 8 \
                  && make install \
                  && make configs \
                  && cd .. \
                  && rm -rf janus-gateway"


FROM clearlinux:latest

WORKDIR /lib64

COPY --from=builder  /lib64/libmicrohttpd.so.12.56.0 .
COPY --from=builder  /lib64/libmicrohttpd.so.12 .
COPY --from=builder  /lib64/libmicrohttpd.so .

COPY --from=builder /lib64/libogg.so.0.8.4 .
COPY --from=builder /lib64/libogg.so.0 .
COPY --from=builder /lib64/libogg.so .

COPY --from=builder /lib64/libjansson.so.4.11.1 .
COPY --from=builder /lib64/libjansson.so.4 .
COPY --from=builder /lib64/libjansson.so .

COPY --from=builder /lib64/libopus.so.0.8.0 .
COPY --from=builder /lib64/libopus.so.0 .
COPY --from=builder /lib64/libopus.so .

COPY --from=builder /lib64/libsrtp.so.1 .
COPY --from=builder /lib64/libsrtp.so .

COPY --from=builder /lib64/libcurl.so.4.6.0 .
COPY --from=builder /lib64/libcurl.so.4 .
COPY --from=builder /lib64/libcurl.so .


COPY --from=builder /lib64/libconfig.so.11.0.2 .
COPY --from=builder /lib64/libconfig.so.11 .
COPY --from=builder /lib64/libconfig.so .

COPY --from=builder /lib64/liblua.so.5.3.5 .
COPY --from=builder /lib64/liblua.so.5.3 .
COPY --from=builder /lib64/liblua.so .

COPY --from=builder /lib64/libpcre.so.1.2.11 .
COPY --from=builder /lib64/libpcre.so.1 .
COPY --from=builder /lib64/libpcre.so .

COPY --from=builder /lib64/libffi.so.6.0.4 .
COPY --from=builder /lib64/libffi.so.6 .
COPY --from=builder /lib64/libffi.so .

COPY --from=builder /lib64/libnice.so.10.10.0 .
COPY --from=builder /lib64/libnice.so.10 .
COPY --from=builder /lib64/libnice.so .

COPY --from=builder /usr/lib/libwebsockets.so .
COPY --from=builder /usr/lib/libwebsockets.so.15 .

COPY --from=builder /opt/boringssl/lib/libssl.so .
COPY --from=builder /opt/boringssl/lib/libcrypto.so .

COPY --from=builder /opt/janus/ /opt/janus/

WORKDIR /opt/janus
CMD bin/janus