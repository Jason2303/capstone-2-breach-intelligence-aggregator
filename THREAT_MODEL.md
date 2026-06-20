# Threat Model — AWS Breach Intelligence Aggregator

## Overview

This document applies the STRIDE threat modelling framework to the AWS Breach Intelligence Aggregator. The solution accepts email addresses through an API endpoint, orchestrates breach intelligence lookups using AWS Step Functions and Lambda functions, enriches results with analytics, generates reports, and delivers findings through secure report distribution mechanisms.

Because the system processes potentially sensitive breach exposure information and stores generated reports, confidentiality, integrity, availability, and auditability are primary security concerns.

---

## Architecture Summary

```text
User
  ↓
API Gateway
  ↓
Lambda 1 (Request Handler)
  ↓
Step Functions
  ↓
Lambda 2 (HIBP Query) → Secrets Manager
  ↓
Lambda 3 (Athena Analytics)
  ↓
Lambda 4 (Report Generator)
  ↓
S3 Report Bucket
  ↓
SNS Notification → User

CloudTrail → S3 + CloudWatch Logs

All major services encrypted using KMS CMK
```

---

## Assets

| Asset                                            | Classification | Sensitivity |
| ------------------------------------------------ | -------------- | ----------- |
| User email addresses submitted for breach checks | Confidential   | High        |
| HIBP API key stored in Secrets Manager           | Critical       | Critical    |
| Generated breach reports                         | Confidential   | High        |
| Athena query results                             | Confidential   | High        |
| CloudTrail audit logs                            | Internal       | High        |
| Presigned report URLs                            | Confidential   | High        |
| IAM execution roles and policies                 | Internal       | High        |
| Step Functions workflow definitions              | Internal       | High        |
| KMS Customer Managed Key                         | Critical       | Critical    |
| Terraform state file                             | Internal       | High        |
| Glue table schema                                | Internal       | Medium      |
---

## Trust Boundaries

1. **External User → API Gateway** — Users submit breach scan requests through a public HTTPS endpoint.
2. **API Gateway → Lambda 1** — API Gateway validates and forwards requests to the ingestion Lambda.
3. **Lambda 1 → Step Functions** — Workflow execution is initiated using IAM-controlled permissions.
4. **Step Functions → Lambda 2/3/4** — State machine orchestrates multiple Lambda functions with scoped permissions.
5. **Lambda 2 → Secrets Manager / HIBP API** — Internal AWS resources communicate with an external third-party breach intelligence provider.
6. **Lambda Functions → S3 / Athena / SNS** — Downstream service interactions occur under least-privilege IAM permissions.
7. **CloudTrail → S3 / CloudWatch Logs** — Audit logs are delivered to dedicated logging resources.

---

# STRIDE Analysis

## Spoofing

| Threat                           | Description                                                                                                 | Likelihood | Impact   |
| -------------------------------- | ----------------------------------------------------------------------------------------------------------- | ---------- | -------- |
| Unauthenticated API requests     | An attacker submits scan requests while impersonating legitimate users because the API lacks authentication | High       | Medium   |
| Direct Step Functions invocation | An attacker bypasses API Gateway and starts workflow executions directly                                    | Low        | High     |
| Direct Lambda invocation         | An attacker invokes Lambda functions directly and provides forged scan identifiers                          | Low        | High     |
| Unauthorized SNS publishing      | An attacker publishes fake notifications to SNS topics                                                      | Low        | Medium   |
| IAM credential compromise        | An attacker impersonates a trusted AWS principal to access pipeline resources                               | Low        | Critical |

### Mitigations

* API Gateway serves as the intended entry point for all scan requests.
* AWS WAF is attached to API Gateway to filter malicious requests and automated abuse.
* IAM policies restrict `states:StartExecution` permissions to authorized principals only.
* SNS topics are protected through IAM policies that only allow approved publishers.
* CloudTrail logs all workflow executions, Lambda invocations, SNS publishes, and IAM role assumptions.
* Least-privilege IAM roles are implemented across all services.

### Residual Risk

