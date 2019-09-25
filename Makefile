NAME           := redmine
PACKAGER       := 'Digital-Me Infra Team <infra@digital-me.nl>'
VENDOR         := 'Digital-Me'
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

.PHONY: all check fpm rpm_fpm

all: rpm
check: rpm_check

fpm:
	yum -y install rh-ruby23-ruby-devel gcc make rpm-build rh-ruby23-rubygems;
	scl enable rh-ruby23 -- gem install --no-ri --no-rdoc fpm rake;

rpm_fpm: VERGEMS ?= $(shell scl enable rh-ruby23 -- bundle check --gemfile target/build/BUILD/redmine-$(RPM_VERSION)/Gemfile | grep " \* " | sed -r -e 's/\s\*\s([^ ]+)\s\((.+)\)/\2:\1/g')
rpm_fpm: fpm
	cp -f src/redmine-database.yml target/build/BUILD/redmine-$(RPM_VERSION)/config/database.yml;
	cd target/dists;
	echo $(shell BUNDLE_WITHOUT="test development" scl enable rh-ruby23 -- bundle check --gemfile target/build/BUILD/redmine-$(RPM_VERSION)/Gemfile | grep " \* " | sed -r -e 's/\s\*\s([^ ]+)\s\((.+)\)/\2:\1/g')
	$(foreach VERGEM,$(VERGEMS), scl enable rh-ruby23 -- fpm --input-type gem --output-type rpm --force --maintainer "$(RPM_PACKAGER)" --vendor "$(RPM_VENDOR)" --gem-package-name-prefix rh-ruby23-rubygem --iteration $(RELEASE) -v $(subst :, ,$(VERGEM);))
