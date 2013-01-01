#!/bin/bash
#zram_stat.sh
# by John Moser <john.r.moser@gmail.com>
#
# This script just stats up a zram block device
# for analysis as a swap device.  It tells you:
#
#   - Amount of RAM swapped into zram0
#   - The compressed size of swapped data
#   - The total RAM used by zram0
#   - The total memory savings
#   - Total ratio and bare compression ratio
#   - Effective RAM (RAM + savings)
#
# The second column shows predictions based on
# filling the entire block device at the current
# ratio.

#total RAM
#RAMSZ=$(( $(cat /proc/meminfo |grep MemTotal | awk '{print $2}') * 1024 ))
RAMSZ=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)

#Original and Compressed size of swap
OSZ=0
CSZ=0
TCSZ=0
DSZ=0

add_to_stats() {
	ZRAM="/sys/block/${1}/"

	#Original and Compressed size of swap
	OSZ=$(( OSZ + $(cat "${ZRAM}/orig_data_size") ))
	CSZ=$(( CSZ + $(cat "${ZRAM}/compr_data_size") ))
	TCSZ=$(( TCSZ + $(cat "${ZRAM}/mem_used_total") ))
	DSZ=$(( DSZ + $(cat "${ZRAM}/disksize") ))

}

# Add 'em all up!
for i in $(swapon -s | awk '/^\/dev\/zram/{print $1}'); do
	add_to_stats $( echo "${i}" | cut -f 3 -d'/' )
done


# Ratio
CRATIO=$(( CSZ * 100 / OSZ ))
TCRATIO=$(( TCSZ * 100 / OSZ ))

OSZ=$(( OSZ / 1024 ))
CSZ=$(( CSZ / 1024 ))
TCSZ=$(( TCSZ / 1024 ))
DSZ=$(( DSZ / 1024 ))

# Effective and predicted
ERAM=$(( (RAMSZ + OSZ - TCSZ) / 1024 ))

# Predicted used RAM when filled
PUSERAM="$(echo "$DSZ $TCSZ $OSZ" | awk '{print $1 * ($2 / $3)}' | cut -f 1 -d'.' )"
PSVRAM="$(echo "$DSZ $TCSZ $OSZ" | awk '{print $1 * (1 - ($2 / $3)) / (1024)}' | cut -f 1 -d'.' )"
PERAM=$(( RAMSZ / 1024 + PSVRAM ))



echo	"		Current		Predicted"
echo	"Original:	$(( OSZ / 1024 ))M		$(( DSZ / 1024 ))M"
echo	"Compressed:	$(( CSZ / 1024 ))M"
echo	"Total mem use:	$(( TCSZ / 1024 ))M		$(( PUSERAM / 1024 ))M"
echo	"Saved:		$(( (OSZ - TCSZ) / 1024 ))M		${PSVRAM}M"
echo	"Ratio:		${TCRATIO}%	(${CRATIO}%)"
echo 
echo	"Physical RAM:	$(( RAMSZ / 1024 ))M"
echo	"Effective RAM:	${ERAM}M		(${PERAM}M)"
