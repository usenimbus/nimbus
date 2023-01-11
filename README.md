# nimbus server
## Download latest server binary
`sudo curl -L https://github.com/usenimbus/nimbus/releases/latest/download/nimbus-linux-amd64 -o /usr/bin/nimbus && sudo chmod 755 /usr/bin/nimbus`
## Download latest service unit
`sudo curl -L https://github.com/usenimbus/nimbus/releases/latest/download/nimbus.service -o /etc/systemd/system/nimbus.service && sudo systemctl daemon-reload`
## setup your config secrets inside of /opt/nimbus/config.yaml
Example config (copy using `sudo curl --create-dirs -L https://github.com/usenimbus/nimbus/releases/latest/download/config.yaml -o /opt/nimbus/config.yaml`):
```
HOST: "nimbus.example.com" # replace nimbus.example.com with your chosen domain
LICENSE_KEY: "my_example_key" # contact Nimbus to obtain your key
NIMBUS_API: "https://summit.usenimbus.com/graphql" # this is the Nimbus platform API
OIDC_ISSUER_URL: "https://nimbus.example.com" # replace nimbus.example.com with your chosen domain
OIDC_REDIRECT_URL: "https://nimbus.example.com/auth/callback" # replace nimbus.example.com with your chosen domain
SSO_PROVIDER: "username_password" # this sets your instance to standard username/password login
ADMIN_PRIVATE_KEY: "" # this will be generated during the `nimbus database init` step. Copy the value into this field
ENT_DATASOURCE: "postgresql://$USER:$PASSWORD@$HOST/$DATABASE?sslmode=verify-full" # any postgres compliant connection string should work here
```
## Initialize the database
`nimbus database init`

Enter `Y` when prompted to proceed with the database setup
## Start server as a service (and enable start on reboot)
`systemctl enable nimbus --now`
## route your domain/loadbalancer to the service (running on port :8080)
