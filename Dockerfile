FROM centos:7

SHELL [ "/bin/bash", "-c" ]

RUN yum update -y && \
    yum install -y \
        gcc \
        openssl-devel \
        bzip2 \
        bzip2-devel \
        libffi-devel \
        lzma-devel \
        zlib-devel \
        xz-devel \
        readline-devel \
        sqlite \
        sqlite-devel \
        curl \
        tar \
        make \
        centos-release-scl && \
    yum install -y devtoolset-8 && \
    yum clean all

ARG PYTHON_VERSION=3.9.9
WORKDIR /build
# Set PATH to pickup virtualenv by default
ENV PATH=/usr/local/venv/bin:"${PATH}"
# As soon as NCSA Blue Waters is EOL and no longer needed, switch over to
# centos:8 immediatley.
RUN curl -sLO "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz" && \
    tar -xzf "Python-${PYTHON_VERSION}.tgz" && \
    cd "Python-${PYTHON_VERSION}" && \
    source scl_source enable devtoolset-8 && \
    ./configure --help && \
    ./configure --prefix=/usr/local \
        --exec_prefix=/usr/local \
        --with-ensurepip \
        --enable-shared \
        --enable-optimizations \
        --with-lto \
        --enable-ipv6 && \
    make -j"$(($(nproc) - 1))" && \
    make install && \
    printf "\n# For Python 2.7 use 'python2'\n" >> ~/.bashrc && \
    printf "# For Python 2.7 in shebangs use '#!/usr/libexec/platform-python'\n" >> ~/.bashrc && \
    printf "\nsource scl_source enable devtoolset-8\n" >> ${HOME}/.bash_profile && \
    LD_LIBRARY_PATH=/usr/local/lib python3 -m venv /usr/local/venv && \
    . /usr/local/venv/bin/activate && \
    cd / && \
    rm -rf /build
WORKDIR /

ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
# As --enable-shared is used put .so files in LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH=/usr/local/lib:"${LD_LIBRARY_PATH}"
# Make /usr/local/include/python3.8/Python.h findable by gcc
# c.f. http://gcc.gnu.org/onlinedocs/gcc-4.8.5/gcc/Environment-Variables.html#Environment-Variables
ENV C_INCLUDE_PATH=/usr/local/include/python3.8
ENV CPLUS_INCLUDE_PATH=/usr/local/include/python3.8
# Match official Python docker image environment variables
ENV PYTHON_VERSION="${PYTHON_VERSION}"
# pip version needs to be determined empirically for each CPython
# release as ENV can't be set from RUN output
ENV PYTHON_PIP_VERSION=21.1.1

ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["/bin/bash"]
