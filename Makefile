###########################################################################
#
#  Copyright (c) 2013-2016, ARM Limited, All Rights Reserved
#  SPDX-License-Identifier: Apache-2.0
#
#  Licensed under the Apache License, Version 2.0 (the "License"); you may
#  not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
###########################################################################
# Toolchain
PREFIX:=arm-none-eabi-
CC:=$(PREFIX)gcc
CXX:=$(PREFIX)g++
OBJCOPY:=$(PREFIX)objcopy
OBJDUMP:=$(PREFIX)objdump
AR:=$(PREFIX)ar

# In case VERBOSE variable is defined all rules will be echoed
# This slows the compilation
ifdef VERBOSE
	NO_ECHO:=
else
	NO_ECHO:=@
endif
SHELL:=bash
# Function: return folder of a currently processed make file
# Useful for detecting platform folders.
CURR_MK_DIR = $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# Root folder
ROOT_DIR:= $(CURR_MK_DIR)
OUT_DIR:=$(ROOT_DIR)/BUILD


# DEFAULT TARGET - !!! Be careful when adding new lines above this line !!!
# Generic target - platform specific targets will be added as a dependencies 
# for these targets
.PHONY: all debug release clean fresh
all: debug release
	@echo all done

debug:
	@echo DEBUG build - done

release:
	@echo DEBUG build - done

# Clean everything.
# Note: You will lose any previously compiled library.
clean:
	$(NO_ECHO)rm -rf $(OUT_DIR)

# Same as "all", but clean first.
fresh: clean all

.PHONY: publish .verify_mbed_os_path

publish:  | .verify_mbed_os_path
	@echo publish done

.verify_mbed_os_path:
	$(NO_ECHO)if [ -z "$(MBEDOS_ROOT)" ]; then echo "MBEDOS_ROOT variable not set"; false ; fi

EMPTY:=

# Function for reseting all PLAT_CFG_* variables.
# This function should be called by platform make file prior defining
# new values in order to insure stale values will not be used
clear_plat_cfg_vars = $(foreach v,$(filter PLAT_CFG_%,$(.VARIABLES)),$(eval $(v):=$(EMPTY)))

# Function for registering current platform to uVisor build system.
# This function should be called by platform make file once all
# PLAT_CFG_* variables are defines and assigned with correct values
define register_uvisor_platform
$(eval CURR_PLATFORM_DIR:=$(CURR_MK_DIR));
$(eval FLAVOUR:=debug);
$(eval MBEDOS_BUILD_TYPE:=TARGET_DEBUG);
$(eval OPT:=-g3);
$(eval DBG_DEFS:=$(EMPTY));
$(eval $(call add_platform));
$(eval FLAVOUR:=release)
$(eval MBEDOS_BUILD_TYPE:=TARGET_RELEASE)
$(eval OPT:=-Os)
$(eval DBG_DEFS:=-DNDEBUG)
$(eval $(call add_platform))

endef

# Determine the repository version.
PROGRAM_VERSION:=$(shell git describe --tags --abbrev=4 --dirty 2>/dev/null | sed s/^v//)
ifeq ("$(PROGRAM_VERSION)","")
PROGRAM_VERSION:='unknown'
endif

# Build folder for current configuration.
# Using mbed-os like output file structure for easier artifacts exporting
# to mbed-os tree.
BUILD_DIR= $(OUT_DIR)/$(PLAT_CFG_NAME)/$(PLAT_CFG_MBEDOS_DIR)/$(MBEDOS_BUILD_TYPE)/$(PLAT_CFG_MBEDOS_CONFIG_DIR)

# Top-level folder paths
API_DIR:=$(ROOT_DIR)/api
CORE_DIR:=$(ROOT_DIR)/core
DOCS_DIR:=$(ROOT_DIR)/docs
PLATFORM_DIR:=$(ROOT_DIR)/platform
TOOLS_DIR:=$(ROOT_DIR)/tools

# Core paths
CORE_CMSIS_DIR:=$(CORE_DIR)/cmsis
CORE_DEBUG_DIR:=$(CORE_DIR)/debug
CORE_LIB_DIR:=$(CORE_DIR)/lib
CORE_LINKER_DIR:=$(CORE_DIR)/linker
CORE_SYSTEM_DIR:=$(CORE_DIR)/system
CORE_VMPU_DIR:=$(CORE_DIR)/vmpu


# Release library definitions
API_ASM_HEADER:=$(API_DIR)/src/uvisor-header.S
API_ASM_INPUT:=$(API_DIR)/src/uvisor-input.S
API_RELEASE=$(BUILD_DIR)/api/$(PLAT_CFG_NAME).a
API_VERSION=$(BUILD_DIR)/api/$(PLAT_CFG_NAME).txt
API_ASM_OUTPUT=$(BUILD_DIR)/api/uvisor-output.s

# Architecture filters.
ARCH_CORE_LOWER=$(shell echo $(PLAT_CFG_ARCH_CORE) | tr '[:upper:]' '[:lower:]')
ARCH_MPU_LOWER=$(shell echo $(PLAT_CFG_ARCH_MPU) | tr '[:upper:]' '[:lower:]')

# Release library source files directories
# Note: We assume that the all source files directories follow the src/inc
#       directory structure, including optional MPU- or core-specific folders.
API_DIRS:=\
	$(API_DIR)
API_SRC_DIRS=\
	$(foreach DIR, $(API_DIRS), $(DIR)/src) \
	$(foreach DIR, $(API_DIRS), $(DIR)/src/$(ARCH_CORE_LOWER)) \
	$(foreach DIR, $(API_DIRS), $(DIR)/src/$(ARCH_MPU_LOWER)) \
	$(foreach DIR, $(API_DIRS), $(DIR)/src/$(ARCH_CORE_LOWER)/$(ARCH_MPU_LOWER))

# Release library source files
# Note: We explicitly remove unsupported.c from the list of source files. It
#       will be compiled by the host OS in case uVisor is not supported.
API_SOURCES=$(foreach DIR, $(API_SRC_DIRS), $(filter-out $(API_DIR)/src/unsupported.c,$(wildcard $(DIR)/*.c)))

# Release library object files
API_OBJS= 	\
    $(patsubst $(ROOT_DIR)%.c, $(BUILD_DIR)%.o, $(filter %.c, $(API_SOURCES))) \
	$(API_ASM_OUTPUT:.s=.o)

# List of core libraries
# Note: One could do it in a simpler way but this prevents spurious files in
#       $(CORE_LIB_DIR) from getting picked.
CORE_LIBS:=$(notdir $(realpath $(dir $(wildcard $(CORE_LIB_DIR)/*/))))

