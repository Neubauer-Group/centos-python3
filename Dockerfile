FROM centos:7

SHELL [ "/bin/bash", "-c" ]

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
# Ensure that python means python3 even in non-interactive sessions through
# aliases and symbolic links
# N.B.:
# shebang manipulation is a bad thing to do in general and this is ONLY being
# done to ensure that non-interatice sessions don't cause unintended bugs.
# As soon as NCSA Blue Waters is EOL and no longer needed, switch over to
# centos:8 immediatley.
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
    printf "# For Python 2.7 use 'python2'\n" >> ~/.bashrc && \
    printf "# For Python 2.7 in shebangs use '#!/usr/libexec/platform-python'\n" >> ~/.bashrc && \
    ln --symbolic --force "$(command -v python3)" "$(command -v python)" && \
    cd / && \
    rm -rf /build && \
    grep --recursive '#!/usr/bin/python' /usr/bin/ \
        | grep --invert-match 'python3\|python2.7' \
        | sed 's/:.*$//' \
        | xargs sed --in-place 's|#!/usr/bin/python|#!/usr/libexec/platform-python|g'
WORKDIR /

ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8

ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["/bin/bash"]
