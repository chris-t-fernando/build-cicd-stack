# cicd-build
Powershell script to provision an ec2 instance and deploy sonarqube and jenkins to it

Requires:
- Because of hardcoded laziness/no need to gold plate:
AWS region us-west-2 (because AMI ID differs per region)
    - SSH keyname chris2
    - security group sg-8b5c50ee
    - my account ID
- IAM setup
    - A policy attached to the EC2 instances and the requesting user, allowing interaction with SSM, which is used to hand EC2 build status from the EC2 instance back to the user, as well as storing secrets (pastgres password, Jenkins initial config key etc).  This is hard coded to be named jenkins-build-ec2roleapplied.  The ARNs are hard coded too
    - A policy attached to the requesting user which allows them to give the PassRole to EC2 instances


Contents of passrole IAM policy
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "arn:aws:iam::036372598227:role/jenkins-build-ec2roleapplied"
        }
    ]
}

Contents of SSM IAM policy arn:aws:iam::036372598227:policy/SSM-writetags-jenkins-build
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ssm:PutParameter",
                "ssm:GetParametersByPath",
                "ssm:GetParameters",
                "ssm:GetParameter"
            ],
            "Resource": [
                "arn:aws:ssm:us-west-2:036372598227:parameter/*",
                "arn:aws:ssm:*:036372598227:parameter/*"
            ]
        }
    ]
}
