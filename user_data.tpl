Content-Type: multipart/mixed; boundary="==BOUNDARY=="
MIME-Version: 1.0
--==BOUNDARY==
Content-Type: text/cloud-boothook; charset="us-ascii"

# Install ECS agent
cloud-init-per once yum_update yum update -y
cloud-init-per once disable_docker_repo amazon-linux-extras disable docker
cloud-init-per once install_ecs_agent amazon-linux-extras install -y ecs
cloud-init-per once enable_ecs_agent systemctl enable --now ecs
--==BOUNDARY==
%{ if efs_id != "" }
--==BOUNDARY==
Content-Type: text/cloud-boothook; charset="us-ascii"

# Install amazon-efs-utils
cloud-init-per once install_amazon-efs-utils yum install -y amazon-efs-utils

# Create /efs folder
cloud-init-per once mkdir_efs mkdir /efs

# Mount /efs
cloud-init-per once mount_efs echo -e '${efs_id}:/ /efs efs defaults,_netdev 0 0' >> /etc/fstab
mount -a
%{ endif }
%{ if http_proxy != "" }
--==BOUNDARY==
Content-Type: text/cloud-boothook; charset="us-ascii"
# Specify proxy host, port number, and ECS cluster name to use
PROXY_HOST=${http_proxy}
PROXY_PORT=${http_proxy_port}

# Set Yum HTTP proxy
if [ ! -f /var/lib/cloud/instance/sem/config_yum_http_proxy ]; then
    echo "proxy=http://$PROXY_HOST:$PROXY_PORT" >> /etc/yum.conf
    echo "$$: $(date +%s.%N | cut -b1-13)" > /var/lib/cloud/instance/sem/config_yum_http_proxy
fi

# Set Docker HTTP proxy (different methods for Amazon Linux 2 and Amazon Linux AMI)
mkdir /etc/systemd/system/docker.service.d
cat <<EOF > /etc/systemd/system/docker.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=http://$PROXY_HOST:$PROXY_PORT/"
Environment="HTTPS_PROXY=http://$PROXY_HOST:$PROXY_PORT/"
Environment="NO_PROXY=169.254.169.254,169.254.170.2"
EOF
systemctl daemon-reload
if [ "$(systemctl is-active docker)" == "active" ]
then
    systemctl restart docker
fi
echo "$$: $(date +%s.%N | cut -b1-13)" > /var/lib/cloud/instance/sem/config_docker_http_proxy
# Set ECS agent HTTP proxy
if [ ! -f /var/lib/cloud/instance/sem/config_ecs-agent_http_proxy ]; then
    cat <<EOF > /etc/ecs/ecs.config
HTTP_PROXY=$PROXY_HOST:$PROXY_PORT
HTTPS_PROXY=$PROXY_HOST:$PROXY_PORT
NO_PROXY=169.254.169.254,169.254.170.2,/var/run/docker.sock
EOF
    echo "$$: $(date +%s.%N | cut -b1-13)" > /var/lib/cloud/instance/sem/config_ecs-agent_http_proxy
fi

# Set ecs-init HTTP proxy
mkdir /etc/systemd/system/ecs.service.d
cat <<EOF > /etc/systemd/system/ecs.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=$PROXY_HOST:$PROXY_PORT/"
Environment="HTTPS_PROXY=$PROXY_HOST:$PROXY_PORT/"
Environment="NO_PROXY=169.254.169.254,169.254.170.2,/var/run/docker.sock"
EOF
    systemctl daemon-reload
    if [ "$(systemctl is-active ecs)" == "active" ]; then
        systemctl restart ecs
    fi
    echo "$$: $(date +%s.%N | cut -b1-13)" > /var/lib/cloud/instance/sem/config_ecs-init_http_proxy
%{ if system_controls != "" }
--==BOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
${system_controls}
sysctl -p
%{ endif }
--==BOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
# Set any ECS agent configuration options
echo "ECS_CLUSTER=${ecs_cluster_name}" >> /etc/ecs/ecs.config
echo "ECS_IMAGE_PULL_BEHAVIOR=always" >> /etc/ecs/ecs.config
echo "ECS_ENABLE_UNTRACKED_IMAGE_CLEANUP=true" >> /etc/ecs/ecs.config
echo "ECS_ENABLE_SPOT_INSTANCE_DRAINING=true" >> /etc/ecs/ecs.config

systemctl restart ecs
--==BOUNDARY==--




