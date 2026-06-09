# EC2-Behind-a-Load-Balancer

## Deployment validation bash script
Added a script to automate the validation of the deployment via aws & terraform:

Example output:
```
ALB URL: http://ec2-lb-lab-alb-132526376.eu-west-2.elb.amazonaws.com
EC2 URL: http://ec2-3-8-232-208.eu-west-2.compute.amazonaws.com
Target Group ARN: arn:aws:elasticloadbalancing:eu-west-2:163265929045:targetgroup/ec2-lb-lab-tg/11f028c32c437e99

Checking ALB homepage...
[PASS] ALB homepage reachable
Checking ALB health endpoint...
[PASS] ALB health endpoint returned OK
Checking target group health...
[PASS] Target group reports healthy
Confirming direct EC2 HTTP access is blocked...
[PASS] Direct EC2 HTTP access is blocked

Deployment validation complete.
```


## CI

This repo includes a basic GitHub Actions workflow for Terraform checks.

On push or pull request, it runs:

- `terraform fmt -check -recursive`
- `terraform init -backend=false`
- `terraform validate`

This is intentionally CI-only. It does not run `terraform apply` or make changes to AWS.
