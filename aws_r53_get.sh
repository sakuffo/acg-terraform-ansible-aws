aws route53 list-hosted-zones | jq -r .HostedZones[].Name | egrep "cmcloud*"
