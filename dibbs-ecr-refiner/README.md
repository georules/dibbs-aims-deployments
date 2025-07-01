# dibbs-ecr-refiner

## ✅ 1. S3 Bucket Setup

### **S3 Bucket: `data-repository`**

* **Folders/Prefixes Required**:

  * `/RefinerInput/`
  * `/RefinerOutput/`
  * `/RefinerComplete/`

### **Configuration**

* **EventBridge Integration**:

  * Enable `EventBridge` on this S3 bucket to send `ObjectCreated:*` events.
* **Permissions**:

  * The bucket policy must allow `GetObject`, `PutObject`, and `ListBucket` for the Lambda execution role.

---

## 🔔 2. Amazon EventBridge Configuration

### **Event Buses**

* **Default Event Bus**: Captures all S3 `ObjectCreated:*` events.
* **Custom Event Bus**: Named (e.g., `data-repository-bus`).

### **Rules**

1. **Rule 1: Forward S3 Create Events**

   * **Source**: `aws.s3`
   * **DetailType**: `Object Created`
   * **Targets**: Forward to custom bus

2. **Rule 2: `/RefinerInput/` Prefix Events**

   * **Bus**: `data-repository-bus`
   * **Filter**: Object key starts with `RefinerInput/`
   * **Target**: SQS queue `dibbs-ecr-RefinerInput`

3. **Rule 3: `/RefinerComplete/` Prefix Events**

   * **Bus**: `data-repository-bus`
   * **Filter**: Object key starts with `RefinerComplete/`
   * **Target**: SQS queue `dibbs-ecr-RefinerComplete`

---

## 📬 3. Amazon SQS Setup

### **SQS Queues and DLQs**

1. **Primary Queues**:

   * `dibbs-ecr-RefinerInput`
   * `dibbs-ecr-RefinerComplete`

2. **Dead Letter Queues**:

   * `dibbs-ecr-RefinerInput-dlq`
   * `dibbs-ecr-RefinerComplete-dlq`

3. **DLQ Configuration**:

   * Set RedrivePolicy with `maxReceiveCount` (e.g., 5)
   * Each primary queue forwards to its respective DLQ on failure

4. **SQS Integration with Lambda**:

   * `dibbs-ecr-RefinerInput` queue is configured as an event source for the Lambda

---

## 🧠 4. Lambda Function Configuration

### **Lambda: `dibbs-aims-helloworld/lambda`**

This is a helloworld service to demonstrate a data pipeline of this type using lambda with container images.

* **Runtime**: Container Image (pulled from Amazon ECR)
* **VPC Configuration**: Enabled if access to private resources is required
* **Memory**: \1024 MB (adjustable based on workload)
* **Timeout**: 900 seconds (maximum value)
* **Event Source**: `dibbs-ecr-RefinerInput` SQS queue
* **Environment Variables**:

  * `REFINER_OUTPUT_PREFIX=/RefinerOutput/`
  * `REFINER_COMPLETE_PREFIX=/RefinerComplete/`

### **IAM Role for Lambda**

Attach the following **IAM policies** to a single execution role:

#### **Managed AWS Policies**:

* `AWSLambdaBasicExecutionRole` (CloudWatch logs)
* `AWSLambdaVPCAccessExecutionRole` (VPC support)

#### **Custom Inline Policy**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::data-repository",
        "arn:aws:s3:::data-repository/RefinerInput/*",
        "arn:aws:s3:::data-repository/RefinerOutput/*",
        "arn:aws:s3:::data-repository/RefinerComplete/*"
      ]
    },
    {
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:sqs:<region>:<account>:dibbs-ecr-RefinerInput"
      ]
    }
  ]
}
```

---

## 📦 5. Amazon ECR + Lambda Container

### **Amazon ECR**

* Repository: `dibbs-ecr-refiner/lambda`
* Image: Built using a Node.js Hello World app

### **Node.js Hello World App Requirements**

* **Read** the incoming object from `/RefinerInput/`
* **Generate** two UUIDs
* **Write** two new files to `/RefinerOutput/`, each with the same content as input object
* **Log** all file paths
* **Create** a `/RefinerComplete/<filename>.json` file with an array:

```json
["/RefinerOutput/<uuid1>.txt", "/RefinerOutput/<uuid2>.txt"]
```

* **Log** the `/RefinerComplete/` file path and contents

---

## 🧪 6. Test Scripts & Poller

### **Test Script: Push File to RefinerInput**

* Language: Python / Bash / Node.js
* Uploads a test file (`helloworld.txt`) to `s3://data-repository/RefinerInput/helloworld.txt`

