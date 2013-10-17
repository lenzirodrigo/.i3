#!/bin/sh
# shell script to add RAM-usage to i3status
# needs sed, free and bc
## config
# status command has to be this script
## i3status.conf
# showing cpu_usage has to be enabled (because ram_usage is prepended to that with sed...)
# output_format has to be set to "i3bar"

WIRELESS=wlp2s0
ETH=enp3s0

i3status -c $1  | while :
do
    read line

    if [ -e /sys/class/net/$ETH/operstate ] && [ `cat /sys/class/net/$ETH/operstate` == "up" ]; then
        ETHR2=`cat /sys/class/net/$ETH/statistics/rx_bytes`
        ETHT2=`cat /sys/class/net/$ETH/statistics/tx_bytes`
        ETHTBPS=`expr $ETHT2 - $ETHT1`
        ETHRBPS=`expr $ETHR2 - $ETHR1`
        ETHTKBPS=`expr $ETHTBPS / 1024`
        ETHRKBPS=`expr $ETHRBPS / 1024`

        ETHR1=$ETHR2
        ETHT1=$ETHT2
        sedeth="s/\(\"name\":\"ethernet\",\"instance\":\"$ETH\".*)\)\(\"}\)/\1 D $ETHRKBPS U $ETHTKBPS\2/"
        line=`echo $line | sed -e "$sedeth"`
    fi

    if [ -e /sys/class/net/$WIRELESS/operstate ] && [ `cat /sys/class/net/$WIRELESS/operstate` == "up" ]; then
        WLANR2=`cat /sys/class/net/$WIRELESS/statistics/rx_bytes`
        WLANT2=`cat /sys/class/net/$WIRELESS/statistics/tx_bytes`
        WLANTBPS=`expr $WLANT2 - $WLANT1`
        WLANRBPS=`expr $WLANR2 - $WLANR1`
        WLANTKBPS=`expr $WLANTBPS / 1024`
        WLANRKBPS=`expr $WLANRBPS / 1024`

        WLANR1=$WLANR2
        WLANT1=$WLANT2
        sedwlan="s/\(\"name\":\"wireless\",\"instance\":\"$WIRELESS\".*)\)\(\"}\)/\1 D $WLANRKBPS U $WLANTKBPS\2/"
        line=`echo $line | sed -e "$sedwlan"`
    fi

    # get free and used RAM (this excludes cache)
    ram_both=`free -k | sed -n -e '3 p' | sed 's/-\/+ buffers\/cache:\s*//'`
    used=`echo $ram_both | sed "s/\([0-9]*\)\s*\([0-9]*\)/\1/"`
    free=`echo $ram_both | sed "s/\([0-9]*\)\s*\([0-9]*\)/\2/"`
    used=`echo "scale=1; $used / 1024 / 1024" | bc`
    free=`echo "scale=1; $free / 1024 / 1024" | bc`

    # if free RAM is less than 2GB show text in red, else green
    if [ $(echo "$free < 2" | bc) -eq 1 ]
    then
        color=FF0000
    else
        color=00FF00
    fi

    # put ram_usage before cpu_usage
    sedline="s/cpu_usage/ram_usage\",\"color\":\"#${color}\",\"full_text\":\"RAM: ${free}G\"},{\"name\":\"cpu_usage/"
    line=`echo $line | sed -e "$sedline" | sed -e "s/% \"/%\"/"`

    #remove colons
    colonline='s/\([a-zA-Z]\):/\1/g'
    final=`echo $line | sed -e "$colonline"`

    echo "$final" || exit 1
done
