1. 每次docker build的时候用 `-t` 指定标签，便于管理：
	`docker build -t="crosbymichael/sentry"`

2. ***CMD***和***ENTRYPOINT***

	`CMD /bin/echo`
	
	`CMD ["/bin/echo"]`
	
	***CMD***是可以被overwirtten的，但是***ENTRYPOINT***不会；
	上面两种写法都是可以的，推荐使用第二种，把命令放在`[]`里面，***ENTRYPOINT***也一样。
	
	
	
	
	
	
	
常用的一些docker命令：

```
docker ps - Lists containers.
docker logs - Fetch the logs of a container.

docker logs命令的一些常用参数:
	-f, --follow- Follow log output
   	--since string - Show logs since timestamp
	--tail string - Number of lines to show from the end of the logs (default "all")
	-t, --timestamps - Show timestamps
	
docker stop - Stops running containers.
docker build - Build an image from a Dockerfile.
docker exec - Run a command in a running container.
docker images - List images.
docker login - Log in to a Docker registry.
docker logout - Log out from a Docker registry.
docker pull - Pull an image or a repository from a registry.
docker push - Push an image or a repository to a registry.
docker rename - Rename a container.
docker restart - Restart a container.
docker rm - Remove one or more containers.
docker rmi - Remove one or more images.

docker run - Run a command in a new container.
docker run命令的一些常用参数:
	-i(--interactive) 表示这是一个交互容器，会把当前标准输入重定向到容器的标准输入中，而不是终止程序运行
	-t(--tty) 指为这个容器分配一个终端。
	-v, --volume value - Bind mount a volume (default [])（将容器内部文件挂载出来）
	-d, --detach - Run container in background and print container ID（指后台运行）
	-p, --publish value － Publish a container's port(s) to the host (default [])（将容器内部指定端口暴露给主机）
 	-P, --publish-all － Publish all exposed ports to random ports（将容器内部所有端口暴露给主机）
 	--name string - Assign a name to the container
 	--rm - Automatically remove the container when it exits
 	
docker start - Start one or more stopped containers.
docker stop - Stop one or more running containers.
docker tag - Tag an image into a repository.
CTRL+D 退出容器
```