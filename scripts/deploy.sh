#!/usr/bin/env bash
set -e

ENV_FILE=$1

if [ -z "$ENV_FILE" ]; then
  echo "Usage: ./deploy.sh environments/dev.env"
  exit 1
fi

source "$ENV_FILE"

aws cloudformation deploy \
  --template-file templates/backend.yaml \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --parameter-overrides \
    BucketName="$BUCKET_NAME" \
    LockTableName="$LOCK_TABLE_NAME"

