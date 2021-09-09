#! /bin/bash
../gradlew build
ver="$(( $(cat ver) + 1 ))"
docker tag a4everyone/bastion:0.0.1-SNAPSHOT a4everyone/bastion:0.0.${ver}
docker push a4everyone/bastion:0.0.${ver}
echo $ver > ver