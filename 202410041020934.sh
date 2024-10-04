#!/bin/bash

set -eo pipefail


for cmd in ip ipmitool ping grep cut head tr
do
  if ! command -v $cmd >/dev/null 2>&1; then
    printf "[+] Need Command: %s \n" "${cmd}"
    exit 1
  fi
done


: "${TARGET:=$1}"
: "${IPMI:=ipmitool}"
: "${IPMI_ARGS=-I lanplus -U Administrator -P Admin@9000 -C 17}"

FRU_FILE="fru_${TARGET//./-}.txt"
${IPMI} ${IPMI_ARGS} -H "${TARGET}" fru print > "${FRU_FILE}"

# Board Product Name: GDATCJB-L20Y
_PN_PAYLOAD="0x0C 0x47 0x44 0x41 0x54 0x43 0x4A 0x42 0x2D 0x4C 0x32 0x30 0x59"
function update::board::product_name {
  printf 'Update [Board Product Name]'
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x04 0x00 0x02 0x02 0x00 ${_PN_PAYLOAD}
}


function update::product_name {
  printf 'Update [Product Name]'
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x04 0x02 0x03 0x01 0x00 ${_PN_PAYLOAD}
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x04 0x00 0x06 0x01 0x00 ${_PN_PAYLOAD}
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x04 0x00 0x03 0x01 0x00 ${_PN_PAYLOAD}
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x06 0x02 0xAA
}


# Board Serial Number: caesar(sn)
function update::board::serial_number {
  printf 'Update [Board Serial Number]'
  _OLD_BSN=$(grep 'Board Serial' "${FRU_FILE}" | cut -d ':' -f 2 | head -n 1 | tr -d '[:space:]')
  case ${_OLD_BSN} in
    "02Y"*)
      _NEW_BSN=$(echo -n ${_OLD_BSN} | rev)
    ;;
    *)
      _NEW_BSN=${_OLD_BSN}
    ;;
  esac
  _BSN_PAYLOAD=$(echo -n ${_NEW_BSN} | hexdump -ve '1/1 "0x%02x "')
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x04 0x00 0x02 0x03 0x00 0x10 ${_BSN_PAYLOAD}
}

# Board Part Number: GDATCJB-L20Y
function update::board::part_number {
  printf 'Upadte [Board Part Number]'
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x04 0x00 0x02 0x04 0x00 ${_PN_PAYLOAD}
}


# Board Mfg
function update::board::mfg {
  printf 'Update [Board Mfg]'
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x04 0x02 0x02 0x01 0x00 ${_PN_PAYLOAD}
}


# Product PartModel Number: GDATCJB-L20Y
function update::product::partmodel_number {
  printf 'Update [Product PartModel Number]'
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x04 0x00 0x03 0x02 0x00 ${_PN_PAYLOAD}
}


# Product Serial: caesar(sn)
function update::product::serial_number {
  printf 'Update [Product Serial]'
  _OLD_PSN=$(grep 'Product Serial'  "${FRU_FILE}"| cut -d ':' -f 2 | head -n 1 | tr -d '[:space:]')
  case ${_OLD_PSN} in
    "210619"*)
      _NEW_PSN=$(echo -n ${_OLD_PSN} | rev)
    ;;
    *)
      _NEW_PSN=${_OLD_PSN}
    ;;
  esac
  _PSN_PAYLOAD=$(echo -n ${_NEW_PSN} | hexdump -ve '1/1 "0x%02x "')
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x04 0x00 0x03 0x04 0x00 0x14 ${_PSN_PAYLOAD}
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x04 0x00 0x06 0x03 0x00 0x14 ${_PSN_PAYLOAD}
}


# Chassis Part Number
function update::chassis::part_number {
  printf 'Update [Chassis Part Number]'
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x04 0x00 0x01 0x01 0x00 0x14 0x51 0x47 0x38 0x38 0x4e 0x34 0x4d 0x31 0x56 0x31 0x54 0x31 0x4e 0x32 0x38 0x2e 0x30 0x58 0x5a 0x42
}

