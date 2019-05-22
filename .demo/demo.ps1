Push-Location ${PSScriptRoot}/..

vagrant ssh manager -c 'docker network create -d overlay public'
vagrant ssh manager -c 'docker network create -d overlay private'
scp stack.yml jdoe@10.100.10.3:~/stack.yml
vagrant ssh manager -c 'docker stack deploy -c ~/.stack.yml demo'