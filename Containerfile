FROM docker.io/spark:4.0.1-scala2.13-java21-ubuntu

USER root
RUN ln -sf /bin/bash /bin/sh

ENV PYTHON_VERSION="3.13.9"
RUN set -ex; \
    curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh; \
    uv python install ${PYTHON_VERSION} --install-dir=/opt/python; \
    ln -s /opt/python/cpython-${PYTHON_VERSION}-* /opt/python/${PYTHON_VERSION}; \
    /opt/python/${PYTHON_VERSION}/bin/python -m pip install --upgrade pip setuptools wheel pyspark==4.0.1 pandas numpy scipy matplotlib ipykernel --break-system-packages --root-user-action=ignore; \
    /opt/python/${PYTHON_VERSION}/bin/python -m ipykernel install --name py${PYTHON_VERSION} --display-name "Python ${PYTHON_VERSION}"
ENV PATH="/opt/python/${PYTHON_VERSION}/bin:$PATH"

ENV R_VERSION="4.5.2"
ENV RSTUDIO_VERSION="2025.09.2-418"
RUN set -ex; \
    ARCH="$(dpkg --print-architecture)"; \
    curl -O https://cdn.posit.co/r/ubuntu-2204/pkgs/r-${R_VERSION}_1_${ARCH}.deb; \
    apt-get update; \
    apt-get install -y libpcre2-dev libdeflate-dev liblzma-dev libbz2-dev zlib1g-dev libzstd-dev libicu-dev libxml2-dev libcairo2-dev libgit2-dev default-libmysqlclient-dev libpq-dev libsasl2-dev libsqlite3-dev libssh2-1-dev libxtst6 libcurl4-openssl-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev unixodbc-dev xz-utils ca-certificates gdebi-core git libclang-dev libssl-dev lsb-release psmisc pwgen sudo wget; \
    apt-get install -y ./r-${R_VERSION}_1_${ARCH}.deb; \
    wget https://github.com/just-containers/s6-overlay/releases/download/v2.1.0.2/s6-overlay-${ARCH/arm/aarch}.tar.gz; \
    tar hzxf s6-overlay-${ARCH/arm/aarch}.tar.gz -C / --exclude=usr/bin/execlineb; \
    tar hzxf s6-overlay-${ARCH/arm/aarch}.tar.gz -C /usr ./bin/execlineb; \
    curl -O https://s3.amazonaws.com/rstudio-ide-build/server/jammy/${ARCH}/rstudio-server-${RSTUDIO_VERSION}-${ARCH}.deb ; \
    gdebi --non-interactive "rstudio-server-${RSTUDIO_VERSION}-${ARCH}.deb"; \ 
    rm -rf /var/lib/apt/lists/* r-${R_VERSION}_1_${ARCH}.deb s6-overlay-${ARCH/arm/aarch}.tar.gz rstudio-server-${RSTUDIO_VERSION}-${ARCH}.deb; \
    ln -s /opt/R/${R_VERSION}/bin/R /usr/local/bin/R; \
    ln -s /opt/R/${R_VERSION}/lib/R/lib/libR.so /usr/local/lib/libR.so; \
    ln -s /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript; \
    ln -s /usr/lib/rstudio-server/bin/rstudio-server /usr/local/bin/rstudio-server; \
    ln -s /usr/lib/rstudio-server/bin/rserver /usr/local/bin/rserver; \
    rm -f /var/lib/rstudio-server/secure-cookie-key; \
    mkdir -p /etc/R; \
    echo "rsession-which-r=/usr/local/bin/R" >/etc/rstudio/rserver.conf; \
    echo "lock-type=advisory" >/etc/rstudio/file-locks; \
    mkdir -p /etc/services.d/rstudio; \
    echo "#!/usr/bin/with-contenv bash" > /etc/services.d/rstudio/run; \
    echo "for line in \$( cat /etc/environment ) ; do export \$line > /dev/null; done" >> /etc/services.d/rstudio/run; \
    echo "exec /usr/lib/rstudio-server/bin/rserver --server-daemonize 0" >> /etc/services.d/rstudio/run; \
    echo "#!/bin/bash" > /etc/services.d/rstudio/finish; \
    echo "/usr/lib/rstudio-server/bin/rstudio-server stop" >> /etc/services.d/rstudio/finish; \
    echo "[*]" > /etc/rstudio/logging.conf; \
    echo "log-level=warn" >> /etc/rstudio/logging.conf; \
    echo "logger-type=syslog" >> /etc/rstudio/logging.conf; \
    echo "" > /etc/cont-init.d/01_set_env; \
    R CMD javareconf; \
    mkdir -p "/root/.config/rstudio/"; \
    echo "{\"save_workspace\": \"never\", \"always_save_history\": false, \"reuse_sessions_for_project_links\": true, \"initial_working_directory\": \"/root/results\", \"python_project_environment_automatic_activate\": false, \"posix_terminal_shell\": \"bash\", \"python_type\": \"system\", \"python_version\": \"${PYTHON_VERSION}\", \"python_path\": \"/opt/python/${PYTHON_VERSION}/bin/python\"}" > /root/.config/rstudio/rstudio-prefs.json; \
    mkdir -p "/opt/R/${R_VERSION}/lib/R/site-library"; \
    chown root:staff "/opt/R/${R_VERSION}/lib/R/site-library"; \
    chmod g+ws "/opt/R/${R_VERSION}/lib/R/site-library"; \
    git config --system credential.helper 'cache --timeout=3600'; \
    git config --system push.default simple; \
    echo "R_LIBS=\${R_LIBS-'/opt/R/${R_VERSION}/lib/R/site-library:/opt/R/${R_VERSION}/lib/R/library'}" >> "/opt/R/${R_VERSION}/lib/R/etc/Renviron.site"; \
    echo "options(repos = c(CRAN = 'https://p3m.dev/cran/__linux__/jammy/latest'), download.file.method = 'libcurl')" >> /opt/R/${R_VERSION}/lib/R/etc/Rprofile.site; \
    Rscript -e "install.packages(c('sparklyr', 'tidyverse', 'devtools', 'rmarkdown', 'BiocManager', 'vroom', 'gert', 'arrow', 'dbplyr', 'DBI', 'dtplyr', 'duckdb', 'nycflights13', 'Lahman', 'RMariaDB', 'RPostgres', 'RSQLite', 'fst', 'png', 'reticulate'))"
ENV R_HOME="/opt/R/${R_VERSION}/lib/R"
COPY /scripts/init_set_env.sh /etc/cont-init.d/01_set_env
COPY /scripts/init_userconf.sh /etc/cont-init.d/02_userconf
COPY /scripts/pam-helper.sh /usr/lib/rstudio-server/bin/pam-helper

ENV PANDOC_VERSION="3.8.2.1"
RUN set -ex; \
    ARCH="$(dpkg --print-architecture)"; \
    wget https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-1-${ARCH}.deb; \
    wget https://github.com/jgm/pandoc-templates/archive/${PANDOC_VERSION}.tar.gz; \
    apt-get update; \
    apt-get install -y ./pandoc-${PANDOC_VERSION}-1-${ARCH}.deb; \
    rm -fr /opt/pandoc/templates; \
    mkdir -p /opt/pandoc/templates; \
    tar xvf ${PANDOC_VERSION}.tar.gz; \
    cp -r pandoc-templates*/* /opt/pandoc/templates && rm -rf pandoc-templates*; \
    rm -fr /root/.pandoc; \
    mkdir /root/.pandoc && ln -s /opt/pandoc/templates /root/.pandoc/templates; \
    ln -fs /usr/lib/rstudio-server/bin/quarto/bin/quarto /usr/local/bin/quarto; \
    apt-get install -y texlive-latex-extra texlive-lang-polish texlive-science texlive-pictures texlive-lang-english texlive-lang-european texlive-fonts-extra texlive-bibtex-extra; \
    rm -rf /var/lib/apt/lists/* ./pandoc-${PANDOC_VERSION}-1-${ARCH}.deb ./${PANDOC_VERSION}.tar.gz

USER spark

