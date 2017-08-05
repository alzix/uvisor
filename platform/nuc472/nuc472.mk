###########################################################################
#
#  Copyright (c) 2016-2017, Nuvoton, All Rights Reserved
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

$(call clear_plat_cfg_vars)

PLAT_CFG_NAME:=nuc472

PLAT_CFG_ARCH_CORE:=CORE_ARMv7M
PLAT_CFG_ARCH_MPU:=MPU_ARMv7M
PLAT_CFG_MBEDOS_DIR:=nuc472
PLAT_CFG_MBEDOS_CONFIG_DIR:=TARGET_M4
PLAT_CFG_DEFINES:=-DCONFIGURATION_NUC472_CORTEX_M4_0x20000000_0x0
PLAT_CFG_FLAGS:=-mthumb -march=armv7-m

# skip compilation as uVisor does not fit into the target memory
#$(call register_uvisor_platform)