# Board Extra
function update::board::extra {
  printf 'Update [Board Extra]'
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x04 0x00 0x05 0x00 0x00 0x92 0x44 0x65 0x73 0x63 0x72 0x69 0x70 0x74 0x69 0x6F 0x6E 0x3D 0x52 0x61 0x63 0x6B 0x20 0x53 0x65 0x72 0x76 0x65 0x72 0x20 0x43 0x6F 0x6D 0x70 0x6C 0x65 0x74 0x65 0x20 0x41 0x70 0x70 0x6C 0x69 0x61 0x6E 0x63 0x65 0x2C 0x47 0x44 0x41 0x54 0x43 0x4A 0x42 0x2D 0x4C 0x32 0x30 0x59 0x28 0x32 0x2A 0x39 0x30 0x30 0x57 0x2C 0x32 0x2A 0x34 0x33 0x31 0x34 0x2C 0x36 0x2A 0x33 0x32 0x47 0x42 0x2C 0x32 0x2A 0x31 0x32 0x30 0x30 0x47 0x42 0x2D 0x53 0x41 0x53 0x2C 0x36 0x2A 0x39 0x36 0x30 0x47 0x42 0x2D 0x53 0x41 0x54 0x41 0x2C 0x31 0x2A 0x58 0x52 0x34 0x35 0x30 0x43 0x2D 0x4D 0x58 0x2C 0x31 0x2A 0x58 0x50 0x33 0x38 0x30 0x2C 0x31 0x2A 0x58 0x50 0x33 0x38 0x30 0x29 0x2C 0x48 0x31 0x32 0x48 0x2D 0x30 0x36 0x2D 0x30 0x38 0x34 0x30 0x31 0x37
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x04 0x01 0x05 0x00 0x00 0x92 0x44 0x65 0x73 0x63 0x72 0x69 0x70 0x74 0x69 0x6F 0x6E 0x3D 0x52 0x61 0x63 0x6B 0x20 0x53 0x65 0x72 0x76 0x65 0x72 0x20 0x43 0x6F 0x6D 0x70 0x6C 0x65 0x74 0x65 0x20 0x41 0x70 0x70 0x6C 0x69 0x61 0x6E 0x63 0x65 0x2C 0x47 0x44 0x41 0x54 0x43 0x4A 0x42 0x2D 0x4C 0x32 0x30 0x59 0x28 0x32 0x2A 0x39 0x30 0x30 0x57 0x2C 0x32 0x2A 0x34 0x33 0x31 0x34 0x2C 0x36 0x2A 0x33 0x32 0x47 0x42 0x2C 0x32 0x2A 0x31 0x32 0x30 0x30 0x47 0x42 0x2D 0x53 0x41 0x53 0x2C 0x36 0x2A 0x39 0x36 0x30 0x47 0x42 0x2D 0x53 0x41 0x54 0x41 0x2C 0x31 0x2A 0x58 0x52 0x34 0x35 0x30 0x43 0x2D 0x4D 0x58 0x2C 0x31 0x2A 0x58 0x50 0x33 0x38 0x30 0x2C 0x31 0x2A 0x58 0x50 0x33 0x38 0x30 0x29 0x2C 0x48 0x31 0x32 0x48 0x2D 0x30 0x36 0x2D 0x30 0x38 0x34 0x30 0x31 0x37
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x04 0x02 0x05 0x00 0x00 0x92 0x44 0x65 0x73 0x63 0x72 0x69 0x70 0x74 0x69 0x6F 0x6E 0x3D 0x52 0x61 0x63 0x6B 0x20 0x53 0x65 0x72 0x76 0x65 0x72 0x20 0x43 0x6F 0x6D 0x70 0x6C 0x65 0x74 0x65 0x20 0x41 0x70 0x70 0x6C 0x69 0x61 0x6E 0x63 0x65 0x2C 0x47 0x44 0x41 0x54 0x43 0x4A 0x42 0x2D 0x4C 0x32 0x30 0x59 0x28 0x32 0x2A 0x39 0x30 0x30 0x57 0x2C 0x32 0x2A 0x34 0x33 0x31 0x34 0x2C 0x36 0x2A 0x33 0x32 0x47 0x42 0x2C 0x32 0x2A 0x31 0x32 0x30 0x30 0x47 0x42 0x2D 0x53 0x41 0x53 0x2C 0x36 0x2A 0x39 0x36 0x30 0x47 0x42 0x2D 0x53 0x41 0x54 0x41 0x2C 0x31 0x2A 0x58 0x52 0x34 0x35 0x30 0x43 0x2D 0x4D 0x58 0x2C 0x31 0x2A 0x58 0x50 0x33 0x38 0x30 0x2C 0x31 0x2A 0x58 0x50 0x33 0x38 0x30 0x29 0x2C 0x48 0x31 0x32 0x48 0x2D 0x30 0x36 0x2D 0x30 0x38 0x34 0x30 0x31 0x37
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x04 0x03 0x05 0x00 0x00 0x92 0x44 0x65 0x73 0x63 0x72 0x69 0x70 0x74 0x69 0x6F 0x6E 0x3D 0x52 0x61 0x63 0x6B 0x20 0x53 0x65 0x72 0x76 0x65 0x72 0x20 0x43 0x6F 0x6D 0x70 0x6C 0x65 0x74 0x65 0x20 0x41 0x70 0x70 0x6C 0x69 0x61 0x6E 0x63 0x65 0x2C 0x47 0x44 0x41 0x54 0x43 0x4A 0x42 0x2D 0x4C 0x32 0x30 0x59 0x28 0x32 0x2A 0x39 0x30 0x30 0x57 0x2C 0x32 0x2A 0x34 0x33 0x31 0x34 0x2C 0x36 0x2A 0x33 0x32 0x47 0x42 0x2C 0x32 0x2A 0x31 0x32 0x30 0x30 0x47 0x42 0x2D 0x53 0x41 0x53 0x2C 0x36 0x2A 0x39 0x36 0x30 0x47 0x42 0x2D 0x53 0x41 0x54 0x41 0x2C 0x31 0x2A 0x58 0x52 0x34 0x35 0x30 0x43 0x2D 0x4D 0x58 0x2C 0x31 0x2A 0x58 0x50 0x33 0x38 0x30 0x2C 0x31 0x2A 0x58 0x50 0x33 0x38 0x30 0x29 0x2C 0x48 0x31 0x32 0x48 0x2D 0x30 0x36 0x2D 0x30 0x38 0x34 0x30 0x31 0x37
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x04 0x04 0x05 0x00 0x00 0x92 0x44 0x65 0x73 0x63 0x72 0x69 0x70 0x74 0x69 0x6F 0x6E 0x3D 0x52 0x61 0x63 0x6B 0x20 0x53 0x65 0x72 0x76 0x65 0x72 0x20 0x43 0x6F 0x6D 0x70 0x6C 0x65 0x74 0x65 0x20 0x41 0x70 0x70 0x6C 0x69 0x61 0x6E 0x63 0x65 0x2C 0x47 0x44 0x41 0x54 0x43 0x4A 0x42 0x2D 0x4C 0x32 0x30 0x59 0x28 0x32 0x2A 0x39 0x30 0x30 0x57 0x2C 0x32 0x2A 0x34 0x33 0x31 0x34 0x2C 0x36 0x2A 0x33 0x32 0x47 0x42 0x2C 0x32 0x2A 0x31 0x32 0x30 0x30 0x47 0x42 0x2D 0x53 0x41 0x53 0x2C 0x36 0x2A 0x39 0x36 0x30 0x47 0x42 0x2D 0x53 0x41 0x54 0x41 0x2C 0x31 0x2A 0x58 0x52 0x34 0x35 0x30 0x43 0x2D 0x4D 0x58 0x2C 0x31 0x2A 0x58 0x50 0x33 0x38 0x30 0x2C 0x31 0x2A 0x58 0x50 0x33 0x38 0x30 0x29 0x2C 0x48 0x31 0x32 0x48 0x2D 0x30 0x36 0x2D 0x30 0x38 0x34 0x30 0x31 0x37
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x04 0x05 0x05 0x00 0x00 0x92 0x44 0x65 0x73 0x63 0x72 0x69 0x70 0x74 0x69 0x6F 0x6E 0x3D 0x52 0x61 0x63 0x6B 0x20 0x53 0x65 0x72 0x76 0x65 0x72 0x20 0x43 0x6F 0x6D 0x70 0x6C 0x65 0x74 0x65 0x20 0x41 0x70 0x70 0x6C 0x69 0x61 0x6E 0x63 0x65 0x2C 0x47 0x44 0x41 0x54 0x43 0x4A 0x42 0x2D 0x4C 0x32 0x30 0x59 0x28 0x32 0x2A 0x39 0x30 0x30 0x57 0x2C 0x32 0x2A 0x34 0x33 0x31 0x34 0x2C 0x36 0x2A 0x33 0x32 0x47 0x42 0x2C 0x32 0x2A 0x31 0x32 0x30 0x30 0x47 0x42 0x2D 0x53 0x41 0x53 0x2C 0x36 0x2A 0x39 0x36 0x30 0x47 0x42 0x2D 0x53 0x41 0x54 0x41 0x2C 0x31 0x2A 0x58 0x52 0x34 0x35 0x30 0x43 0x2D 0x4D 0x58 0x2C 0x31 0x2A 0x58 0x50 0x33 0x38 0x30 0x2C 0x31 0x2A 0x58 0x50 0x33 0x38 0x30 0x29 0x2C 0x48 0x31 0x32 0x48 0x2D 0x30 0x36 0x2D 0x30 0x38 0x34 0x30 0x31 0x37
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x04 0x06 0x05 0x00 0x00 0x92 0x44 0x65 0x73 0x63 0x72 0x69 0x70 0x74 0x69 0x6F 0x6E 0x3D 0x52 0x61 0x63 0x6B 0x20 0x53 0x65 0x72 0x76 0x65 0x72 0x20 0x43 0x6F 0x6D 0x70 0x6C 0x65 0x74 0x65 0x20 0x41 0x70 0x70 0x6C 0x69 0x61 0x6E 0x63 0x65 0x2C 0x47 0x44 0x41 0x54 0x43 0x4A 0x42 0x2D 0x4C 0x32 0x30 0x59 0x28 0x32 0x2A 0x39 0x30 0x30 0x57 0x2C 0x32 0x2A 0x34 0x33 0x31 0x34 0x2C 0x36 0x2A 0x33 0x32 0x47 0x42 0x2C 0x32 0x2A 0x31 0x32 0x30 0x30 0x47 0x42 0x2D 0x53 0x41 0x53 0x2C 0x36 0x2A 0x39 0x36 0x30 0x47 0x42 0x2D 0x53 0x41 0x54 0x41 0x2C 0x31 0x2A 0x58 0x52 0x34 0x35 0x30 0x43 0x2D 0x4D 0x58 0x2C 0x31 0x2A 0x58 0x50 0x33 0x38 0x30 0x2C 0x31 0x2A 0x58 0x50 0x33 0x38 0x30 0x29 0x2C 0x48 0x31 0x32 0x48 0x2D 0x30 0x36 0x2D 0x30 0x38 0x34 0x30 0x31 0x37
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x04 0x0A 0x05 0x00 0x00 0x92 0x44 0x65 0x73 0x63 0x72 0x69 0x70 0x74 0x69 0x6F 0x6E 0x3D 0x52 0x61 0x63 0x6B 0x20 0x53 0x65 0x72 0x76 0x65 0x72 0x20 0x43 0x6F 0x6D 0x70 0x6C 0x65 0x74 0x65 0x20 0x41 0x70 0x70 0x6C 0x69 0x61 0x6E 0x63 0x65 0x2C 0x47 0x44 0x41 0x54 0x43 0x4A 0x42 0x2D 0x4C 0x32 0x30 0x59 0x28 0x32 0x2A 0x39 0x30 0x30 0x57 0x2C 0x32 0x2A 0x34 0x33 0x31 0x34 0x2C 0x36 0x2A 0x33 0x32 0x47 0x42 0x2C 0x32 0x2A 0x31 0x32 0x30 0x30 0x47 0x42 0x2D 0x53 0x41 0x53 0x2C 0x36 0x2A 0x39 0x36 0x30 0x47 0x42 0x2D 0x53 0x41 0x54 0x41 0x2C 0x31 0x2A 0x58 0x52 0x34 0x35 0x30 0x43 0x2D 0x4D 0x58 0x2C 0x31 0x2A 0x58 0x50 0x33 0x38 0x30 0x2C 0x31 0x2A 0x58 0x50 0x33 0x38 0x30 0x29 0x2C 0x48 0x31 0x32 0x48 0x2D 0x30 0x36 0x2D 0x30 0x38 0x34 0x30 0x31 0x37
  # ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x04 0x00 0x02 0x02 0x00 0x96 0x44 0x65 0x73 0x63 0x72 0x69 0x70 0x74 0x69 0x6F 0x6E 0x3D 0x52 0x61 0x63 0x6B 0x20 0x53 0x65 0x72 0x76 0x65 0x72 0x20 0x43 0x6F 0x6D 0x70 0x6C 0x65 0x74 0x65 0x20 0x41 0x70 0x70 0x6C 0x69 0x61 0x6E 0x63 0x65 0x2C 0x47 0x44 0x41 0x54 0x43 0x4A 0x42 0x2D 0x4C 0x32 0x30 0x59 0x28 0x32 0x2A 0x32 0x30 0x30 0x30 0x57 0x2C 0x36 0x2A 0x33 0x30 0x30 0x30 0x57 0x2C 0x32 0x2A 0x38 0x34 0x36 0x38 0x57 0x2C 0x33 0x32 0x2A 0x36 0x34 0x47 0x42 0x2C 0x32 0x2A 0x34 0x38 0x30 0x47 0x42 0x2D 0x53 0x41 0x54 0x41 0x2C 0x34 0x2A 0x33 0x38 0x34 0x30 0x47 0x42 0x2D 0x4E 0x56 0x4D 0x65 0x2C 0x31 0x2A 0x39 0x35 0x36 0x30 0x2D 0x38 0x2C 0x38 0x2A 0x4D 0x43 0x58 0x37 0x35 0x35 0x31 0x30 0x36 0x41 0x53 0x2D 0x48 0x45 0x41 0x54 0x29 0x2C 0x31 0x32 0x36 0x31 0x37 0x32
  # ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x04 0x02 0x05 0x00 0x00 0x57 0x44 0x65 0x73 0x63 0x72 0x69 0x70 0x74 0x69 0x6F 0x6E 0x3D 0x4D 0x61 0x6E 0x75 0x66 0x61 0x63 0x74 0x75 0x72 0x65 0x64 0x20 0x42 0x6F 0x61 0x72 0x64 0x2C 0x47 0x44 0x41 0x54 0x43 0x4A 0x42 0x2D 0x4C 0x32 0x30 0x59 0x2C 0x42 0x43 0x31 0x35 0x46 0x44 0x43 0x46 0x2C 0x31 0x32 0x56 0x20 0x46 0x61 0x6E 0x20 0x44 0x72 0x69 0x76 0x65 0x72 0x20 0x43 0x6F 0x6E 0x6E 0x65 0x63 0x74 0x6F 0x72 0x20 0x42 0x6F 0x61 0x72 0x64 0x2C 0x31 0x2A 0x31
}

function update::boot_type {
  printf 'Update [Boot Type]'
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x93 0x14 0xe3 0x00 0x35 0x52 0x00 0x01 0x00 0x00 0x00 0xff 0xff 0x00 0x01 0x00 0x04 0x00 0x00 0x01 0x00
}

function update::ai_module {
  printf 'Update [AI Module]'
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x93 0x14 0xe3 0x00 0x5a 0x34 0x00 0x04 0x00 0x00 0x00 0x08 0x00
}

function update::flush {
  printf 'Flush'
  ${IPMI} ${IPMI_ARGS} -H "${TARGET}" raw 0x30 0x90 0x06 0x00 0xAA
}


function main {
  update::board::product_name
  update::board::serial_number
  update::board::part_number
  update::board::mfg
  update::product::partmodel_number
  update::product::serial_number
  update::chassis::part_number
  update::board::extra
  update::product_name
  update::boot_type
  update::ai_module
  update::flush
}


main