### **Poller Script**

* Language: Python / Node.js
* **Polls** `s3://data-repository/RefinerComplete/` for new JSON files
* On detecting a new file:

  * Downloads and parses the JSON array
  * Retrieves each output file listed
  * Logs content of each file to stdout

Here is a new section to include in your project requirements that describes the **CI/CD responsibilities**, distinguishing between what will be handled using **Bash scripts** and what will be managed using **Terraform**:

---

Absolutely — here is the **updated CI/CD Requirements section** reflecting that:

* CI/CD **executed via GitLab Runners**
* **Code and container images hosted on GitHub**
* Integration between GitLab CI pipelines and GitHub (for image pull based on release tags)

---

## 🚀 CI/CD Requirements and Automation Responsibilities

This section outlines the automation framework used to manage the full lifecycle of infrastructure and application deployments for the refiner pipeline. It distinguishes between responsibilities handled via **Terraform** and **Bash scripts executed in GitLab Runners**, with GitHub serving as the canonical source for application code and built container images.

---

### 🧱 Terraform Responsibilities (Infrastructure-as-Code)

Terraform will be used as the **primary provisioning tool** and will:

#### 🔧 AWS Infrastructure Setup

* **Create and manage:**

  * Amazon S3 buckets (with EventBridge enabled)
  * EventBridge custom bus and event rules (prefix-based)
  * SQS queues and dead-letter queues (DLQs)
  * Lambda functions (with container image support)
  * ECR repositories (target for container images)
  * IAM roles and policies
  * VPC access (if needed for Lambda execution)

#### 🧩 Modular Resource Deployment

Terraform modules must support instantiating new rule sets using:

* A **prefix** (e.g., `/MyNewPrefix/`)
* An **ECR image URI** (e.g., `123456789012.dkr.ecr.us-east-1.amazonaws.com/my-container:v1.0.0`)

> These variables will be passed from the GitLab CI pipeline or `.tfvars` files tied to tagged releases.

---

### 🐚 Bash Script Responsibilities (Executed via GitLab Runners)

**GitLab CI/CD pipelines** will handle all workflows that involve interaction with **external registries**, such as GitHub and Amazon ECR. These include:

#### 🔁 GitHub → ECR Image Sync Workflow

For each release tag:

1. **Authenticate** to:

   * GitHub Container Registry (`ghcr.io`)
   * Amazon ECR
2. **Pull the Docker image** from GitHub based on the GitHub release tag.
3. **Retag and push** the image to the correct ECR repository.
4. **Trigger Terraform deployment** using the image tag as a pipeline variable.

> These steps will run in GitLab Runners as part of the CI/CD pipeline, triggered by merge, tag, or manual deploy jobs.

---

### 🧪 Sample GitLab CI/CD Pipeline Stages

```yaml
stages:
  - prepare
  - sync-image
  - deploy

variables:
  RELEASE_TAG: "v1.2.3"
  ECR_REPO: "123456789012.dkr.ecr.us-east-1.amazonaws.com/refiner"
  GITHUB_IMAGE: "ghcr.io/org-name/refiner"

sync-image:
  stage: sync-image
  image: docker:latest
  services:
    - docker:dind
  script:
    - echo $GITHUB_TOKEN | docker login ghcr.io -u your-username --password-stdin
    - aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_REPO
    - docker pull $GITHUB_IMAGE:$RELEASE_TAG
    - docker tag $GITHUB_IMAGE:$RELEASE_TAG $ECR_REPO:$RELEASE_TAG
    - docker push $ECR_REPO:$RELEASE_TAG

deploy:
  stage: deploy
  image: hashicorp/terraform:light
  script:
    - terraform init
    - terraform apply -var="release_tag=$RELEASE_TAG" -auto-approve
```

---

### 🧩 Integration Strategy

* **Terraform code** is stored in the GitLab repository.
* **Application logic and Dockerfiles** are hosted in **GitHub**.
* GitHub builds and publishes Docker images to **GitHub Container Registry** (`ghcr.io`) on **release tags**.
* **GitLab CI/CD** pipelines:

  * Detect new tags
  * Pull corresponding images from GitHub
  * Push to Amazon ECR
  * Use Terraform to deploy the infrastructure referencing the release tag

---

### 🔒 Security & Credentials

* Store `GITHUB_TOKEN` and `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` in GitLab CI/CD **protected variables**.
* Use **least privilege** IAM roles for image pushing and deployment.
* Terraform should assume a role if deployed from untrusted runners.

---
