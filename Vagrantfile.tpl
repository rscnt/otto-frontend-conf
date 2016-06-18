# coding: utf-8

# Vagrant file used by otto.
# From Docs: The Vagrantfile is rendered as an otto template, which uses jinja2.
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.box_check_update = false
  config.vm.hostname = "storyboardshare.box"
  config.vm.provision "shell", inline: $sytem_script
  config.vm.provision "shell", inline: $user_script, privileged: false

  config.vm.synced_folder '{{ path.working }}', "/home/vagrant/storyboardShare",
                          owner: "vagrant", group: "vagrant"

  config.ssh.forward_agent = true
  config.vm.network "private_network", ip: "{{ dev_ip_address }}"

  config.vm.provider "virtualbox" do |p|
    p.linked_clone = true
  end

  config.vm.provider :virtualbox do |vb|
    vb.customize [
      "modifyvm", :id,
      "--cpuexecutioncap", "50",
      "--memory", "1024",
    ]
  end
end

$user_script = <<SCRIPT
set -e

# rbenv - ruby

export RBENV_PATH=$HOME/.rbenv
export RBENV_BUILD_PATH=$HOME/.rbenv/plugins/ruby-build


if [ ! -d "$RBENV_PATH" ]; then
  git clone https://github.com/rbenv/rbenv.git $RBENV_PATH
fi

if [ ! -d "$RBENV_BUILD_PATH" ]; then
  git clone https://github.com/rbenv/ruby-build.git $RBENV_BUILD_PATH
fi

cd $RBENV_PATH && src/configure && make -C src;

echo 'export PATH="$RBENV_PATH/bin:$PATH"' >>  $HOME/.profile
echo 'eval $(rbenv init -)' >> $HOME/.profile

export PATH="$RBENV_PATH/bin:$PATH"

export CONFIGURE_OPTS="--disable-install-doc"

echo 'gem: --no-rdoc --no-ri' >> $HOME/.gemrc

eval "$($RBENV_PATH/bin/rbenv init -)"

if [ ! -d "$RBENV_PATH/versions/2.3.1" ]; then
  rbenv install	2.3.1
fi

rbenv global 2.3.1

rbenv rehash

gem install compass bundler

# nvm - node

export NVM_DIR=$HOME/.nvm

if [ ! -d "$NVM_DIR" ]; then
  git clone https://github.com/creationix/nvm.git $NVM_DIR
fi

echo 'export NVM_DIR="$HOME/.nvm"' >>  $HOME/.profile
echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' >> $HOME/.profile

. $NVM_DIR/nvm.sh

nvm install stable

nvm use stable

nvm alias default stable

echo "stable" >> $HOME/.nvmrc

npm install -g grunt-cli bower yo generator-karma generator-angular

cd $HOME/storyboardShare
npm install

rm -rf bower_components

bower install --verbose --force

SCRIPT

$sytem_script = <<SCRIPT
#!/usr/bin/env bash
set -e

apt-get update

apt-get -y install \
  build-essential \
  curl \
  python \
  postgresql \
  nginx \
  git \
  libffi-dev \
  libssl-dev \
  libreadline-dev \
  zlib1g-dev \
  libyaml-dev \
  libxml2-dev \
  libxslt-dev

locale-gen "en_US.UTF-8"

dpkg-reconfigure locales 

export 'LC_ALL=en_US.UTF-8' >> /etc/environment
export 'LANG=en_US.UTF-8' >> /etc/environment

SCRIPT