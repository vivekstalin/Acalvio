#!/bin/sh
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get -y install python-setuptools
sudo apt-get -y install unzip
sudo easy_install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz
sudo cfn-init -s linux-wait-instanceid -r LaunchConfig --region ap-northeast-1
sudo sleep 10
sudo su - ubuntu
cd /home/ubuntu
touch sample.txt
wget https://suma-bcde-bkt.s3.amazonaws.com/bcde.zip
sudo chmod 777 /home/ubuntu/*
unzip bcde.zip -d ./bcde_scale
cd bcde_scale
chmod 777 ./*
./bcde.sh -f ./bcde.config -t 1
instance_id=$(sudo curl http://169.254.169.254/latest/meta-data/instance-id)
for i in $(seq 7)
do
  bcde_status=$(sudo cat /var/log/cloud-init-output.log | grep "Completed deployment/cleanup on endpoint")
  echo "checking iteartion:$i"
  echo "bcde status ---> $bcde_status"
  if [ $i -eq 10 ]
  then
    echo "Tried for 10mins. Maximum tries reached. Sending Failure signal to CFN and exiting"
    cfn-signal -e 1 --stack linux-wait-instanceid         --resource AutoScalingGroup         --region ap-northeast-1  --reason "Instance $instance_id sent the Failure signal"
    break
  fi
  if echo $bcde_status | grep "Completed"
  then
    echo "Seen completed log in bcde installation, sending success signal to CFN and exiting"
    cfn-signal -e 0 --stack linux-wait-instanceid         --resource AutoScalingGroup         --region ap-northeast-1  --reason "Instance $instance_id sent the Success signal"
    break
  else
    echo "bcde installation is not completed. Cannot send success signal to CFN"
    echo "Time:$i: Sleeping for 1min for service to come up"
    sleep 60
  fi
done
sudo echo "Done reporting bcde installation status via the signal back to the stack"
