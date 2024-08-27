#region Functions
function Compare-StringMatchLength
{
	<#
	.SYNOPSIS
		Compare each character of two string and return the postion they stop matching
	.DESCRIPTION
		Compare one string to another by looping through each character of both strings until
		there is a mismatch between character. Return the postion number value.
	.PARAMETER MainString
		The string that you want to compare
	.PARAMETER toString
		The string that you are comparing against
	.NOTES
		by Michael Escamilla
	#>
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]$MainString,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]$toString,
		[boolean]$CaseSensitive = $false
	)
	BEGIN
	{
		# Check if Strings match exactly
		if (!$CaseSensitive)
		{
			# Case insensitive
			if ($MainString -eq $toString)
			{
				return -1
			}
		}
		else
		{
			# Case Sensitive
			if ($MainString -ceq $toString)
			{
				return -1
			}
		}
	}
	PROCESS
	{
		$MainStringLength = $MainString.Length
		# Check if Strings match exactly
		if (!$CaseSensitive)
		{
			# Case insensitive
			for ($i = 0; $i -le $MainStringLength; $i++)
			{
				if ($MainString[$i] -ne $toString[$i])
				{
					return $i
				}
			}
		}
		else
		{
			# Case Sensitive
			for ($i = 0; $i -le $MainStringLength; $i++)
			{
				if ($MainString[$i] -cne $toString[$i])
				{
					return $i
				}
			}
		}
	}
	END
	{
		
	}
}
#endregion Functions

# Default Group eg: g123456789
$DefaultGroup = "<Add Default Group ID>"

## Build Web Call
# Auth Token
$token = "<Add Token Here>"
$bearer = "Bearer", $token

# Build Headers
$header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$header.Add("authorization", $bearer)

# API URIs
$pinguri = "https://webapi.teamviewer.com/api/v1/ping"
$groupsUri = 'https://webapi.teamviewer.com/api/v1/groups/'
$deviceUri = 'https://webapi.teamviewer.com/api/v1/devices/'
$usersUri = 'https://webapi.teamviewer.com/api/v1/users/'
$policiesUri = 'https://webapi.teamviewer.com/api/v1/teamviewerpolicies/'

# Ping Teamviewer API
$pingTest = Invoke-RestMethod -Uri $pinguri -Method Get -Headers $header

if ($pingTest.token_valid)
{
	# Get all devices from Teamviewer API
	$AllTVDevices = Invoke-RestMethod -Uri $deviceUri -Method Get -Headers $header
	# Get all groups from Teamviewer API
	$AllGroups = Invoke-RestMethod -Uri $groupsUri -Method Get -Headers $header
	# Get client id from Registery
	# Get client id from Registery
	if ($PSVersionTable.PSVersion.Major -ge 5)
	{
		$rControlId = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\WOW6432Node\TeamViewer" -Name "ClientID"
	}
	else
	{
		$rControlId = $(Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\TeamViewer" -Name "ClientID").ClientID
	}
	# Match ControlId with $AllDevices
	$TVDeviceInfo = $AllTVDevices.devices | Where-Object { $_.remotecontrol_id -eq "r$rControlId" }
	# Get OperatingSystem ProductType
	$OSProductType = (Get-WmiObject Win32_OperatingSystem).ProductType
	# Get SCCM User Information from Affinity
	#$UserAffinity = (Get-CimInstance -ClassName "CCM_UserAffinity" -Namespace "root\ccm\Policy\Machine\ActualConfig" -Property "ConsoleUser")
	$UserAffinity = (Get-CimInstance -ClassName "SMS_SystemConsoleUsage" -Namespace "root\cimv2\sms")
	if ($UserAffinity)
	{
		# Store Just Username
		#$UserAffinityValue = ($UserAffinity.ConsoleUser).ToString().Split('\\')[-1]
		$UserAffinityValue = ($UserAffinity.TopConsoleUser).ToString().Split('\\')[-1]
		# Check for local_users value
		if ($UserAffinityValue -eq "local_users")
		{
			$UserAffinityValue = $null
		}
	}
	### Set Desired TV Alias
	# Only add username if Workstation OS
	if ($OSProductType -eq 1)
	{
		if ($UserAffinityValue)
		{
			$DeviceAlias = "$env:COMPUTERNAME - $UserAffinityValue"
		}
		else
		{
			$DeviceAlias = "$env:COMPUTERNAME"
		}
	}
	else
	{
		$DeviceAlias = "$env:COMPUTERNAME"
	}
	### Set Desired TV Group
	# Set some initial variables
	$DeviceGroup = $null
	$TopGroupValue = 0
	foreach ($Group in $AllGroups.groups)
	{
		# Compare Computer Name to Group name
		$ComputerName = $($env:COMPUTERNAME)
		$Compare = Compare-StringMatchLength -MainString $ComputerName -toString $Group.name
		#Write-Output "CompName:  $($ComputerName) - GroupName: $($Group.name)  - CompareValue: $($Compare) - CurrentTopGroupID: $($DeviceGroup) - CurrentTopCompareValue: $($TopGroupValue)"
		# Check if Compare Value is equal to Group Name Length
		if ($Compare -eq $Group.name.Length)
		{
			# Check if current $Compare is Great than $TopCompareValue
			if ($Compare -gt $TopGroupValue)
			{
				# Set new Top Group Value
				$TopGroupValue = $Compare
				$DeviceGroup = $Group.id
			}
		}
	}
	# Set Default Group if No Match was Found
	if (!$DeviceGroup)
	{
		$DeviceGroup = "$($DefaultGroup)"
	}
	# Build Device Infomation to Write Back
	$putDevice = (@{
			alias = $DeviceAlias
			groupid = $DeviceGroup
			description = "Last Updated: $(Get-Date -Format "yyyy-MM-dd HH:mm K")"
		}) | ConvertTo-Json
	# Write back new device information
	Invoke-RestMethod -Uri "$($deviceUri)$($TVDeviceInfo.device_id)" -Method Put -Headers $header -ContentType application/json -Body $putDevice
}
