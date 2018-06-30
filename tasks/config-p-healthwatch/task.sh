#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

properties_config=$($JQ_CMD -n \
  --arg healthwatch_forwarder_boshhealth_instance_count "${HEALTHWATCH_FORWARDER_BOSHHEALTH_INSTANCE_COUNT:-1}" \
  --arg healthwatch_forwarder_boshtasks_instance_count "${HEALTHWATCH_FORWARDER_BOSHTASKS_INSTANCE_COUNT:-1}" \
  --arg healthwatch_forwarder_canary_instance_count "${HEALTHWATCH_FORWARDER_CANARY_INSTANCE_COUNT:-1}" \
  --arg healthwatch_forwarder_cli_instance_count "${HEALTHWATCH_FORWARDER_CLI_INSTANCE_COUNT:-1}" \
  --arg healthwatch_forwarder_foundation_name "${HEALTHWATCH_FORWARDER_FOUNDATION_NAME}" \
  --arg healthwatch_forwarder_health_check_az "${HEALTHWATCH_FORWARDER_HEALTH_CHECK_AZ}" \
  --arg healthwatch_forwarder_health_check_vm_type "${HEALTHWATCH_FORWARDER_HEALTH_CHECK_VM_TYPE:-"nano"}" \
  --arg healthwatch_forwarder_ingestor_instance_count "${HEALTHWATCH_FORWARDER_INGESTOR_INSTANCE_COUNT:-4}" \
  --arg healthwatch_forwarder_opsman_instance_count "${HEALTHWATCH_FORWARDER_OPSMAN_INSTANCE_COUNT:-2}" \
  --arg healthwatch_forwarder_publish_to_eva "${HEALTHWATCH_FORWARDER_PUBLISH_TO_EVA:-true}" \
  --arg healthwatch_forwarder_worker_instance_count "${HEALTHWATCH_FORWARDER_WORKER_INSTANCE_COUNT:-4}" \
  --arg mysql_skip_name_resolve "${MYSQL_SKIP_NAME_RESOLVE:-true}" \
  --arg opsman "${OPSMAN:-"enable"}" \
  --arg opsman_enable_url "${OPSMAN_ENABLE_URL}" \
'{
  ".properties.opsman": {
    "value": $opsman
  }
}
+
if $opsman == "enable" then
{
  ".properties.opsman.enable.url": {
    "value": $opsman_enable_url
  }
}
else .
end
+
{
  ".mysql.skip_name_resolve": {
    "value": $mysql_skip_name_resolve
  },
  ".healthwatch-forwarder.foundation_name": {
    "value": $healthwatch_forwarder_foundation_name
  },
  ".healthwatch-forwarder.ingestor_instance_count": {
    "value": $healthwatch_forwarder_ingestor_instance_count
  },
  ".healthwatch-forwarder.worker_instance_count": {
    "value": $healthwatch_forwarder_worker_instance_count
  },
  ".healthwatch-forwarder.canary_instance_count": {
    "value": $healthwatch_forwarder_canary_instance_count
  },
  ".healthwatch-forwarder.boshhealth_instance_count": {
    "value": $healthwatch_forwarder_boshhealth_instance_count
  },
  ".healthwatch-forwarder.boshtasks_instance_count": {
    "value": $healthwatch_forwarder_boshtasks_instance_count
  },
  ".healthwatch-forwarder.cli_instance_count": {
    "value": $healthwatch_forwarder_cli_instance_count
  },
  ".healthwatch-forwarder.opsman_instance_count": {
    "value": $healthwatch_forwarder_opsman_instance_count
  },
  ".healthwatch-forwarder.publish_to_eva": {
    "value": $healthwatch_forwarder_publish_to_eva
  },
  ".healthwatch-forwarder.health_check_az": {
    "value": $healthwatch_forwarder_health_check_az
  },
  ".healthwatch-forwarder.health_check_vm_type": {
    "value": $healthwatch_forwarder_health_check_vm_type
  }
}'
)

resources_config="{
  \"mysql\": {\"instances\": ${MYSQL_INSTANCES:-1}, \"instance_type\": { \"id\": \"${MYSQL_INSTANCE_TYPE:-2xlarge}\"}, \"persistent_disk\": { \"size_mb\": \"${MYSQL_PERSISTENT_DISK_MB:-102400}\"}},
  \"redis\": {\"instances\": ${REDIS_INSTANCES:-1}, \"instance_type\": { \"id\": \"${REDIS_INSTANCE_TYPE:-xlarge}\"}, \"persistent_disk\": { \"size_mb\": \"${REDIS_PERSISTENT_DISK_MB:-102400}\"}},
  \"healthwatch-forwarder\": {\"instances\": ${HEALTHWATCH_FORWARDER_INSTANCES:-2}, \"instance_type\": { \"id\": \"${HEALTHWATCH_FORWARDER_INSTANCE_TYPE:-xlarge}\"}, \"persistent_disk\": { \"size_mb\": \"${HEALTHWATCH_FORWARDER_PERSISTENT_DISK_MB:-102400}\"}}
}"

network_config=$($JQ_CMD -n \
  --arg network_name "$NETWORK_NAME" \
  --arg other_azs "$OTHER_AZS" \
  --arg singleton_az "$SINGLETON_JOBS_AZ" \
  --arg service_network_name "$SERVICE_NETWORK_NAME" \
'
  {
    "network": {
      "name": $network_name
    },
    "other_availability_zones": ($other_azs | split(",") | map({name: .})),
    "singleton_availability_zone": {
      "name": $singleton_az
    },
    "service_network": {
      "name": $service_network_name
    }
  }
'
)

$OM_CMD \
  --target https://$OPS_MGR_HOST \
  --username "$OPS_MGR_USR" \
  --password "$OPS_MGR_PWD" \
  --skip-ssl-validation \
  configure-product \
  --product-name $PRODUCT_IDENTIFIER \
  --product-properties "$properties_config" \
  --product-network "$network_config" \
  --product-resources "$resources_config"
