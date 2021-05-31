# cicd-build
Powershell script to provision an ec2 instance and deploy sonarqube and jenkins to it

## Usage
1. Clone the repo
2. Create your VPC, NSGs, IAM configs etc
3. ./build.ps1
4. The script gives some high level debug info about what its doing, and any progress milestone messages it gets back from the instance
5. You can monitor the progress of the build in detail by SSHing into the instance and tailing /var/log/user-data.log
6. Once complete, you'll be prompted to:
    - Change the admin password for sonarqube
    - Complete the initial config of Jenkins.  The script will give you the first time setup code to enter into the Jenkins web UI

### Example output
````
PS C:\Users\Chris\jenkins-build> .\build.ps1
Debug: Reservation ID is r-04e256cbeb47bf906, new instance ID is i-023787b10ee9c0d02
Debug: New instance is not up yet, sleeping 10 seconds
Debug: New instance is not up yet, sleeping 10 seconds
Debug: New instance is not up yet, sleeping 10 seconds
Debug: New instance is not up yet, sleeping 10 seconds
Debug: New instance is not up yet, sleeping 10 seconds
Debug: New instance is not up yet, sleeping 10 seconds
Debug: New instance is still running user-data, sleeping 10 seconds
Debug: New instance is still running user-data, sleeping 10 seconds
Debug: New instance is still running user-data, sleeping 10 seconds
Debug: New instance is still running user-data, sleeping 10 seconds
Debug: New instance is still running user-data, sleeping 10 seconds
Debug: Status update: Reached jenkins package install
Debug: New instance is still running user-data, sleeping 10 seconds
Debug: Status update: Reached Postgres sleep
Debug: New instance is still running user-data, sleeping 10 seconds
Debug: New instance is still running user-data, sleeping 10 seconds
Debug: New instance is still running user-data, sleeping 10 seconds
Debug: Status update: Reached sonarqube
Debug: New instance has finished user-data
Finished building Jenkins on instance ID i-023787b10ee9c0d02, public IP is 35.164.190.76
Go to http://35.164.190.76:8080 to finish Jenkins configuration.  The first time code to unlock the config is
abcdefghijklmnopqrstuvwxyz
Go to http://35.164.190.76:9000 to finish Sonarqube configuration AND CHANGE THE DEFAULT PASSWORD
````

## To do
1. Automate the Jenkins config that is usually UI driven
2. Automate changing the sonarqube admin password

## Requires
- Because of hardcoded laziness/no need to gold plate:
    - AWS region us-west-2 (because AMI ID differs per region)
    - SSH keyname chris2
    - security group sg-8b5c50ee
    - my account ID
- IAM setup
    - A policy attached to the EC2 instances and the requesting user, allowing interaction with SSM, which is used to hand EC2 build status from the EC2 instance back to the user, as well as storing secrets (postgres password, Jenkins initial config key etc).  This is hard coded to be named jenkins-build-ec2roleapplied.  The ARNs are hard coded too
    - A policy attached to the requesting user which allows them to give the PassRole to EC2 instances

### Network Security Group
- 80
- 8080
- 9000

### Contents of the passrole IAM policy
```
{
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
                "Resource": "arn:aws:iam::xxxxxxxxx:role/jenkins-build-ec2roleapplied"
            }
        ]
    }
}
```
### Contents of SSM IAM policy arn:aws:iam::xxxxxxxxx:policy/SSM-writetags-jenkins-build
```
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
                "arn:aws:ssm:us-west-2:xxxxxxxxx:parameter/*",
                "arn:aws:ssm:*:xxxxxxxxx:parameter/*"
            ]
        }
    ]
}
```
