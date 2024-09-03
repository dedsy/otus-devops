yc vpc network create --name external-bastion-network
yc vpc network create --name internal-bastion-network
yc vpc subnet create --name bastion-external-segment --range 172.16.17.0/28 --network-name external-bastion-network
yc vpc subnet create --name bastion-internal-segment --range 172.16.16.0/24 --network-name internal-bastion-network
yc vpc security-group create --name secure-bastion-sg --network-name external-bastion-network --rule "direction=ingress,port=22,protocol=tcp,v4-cidrs=[0.0.0.0/0]"
yc vpc security-group create --name internal-bastion-sg --network-name internal-bastion-network --rule "direction=ingress,port=22,protocol=tcp,v4-cidrs=[172.16.16.254/32]"
yc vpc security-group update-rules internal-bastion-sg --add-rule "direction=egress,port=22,protocol=tcp,predefined=self_security_group"
yc vpc security-group update-rules internal-bastion-sg --add-rule "direction=ingress,port=any,protocol=any,v4-cidrs=[0.0.0.0/0]"
yc vpc security-group update-rules internal-bastion-sg --add-rule "direction=egress,port=any,protocol=any,v4-cidrs=[0.0.0.0/0]"
yc vpc gateway create --name otus-gw
yc vpc address create --name bastion_ip --external-ipv4 zone=ru-central1-b
gw_id=`yc vpc gateway get otus-gw | head -n 1 | cut -d " " -f 2`
internal_sg_id=`yc vpc security-group get internal-bastion-sg | head -n 1 | cut -d " " -f 2`
external_sg_id=`yc vpc security-group get secure-bastion-sg | head -n 1 | cut -d " " -f 2`
public_ip=`yc vpc address get bastion_ip | grep "address: " | cut -d ":" -f 2`
yc vpc route-table create --name=otus-route-table --network-name=internal-bastion-network --route destination=0.0.0.0/0,gateway-id=${gw_id}
yc vpc subnet update bastion-internal-segment --route-table-name=otus-route-table
yc compute instance create --name bastion-host --hostname bastion-host --create-boot-disk "image-id=fd8dsvobup2d3l2nuv1m, size=20" --network-interface "subnet-name=bastion-external-segment,security-group-ids=${external_sg_id},nat-address=${public_ip}" --network-interface "subnet-name=bastion-internal-segment,security-group-ids=${internal_sg_id},ipv4-address=172.16.16.254" --memory 2GB --cores 2 --core-fraction 20 --preemptible --metadata-from-file user-data=cloud-config.yaml
yc compute instance create --name otus-app01 --hostname otus-app01 --create-boot-disk "image-id=fd8j0uq7qcvtb65fbffl, size=40" --network-interface "subnet-name=bastion-internal-segment,security-group-ids=${internal_sg_id},ipv4-address=" --memory 2GB --cores 2 --core-fraction 20 --preemptible --metadata-from-file user-data=cloud-config.yaml
