#****************************************************************************
#* ivpm.mk
#*
#* Makefile template for a Chisel project
#****************************************************************************
SCRIPTS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
ROOT_DIR := $(abspath $(SCRIPTS_DIR)/..)
PACKAGES_DIR ?= $(ROOT_DIR)/packages

ifneq (true,$(VERBOSE))
Q=@
endif

# Must support dual modes: 
# - build dependencies if this project is the active one
# - rely on the upper-level makefile to resolve dependencies if we're not
-include $(PACKAGES_DIR)/packages.mk
include $(ROOT_DIR)/etc/ivpm.info
PROJECT := $(name)

# Include makefiles with dependencies
MK_INCLUDES += $(wildcard $(ROOT_DIR)/mkfiles/*.mk)

include $(MK_INCLUDES)

RULES := 1

ifeq (true,$(PHASE2))
build : \
	$(ROOT_DIR)/src-gen/sdram_master_bfm.d
else
build : $($(PROJECT)_deps)
	$(Q)$(MAKE) -f $(SCRIPTS_DIR)/ivpm.mk PHASE2=true VERBOSE=$(VERBOSE) build
endif

release : build
	$(Q)rm -rf $(ROOT_DIR)/build
	$(Q)mkdir -p $(ROOT_DIR)/build/$(PROJECT)
	$(Q)cp -r \
          $(ROOT_DIR)/lib \
          $(ROOT_DIR)/etc \
          $(ROOT_DIR)/build/$(PROJECT)
	$(Q)cd $(ROOT_DIR)/build ; \
		tar czf $(PROJECT)-$(version).tar.gz $(PROJECT)
	$(Q)rm -rf $(ROOT_DIR)/build/$(PROJECT)

$(ROOT_DIR)/src-gen/sdram_master_bfm.d : $(ROOT_DIR)/src/sdram_master_bfm.bid
	$(Q)$(BFM_TOOLS)/bin/bfm-tools gen-ifc -o $(ROOT_DIR)/src-gen -force \
		$(ROOT_DIR)/src/sdram_master_bfm.bid
	$(Q)touch $@

include $(MK_INCLUDES)

-include $(PACKAGES_DIR)/packages.mk
