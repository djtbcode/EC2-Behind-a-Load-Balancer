# ALB Security Group Validation

## Goal

Move the EC2 instance properly behind the Application Load Balancer by removing direct public HTTP access to the instance.

Expected traffic path:

```text
Internet -> ALB :80 -> EC2 :80
```

Blocked path:

```text
Internet -> EC2 :80
```

## Terraform change

Updated the EC2 security group.

Before, EC2 allowed HTTP from anywhere:

```hcl
cidr_blocks = ["0.0.0.0/0"]
```

After, EC2 only allows HTTP from the ALB security group:

```hcl
security_groups = [
  aws_security_group.alb_sg.id
]
```

Terraform plan showed the intended in-place update:

```text
Plan: 0 to add, 1 to change, 0 to destroy.
```

## Pre-change check

Direct HTTP access to EC2 worked:

```bash
curl http://ec2-3-8-232-208.eu-west-2.compute.amazonaws.com
```

Output:

```text
EC2 instance running behind future load balancer
```

## Post-change check

Direct HTTP access to EC2 no longer worked:

```bash
curl --connect-timeout 5 http://ec2-3-8-232-208.eu-west-2.compute.amazonaws.com
```

Result: timed out / hung until cancelled.

This confirmed public HTTP access to the EC2 instance had been removed.

## ALB check

Traffic through the ALB still worked:

```bash
curl http://ec2-lb-lab-alb-132526376.eu-west-2.elb.amazonaws.com
```

Output:

```text
EC2 instance running behind future load balancer
```

Health check endpoint also worked:

```bash
curl http://ec2-lb-lab-alb-132526376.eu-west-2.elb.amazonaws.com/health
```

Output:

```text
OK
```

## Target group health

Checked the target group health from the Terraform output:

```bash
aws elbv2 describe-target-health \
  --target-group-arn "$(terraform output -raw target_group_arn)" \
  --query "TargetHealthDescriptions[].{Target:Target.Id,Port:Target.Port,State:TargetHealth.State,Reason:TargetHealth.Reason,Description:TargetHealth.Description}" \
  --output table
```

Result:

```text
Target: i-06be8e9d6aa6b52c0
Port: 80
State: healthy
```

## Result

The EC2 instance is no longer directly reachable from the internet over HTTP.

The ALB can still reach the EC2 instance and the target group reports the instance as healthy.
