#!/bin/bash
# Author:Forrest duan
# Version: 1.00
# Maintainer:Forrest duan
# Location:  dev test demo pre pro env appname.env
# First Created: 2016-05-25
# Last  Updated: 2016-10-28

#Functions mothod
function Help () {
cat <<EOF
Help documentation for $0 .

Basic usage: $0 dev appnameone appnametwo

Command line switches are optional. The following switches are recognized.
dev    --Sets the value for option dev.        Default is dev.
test   --Sets the value for option test.       Default is test.
demo   --Sets the value for option demo.       Default is demo.
pre    --Sets the value for option pre.        Default is pre.
pro    --Sets the value for option pro.        Default is pro.
-h      --Displays this help message. No further functions are performed.

Example(1): $0 dev  install    appname.dev
Example(2): $0 test update     appname.test
Example(3): $0 pre  push       appname.test
########################################################################
EOF
}
#------------------- spring cloud env ------------------
function springcloud_registry(){
export  Dev_registry="172.21.0.11:5000/"
export  Test_registry="172.21.0.11:5000/"
export  Demo_registry="172.21.0.11:5000/"
export  Pre_registry="101.201.238.38:5000/"
export  Pro_registry="172.21.0.11:5000/"
export  Cicd_registry="172.21.0.11:5000/"
}
#-------------------spring cloud env ------------------
#------------docker api----------------
function Docker_exec_build(){
shift
if [ a$1 = "a" ] ;then
        echo "please check app name"
        exit 1
fi

for i in $*
do
        app=`echo $i|awk -F'.' '{print $1}'`
        update_time=`date +%Y%m%d%H%M`
        images=`find ./src/   -name "*$app*.jar"`
        if [[ $i == "mycat.apre" ]] ;then
                cp /data0/springcloud/pkg/Mycat-server-1.6-RELEASE-20161028204710-linux.tar.gz /data0/springcloud/temp/ && cp -arp /data0/springcloud/dev/aws_mycat/*.xml /data0/springcloud/temp/
        elif [[  $i == "mycat.apro" ]] ;then
                cp /data0/springcloud/pkg/Mycat-server-1.6-RELEASE-20161028204710-linux.tar.gz /data0/springcloud/temp/ && cp -arp /data0/springcloud/dev/aws_mycat_pro/*.xml /data0/springcloud/temp/
        elif [[ $i == "myweb.apre" || $i == "myweb.apro" ]] ;then
                cp /data0/springcloud/pkg/mycat-web.tar.gz /data0/springcloud/temp/
        elif [[ $i == "select.apro" ]] ;then
                        cp /data0/springcloud/dev/aws_db_select/database.sql /data0/springcloud/temp/
        elif [[ $i == "eureka.pro" ]] ;then
                mkdir -p  /data0/backupfile/$i/$update_time && /bin/cp $images /data0/backupfile/$i/$update_time/
                mv $images /data0/springcloud/temp/ && cp /data0/springcloud/conf/$workdir/$i temp/ && cd temp
                docker -H tcp://172.21.0.11:2375 build -t $Pro_registry$i:devops`date +%Y%m%d` --file="$i.devops" . && docker -H tcp://172.21.0.11:2375  push $Pro_registry$i:devops`date +%Y%m%d`
                docker -H tcp://172.21.0.11:2375 build -t $Pro_registry$i:mdb01`date +%Y%m%d` --file="$i.mdb01" . && docker -H tcp://172.21.0.11:2375  push $Pro_registry$i:mdb01`date +%Y%m%d`
                docker -H tcp://172.21.0.11:2375 build -t $Pro_registry$i:mdb02`date +%Y%m%d` --file="$i.mdb02" . && docker -H tcp://172.21.0.11:2375  push $Pro_registry$i:mdb02`date +%Y%m%d`
        else
        mkdir -p  /data0/backupfile/$i/$update_time && /bin/cp $images /data0/backupfile/$i/$update_time/
        mv $images /data0/springcloud/temp/ && cp /data0/springcloud/conf/$workdir/$i temp/ && cd temp
        fi
        if [[ $Runenv == 'test' ]] ;then
                docker -H tcp://172.21.0.11:2375 build -t $Test_registry$i:`date +%Y%m%d` --file="$i" . && docker -H tcp://172.21.0.11:2375  push $Test_registry$i:`date +%Y%m%d`
        elif [[ $Runenv == 'dev' ]];then
                docker -H tcp://172.21.0.11:2375 build -t $Dev_registry$i:`date +%Y%m%d` --file="$i" . && docker -H tcp://172.21.0.11:2375  push $Dev_registry$i:`date +%Y%m%d`
        elif [[ $Runenv == 'pre' ]];then
                docker -H tcp://172.21.0.11:2375 build -t $Pre_registry$i:`date +%Y%m%d` --file="$i" . && docker -H tcp://172.21.0.11:2375  push $Pre_registry$i:`date +%Y%m%d`
        elif [[ $Runenv == 'pro' ]];then
                docker -H tcp://172.21.0.11:2375 build -t $Pro_registry$i:`date +%Y%m%d` --file="$i" . && docker -H tcp://172.21.0.11:2375  push $Pro_registry$i:`date +%Y%m%d`
        elif [[ $Runenv == 'cicd' ]];then
                docker -H tcp://172.21.0.11:2375 build -t $Cicd_registry$i:`date +%Y%m%d` --file="$i" . && docker -H tcp://172.21.0.11:2375  push $Cicd_registry$i:`date +%Y%m%d`
        fi
        rm $i && echo $images|awk 'BEGIN { FS = "/" } { system("rm "$5"")}' || rm *.xml
done
}

function Docker_exec_run(){
        n=0
        declare -a line
                awk '$2 ~ /'$2'/ {print}' /etc/docker/continer.conf |grep -v '^#' |while read line
                do
                        service=$(echo ${line[*]}|awk '{print $2}')
                        port=$(echo ${line[*]}|awk '{print $3}')
                        machinenode=$(echo ${line[*]}|awk '{print $4}')
                        if [ $n = 0 ];then
                                #if [ $Runenv != 'test' ] ;then
                                docker -H tcp://$machinenode:2375  pull $service:`date +%Y%m%d`
                                #fi
                                if [[ $2 == "eureka.pro" ]];then
                                        docker -H tcp://172.21.0.11:2375 run -d  -m 2048m --oom-kill-disable --name=$service --net="host" \
                                        -v /data0/logs/$service:/var/ -p 172.21.0.11:$port:$port -t $service:devops`date +%Y%m%d`
                                        docker -H tcp://172.21.0.10:2375 run -d  -m 2048m --oom-kill-disable --name=$service --net="host" \
                                        -v /data0/logs/$service:/var/ -p 172.21.0.10:$port:$port -t $service:mdb01`date +%Y%m%d`
                                        docker -H tcp://172.21.0.16:2375 run -d  -m 2048m --oom-kill-disable --name=$service --net="host" \
                                        -v /data0/logs/$service:/var/ -p 172.21.0.16:$port:$port -t $service:mdb02`date +%Y%m%d`
                                        exit 0
                                fi
                                if docker -H tcp://$machinenode:2375 ps -a |grep -q $service ;then
                                        docker -H tcp://$machinenode:2375 rm -f $service
                                fi
                                        docker -H tcp://$machinenode:2375 run -d  -m 4096m  --oom-kill-disable --name=$service --net="host"\
                                        -v /data0/logs/$service:/var/ -p $machinenode:$port:$port -t $service:`date +%Y%m%d`
                        else
                                if [ $Runenv != 'test'] ;then
                                docker -H tcp://$machinenode:2375  pull $service:`date +%Y%m%d`
                                fi
                                docker -H tcp://$machinenode:2375  pull $service.$port:`date +%Y%m%d`
                                if docker -H tcp://$machinenode:2375  ps -a |grep -q $service.$port ;then
                                        docker -H tcp://$machinenode:2375  rm -f $service.$port
                                fi
                                        docker -H tcp://$machinenode:2375 run -d  -m 1024m --name=$service.$port \
                                        -v /data0/logs/$service.$port:/var/ -p $machinenode:$port:$port -t $service.$port:`date +%Y%m%d`
                        fi
                        if hostname|grep -q test;then
                                n=$[n+1]
                        fi
                        sleep 60
                done
}
#------------docker api----------------

function main(){
case $1 in
        dev)
        if hostname|grep -E -q 'devops';then
                Docker_exec_build $* && ansible dev --key-file="/var/lib/hudson/.ssh/id_rsa"  -m command  -a "springcloud.sh dev $i"
        else
                Docker_exec_run $*
        fi
        ;;
        test)
        if hostname|grep -E -q 'devops';then
                Docker_exec_build $* && ansible test --key-file="/var/lib/hudson/.ssh/id_rsa"  -m command  -a "springcloud.sh test $i"
        else
                Docker_exec_run $*
        fi
        ;;
        demo)
        if hostname|grep -E -q 'devops';then
                Docker_exec_build $* && ansible demo --key-file="/var/lib/hudson/.ssh/id_rsa"  -m command  -a "springcloud.sh demo $i"
        else
                Docker_exec_run $*
        fi
        ;;
        pre)
        if hostname|grep -E -q 'devops';then
                Docker_exec_build $* && ansible pre --key-file="/var/lib/hudson/.ssh/id_rsa"  -m command  -a "springcloud.sh pre $i"
        else
                Docker_exec_run $*
        fi
        ;;
        pro)
        if hostname|grep -E -q 'devops';then
                Docker_exec_build $* && Docker_exec_run $*
        else
                Docker_exec_build $* && ansible pro --key-file="/var/lib/hudson/.ssh/id_rsa"  -m command  -a "springcloud.sh pro $i"
        fi
        ;;
        cicd)
        if hostname|grep -E -q 'devops';then
                Docker_exec_build $* && Docker_exec_run $*
        else
                Docker_exec_build $* && ansible pro --key-file="/var/lib/hudson/.ssh/id_rsa"  -m command  -a "springcloud.sh cicd $i"
        fi
        ;;
        --help|-help|-h)
        Help
        cat /etc/docker/continer.conf
        ;;
        *)
        Help
        ;;
esac
}

workdir=$1
Runenv=$1
Date=`date +%Y%m%d%H%M`
springcloud_registry

if hostname |grep -E -q 'devops';then
        cd  /data0/springcloud/ || echo "Please check /data0/springcloud/, path is no exist"
fi
main $*
#------------ cloud app end------
