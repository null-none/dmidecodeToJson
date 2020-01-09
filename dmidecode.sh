#!/bin/bash

cpu_info() {
  cpufile="/proc/cpuinfo"
  start='"cpu_info" : ['
  end=']'
  if [ -f "$cpufile" ]; then
    count=$(grep -Ec 'processor' $cpufile)
    i=1
    while [ $i -le $count ]; do
      fetch="$(cat "$cpufile" | awk -vi="$i" '/processor/{j++}j==i')"
      grep_processor=$(echo "$fetch" | perl -F: -alpe 's/.*:*/"$F[0]":"$F[1]"/' | tr -s '\n' ','  |  sed 's/\s\(":"\)\s/":"/g' | sed -zE 's/[[:space:]]+([:"])/\1/g' )
      proc="{"${grep_processor::-1}"},"
      mid=$mid$proc
      i=$((i+1))
    done
  fi
  echo $start${mid::-1}$end
}

mem_info() {
  start='"mem_info" : ['
  end=']'
  memInfo=$(dmidecode --type memory | grep 'Memory\|Size\|Type\|Speed\|Manufacturer\|Serial\|Part' | sed "/Memory/d")
  count=$(echo "$memInfo" | grep -Ec 'Size')
  i=1
  while [ $i -le $count ]; do
    fetch="$(echo "$memInfo" | awk -vi="$i" '/Size/{j++}j==i')"
    grep_processor=$(echo "$fetch" | perl -F: -alpe 's/.*:*/"$F[0]":"$F[1]"/' | tr -s '\n' ','  |  sed 's/\s\(":"\)\s/":"/g' | sed -zE 's/[[:space:]]+([:"a-zA-Z0-9])/\1/g' )
    proc="{"${grep_processor::-1}"},"
    mid=$mid$proc
    i=$((i+1))
  done
  echo $start${mid::-1}$end
}

disk_info() {
  start='"disk_info" : ['
  end=']'
  diskInfo=$(sudo lshw -quiet -class disk | sed "/*-/d")
  count=$(lshw -quiet -class disk | grep -Ec '*-disk')
  i=1
  while [ $i -le $count ]; do
    fetch="$(echo "$diskInfo" | awk -vi="$i" '/description/{j++}j==i')"
    grep_processor=$(echo "$fetch" | perl -F: -alpe 's/.*:*/"$F[0]":"$F[1]"/' | tr -s '\n' ','  |  sed 's/\s\(":"\)\s/":"/g' | sed -zE 's/[[:space:]]+([:"a-zA-Z0-9])/\1/g' )
    proc="{"${grep_processor::-1}"},"
    mid=$mid$proc
    i=$((i+1))
  done
  echo $start${mid::-1}$end
}

motherboard_info() {
  start='"motherboard_info" : {'
  end='}'
  mbinfo=$(dmidecode --type baseboard | grep 'Manufacturer\|Name\|Version\|Serial')
  grep_processor=$(echo "$mbinfo" | perl -F: -alpe 's/.*:*/"$F[0]":"$F[1]"/' | tr -s '\n' ','  |  sed 's/\s\(":"\)\s/":"/g' | sed -zE 's/[[:space:]]+([:"a-zA-Z0-9])/\1/g' )
  proc=${grep_processor::-1}
  local mid=$mid$proc
  echo $start${mid}$end
}

output_file() {
  boardvendor=$(dmidecode -s baseboard-manufacturer)
  boardserial=$(dmidecode -s baseboard-serial-number)
  echo "$boardvendor-$boardserial.json"
}


motherboard=$(motherboard_info)
cpu=$(cpu_info)
mem=$(mem_info)
disk=$(disk_info)
filename=$(output_file)
echo "{$motherboard,$cpu,$mem,$disk}" > "${filename}"

