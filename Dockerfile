FROM centos:7

RUN yum update -y && \
    yum install -y \
        gcc \
        openssl-devel \
        bzip2-devel \
        libffi-devel \
        lzma-devel \
        curl \
        tar \
        make && \
    yum clean all

ARG PYTHON_VERSION=3.8.8
WORKDIR /build
RUN curl -sLO "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz" && \
    tar -xzf "Python-${PYTHON_VERSION}.tgz" && \
    cd "Python-${PYTHON_VERSION}" && \
    ./configure --help && \
    ./configure --prefix=/usr \
        --exec_prefix=/usr \
        --with-ensurepip \
        --enable-optimizations \
        --with-lto \
        --enable-ipv6 && \
    make -j"$(($(nproc) - 1))" && \
    make install && \
    printf "\nalias python='python3'\n" >> ~/.bashrc && \
    cd / && \
    rm -rf /build
WORKDIR /

ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8

CMD [ "/bin/bash" ]
