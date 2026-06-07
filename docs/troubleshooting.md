# Troubleshooting Notes

## AWS CLI login and Terraform credentials

### Issue

This project uses AWS CLI login rather than long-term IAM access keys.

The AWS CLI was able to authenticate successfully:

```bash
aws login
aws sts get-caller-identity
```

However, Terraform could not use the AWS CLI login session directly. To allow Terraform to authenticate, temporary AWS credentials were exported from the AWS CLI session into environment variables:

```bash
eval "$(aws configure export-credentials --format env)"
```

### Error encountered

During one session, the AWS CLI credential cache became stale and returned:

```bash
aws: [ERROR]: Credentials were refreshed, but the refreshed credentials are still expired.
```

### Resolution

The stale session was cleared by logging out and removing any existing AWS credential environment variables:

```bash
aws logout

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
unset AWS_SECURITY_TOKEN
unset AWS_PROFILE
```

A fresh login was then completed:

```bash
aws login
eval "$(aws configure export-credentials --format env)"
aws sts get-caller-identity
```

After this, Terraform was able to authenticate successfully.

---

## Terraform workflow

The initial Terraform setup was validated with:

```bash
terraform init
terraform fmt
terraform validate
```

Expected validation output:

```bash
Success! The configuration is valid.
```

After configuring `main.tf` and `outputs.tf`, the configuration was checked again:

```bash
terraform fmt
terraform validate
terraform plan
```

---

## EC2 instance type Free Tier issue

### Issue

The first Terraform apply attempted to create a `t2.micro` instance. AWS rejected this because the instance type was not eligible for the current account's Free Tier.

### Resolution

The instance type was changed to a Free Tier eligible type:

```hcl
instance_type = "t3.micro"
```

A fresh plan was then run:

```bash
terraform plan
```

---

## Terraform apply interrupted and resource tainting

### Issue

During `terraform apply`, the EC2 instance was created in AWS, but the apply process stalled after the AWS credential/session issue.

The apply was interrupted with:

```bash
Ctrl+C
```

After credentials were refreshed, Terraform detected the EC2 instance in state but marked it as tainted:

```bash
aws_instance.web is tainted, so must be replaced
```

Terraform then planned to destroy and recreate the instance:

```bash
-/+ destroy and then create replacement
```

### Investigation

Terraform state was checked:

```bash
terraform state list
```

The state showed that Terraform was tracking both the EC2 instance and security group:

```bash
data.aws_ami.amazon_linux
data.aws_vpc.default
aws_instance.web
aws_security_group.web_sg
```

The EC2 instance was also confirmed as running in the AWS Console.

### Resolution

Since the instance was running correctly and Terraform was already tracking it, the taint was removed:

```bash
terraform untaint aws_instance.web
```

A fresh plan was run:

```bash
terraform plan
```

Terraform then showed only output value updates for the public IP, public DNS, and website URL. These were applied to update local Terraform state:

```bash
terraform apply
```

---

## Cleanup

After testing, all resources were destroyed:

```bash
terraform destroy
```

Terraform state was checked afterwards:

```bash
terraform state list
```

The state list was blank, confirming Terraform no longer tracked any deployed resources.

The AWS Console was also checked to confirm:

- The EC2 instance was terminated
- The security group was removed
- No unexpected resources remained running