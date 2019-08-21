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
	docker build -t 127.0.0.1:5000/plantuml-server:on-promise .
	docker stack deploy -c <(docker-compose config) plantuml
	exit 1
fi

# SERVER 값 필수
if [[ -z "${SERVER}" ]]; then
  echo "Fail: export server config"
  exit 1
fi

echo "push docker image to ${server}"
# docker image 빌드
docker build -t 127.0.0.1:5000/plantuml-server:${tag} .
docker save 127.0.0.1:5000/plantuml-server:${tag} | ssh irteam@${server} "docker load"
#scp docker-compose.yml irteam@${server}:~/docker-compose.${server}.yml
ssh irteam@${server} "docker push ${registry}/${service}:${tag}"
ssh irteam@${server} "docker stack deploy -c <(docker-compose config) plantuml"
