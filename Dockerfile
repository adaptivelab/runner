FROM debian:buster

ENV GITHUB_PAT ""
ENV GITHUB_OWNER ""
ENV GITHUB_REPOSITORY ""
ENV RUNNER_WORKDIR "_work"
ENV RUNNER_LABELS ""
ENV ADDITIONAL_PACKAGES ""
ENV DOCKER_VERSION "20.10.6"
ENV DOCKER_HOST ""

RUN apt-get update \
    && apt-get install -y \
        curl \
        sudo \
        git \
        jq \
        unzip \
        gnupg2 \
        gcc \
        g++ \
        make \
        procps \
        dirmngr \
        git-core \
        zlib1g-dev \
        build-essential \
        libssl-dev \
        libreadline-dev \
        libyaml-dev \
        libsqlite3-dev \
        sqlite3 \
        libxml2-dev \
        libxslt1-dev \
        libcurl4-openssl-dev \
        software-properties-common \
        libffi-dev \
        iputils-ping \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m github \
    && usermod -aG sudo github \
    && echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && curl https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz --output docker-${DOCKER_VERSION}.tgz \
    && tar xvfz docker-${DOCKER_VERSION}.tgz \
    && cp docker/* /usr/bin/

# Install azure-cli
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Ruby, Rake, Node and Yarn for Idean build tooling
RUN curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash - \
&& curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - \
&& echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list \
&& apt-get update \
&& apt-get install -y \
    nodejs \
    yarn \
&& git clone https://github.com/rbenv/rbenv.git ~/.rbenv \
&& echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc \
&& echo 'eval "$(rbenv init -)"' >> ~/.bashrc \
&& exec $SHELL \
&& git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build \
&& echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc \
&& exec $SHELL \
&& rbenv install 2.7.0 \
&& rbenv global 2.7.0 \
&& ruby -v \
&& echo "gem: --no-document" >> ~/.gemrc \
&& gem update --system \
&& gem install \
    bundler \
    rails \
    rake

USER github
WORKDIR /home/github

RUN GITHUB_RUNNER_VERSION=$(curl --silent "https://api.github.com/repos/adaptivelab/runner/releases/latest" | jq -r '.tag_name[1:]') \
    && curl -Ls https://github.com/adaptivelab/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz | tar xz \
    && sudo ./bin/installdependencies.sh

COPY --chown=github:github entrypoint.sh runsvc.sh ./
RUN sudo chmod u+x ./entrypoint.sh ./runsvc.sh

ENTRYPOINT ["/home/github/entrypoint.sh"]