The pipeline currently does not implement user authentication through Amazon Cognito or another identity provider. Any user capable of reaching the API endpoint can submit requests. Authentication and authorization controls would significantly reduce spoofing risk in a production environment.

---

## Tampering

| Threat                              | Description                                                        | Likelihood | Impact   |
| ----------------------------------- | ------------------------------------------------------------------ | ---------- | -------- |
| Report modification in S3           | An attacker alters generated breach reports before retrieval       | Low        | High     |
| Secrets Manager value modification  | A privileged user modifies the HIBP API key or related secrets     | Low        | High     |
| Step Functions definition tampering | Workflow logic is altered to skip controls or manipulate outputs   | Low        | High     |
| Terraform state file tampering      | Infrastructure state is modified to introduce unauthorized changes | Low        | High     |
| Lambda configuration tampering      | Environment variables or runtime settings are altered              | Low        | Medium   |
| CloudTrail log modification         | Audit evidence is altered or deleted                               | Low        | Critical |

### Mitigations

* S3 buckets use SSE-KMS encryption.
* S3 versioning is enabled to recover modified or deleted objects.
* KMS key policies restrict key usage to approved services and roles.
* CloudTrail log file validation detects unauthorized log modifications.
* Terraform code is scanned using Checkov before deployment.
* IAM permissions limit who can modify Step Functions definitions, Lambda configurations, and Secrets Manager values.
* S3 public access block prevents unauthorized modifications through public access paths.

### Residual Risk

S3 Object Lock is currently not enabled. Although versioning allows recovery of deleted objects, a sufficiently privileged administrator could still permanently remove versions. Implementing Object Lock in Governance mode would significantly reduce this risk.

---

## Repudiation

| Threat                                | Description                                                         | Likelihood | Impact |
| ------------------------------------- | ------------------------------------------------------------------- | ---------- | ------ |
| User denies submitting a scan request | A user disputes having initiated a breach scan                      | Medium     | Medium |
| Workflow execution denial             | An operator denies starting or modifying a Step Functions execution | Low        | High   |
| Report generation denial              | A Lambda function action cannot be conclusively attributed          | Low        | Medium |
| Presigned URL access denial           | A recipient denies accessing a generated report                     | Medium     | Medium |

### Mitigations

* API Gateway access logs record request metadata, timestamps, and source information.
* CloudTrail records all API activity including Step Functions executions, Lambda invocations, IAM actions, and S3 access.
* CloudTrail log file validation protects audit log integrity.
* CloudWatch Logs capture execution details from Lambda functions and Step Functions.
* CloudTrail logs are stored in encrypted S3 buckets with retention controls.
* SNS notifications provide traceable workflow completion records.

### Residual Risk

Presigned URL access can be traced to the URL usage event but cannot definitively prove which individual accessed the report if the link is shared. Stronger attribution would require authenticated report retrieval rather than anonymous presigned URL access.

---

## Information Disclosure

| Threat                               | Description                                                                   | Likelihood | Impact   |
| ------------------------------------ | ----------------------------------------------------------------------------- | ---------- | -------- |
| Exposure of generated breach reports | Unauthorized access to stored reports reveals sensitive breach information    | Low        | High     |
| Secrets Manager disclosure           | HIBP API key is exposed to unauthorized users or services                     | Low        | Critical |
| SNS notification data leakage        | Notifications contain breach information that may be visible in email systems | Medium     | Medium   |
| Athena query results exposure        | Analytics output becomes accessible to unauthorized users                     | Low        | High     |
| CloudWatch log leakage               | Sensitive breach data is accidentally logged by Lambda functions              | Medium     | High     |
| Presigned URL leakage                | Report access links are forwarded or intercepted                              | Medium     | High     |

### Mitigations

* S3, SNS, CloudWatch Logs, Athena outputs, and Lambda environment variables use KMS encryption.
* Secrets Manager securely stores API credentials with IAM-controlled access.
* Presigned URLs are time-limited and generated only when needed.
* S3 public access block prevents anonymous bucket access.
* IAM policies follow least-privilege principles.
* TLS protects data in transit between AWS services and users.

### Residual Risk

