#!/bin/sh
echo "Setting environment variables for Terraform"
export ARM_SUBSCRIPTION_ID=36483a93-0c29-4b4f-89fd-2b1077a44280
export ARM_CLIENT_ID=29e008e2-2708-4484-9e78-9a652389124b
export ARM_CLIENT_SECRET=Mi2@/mM=4Js3l4xRv:KrCEjHlvGU]N@3
export ARM_TENANT_ID=8ce308d8-142f-4ba1-8e44-7ac446b0b300

# Not needed for public, required for usgovernment, german, china
export ARM_ENVIRONMENT=AzureCloud
