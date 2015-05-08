#!/bin/bash

p_my=$0
p_m=$1
p_cn=$2
p_package=$3
dtemp_dir="/root/.deploytemp" 
dir_conf="/root/docker-run.d/"
volumns_dir=/root/docker/volumns

method_array=("start" "stop" "restart" "deploy")
#docker_con_array=("ics-postgres" "icss" "mbess")
docker_con_array=()

load_containers(){
  index=0
  for file in $dir_conf/*
  do
    if test -f $file
    then
      filetype=`echo $file | awk -F. '{print $NF}'`
      filename=`echo $file | awk -F/ '{print $NF}'| awk -F.run {'print $1'}`
      if [ "$filetype" == "run" ];then
        docker_con_array[$index]=$filename
        index=$index+1
      fi
    fi
  done
}

usage(){
    echo "usage:$0 [start|stop|restart|deploy] [container-name]"
    echo "container-name contains:"
    echo "     all:all containers"
    for var in ${docker_con_array[@]}
    do
      echo "     $var"
    done
}


check_method(){
  flag=0
  for var in ${method_array[@]}
  do
    if [ "$var" == "$p_m" ]
    then
      flag=1
    fi
  done

  if [ $flag == 0 ]
  then
    if [ "$p_m" == "help" ] || [ "$p_m" == "" ]
    then
      usage
      exit 0
    fi
    echo "unkown the method [$p_m]"
    echo ""
    usage
  exit 0
  fi
}

check_container(){
  flag=0
  for var in ${docker_con_array[@]}
  do
    if [ "$var" == "$p_cn" ]
    then
      flag=true
    fi
  done

  if [ $flag == 0 ] && [ $p_cn != "all" ]
  then
    echo "unkown the container name [$p_cn]"
    exit 0
  fi
}

after_start_hook(){
    as_hook=$dir_conf/$p_cn.after.hook.sh
    if [ -f $as_hook ];then
        $as_hook
    fi
}

run_container(){
  $dir_conf/$p_cn.run
  after_start_hook
}

start_container(){
  con=`docker ps -a|grep $p_cn|awk -v var="$p_cn" '{if ($NF==var) print $1}'`
  run_con=`docker ps|grep $p_cn|awk -v var="$p_cn" '{if ($NF==var) print $1}'`
  if [ "$con" == "" ]
  then
    echo "container $p_cn not exist,create it"
    run_container
  elif [ "$run_con" == "" ]
  then
    echo "starting $p_cn"
    docker start $p_cn
    after_start_hook
  else
    echo "container $p_cn is running,skip"
  fi
}

start_all(){
  for var in ${docker_con_array[@]}
  do
    p_cn=$var
    start_container
  done
}

stop_container(){
  con=`docker ps -a|grep $p_cn|awk -v var="$p_cn" '{if ($NF==var) print $1}'`
  run_con=`docker ps|grep $p_cn|awk -v var="$p_cn" '{if ($NF==var) print $1}'`
  if [ "$con" == "" ]
  then
    echo "container $p_cn not exist"
  elif [ "$run_con" == "" ]
  then
    echo "container $p_cn is not running"
  else
    docker stop $p_cn
  fi
}

stop_all(){
  for var in ${docker_con_array[@]}
  do
    p_cn=$var
    stop_container
  done
}

restart_container(){
  con=`docker ps -a|grep $p_cn|awk -v var="$p_cn" '{if ($NF==var) print $1}'`
  run_con=`docker ps|grep $p_cn|awk -v var="$p_cn" '{if ($NF==var) print $1}'`
  if [ "$con" == "" ]
  then
    echo "container $p_cn not exist,create it"
    run_container
  elif [ "$run_con" == "" ]
  then
    echo "container $p_cn is not running,start it"
    docker start $p_cn
    after_start_hook
  else
    echo "restarting $p_cn"
    docker restart $p_cn
    after_start_hook
  fi
}

restart_all(){
  for var in ${docker_con_array[@]}
  do
    p_cn=$var
    restart_container
  done
}

deploy_check(){
  if [ "$p_package" != "" ];then
    if [ ! -f "$p_package" ];then
      filetype=`echo $p_package | awk -F. '{print $NF}'`
	    filename=`echo $p_package | awk -F/ '{print $NF}'`
      if [ "$filetype" == "zip" ];then
        if [ -d "$dtemp_dir" ];then
          rm -rf "$dtemp_dir"
        fi
        mkdir -p "$dtemp_dir"

        cp -rf "$p_package" "$dtemp_dir/"
        crt=$PWD
        cd "$dtemp_dir" 
        unzip $filename
        cd $crt
	    fi
#      echo "the package $p_package not exist!"
#      exit 0
    fi 
  fi
}

deploy_container(){
  deploy_check
  con=`docker ps -a|grep $p_cn|awk -v var="$p_cn" '{if ($NF==var) print $1}'`
  run_con=`docker ps|grep $p_cn|awk -v var="$p_cn" '{if ($NF==var) print $1}'`
  if [ "$run_con" != "" ]
  then
    docker stop $p_cn
  fi
  if [ -f $dir_conf/$p_cn.deploy ];then
    echo "cann't found $p_cn deploy file"
  fi
  $dir_conf/$p_cn.deploy $p_package $dtemp_dir

  start_container
}

do_method(){
  if [ "$p_m" == "start" ];then
    if [ "$p_cn" == "all" ];then
      start_all
    else
      start_container
    fi
  elif [ "$p_m" == "stop" ];then
    if [ "$p_cn" == "all" ];then
      stop_all
    else
      stop_container
    fi
  elif [ "$p_m" == "restart" ];then
    if [ "$p_cn" == "all" ];then
      restart_all
    else
      restart_container
    fi
  elif [ "$p_m" == "deploy" ];then
    if [ "$p_cn" == "all" ];then
      echo "cann't deploy all"
      exit 0
    fi
    deploy_container
  fi
}

load_containers
check_method
check_container
do_method

