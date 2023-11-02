FROM almalinux:9

# Reference: https://github.com/hadolint/hadolint/wiki/DL4006

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Configure the build.

ARG PY_EXE=python3.9
ARG PY_PKG=python3
ARG TINI_ARCH=amd64
ARG TINI_VERSION=v0.19.0
ARG WEB_UID=1001
ARG WEB_USER=web
ARG WEB_GID=1001
ARG WEB_GROUP=web

# Configure the environment.

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV WEB_UID=${WEB_UID}
ENV WEB_USER=${WEB_USER}
ENV WEB_GID=${WEB_GID}
ENV WEB_GROUP=${WEB_GROUP}

# Install essential packages and utilities.

USER root
WORKDIR /tmp
RUN true \
    && dnf update -y \
    && dnf install -y --allowerasing \
        ca-certificates \
        curl \
        glibc-langpack-en \
        procps \
        ${PY_PKG}-pip \
    && dnf clean all \
    && rm -rf /var/cache/dnf/* \
    #
    && curl -fsSL -o /usr/local/sbin/tini "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-${TINI_ARCH}" \
    && chmod u=rwx,go=rx /usr/local/sbin/tini \
    && ${PY_EXE} -m pip install -U --no-cache-dir pip setuptools wheel \
    #
    && groupadd -r -g "${WEB_GID}" "${WEB_GROUP}" \
    && useradd -r -g "${WEB_GROUP}" -u "${WEB_UID}" -d / -s /usr/sbin/nologin -c "System user for the web server" "${WEB_USER}" \
    && true

# Install the FastAPI application.

COPY poetry.lock pyproject.toml requirements.txt /srv/
RUN ${PY_EXE} -m pip install --no-cache-dir -r /srv/requirements.txt

COPY app /srv/app/

# Configure container startup.

USER ${WEB_UID}:${WEB_GID}
WORKDIR /srv
ENTRYPOINT ["/usr/local/sbin/tini", "-g", "--"]
CMD ["uvicorn", "--host", "0.0.0.0", "--port", "8080", "app.main:app"]
