<div align="center">

# 🌐 API Gateway: Qwik Start & Cloud Functions Backend 🚀 

<img src="https://img.shields.io/badge/Google%20Cloud-%234285F4.svg?style=for-the-badge&logo=google-cloud&logoColor=white" alt="Google Cloud">
<img src="https://img.shields.io/badge/API%20Gateway-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white" alt="API Gateway">
<img src="https://img.shields.io/badge/Cloud%20Functions-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white" alt="Cloud Functions">
<img src="https://img.shields.io/badge/Bash_Scripting-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white" alt="Bash Script">

<br>

**A fully automated, one-click deployment script to configure API Gateway with a secure Cloud Functions backend.**

</div>

---

## 📖 About This Repository

This repository contains an automated Bash script designed to instantly provision and configure the infrastructure required for routing and securing APIs on Google Cloud using **API Gateway**.

Instead of manually navigating the Google Cloud Console, this script interacts directly with the Google Cloud SDK to deploy the backend services, configure OpenAPI specifications, and enforce API key security in minutes.

### 🏗️ Architecture Deployed:
1. **Cloud Functions (Node.js):** Deploys a backend `helloGET` serverless function.
2. **API Gateway & OpenAPI Spec:** Dynamically generates `openapi2-functions.yaml` files and creates the API Gateway and API Configs to route traffic to the backend.
3. **Security & Authentication:** Automatically generates API Keys, updates the gateway configuration to enforce security, and tests both unauthenticated (rejected) and authenticated (successful) endpoints.
4. **IAM & Permissions:** Automatically handles all necessary Service Account bindings and enables required managed services.

---

## ⚠️ Disclaimer 

> **Educational Purpose Only:** This script and guide are provided strictly for educational purposes to help developers and cloud enthusiasts understand Google Cloud services, API management, and infrastructure-as-code automation. 
> 
> **Terms Compliance:** Always ensure compliance with Google Cloud Skills Boost / Qwiklabs terms of service. Before running the script, please review the code to familiarize yourself with the underlying commands and concepts. The aim is to enhance your learning experience — not to circumvent it.

---

## 🚀 Quick Start: Run in Cloud Shell

To execute the automated deployment, open your Google Cloud Shell terminal and run the following commands sequentially:

```bash
# 1. Download the automated script
curl -LO [https://raw.githubusercontent.com/saswatsubhransudev/](https://raw.githubusercontent.com/saswatsubhransudev/)[YOUR_REPO_NAME]/refs/heads/main/saswatsubhransu.sh

# 2. Grant execution permissions
sudo chmod +x saswatsubhransu.sh

# 3. Execute the script
./saswatsubhransu.sh