Although full reports are delivered through presigned URLs rather than email attachments, SNS notifications may still contain summary breach information. Email remains an inherently less controlled communication channel than authenticated portal access.

---

## Denial of Service

| Threat                            | Description                                                   | Likelihood | Impact |
| --------------------------------- | ------------------------------------------------------------- | ---------- | ------ |
| API request flooding              | Excessive requests overwhelm downstream services              | Medium     | High   |
| Step Functions execution flooding | Large numbers of workflow executions consume service capacity | Medium     | High   |
| Lambda concurrency exhaustion     | Concurrent scans exhaust available Lambda capacity            | Medium     | High   |
| Secrets Manager throttling        | High request volume causes secret retrieval failures          | Low        | Medium |
| DLQ saturation                    | Failed requests accumulate without remediation                | Medium     | Medium |
| External API rate limiting        | HIBP rate limits prevent successful breach lookups            | Medium     | Medium |

### Mitigations

* AWS WAF enforces request rate limiting at the API layer.
* API Gateway throttling limits excessive requests.
* Dead Letter Queues capture failed processing attempts.
* CloudWatch alarms monitor DLQ depth and workflow failures.
* Step Functions provides built-in retry mechanisms.


### Residual Risk

Reserved concurrency is not configured for all Lambda functions. A sufficiently large request volume could still consume available account-level concurrency and affect unrelated workloads.

---

## Elevation of Privilege

| Threat                                   | Description                                                                    | Likelihood | Impact   |
| ---------------------------------------- | ------------------------------------------------------------------------------ | ---------- | -------- |
| Unauthorized Secrets Manager access      | A role gains `secretsmanager:GetSecretValue` permissions beyond intended scope | Low        | Critical |
| Overly permissive Lambda execution roles | Lambda functions obtain access to resources outside their responsibilities     | Low        | High     |
| Shared KMS key misuse                    | Compromise of one service increases access to data encrypted by the same CMK   | Low        | High     |
| Step Functions privilege escalation      | Workflow execution role gains access to unintended services                    | Low        | High     |
| API endpoint abuse                       | An attacker discovers the endpoint and leverages excessive permissions         | Medium     | Medium   |

### Mitigations

* IAM roles implement least-privilege permissions.
* Secrets Manager access is restricted to only the Lambda functions that require the secret.
* KMS key policies explicitly scope service and role access.
* Terraform-managed IAM policies undergo Checkov security scanning.
* CloudTrail records all privilege-related API activity.
* Rotation of KMS Customer Managed Key.
* Resource-level permissions restrict service interactions wherever supported.

### Residual Risk

A single customer-managed KMS key is shared across multiple services. While operationally simpler, this creates a larger blast radius if permissions are misconfigured or a trusted role is compromised.

---

## Summary of Residual Risks

| Risk                                        | Severity | Recommended Mitigation                                           |
| ------------------------------------------- | -------- | ---------------------------------------------------------------- |
| No user authentication on API endpoint      | High     | Implement Amazon Cognito or federated authentication             |
| S3 Object Lock not enabled                  | Medium   | Enable Object Lock in Governance mode                            |
| Presigned URL sharing                       | Medium   | Require authenticated report access                              |
| SNS notification data exposure              | Medium   | Minimize email content and deliver details through secure portal |
| Step Functions execution flooding           | Medium   | Add throttling, quotas, and workflow protection controls         |
| Shared KMS key across services              | Low      | Implement service-specific KMS keys                              |
| Account-level Lambda concurrency exhaustion | Medium   | Configure reserved concurrency limits                            |
| Sensitive breach data logged by Lambda      | High     | Attach a CloudWatch Data Protection policy to Lambda CW Groups   |

---

## Assumptions and Scope

* This threat model focuses on AWS infrastructure and cloud-native security controls.
* Application-layer vulnerabilities within Lambda code are outside the scope of this assessment.
* The solution operates within a single AWS account.
* The Have I Been Pwned API is treated as a trusted third-party service.
* Generated reports may contain sensitive breach intelligence and should be handled according to organizational data classification requirements.
* User authentication is not currently implemented and is considered a known design limitation.
