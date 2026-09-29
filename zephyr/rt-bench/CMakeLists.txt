# SPDX-License-Identifier: GPL-2.0
cmake_minimum_required(VERSION 3.20.0)
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(rt_bench)

target_sources(app PRIVATE src/main.c)

# Zephyr has no inmate command line: override the defaults at build time,
# e.g. -DRTB_WS_KB=512 (see scripts/build_zephyr.sh).
foreach(p PERIOD_US WINDOW WS_KB LOADS DEADLINE_US)
  if(DEFINED RTB_${p})
    target_compile_definitions(app PRIVATE RTB_${p}=${RTB_${p}})
  endif()
endforeach()
