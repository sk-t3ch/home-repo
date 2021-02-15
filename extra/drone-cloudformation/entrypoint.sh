#!/bin/sh

export AWS_DEFAULT_REGION="eu-west-1"
PARAM_FILE=/tmp/fullParams.json

JQ_EVENTS_QUERY='[ .StackEvents[] | "Updating" + " " + .StackName + " " + .ResourceType + " - " + .LogicalResourceId + " " + .ResourceStatus +" "+ .ResourceStatusReason] | reverse | .[]'
# preparing args for xargs
JQ_SSM_REDUCER='[ to_entries[]] | reduce .[] as $item (""; . + $item.key + ":" + $item.value + ":")' # key:value:key:value:

# getting secure parameters from AWS SSM
if [ "$PLUGIN_SSMSECUREPARAMS" ]; then
  SSM_PARAMS_STRING=$(echo $PLUGIN_SSMSECUREPARAMS | jq -r "$JQ_SSM_REDUCER")
  echo ${SSM_PARAMS_STRING%?} | xargs -n 2 -d ":" ssm-params # outputs in /tmp/secureParams.json
fi

# getting params
if [ "$PLUGIN_PARAMS" ]; then
  PARAMS="$(echo "$PLUGIN_PARAMS" | jq -r "[ to_entries[] | {ParameterKey: .key, ParameterValue: .value | tostring} ]")"
  echo "$PARAMS" | head -n -1 | tail -n +2 > /tmp/params.json
fi

if [ -n "$PLUGIN_REGION" ]; then
  echo "Setting Region"
  DEPLOY_REGION=" --region $PLUGIN_REGION"
else
  DEPLOY_REGION=""
fi

echo "[" > $PARAM_FILE
if [ "$PARAMS" ]; then cat /tmp/params.json >> $PARAM_FILE; fi
if [ "$PARAMS" ] && [ "$SSM_PARAMS_STRING" ]; then  echo "," >> $PARAM_FILE; fi
if [ "$SSM_PARAMS_STRING" ]; then SP=$(cat /tmp/secureParams.json); echo ${SP%?} >> $PARAM_FILE; fi
echo "]" >> $PARAM_FILE

echo $PLUGIN_TAGS
TAGS="$(echo "$PLUGIN_TAGS" | jq -r "[ to_entries[] | {Key: .key, Value: .value} ]")"
echo $TAGS
echo "$TAGS" > /tmp/tags.json

# performs the stack actions for create-stack or update-stack
function do_stack {
    CMD="aws cloudformation $1 $DEPLOY_REGION --stack-name $PLUGIN_STACKNAME --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND --template-body file://$PLUGIN_TEMPLATE"
    if [ "$PARAMS" ] || [ "$PLUGIN_SSMSECUREPARAMS" ]; then CMD="$CMD --parameters file://$PARAM_FILE"; fi
    if [ "$TAGS" ]; then CMD="$CMD --tags file:///tmp/tags.json"; fi

    # capture output and deal with no updates validation error
    STACK_ID="$($CMD 2>&1)"
    echo "$STACK_ID"
    if [[ $(echo "$STACK_ID" | awk "/No updates are to be performed/") ]]; then exit 0; fi
    echo "Creating/Updating stack arn: $(echo $STACK_ID | jq -rc '.StackId')"
    echo "Waiting on status change..."
    aws cloudformation wait $2 --stack-name $PLUGIN_STACKNAME $DEPLOY_REGION
    if [ $? -eq 0 ]; then
        echo "Last 20 events..."
        aws cloudformation describe-stack-events --stack-name $PLUGIN_STACKNAME $DEPLOY_REGION --max-items 20 | jq -rc "$JQ_EVENTS_QUERY"
    else
        exit 1
    fi
}

case $PLUGIN_MODE in
"validate")
  aws cloudformation validate-template $DEPLOY_REGION --template-body file://$PLUGIN_TEMPLATE
  RET_CODE=$?
  rm /tmp/*
  exit $(($RET_CODE))
  ;;
"delete")
  aws cloudformation delete-stack --stack-name $PLUGIN_STACKNAME $DEPLOY_REGION
  aws cloudformation wait stack-delete-complete --stack-name $PLUGIN_STACKNAME $DEPLOY_REGION 
  ;;
"test")
  if [ "$DRONE_CI" ]; then
    echo "Do not use test mode in an actual drone pipeline"
    rm /tmp/*
    exit 1
  fi
  
  echo "***Region***"
  echo $DEPLOY_REGION

  echo "***PARAMETERS FILE***"
  cat /tmp/fullParams.json
  # mocking out aws
  function aws(){
    echo "MOCK :: aws invoked with args $@"
  }

  echo "***AWS COMMAND CHECK***"
  do_stack "create-stack" "stack-create-complete"

  ;;
*)
  if [ "$(aws cloudformation describe-stacks $DEPLOY_REGION --stack-name $PLUGIN_STACKNAME 2> /dev/null)" = "" ];
    then
    do_stack "create-stack" "stack-create-complete"
  else
    do_stack "update-stack" "stack-update-complete"
  fi
  ;;
esac

# cleanup so hackers cannot re-run this to spoof secrets!
rm /tmp/*
