#!/usr/bin/env bash
############################################################################
#
# SPDX-License-Identifier: Apache-2.0
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.  The
# ASF licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations
# under the License.
#
############################################################################

# MSYS2
# (Always use the MSYS2 shell launcher ->  C:\msys64\msys2.exe)

set -e
set -o xtrace

CIWORKSPACE=$(cd "$(dirname "$0")" && pwd)
NUTTXTOOLS=${CIWORKSPACE}/win-tools

add_path() {
  PATH=$1:${PATH}
}

# Calculate hash value of passed file
check_hash() {

publishedHash=$1
filetocheck=$2

  if [[ -z $publishedHash && -z $filetocheck ]]; then
    echo "ERROR: invalid number of arguments passed"
    exit 1
  fi

  if [ ! -f $filetocheck ]; then
    echo "ERROR: file '${filetocheck}' does not exist"
    exit 1
  fi

  hash_algo_cmd="shasum -a 256"
  calc_hash=$(${hash_algo_cmd} "${filetocheck}" | cut -d' ' -f1)

  if [ "${publishedHash}" == "${calc_hash}" ]; then
    echo "File verification successful"
  else
    echo "File ${filetocheck} verification failed"
    rm -rf "${filetocheck}"
    exit 1
  fi
}

busybox_tool() {
  add_path "${NUTTXTOOLS}"

  if ! type busybox > /dev/null 2>&1; then
    local basefile
    local publishedHash
    local toolname

    # 2025-02-28
    basefile=FRP-5579-g5749feb35
    publishedHash="1255109d6335adf8374888f9c9fc70221f098cb6bf03f183e710e71179ecad78"
    toolname=busybox.exe

    cd "${NUTTXTOOLS}"
    # Download the latest busybox64 prebuilt by frippery.org
    curl -L https://frippery.org/files/busybox/busybox-w64-${basefile}.exe -o "${NUTTXTOOLS}/${toolname}"

    # Verify file integrity
    check_hash "${publishedHash}" "${NUTTXTOOLS}/${toolname}"
  fi
  
  busybox --list
}

install_build_tools() {

  if [ ! -d "${NUTTXTOOLS}" ]; then
     mkdir -p "${NUTTXTOOLS}"
  else
     rm -rf "${NUTTXTOOLS}"
     mkdir -p "${NUTTXTOOLS}"
  fi

  install="basename cat cmp cp cut echo expr find grep install ls mv patch printf pwd rm sed seq sha256sum sha3sum sha512sum sort test touch tr uniq unzip xxd yes"

  oldpath=$(cd . && pwd -P)
  
  busybox_tool
  
  for func in ${install}; do
    cp -pfv ${NUTTXTOOLS}/busybox.exe ${NUTTXTOOLS}/${func}.exe
  done

  cd "${oldpath}"
}

install_build_tools
