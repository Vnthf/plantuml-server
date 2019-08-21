#. ./.env
REGISTRY=127.0.0.1:5000
REPLICA=2
TAG=on-promise
SERVICE=plantuml-server

if [[ -z "${SERVER}" ]]; then
  echo "Fail: export server config"
  exit 1
else
  MY_SCRIPT_VARIABLE="${SERVER}"
fi

docker build -t 127.0.0.1:5000/plantuml-server:${TAG} .
docker save 127.0.0.1:5000/plantuml-server:${TAG}
scp docker-compose.yml irteam@${SERVER}:~/docker-compose.${SERVICE}.yml
ssh irteam@${SERVER} "docker load"
ssh irteam@${SERVER} "docker push ${REGISTRY}/${SERVICE}:${TAG}"
ssh irteam@${SERVER} "docker stack deploy -c docker-compose.${SERVICE}.yml plantuml"