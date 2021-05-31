function debugEcho {
	param (
		[parameter(mandatory)]
		[string]$debugText
	)
	
	write-output "Debug: $debugText"
	
}

$parameterVersion = Write-SSMParameter -name "/jenkins-build/server-build-status" -type "string" -value "-1" -overwrite $true
$parameterVersion = Write-SSMParameter -name "/jenkins-build/server-build-status-message" -type "string" -value "0" -overwrite $true

$userDataFile = 'jenkins-build-userdata.txt'

# set up user data - not used right now...
#$userDataString = Get-Content -Path $userDataFile | Out-String
#$userDataString = @"
#$userDataString
#"@
#$EncodeUserData = [System.Text.Encoding]::UTF8.GetBytes($userDataString)
#$userData = [System.Convert]::ToBase64String($EncodeUserData)

# create instance 

$Script = Get-Content -Raw jenkins-build-userdata.txt
$UserData = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($Script))

$instanceRequest = New-EC2Instance -ImageId ami-03d5c68bab01f3496 -MinCount 1 -MaxCount 1 -KeyName chris2 -SecurityGroupId sg-8b5c50ee -InstanceType t3a.medium -userdata $userData -iaminstanceprofile_name jenkins-build-ec2roleapplied

debugecho ("Reservation ID is " + $instanceRequest.reservationId  + ", new instance ID is " + $instanceRequest.instances[0].instanceId)
start-sleep 10

# wait 60 seconds for the instance to be up
$wait = 60
$sofar = 0

while ( $sofar -lt $wait )
{
	if ( ((get-ec2instancestatus -instanceid $instancerequest.instances[0]).status).status -eq "ok" )
	{
		debugecho "New instance is up"
		break
		
	} else {
		debugecho "New instance is not up yet, sleeping 10 seconds"
		
	}
	start-sleep -seconds 10
	$sofar += 10
		
}

# now wait for user data
$wait = 240
$sofar = 0

while ( $sofar -lt $wait )
{
	if ( (get-SSMParameter -name "/jenkins-build/server-build-status").value -eq "stage1" )
	{
		debugecho "New instance has finished user-data"
		break
		
	} else {
		if ( (get-SSMParameter -name "/jenkins-build/server-build-status-message").value -ne "0" ) 
		{
			debugecho ("Status update: " + (get-SSMParameter -name "/jenkins-build/server-build-status-message").value )
			$parameterVersion = Write-SSMParameter -name "/jenkins-build/server-build-status-message" -type "string" -value "0" -overwrite $true
			
		} else {
			debugecho "New instance is still running user-data, sleeping 10 seconds"
			
		}
		
		
	}
	
	start-sleep -seconds 10
	$sofar += 10
		
}

$reservation=""
$reservation = New-Object 'collections.generic.list[string]'
$reservation.add($instanceRequest.reservationId)
$filter_reservation = New-Object Amazon.EC2.Model.Filter -Property @{Name = "reservation-id"; Values = $reservation}
write-output ("Finished building Jenkins on instance ID " + $instanceRequest.instances[0].instanceId + ", public IP is " + ((Get-EC2Instance -Filter $filter_reservation).instances).publicipaddress) 
write-output ("Go to http://" + ((Get-EC2Instance -Filter $filter_reservation).instances).publicipaddress + ":8080 to finish Jenkins configuration.  The first time code to unlock the config is")
write-output ((get-SSMParameter -name "/jenkins-build/server-build-jenkinscode").value)
write-output ("Go to http://" + ((Get-EC2Instance -Filter $filter_reservation).instances).publicipaddress + ":9000 to finish Sonarqube configuration AND CHANGE THE DEFAULT PASSWORD") 

