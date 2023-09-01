FROM flyio/postgres-flex:15.3

RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates curl bash dnsutils vim-tiny procps jq haproxy git \
    bison build-essential flex postgresql-server-dev-all locales \
    && apt autoremove -y

ENV LANG=en_US.UTF-8
ENV LC_COLLATE=en_US.UTF-8
ENV LC_CTYPE=en_US.UTF-8

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8

# Set the pgage version
ARG PGAGE_VERSION_A='PG15'
ARG PGAGE_VERSION_B='v1.4.0-rc0'

# Download and extract the age release, build the extension, and install it
RUN curl -L -o age.tar.gz "https://github.com/apache/age/archive/refs/tags/${PGAGE_VERSION_A}/${PGAGE_VERSION_B}.tar.gz" && \
    tar -xzf age.tar.gz && \
    cd "age-${PGAGE_VERSION_A}-${PGAGE_VERSION_B}" && \
    make && \
    make install

# Set the pgvector version
ARG PGVECTOR_VERSION=0.4.1

# Download and extract the pgvector release, build the extension, and install it
RUN curl -L -o pgvector.tar.gz "https://github.com/ankane/pgvector/archive/refs/tags/v${PGVECTOR_VERSION}.tar.gz" && \
    tar -xzf pgvector.tar.gz && \
    cd "pgvector-${PGVECTOR_VERSION}" && \
    make && \
    make install

# Clean up build dependencies and temporary files
RUN apt-get remove -y build-essential curl postgresql-server-dev-all && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /pgvector.tar.gz /pgvector-${PGVECTOR_VERSION}