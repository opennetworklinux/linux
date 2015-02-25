############################################################
# <bsn.cl fy=2015 v=onl>
#
#           Copyright 2015 Big Switch Networks, Inc.
#
# Licensed under the Eclipse Public License, Version 1.0 (the
# "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
#
#        http://www.eclipse.org/legal/epl-v10.html
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific
# language governing permissions and limitations under the
# License.
#
# </bsn.cl>
############################################################
#
# Prepare and build a kernel.
#
############################################################

#
# The kernel patchlevel.
#
ifndef K_PATCH_LEVEL
$(error $$K_PATCH_LEVEL must be set)
endif

#
# The kernel sublevel
#
ifndef K_SUB_LEVEL
$(error $$K_SUB_LEVEL must be set)
endif

#
# The directory containing the patches to be applied
# to the kernel sources.
#
ifndef K_PATCH_DIR
$(error $$K_PATCH_DIR must be set)
endif

#
# This is the directory that will receive the build targets.
# The kernel build tree is placed in this directory,
# as well as any custom copy targets.
#
ifndef K_TARGET_DIR
$(error $$K_TARGET_DIR not set)
endif

#
# This is the absolute path to the kernel configuration
# that should be used for this build.
#
ifndef K_CONFIG
$(error $$K_CONFIG not set)
endif

#
# This is the build target. bzImage, uImage, etc.
#
ifndef K_BUILD_TARGET
$(error $$K_BUILD_TARGET not set)
endif

############################################################
############################################################

K_VERSION := 3.$(K_PATCH_LEVEL).$(K_SUB_LEVEL)
K_NAME := linux-$(K_VERSION)
K_ARCHIVE_NAME := $(K_NAME).tar.xz
K_ARCHIVE_PATH := $(ONLL)/archives/$(K_ARCHIVE_NAME)
K_ARCHIVE_URL := https://www.kernel.org/pub/linux/kernel/v3.x/$(K_ARCHIVE_NAME)
K_SOURCE_DIR := $(K_TARGET_DIR)/$(K_NAME)
K_MBUILD_DIR := $(K_SOURCE_DIR)-mbuild

#
# The kernel source archive. Download if not present.
#
$(K_ARCHIVE_PATH):
	cd $(ONLL)/archives && wget $(K_ARCHIVE_URL)


.PHONY : ksource kpatched

#
# The extracted kernel sources
#
$(K_SOURCE_DIR)/Makefile: $(K_ARCHIVE_PATH)
	cd $(K_TARGET_DIR) && tar kxf $(K_ARCHIVE_PATH)
	touch -c $(K_SOURCE_DIR)/Makefile
	$(K_MAKE) mrproper

ksource: $(K_SOURCE_DIR)/Makefile

#
# The patched kernel sources
#
$(K_SOURCE_DIR)/.PATCHED: $(K_SOURCE_DIR)/Makefile
	$(ONLL_TOOLS)/apply-patches.sh $(K_SOURCE_DIR) $(K_PATCH_DIR)
	touch $(K_SOURCE_DIR)/.PATCHED

kpatched: $(K_SOURCE_DIR)/.PATCHED

#
# Setup the kernel and output directory for the build.
#
setup: $(K_SOURCE_DIR)/.PATCHED
	cp $(K_CONFIG) $(K_SOURCE_DIR)/.config

#
# Kernel build command.
#
K_MAKE    := $(MAKE) -C $(K_SOURCE_DIR)

#
# Build the kernel.
#
build: setup
	$(K_MAKE) $(K_BUILD_TARGET)
ifdef K_COPY_SRC
ifdef K_COPY_DST
	cp $(K_SOURCE_DIR)/$(K_COPY_SRC) $(K_TARGET_DIR)/$(K_COPY_DST)
endif
endif


MODSYNCLIST := .config Module.symvers Makefile include scripts arch/x86/include arch/x86/Makefile
mbuild: build
	rm -rf $(K_MBUILD_DIR)
	mkdir -p $(K_MBUILD_DIR)
	$(foreach f,$(MODSYNCLIST),$(ONLL_TOOLS)/sync.sh $(K_SOURCE_DIR) $(f) $(K_MBUILD_DIR);)



all: modheaders

#
# This target can be used to manage the configuration file.
#
configure: setup
	$(K_MAKE) menuconfig
	cp $(K_SOURCE_DIR)/.config $(K_CONFIG)


.DEFAULT_GOAL := mbuild



