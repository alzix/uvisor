###########################################################################
#
#  Copyright 2016 Silicon Laboratories, Inc.
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

# uVisor configurations for EFM32 devices
# The M3_P1 configuration supports:
#  - EFM32 Giant Gecko
#  - EFM32 Leopard Gecko
#  - EFM32 Jade Gecko

$(call clear_plat_cfg_vars)

PLAT_CFG_NAME:=efm32_m3

PLAT_CFG_ARCH_CORE:=CORE_ARMv7M
PLAT_CFG_ARCH_MPU:=MPU_ARMv7M

PLAT_CFG_MBEDOS_DIR:=TARGET_EFM32
PLAT_CFG_MBEDOS_CONFIG_DIR:=TARGET_M3

PLAT_CFG_DEFINES:=-DCONFIGURATION_EFM32_CORTEX_M3_P1
PLAT_CFG_FLAGS:=-mthumb -march=armv7-m

$(call register_uvisor_platform)

# The M4_P1 configuration supports:
#  - EFM32 Wonder Gecko
#  - EFM32 Pearl Gecko
$(call clear_plat_cfg_vars)

PLAT_CFG_NAME:=efm32_m4

PLAT_CFG_ARCH_CORE:=CORE_ARMv7M
PLAT_CFG_ARCH_MPU:=MPU_ARMv7M

PLAT_CFG_MBEDOS_DIR:=EFM32
PLAT_CFG_MBEDOS_CONFIG_DIR:=TARGET_M4

PLAT_CFG_DEFINES:=-DCONFIGURATION_EFM32_CORTEX_M4_P1
PLAT_CFG_FLAGS:=-mthumb -march=armv7-m

$(call register_uvisor_platform)
