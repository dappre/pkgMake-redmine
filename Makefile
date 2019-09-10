NAME           := redmine
PACKAGER       := 'Digital-Me Infra Team <infra@digital-me.nl>'
TARGET_DIR     := $(abspath target)
DISTS_DIR      := $(TARGET_DIR)/dists

RPM_NAME        = $(NAME)
RPM_VERSION     = $(VERSION)
RPM_RELEASE     = $(RELEASE)
RPM_PACKAGER    = $(PACKAGER)
RPM_VENDOR      = $(VENDOR)
RPM_TARGET_DIR  = $(TARGET_DIR)
RPM_DISTS_DIR   = $(DISTS_DIR)
RPM_DEBUGINFO   = 0

include rpmMake/Makefile

.PHONY: all scl fpm rpm_fpm

all: rpm

scl:
	yum -y install centos-release-scl;
	rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo;

rpm_pre: scl

fpm: scl
	yum -y install rh-ruby23-ruby-devel gcc make rpm-build rubygems;
	scl enable rh-ruby23 -- gem install --no-ri --no-rdoc fpm rake;

rpm_fpm: VERGEMS ?= $(shell scl enable rh-ruby23 -- bundle check --gemfile target/build/BUILD/redmine-$(RPM_VERSION)/Gemfile | grep " \* " | sed -r -e 's/\s\*\s([^ ]+)\s\((.+)\)/\2:\1/g')
rpm_fpm: fpm
	cp -f src/redmine-database.yml target/build/BUILD/redmine-$(RPM_VERSION)/config/database.yml;
	cd target/dists;
	echo $(shell BUNDLE_WITH=ldap scl enable rh-ruby23 -- bundle check --gemfile target/build/BUILD/redmine-$(RPM_VERSION)/Gemfile | grep " \* " | sed -r -e 's/\s\*\s([^ ]+)\s\((.+)\)/\2:\1/g')
	$(foreach VERGEM,$(VERGEMS), scl enable rh-ruby23 -- fpm --input-type gem --output-type rpm --force --maintainer "$(RPM_PACKAGER)" --vendor "$(RPM_VENDOR)" --gem-package-name-prefix rh-ruby23-rubygem --iteration $(RELEASE) -v $(subst :, ,$(VERGEM);))
