Push-Location ${PSScriptRoot}/..

scp ./.demo/stack.yml jdoe@10.100.10.3:/tmp/stack.yml
ssh jdoe@10.100.10.3 -C 'chmod 644 /tmp/stack.yml' 
vagrant ssh manager -c 'docker network create -d overlay public; docker network create -d overlay private; docker stack deploy -c /tmp/stack.yml demo'
Pop-Location