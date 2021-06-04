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
        make && \
    yum clean all

ARG PYTHON_VERSION=3.8.10
WORKDIR /build
# Ensure that python means python3 even in non-interactive sessions through
# aliases and symbolic links
# N.B.:
# shebang manipulation is a bad thing to do in general and this is ONLY being
# done to ensure that non-interatice sessions don't cause unintended bugs.
# As soon as NCSA Blue Waters is EOL and no longer needed, switch over to
# centos:8 immediatley.
# The grep bit at the end:
# * Finds all matches under /usr/bin that contain #!/usr/bin/python
# * Ignores all matches with python3 or python2.7
# * Strips out just the filename
# * Passes those filenames to sed to replace the shebang with #!/usr/libexec/platform-python
RUN curl -sLO "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz" && \
    tar -xzf "Python-${PYTHON_VERSION}.tgz" && \
    cd "Python-${PYTHON_VERSION}" && \
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
    printf "\nalias python='python3'\n" >> ~/.bashrc && \
    printf "# For Python 2.7 use 'python2'\n" >> ~/.bashrc && \
    printf "# For Python 2.7 in shebangs use '#!/usr/libexec/platform-python'\n" >> ~/.bashrc && \
    ln --symbolic "$(command -v python3)" /usr/local/bin/python && \
    ln --symbolic "$(command -v pip3)" /usr/local/bin/pip && \
    cd / && \
    rm -rf /build && \
    grep --recursive '#!/usr/bin/python' /usr/bin/ \
        | grep --invert-match 'python3\|python2.7' \
        | sed 's/:.*$//' \
        | xargs sed --in-place 's|#!/usr/bin/python|#!/usr/libexec/platform-python|g' && \
    grep --recursive '#!' /usr/libexec/ \
        | grep "python" \
        | sed 's/:.*$//' \
        | xargs sed --in-place 's|/usr/bin/python|/usr/libexec/platform-python|g'
WORKDIR /

ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
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
