read_var() {
  if [ -z "$1" ]; then
    echo "environment variable name is required"
    return
  fi

  local ENV_FILE='.env'
  if [ ! -z "$2" ]; then
    ENV_FILE="$2"
  fi

  local VAR=$(grep $1 "$ENV_FILE" | xargs)
  IFS="=" read -ra VAR <<< "$VAR"
  local name=$1
  echo ${!name:-${VAR[1]}}
}

service=$(read_var SERVICE)
server=$(read_var SERVER)
port=$(read_var PORT)
tag=$(read_var TAG)
registry=$(read_var REGISTRY)
env=$(read_var ENV)

# local 환경 설정
if [ $env == "local" ]; then
	echo local
	docker build -t 127.0.0.1:5000/${service}:${tag} .
	docker-compose config | docker stack deploy -c - ${service}
	exit 0
fi

timestamp=$(read_var TIMESTAMP)
useToastDeploy=$(read_var USE_TOAST_DEPLOY)
echo "timestamp: ${timestamp}"

# docker image 빌드
echo "push docker build image 127.0.0.1:5000/${service}:${tag}"
docker build --build-arg TIMESTAMP=${timestamp} -t 127.0.0.1:5000/${service}:${tag} .

# toast deploy 를 이용
if [ "$useToastDeploy" == true ] ; then
	docker save -o ${service}.tar 127.0.0.1:5000/${service}:${tag}
	echo "build success ${service}.tar"
	exit 0
fi

# SERVER 값 필수
if [[ -z "${SERVER}" ]]; then
  echo "Fail: export server config"
  exit 1
fi

echo "push docker image to ${server}"

# dev beta alpha의 경우는 ci의 registry 서버를 사용. 환경변수에 registry 설정해야 함
if [ [$env == "dev" ] || [ $env == "beta" ] || [ $env == "alpha" ] ]; then
	docker push 127.0.0.1:5000/${service}:${tag}
	docker-compose config | ssh irteam@${server} "docker stack deploy -c - ${service}"

else
	docker save 127.0.0.1:5000/${service}:${tag} | ssh irteam@${server} "docker load"
    ssh irteam@${server} "docker push ${registry}/${service}:${tag}"
    docker-compose config | ssh irteam@${server} "docker stack deploy -c - ${service}"
fi