# Core source files directories
# Change this list every time a folder is added or removed.
# Note: We assume that the all source files directories follow the src/inc
#       directory structure, including optional MPU- or core-specific folders.
CORE_DIRS=\
	$(CORE_CMSIS_DIR) \
	$(CORE_DEBUG_DIR) \
	$(foreach LIB, $(CORE_LIBS), $(CORE_LIB_DIR)/$(LIB)) \
	$(CORE_SYSTEM_DIR) \
	$(CORE_VMPU_DIR) \
	$(CURR_PLATFORM_DIR)
CORE_INC_DIRS=\
	$(foreach DIR, $(CORE_DIRS), $(DIR)/inc) \
	$(foreach DIR, $(CORE_DIRS), $(DIR)/inc/$(ARCH_CORE_LOWER)) \
	$(foreach DIR, $(CORE_DIRS), $(DIR)/inc/$(ARCH_MPU_LOWER)) \
	$(foreach DIR, $(CORE_DIRS), $(DIR)/inc/$(ARCH_CORE_LOWER)/$(ARCH_MPU_LOWER))
CORE_SRC_DIRS=\
	$(foreach DIR, $(CORE_DIRS), $(DIR)/src) \
	$(foreach DIR, $(CORE_DIRS), $(DIR)/src/$(ARCH_CORE_LOWER)) \
	$(foreach DIR, $(CORE_DIRS), $(DIR)/src/$(ARCH_MPU_LOWER)) \
	$(foreach DIR, $(CORE_DIRS), $(DIR)/src/$(ARCH_CORE_LOWER)/$(ARCH_MPU_LOWER))

