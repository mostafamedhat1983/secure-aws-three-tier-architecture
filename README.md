# SecureVault --- Secure AWS Three-Tier Architecture

A security-focused AWS infrastructure project built with Terraform.
SecureVault deploys a containerized secrets-management application using
network segmentation, private compute and database tiers,
least-privilege IAM, AWS Secrets Manager, encryption, AWS WAF, and
security monitoring.

The main focus is the **AWS architecture, infrastructure security, and
repeatable Infrastructure as Code deployment**. The application provides
a working workload through which these controls can be demonstrated.

> **Project status:** The application has been tested locally. The AWS
> infrastructure is defined using Terraform. Complete AWS deployment and
> security validation should only be marked complete after the
> corresponding tests have been performed and evidence has been
> collected.

------------------------------------------------------------------------

## Table of Contents

-   [Project Overview](#project-overview)
-   [Architecture](#architecture)
-   [How the Application Works](#how-the-application-works)
-   [Security Implementation](#security-implementation)
-   [AWS Services](#aws-services)
-   [Terraform Structure](#terraform-structure)
-   [Prerequisites](#prerequisites)
-   [Resources Created Outside
    Terraform](#resources-created-outside-terraform)
-   [Build and Deploy](#build-and-deploy)
-   [Accessing the Application](#accessing-the-application)
-   [Security Validation](#security-validation)
-   [Destroying the Infrastructure](#destroying-the-infrastructure)
-   [Limitations and Design
    Decisions](#limitations-and-design-decisions)
-   [To Do Later](#to-do-later)

------------------------------------------------------------------------

## Project Overview

SecureVault is a three-tier web application deployed on AWS.

The infrastructure separates the public entry point, frontend, backend,
and database into different network layers. Each layer communicates only
with the next layer through explicitly defined security group rules.

The infrastructure is provisioned using reusable Terraform modules.
Application containers run on EC2 instances managed by Auto Scaling
Groups and distributed across two Availability Zones.

Project objectives:

-   Apply network segmentation and restrict communication between
    application tiers.
-   Avoid exposing EC2 instances and the database directly to the
    internet.
-   Use IAM roles instead of static AWS credentials.
-   Retrieve application and database credentials securely through AWS
    Secrets Manager.
-   Encrypt sensitive data at rest and in transit.
-   Protect the public application endpoint using AWS WAF.
-   Enable AWS account activity logging and threat detection.
-   Monitor load balancer and database health using CloudWatch.
-   Use Infrastructure as Code to make deployment and teardown
    repeatable.

## Architecture

### High-level architecture

``` text
                         Internet
                            |
                            | HTTPS :443
                            v
                  +---------------------+
                  |      Public ALB     |
                  |  ACM TLS Certificate|
                  +---------------------+
                            |
                            | HTTP :8080
                            v
              +---------------------------+
              |        Frontend ASG       |
              |     Private Web Subnets   |
              |                           |
              |       EC2 + Docker        |
              |          Nginx            |
              +---------------------------+
                            |
                            | HTTP :80
                            v
                  +---------------------+
                  |     Internal ALB    |
                  |     Private Only    |
                  +---------------------+
                            |
                            | HTTP :5000
                            v
              +---------------------------+
              |         Backend ASG       |
              |     Private App Subnets  |
              |                           |
              |       EC2 + Docker        |
              |    Flask + Gunicorn       |
              +---------------------------+
                            |
                            | MySQL :3306
                            | TLS required
                            v
                  +---------------------+
                  |      Amazon RDS     |
                  |       MySQL 8.4      |
                  |       Multi-AZ       |
                  |      Data Subnets    |
                  +---------------------+
```

Supporting services include:

-   **Amazon Route 53:** Private DNS resolution for communication
    between the frontend and internal ALB.
-   **AWS Secrets Manager:** Stores application encryption/session keys
    and RDS-managed database credentials.
-   **Amazon ECR:** Stores frontend and backend container images.
-   **AWS Systems Manager:** Provides secure instance access without
    SSH.
-   **AWS WAF:** Protects the public ALB.
-   **AWS CloudTrail:** Records AWS account management activity.
-   **Amazon GuardDuty:** Detects suspicious activity and potential
    threats.
-   **Amazon CloudWatch:** Monitors load balancer and database metrics
    and stores selected RDS logs.

### VPC and subnet layout

The project uses a dedicated VPC with CIDR `10.0.0.0/16` and eight
subnets distributed across two Availability Zones.

  Subnet group     Count Purpose
  -------------- ------- ----------------------------------------
  Public               2 Internet-facing ALB and public routing
  Frontend             2 Frontend EC2 instances
  Backend              2 Internal ALB and backend EC2 instances
  Data                 2 RDS database

The data subnets have no default route to the internet.

A regional NAT Gateway provides outbound connectivity for private
instances that need to install Docker, retrieve container images, access
AWS APIs, and reach package repositories.

### Request flow

1.  The user accesses the application through its public domain.
2.  The public ALB terminates HTTPS using an ACM certificate.
3.  The public ALB forwards requests to frontend instances on port
    `8080`.
4.  Nginx serves the frontend and reverse-proxies API requests to
    `backend.vault.internal`.
5.  The private Route 53 hosted zone resolves that name to the internal
    ALB.
6.  The internal ALB forwards requests to healthy backend instances on
    port `5000`.
7.  Flask communicates with RDS MySQL over TLS on port `3306`.

The internal ALB and backend instances are not directly accessible from
the internet.

## How the Application Works

SecureVault is a simple secrets-management application used to
demonstrate application and infrastructure security together.

### Frontend

-   Nginx serves the web interface.
-   JavaScript communicates with the backend through API requests.
-   Nginx reverse-proxies `/api` requests to the internal backend
    address.
-   The frontend does not connect directly to MySQL or AWS Secrets
    Manager.

### Backend

The backend uses:

-   Python
-   Flask
-   Gunicorn
-   PyMySQL
-   bcrypt
-   cryptography / Fernet
-   boto3

It handles authentication, session management, secret encryption,
database operations, and AWS Secrets Manager integration.

### Authentication and secret storage

**User authentication**

1.  Users register with a username and password.
2.  Passwords are hashed using bcrypt before being stored in MySQL.
3.  During login, the submitted password is verified against the stored
    hash.
4.  Flask creates a signed session cookie.
5.  Sessions expire after 30 minutes.

**Creating and storing secrets**

1.  The authenticated user submits a secret through the frontend.
2.  Flask encrypts the secret using Fernet.
3.  Only the encrypted value is stored in MySQL.
4.  When a user requests to reveal a secret, the backend verifies
    ownership, decrypts the value, and returns it.
5.  The frontend hides the revealed value again after 15 seconds.
6.  Users can delete their own stored entries.

### Application encryption keys

The backend retrieves its required values from AWS Secrets Manager:

-   `fernet_key`: encrypts and decrypts stored vault entries.
-   `session_key`: signs Flask session cookies.
-   The RDS-managed secret supplies the database credentials.

The backend retrieves these values at startup using its EC2 IAM role.

The same application keys are shared by backend instances so that any
healthy instance can decrypt existing entries and validate user
sessions.

**Important:** Losing the Fernet key means previously encrypted vault
entries cannot be decrypted.

## Security Implementation

Security is the primary focus of this project. Controls are implemented
at different infrastructure and application layers.

### 1. Network segmentation

Each application tier has its own security group.

  Source         Destination      Port Purpose
  -------------- -------------- ------ --------------------------
  Internet       Public ALB        443 HTTPS application access
  Public ALB     Frontend         8080 Forward web requests
  Frontend       Internal ALB       80 Internal API traffic
  Internal ALB   Backend          5000 Forward API requests
  Backend        RDS              3306 MySQL over TLS

Security group rules reference other security groups instead of using
broad CIDR ranges for internal application communication.

The database security group accepts connections only from the backend
security group.

### 2. Private compute and database tiers

-   EC2 instances run in private subnets.
-   EC2 instances do not receive public IP addresses.
-   RDS is not publicly accessible.
-   Database subnets have no default internet route.
-   The internal ALB is private.
-   Only the public ALB is exposed to internet traffic.

### 3. IAM least privilege

Separate IAM roles are created for the frontend and backend.

**Frontend role:**

-   Systems Manager access.
-   Pull access to the frontend ECR repository.
-   No permission to read application secrets.

**Backend role:**

-   Systems Manager access.
-   Pull access to the backend ECR repository.
-   Read access to the required Secrets Manager secrets.

No static AWS access keys are stored in the application or EC2 user-data
scripts.

### 4. Secure instance management

SSH is not used.

-   No inbound port 22.
-   No public IP addresses.
-   Systems Manager Session Manager provides administrative access.
-   IMDSv2 is required.
-   The frontend uses metadata hop limit 1.
-   The backend uses metadata hop limit 2 because its container needs to
    retrieve the EC2 instance role credentials.

### 5. Container hardening

The EC2 user-data scripts start containers with security restrictions:

-   Read-only container filesystem.
-   Temporary writable `/tmp` filesystem.
-   All Linux capabilities dropped.
-   Privilege escalation disabled.
-   Process limits.
-   Container memory limits.
-   Docker log rotation.

The backend uses a Distroless runtime image and runs as a non-root user.

### 6. Encryption

**Amazon S3**

All three manually managed S3 buckets use default server-side
encryption:

-   `depi-terraform-backend`
-   `depi-alb-logs`
-   `depi-cloudtrail`

The Terraform backend bucket has additional data-protection
configuration:

-   S3 versioning is enabled to preserve previous object versions.
-   The `terraform-backend-lifecycle` lifecycle rule is enabled.
-   Current object versions have no expiration action configured.
-   Noncurrent versions are retained for 30 days, with the 10 newest
    noncurrent versions retained.
-   Other noncurrent versions are permanently deleted after 30 days.

This lifecycle rule helps control the storage growth of historical
Terraform state versions. It does not expire the current state object.

**Other encryption controls**

-   RDS storage encryption is enabled.
-   EC2 root EBS volumes use encrypted gp3 storage.
-   Application vault entries are encrypted using Fernet before being
    stored in MySQL.
-   Database connections use TLS with RDS CA certificate verification.
-   HTTPS is used between the browser and public ALB.
-   The public ALB uses an ACM certificate and a TLS 1.3 / TLS 1.2
    security policy.

### 7. AWS Secrets Manager

The project avoids storing database passwords and application keys in
container images.

-   RDS manages its master password and stores the credentials in
    Secrets Manager.
-   Terraform creates the application secret and generates the Fernet
    and session keys.
-   The backend IAM role can retrieve only the required secret ARNs.

Terraform state is sensitive because it contains information about
managed resources, including the generated application secret value.
Protect access to the state bucket accordingly.

### 8. AWS WAF

A regional Web ACL is associated with the public ALB.

It includes:

-   AWS Managed Common Rule Set.
-   AWS Managed Known Bad Inputs Rule Set.
-   AWS Managed IP Reputation List.
-   A rate-based rule using IP aggregation.

The rate-based rule blocks requests when an IP exceeds 1,000 requests
within a five-minute evaluation window.

The managed rule groups use their configured AWS rule actions.

### 9. CloudTrail

CloudTrail records AWS account management activity.

Configuration includes:

-   Multi-region trail.
-   Global service events.
-   Read and write management events.
-   Log file integrity validation.
-   Delivery to a dedicated S3 bucket.

The CloudTrail trail is managed by Terraform, while its destination
bucket and bucket policy are maintained manually.

### 10. GuardDuty

GuardDuty is enabled in the configured AWS region to monitor supported
AWS data sources and identify suspicious activity.

### 11. CloudWatch monitoring

Five metric alarms are configured:

  Alarm                            What it monitors
  -------------------------------- ------------------------------------
  Public ALB unhealthy targets     Unhealthy frontend targets
  Internal ALB unhealthy targets   Unhealthy backend targets
  Public ALB 5xx errors            Errors generated by the public ALB
  RDS CPU utilization              High database CPU
  RDS free storage                 Low available database storage

Missing metric data is treated as not breaching, avoiding false alarms
when the application is not receiving traffic.

RDS error and slow-query logs are exported to CloudWatch Logs with
30-day retention.

CloudWatch alarms currently change alarm state but do not send email
notifications. SNS notification integration was intentionally removed.

## AWS Services

  Service                     Role in the project
  --------------------------- ------------------------------------------------
  Amazon VPC                  Network isolation
  EC2                         Runs frontend and backend containers
  Auto Scaling Groups         Maintains and replaces instances
  Application Load Balancer   Public and internal traffic distribution
  Amazon RDS MySQL            Persistent application database
  Amazon ECR                  Container image registry
  AWS IAM                     Instance roles and least-privilege permissions
  AWS Secrets Manager         Database credentials and application keys
  Amazon Route 53             Private internal DNS
  AWS Certificate Manager     Public ALB TLS certificate
  AWS WAF                     Web application protection
  Amazon S3                   Terraform state, ALB logs, and CloudTrail logs
  AWS Systems Manager         Secure instance administration
  AWS CloudTrail              AWS account activity logging
  Amazon GuardDuty            Threat detection
  Amazon CloudWatch           Metrics, alarms, and database logs

## Terraform Structure

The Terraform configuration is located in the `terraform/` directory.

``` text
terraform/
├── backend.tf
├── provider.tf
├── main.tf
├── outputs.tf
├── cloudtrail.tf
├── cloudwatch-alarms.tf
├── guardduty.tf
├── modules/
│   ├── alb/
│   ├── asg/
│   ├── iam/
│   ├── networking/
│   ├── rds/
│   ├── route53-private-zone/
│   ├── secrets-manager/
│   ├── security-groups/
│   └── waf/
└── templates/
    ├── backend_user_data.sh.tftpl
    └── frontend_user_data.sh.tftpl
```

The root module connects the reusable modules and contains the fixed
project configuration in `main.tf`.

The project uses:

-   Terraform `1.17.1`
-   AWS provider `6.71.0`
-   Random provider `3.9.1`
-   S3 remote state with native S3 lockfile support

### Pre-commit checks

The repository uses pre-commit hooks for:

-   Terraform formatting.
-   Terraform validation.
-   TFLint.
-   Terraform documentation generation.
-   Trailing whitespace and file hygiene.
-   Private-key and AWS credential detection.
-   Gitleaks secret scanning.
-   KICS Terraform security scanning.

## Prerequisites

Before deployment, install and configure:

-   Terraform `1.17.1`.
-   AWS CLI.
-   Docker.
-   Git.
-   An AWS account with permissions to create the required
    infrastructure.
-   An ACM certificate for the application domain in `us-east-2`.
-   A registered domain and access to its DNS configuration.

Configure AWS CLI credentials using an appropriate profile or
environment credentials.

Verify the identity before deploying:

``` bash
aws sts get-caller-identity
```

The Terraform provider uses `us-east-2`.

## Resources Created Outside Terraform

Some resources are deliberately created and maintained manually.
Terraform references them but does not manage their lifecycle.

Create these resources before the first Terraform deployment.

  Resource          Name                            Purpose
  ----------------- ------------------------------- -------------------------------------
  S3 bucket         `depi-terraform-backend`        Remote Terraform state
  S3 bucket         `depi-alb-logs`                 Public and internal ALB access logs
  S3 bucket         `depi-cloudtrail`               CloudTrail log delivery
  ECR repository    `vault-frontend`                Frontend container image
  ECR repository    `vault-backend`                 Backend container image
  ACM certificate   `vault.mostafa-medhat.online`   HTTPS certificate
  Domain and DNS    Namecheap                       Public application DNS

### S3 buckets

Create all three buckets in `us-east-2` and keep them private.

All three buckets have default server-side encryption enabled.

**Terraform backend bucket --- `depi-terraform-backend`**

-   Stores Terraform state at `tf-state/terraform.tfstate`.
-   S3 versioning is enabled.
-   Native S3 state locking is enabled through `use_lockfile = true`.
-   The enabled lifecycle rule `terraform-backend-lifecycle` retains the
    10 newest noncurrent versions and permanently deletes other
    noncurrent versions after 30 days.
-   Current versions do not have an expiration action.

**ALB access logs bucket --- `depi-alb-logs`**

-   Configure the required ALB log-delivery bucket policy.
-   The Terraform configuration writes logs using two prefixes:
    -   `public-alb`
    -   `internal-alb`

**CloudTrail bucket --- `depi-cloudtrail`**

-   Configure the CloudTrail bucket policy before creating the trail.
-   Terraform creates the trail, not the bucket or its policy.

### ECR repositories

Create these repositories manually:

-   `vault-frontend`
-   `vault-backend`

Enable **Amazon ECR Enhanced Scanning on push** for both repositories.
This configuration is outside Terraform.

Enhanced Scanning is backed by Amazon Inspector. It scans images when
they are pushed and continuously updates findings for eligible images as
new vulnerabilities are identified.

The repositories use immutable image tags. Publish a new tag for each
image update rather than trying to overwrite an existing tag.

### ACM certificate and DNS

Request and validate an ACM certificate for:

`vault.mostafa-medhat.online`

The certificate must be in `us-east-2` because it is attached to the
public ALB.

After Terraform creates the public ALB, create or update the Namecheap
DNS record:

  Type    Host      Value
  ------- --------- -------------------------------------------
  CNAME   `vault`   Public ALB DNS name from Terraform output

The public application URL is:

`https://vault.mostafa-medhat.online`

The private hosted zone `vault.internal` and its
`backend.vault.internal` record are created by Terraform.

## Build and Deploy

### 1. Prepare the application images

Build the backend and frontend images from the application source.

Authenticate Docker to ECR:

``` bash
aws ecr get-login-password --region us-east-2 \
  | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-2.amazonaws.com
```

Build and tag the backend and frontend images using the Dockerfiles and
build arguments in the application repository.

The frontend image must be configured to use the internal backend
address:

`http://backend.vault.internal`

Push both images to their corresponding ECR repositories:

``` bash
docker push <ACCOUNT_ID>.dkr.ecr.us-east-2.amazonaws.com/vault-backend:<IMAGE_TAG>

docker push <ACCOUNT_ID>.dkr.ecr.us-east-2.amazonaws.com/vault-frontend:<IMAGE_TAG>
```

Use a new tag when publishing updated images because the ECR
repositories use immutable tags.

Update the image tags in the root Terraform configuration before
deployment if they differ from the configured values.

### 2. Initialize Terraform

From the Terraform directory:

``` bash
cd terraform
terraform init
```

Terraform connects to the existing S3 backend and initializes the
providers and modules.

### 3. Review the deployment plan

``` bash
terraform plan
```

Review the resources before applying.

### 4. Deploy the infrastructure

``` bash
terraform apply
```

Review and confirm the plan when prompted.

The Auto Scaling Groups are configured with:

  Setting               Value
  ------------------- -------
  Minimum instances         2
  Desired instances         2
  Maximum instances         4

Both tiers run across two Availability Zones.

### 5. Review Terraform outputs

``` bash
terraform output
```

Use the outputs to identify the public ALB DNS name, application URL,
internal DNS name, RDS address, Auto Scaling Groups, and security group
IDs.

Create or update the Namecheap CNAME using the public ALB DNS output if
it is not already configured.

### 6. Verify deployment

Before considering the deployment complete, verify:

-   Both Auto Scaling Groups have healthy instances.
-   Both ALB target groups show healthy targets.
-   The backend can retrieve its required secrets.
-   The backend connects to RDS successfully over TLS.
-   The frontend can reach the backend through the private DNS name.
-   The application is accessible through the public domain.
-   WAF rules are active.
-   CloudTrail delivers logs to S3.
-   GuardDuty is enabled.
-   CloudWatch alarms exist and receive metrics.

## Accessing the Application

The application is available at:

`https://vault.mostafa-medhat.online`

Administrative access to EC2 instances is through AWS Systems Manager
Session Manager.

No SSH key or public IP is required.

## Security Validation

The project should be validated by testing the security controls, not
simply confirming that the application loads.

  -----------------------------------------------------------------------
  Area                                What to verify
  ----------------------------------- -----------------------------------
  Network isolation                   Database and backend are not
                                      publicly accessible

  Security groups                     Only intended tier-to-tier ports
                                      are allowed

  IAM                                 Frontend cannot retrieve
                                      application secrets; backend can
                                      retrieve only its required secrets

  Instance management                 SSM works and SSH is unavailable

  IMDSv2                              Token-based metadata access is
                                      enforced

  Encryption                          RDS storage, EBS volumes, S3
                                      buckets, and database transport are
                                      encrypted

  S3 protection                       Backend bucket versioning and
                                      lifecycle behavior are configured
                                      as intended

  Secrets Manager                     Backend retrieves the correct
                                      secrets using its instance role

  WAF                                 Managed rules and rate-based
                                      blocking behave as expected

  CloudTrail                          Management events are delivered to
                                      S3

  GuardDuty                           Detector is enabled in the
                                      deployment region

  ECR                                 Enhanced Scanning is enabled for
                                      both repositories

  CloudWatch                          Alarms receive metrics and
                                      transition states as expected

  Resilience                          Auto Scaling replaces unhealthy
                                      instances

  Database                            RDS Multi-AZ configuration and
                                      backups are enabled
  -----------------------------------------------------------------------

For meaningful evidence, retain screenshots, CLI outputs, CloudWatch
alarm history, WAF test results, and relevant AWS service configuration.

## Destroying the Infrastructure

This project is designed for temporary demonstrations and testing. The
infrastructure can be destroyed when it is no longer needed.

From the Terraform directory:

``` bash
terraform destroy
```

Review the destruction plan before confirming.

### Resources Terraform destroys

Examples include:

-   VPC and subnets.
-   Internet Gateway and regional NAT Gateway.
-   Route tables and security groups.
-   Public and internal ALBs.
-   Auto Scaling Groups and their EC2 instances.
-   RDS instance and related database resources.
-   Route 53 private hosted zone and record.
-   Secrets Manager application secret, subject to its configured
    recovery window.
-   WAF Web ACL.
-   CloudTrail trail.
-   GuardDuty detector.
-   CloudWatch alarms and managed log groups.

### Resources that remain after Terraform destroy

The following resources are manually managed and are not deleted by
Terraform:

-   `depi-terraform-backend` --- Terraform state.
-   `depi-alb-logs` --- ALB access logs.
-   `depi-cloudtrail` --- CloudTrail logs.
-   `vault-frontend` ECR repository.
-   `vault-backend` ECR repository.
-   ACM certificate.
-   Namecheap domain and DNS configuration.

S3 bucket contents and ECR images remain unless manually deleted.

**Important database warning:** The current RDS configuration uses
`skip_final_snapshot = true`. Destroying the database therefore does not
create a final snapshot. Database data will be lost.

The application secret has a seven-day recovery window. If you destroy
and immediately recreate the infrastructure, a pending secret deletion
may need to be cancelled before Terraform can create a secret with the
same name.

The Terraform backend bucket must remain available. Do not delete it
when destroying the application infrastructure.

## Limitations and Design Decisions

This is a portfolio and demonstration environment, not a production
service intended for real customer secrets.

Current design trade-offs include:

-   One regional NAT Gateway is used to reduce operational complexity
    and cost compared with deploying separate NAT Gateways per
    Availability Zone.
-   Both Auto Scaling Groups have a minimum and desired capacity of two,
    with a maximum of four.
-   The database uses a small instance class.
-   The database backup retention period is one day.
-   The current RDS destroy configuration skips the final snapshot.
-   CloudWatch alarms do not currently send email notifications.
-   HTTP-to-HTTPS redirection on port 80 is not implemented; the public
    ALB currently exposes its HTTPS listener on port 443.
-   The backend uses the RDS-managed master credentials. A separate
    restricted application database user is a potential improvement.
-   Container image vulnerability remediation and base-image upgrades
    are deferred.

## To Do Later

The following improvements are intentionally outside the current
implementation scope:

-   [ ] Add an HTTP port 80 listener that redirects to HTTPS 443.
-   [ ] Add SNS notifications for CloudWatch alarms.
-   [ ] Evaluate AWS Config and Security Hub CSPM.
-   [ ] Consider VPC endpoints to reduce reliance on NAT for supported
    AWS services.
-   [ ] Review and improve database user privileges.
-   [ ] Review application-level CSRF protection and login rate
    limiting.
-   [ ] Review secret rotation and Fernet key rotation procedures.
-   [ ] Update the backend Distroless base image and Python runtime.
-   [ ] Review and remediate outstanding Trivy HIGH and CRITICAL
    findings.
-   [ ] Perform additional security testing and document the results.
-   [ ] Evaluate multi-AZ NAT deployment if stronger network egress
    availability is required.

------------------------------------------------------------------------

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
