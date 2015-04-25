# auto-docker
batch control docker's container,contain start stop restart and deploy


### usage ###
	
	./docker-run.sh help
show usage

### start ###
start a container

	./docker-run.sh start con01

there must have a file named con01.sh in docker-run.d directory,and con01.sh must is excuteable file

**start all**

	./docker-run.sh start all
the command will start all containers,and the container's file ([container's name].run) must exist in docker-run.d

### stop ###
	
	./docker-run.sh stop con01
	./docker-run.sh stop all
condition same as start
### restart ###
	./docker-run.sh restart con01
	./docker-run.sh restart all

### deploy ###
the deploy methond whill excute the [container's name].deploy file in docker-run.d before excute [container's name].run,and deploy not support **all**