# Core source files
CORE_SOURCES=$(foreach DIR, $(CORE_SRC_DIRS), $(wildcard $(DIR)/*.c))

# Core object files
CORE_OBJS=$(patsubst $(ROOT_DIR)%.c, $(BUILD_DIR)%.o, $(filter %.c, $(CORE_SOURCES)))

SYSLIBS:=-lgcc -lc -lnosys
WARNING:=-Wall -Wstrict-overflow=3 -Werror


UVISOR_BIN=$(BUILD_DIR)/$(PLAT_CFG_NAME).bin

LDFLAGS=\
        $(PLAT_CFG_FLAGS) \
        -T$(UVISOR_BIN:.bin=.linker) \
        -nostartfiles \
        -nostdlib \
        -Xlinker --gc-sections \
        -Xlinker -M \
        -Xlinker -Map=$(UVISOR_BIN:.bin=.map)

CFLAGS_PRE=\
        $(OPT) \
		$(DBG_DEFS)\
        $(WARNING) \
        -DUVISOR_PRESENT=1 \
        -DUVISOR_CORE_BUILD=1 \
        -DARCH_$(PLAT_CFG_ARCH_CORE) \
        -DARCH_$(PLAT_CFG_ARCH_MPU) \
        $(PLAT_CFG_DEFINES) \
        -I$(ROOT_DIR) \
        -I$(CORE_DIR) \
        $(addprefix -I,$(CORE_INC_DIRS)) \
        -ffunction-sections \
        -fdata-sections

CFLAGS=$(PLAT_CFG_FLAGS) $(CFLAGS_PRE)

CXXFLAGS:=-fno-exceptions

LINKER_CONFIG=\
    -DARCH_$(PLAT_CFG_ARCH_CORE) \
    -DARCH_$(PLAT_CFG_ARCH_MPU) \
    $(PLAT_CFG_DEFINES) \
    -I$(CURR_PLATFORM_DIR)/inc \
    -include $(CORE_DIR)/uvisor-config.h

API_CONFIG=\
    -DUVISOR_BIN=\"$(UVISOR_BIN)\" \
    $(PLAT_CFG_DEFINES) \
    -I$(CURR_PLATFORM_DIR)/inc \
    -include $(CORE_DIR)/uvisor-config.h



# publish_%:
# 	echo "publishing"


define add_platform

# Generate the pre-linked uVisor binary for the given platform, configuration
# and build mode.
# The binary is then packaged with the uVisor library implementations into a
# unique .a file.
$(API_RELEASE): $(API_OBJS)
	$(NO_ECHO)echo [$(PLAT_CFG_NAME):$(FLAVOUR)] Archiving $(API_RELEASE)
	$(NO_ECHO)$(AR) Dcr $(API_RELEASE) $(API_OBJS)
	$(NO_ECHO)echo "$(PROGRAM_VERSION)" > $(API_VERSION)

# Copy the core ELF file into a binary.
$(UVISOR_BIN): $(UVISOR_BIN:.bin=.elf)
	$(NO_ECHO)echo [$(PLAT_CFG_NAME):$(FLAVOUR)] Generating Flat Binary $$(notdir $$@)
	$(NO_ECHO)$(OBJCOPY) $$< -O binary $$@

# Link all the core object files into the core ELF.
$(UVISOR_BIN:.bin=.elf): $(CORE_OBJS) $(UVISOR_BIN:.bin=.linker)
	$(NO_ECHO)echo [$(PLAT_CFG_NAME):$(FLAVOUR)] Linking $$(notdir $$@)
	$(NO_ECHO)$(CC) $(LDFLAGS) -o $$@ $(CORE_OBJS) $(SYSLIBS)
	$(NO_ECHO)$(OBJDUMP) -d $$@ > $(UVISOR_BIN:.bin=.asm)

# Pre-process the core linker script.
$(UVISOR_BIN:.bin=.linker): $(CORE_LINKER_DIR)/default.h $(CORE_DIR)/uvisor-config.h
	$(NO_ECHO)echo [$(PLAT_CFG_NAME):$(FLAVOUR)] Generating Linker Script $$(notdir $$@)
	$(NO_ECHO)$(CPP) -w -P $(DBG_DEFS) $(LINKER_CONFIG) $$< -o $$@

# Pre-process and compile a core C file into an object file.
$(BUILD_DIR)/%.o: $(ROOT_DIR)/%.c
	$(NO_ECHO)echo [$(PLAT_CFG_NAME):$(FLAVOUR)] Compiling $$(notdir $$<)
	$(NO_ECHO)mkdir -p $$(dir $$@)
	$(NO_ECHO)$(CC) $(CFLAGS) -c $$< -o $$@

# Generate the output asm file from the asm input file and the INCBIN'ed binary.
$(API_ASM_OUTPUT:.s=.o): $(UVISOR_BIN) $(API_ASM_INPUT)
	$(NO_ECHO)echo [$(PLAT_CFG_NAME):$(FLAVOUR)] Compiling $$(notdir $(API_ASM_OUTPUT))
	$(NO_ECHO)cp $(API_ASM_HEADER) $(API_ASM_OUTPUT)
	$(NO_ECHO)$(CPP) -w -P $(API_CONFIG) $(API_ASM_INPUT) >> $(API_ASM_OUTPUT)
	$(NO_ECHO)$(CC) $(CFLAGS) -c $(API_ASM_OUTPUT) -o $$@

.PHONY: publish_$(PLAT_CFG_NAME)_$(FLAVOUR) $(PLAT_CFG_NAME)_$(FLAVOUR)

$(FLAVOUR): $(PLAT_CFG_NAME)_$(FLAVOUR)

$(PLAT_CFG_NAME)_$(FLAVOUR): $(UVISOR_BIN)

publish: publish_$(PLAT_CFG_NAME)_$(FLAVOUR)

publish_$(PLAT_CFG_NAME)_$(FLAVOUR): $(PLAT_CFG_NAME)_$(FLAVOUR)

endef

# Include supported platforms.
# Including a platform will trigger the mechanism for adding
# the platform to a dependency graph.
CONFIG_FILES:=$(wildcard $(PLATFORM_DIR)/*/*.mk)
include $(CONFIG_FILES)
#include /home/uvisor/dev/uvisor/platform/kinetis/kinetis.mk
