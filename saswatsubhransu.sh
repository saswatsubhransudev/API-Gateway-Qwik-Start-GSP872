#!/bin/bash

# Define color variables
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL=$'\033[38;5;50m'

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
BLINK_TEXT=$'\033[5m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      Welcome to Saswat Subhransu's guides - INITIATING...        ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Retrieve Project ID and Region
export PROJECT_ID=$(gcloud config get-value project)
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

if [ -z "$REGION" ]; then
    echo -n "${CYAN_TEXT}Enter the region (e.g., us-central1): ${RESET_FORMAT}"
    read REGION
fi

gcloud config set compute/region $REGION

# Enable necessary APIs
gcloud services enable apigateway.googleapis.com --project $PROJECT_ID
gcloud services enable run.googleapis.com

sleep 15

export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

# Add IAM policy bindings
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/serviceusage.serviceUsageAdmin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"

sleep 30

# Clone the repository
git clone https://github.com/GoogleCloudPlatform/nodejs-docs-samples.git

cd nodejs-docs-samples/functions/helloworld/helloworldGet

sleep 10

# Deploy Cloud Function
deploy_function() {
  gcloud functions deploy helloGET \
    --runtime nodejs20 \
    --region $REGION \
    --trigger-http \
    --allow-unauthenticated
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "${GREEN_TEXT}Cloud Run service is created. Exiting the loop.${RESET_FORMAT}"
    deploy_success=true
  else
    echo "${YELLOW_TEXT}Waiting for Cloud Run service to be created... retrying in 60s${RESET_FORMAT}"
    sleep 60
  fi
done

echo "${CYAN_TEXT}Running the next code...${RESET_FORMAT}"

gcloud functions describe helloGET --region $REGION

curl -v https://$REGION-$PROJECT_ID.cloudfunctions.net/helloGET

cd ~

# Generate openapi2-functions.yaml dynamically
cat > openapi2-functions.yaml <<EOF_CP
# openapi2-functions.yaml
swagger: '2.0'
info:
  title: API_ID description
  description: Sample API on API Gateway with a Google Cloud Functions backend
  version: 1.0.0
schemes:
  - https
produces:
  - application/json
paths:
  /hello:
    get:
      summary: Greet a user
      operationId: hello
      x-google-backend:
        address: https://$REGION-$PROJECT_ID.cloudfunctions.net/helloGET
      responses:
       '200':
         description: A successful response
         schema:
           type: string
EOF_CP

export API_ID="hello-world-${RANDOM}"

# Replace placeholders in yaml
sed -i "s/API_ID/${API_ID}/g" openapi2-functions.yaml
sed -i "s/PROJECT_ID/$PROJECT_ID/g" openapi2-functions.yaml

echo "${BLUE_TEXT}Created API ID: $API_ID${RESET_FORMAT}"

# Create API Gateway resources
gcloud api-gateway apis create "$API_ID" --project=$PROJECT_ID

gcloud api-gateway api-configs create hello-world-config \
  --project=$PROJECT_ID \
  --api=$API_ID \
  --openapi-spec=openapi2-functions.yaml \
  --backend-auth-service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com

gcloud api-gateway gateways create hello-gateway \
  --location=$REGION \
  --project=$PROJECT_ID \
  --api=$API_ID \
  --api-config=hello-world-config

# Create and retrieve API Key
gcloud alpha services api-keys create --display-name="awesome"  

KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=awesome") 
export API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)") 

echo "${GREEN_TEXT}API Key Generated: $API_KEY${RESET_FORMAT}"

MANAGED_SERVICE=$(gcloud api-gateway apis list --format json | jq -r .[0].managedService | cut -d'/' -f6)
echo "${CYAN_TEXT}Managed Service: $MANAGED_SERVICE${RESET_FORMAT}"

gcloud services enable $MANAGED_SERVICE

# Create second yaml config
cat > openapi2-functions2.yaml <<EOF_CP
# openapi2-functions.yaml
swagger: '2.0'
info:
  title: API_ID description
  description: Sample API on API Gateway with a Google Cloud Functions backend
  version: 1.0.0
schemes:
  - https
produces:
  - application/json
paths:
  /hello:
    get:
      summary: Greet a user
      operationId: hello
      x-google-backend:
        address: https://$REGION-$PROJECT_ID.cloudfunctions.net/helloGET
      security:
        - api_key: []
      responses:
       '200':
         description: A successful response
         schema:
           type: string
securityDefinitions:
  api_key:
    type: "apiKey"
    name: "key"
    in: "query"
EOF_CP

sed -i "s/API_ID/${API_ID}/g" openapi2-functions2.yaml
sed -i "s/PROJECT_ID/$PROJECT_ID/g" openapi2-functions2.yaml

# Update API Gateway resources with security config
gcloud api-gateway api-configs create hello-config \
  --project=$PROJECT_ID \
  --display-name="Hello Config" \
  --api=$API_ID \
  --openapi-spec=openapi2-functions2.yaml \
  --backend-auth-service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com 

gcloud api-gateway gateways update hello-gateway \
  --location=$REGION \
  --project=$PROJECT_ID \
  --api=$API_ID \
  --api-config=hello-config

# Enable required managed service
MANAGED_SERVICE=$(gcloud api-gateway apis list --format json | jq -r --arg api_id "$API_ID" '.[] | select(.name | endswith($api_id)) | .managedService' | cut -d'/' -f6)
echo "${CYAN_TEXT}Managed Service Updated: $MANAGED_SERVICE${RESET_FORMAT}"

gcloud services enable $MANAGED_SERVICE

# Test the Gateway endpoints
export GATEWAY_URL=$(gcloud api-gateway gateways describe hello-gateway --location $REGION --format json | jq -r .defaultHostname)
echo "${YELLOW_TEXT}Testing unauthenticated endpoint (Should fail/return unauthorized):${RESET_FORMAT}"
curl -sL $GATEWAY_URL/hello

echo -e "\n${GREEN_TEXT}Testing authenticated endpoint (Should succeed):${RESET_FORMAT}"
curl -sL -w "\n" $GATEWAY_URL/hello?key=$API_KEY

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}✨ Thank you for using Saswat Subhransu's guides! ✨${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}      Keep learning, keep building, keep growing.      ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
