<#
	.SYNOPSIS
		Assign device to your Teamviewer Account
	
	.DESCRIPTION
		Will assign a Windows Teamviewer device to your account using the legacy method of Share Groups
	
	.PARAMETER APIScriptToken
		A description of the APIScriptToken parameter.
	
	.PARAMETER AssignmentToken
		A description of the AssignmentToken parameter.
	
	.PARAMETER DefaultGroupID
		The default Group ID to assign the device if no other groups are found. eg:'g123456789'
	
	.EXAMPLE
		PS C:\> .\Teamviewer-Device-Assignment_Legacy.ps1 -APIScriptToken 'Value1' -AssignmentToken 'Value2'
	
	.NOTES
		Additional information about the file.
#>
param
(
	[Parameter(Mandatory = $true)]
	[string]$APIScriptToken,
	[Parameter(Mandatory = $true)]
	[string]$AssignmentToken,
	[Parameter(Mandatory = $true)]
	[string]$DefaultGroupID
)

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
#endregion

#region TeamviewerAPISetup

## Build Web Call
# Auth Token
$token = "$($APIScriptToken)"
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

#endregion

#region ErrorCode
# 99 - Main error
$ScriptError_Main = 99
# 89 - TV Ping error
$ScriptError_Ping = 89
# 79 - TV Assignment error
$ScriptError_Assignment = 79
#endregion

# Main Script
try
{
	# Ping Teamviewer API
	try
	{
		$pingTest = Invoke-RestMethod -Uri $pinguri -Method Get -Headers $header
	}
	catch
	{
		Exit $ScriptError_Ping
	}
	
	# Continue if communication was successfull
	if ($pingTest.token_valid)
	{
		# Get all devices from Teamviewer API
		$AllTVDevices = Invoke-RestMethod -Uri $deviceUri -Method Get -Headers $header
		# Get all groups from Teamviewer API
		$AllGroups = Invoke-RestMethod -Uri $groupsUri -Method Get -Headers $header
		
		# Get Teamviewer client id from Registery
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
		
		# Get User Information from SMS_SystemConsoleUser if it Exists, Sort by NumberOfConsoleLogons Descending
		$UserAffinity = Get-CimInstance -ClassName "SMS_SystemConsoleUser" -Namespace "root\cimv2\sms" -ErrorAction SilentlyContinue | Sort-Object NumberOfConsoleLogons -Descending
		
		# Select the first record, Clean up the Username by removing the "Domain\"
		if ($UserAffinity)
		{
			# Store Just Username
			$UserAffinityValue = ($UserAffinity[0].SystemConsoleUser).ToString().Split('\\')[-1]
			# Check for local_users value
			if ($UserAffinityValue -eq "local_users")
			{
				$UserAffinityValue = $null
			}
		}
		
		### Set Desired Teamviewer Alias
		# Get OperatingSystem ProductType
		$OSProductType = (Get-WmiObject Win32_OperatingSystem).ProductType
		
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
				# Check if current $Compare is Greater than $TopCompareValue
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
			$DeviceGroup = "$($DefaultGroupID)"
		}
	}
	
	# Check Teamviewer Bitness Version
	if ((Test-Path -Path "${env:ProgramFiles(x86)}\TeamViewer\Teamviewer.exe"))
	{
		$InstallDirectory = "${env:ProgramFiles(x86)}\TeamViewer"
	}
	elseif ((Test-Path -Path "$env:ProgramFiles\TeamViewer\Teamviewer.exe"))
	{
		$InstallDirectory = "$env:ProgramFiles\TeamViewer"
	}
	else
	{
		# Fallback: Lets just assume x64 OS and x86 Teamviewer
		$InstallDirectory = "${env:ProgramFiles(x86)}\TeamViewer"
	}
	
	# Assignment Token
	$TVAssignmentToken = "$($AssignmentToken)"
	# Perform Assignment
	try
	{
		Start-Process -FilePath "$InstallDirectory\Teamviewer.exe" -ArgumentList "assign --api-token `"$($TVAssignmentToken)`" --reassign --grant-easy-access --alias `"$($DeviceAlias)`" --group-id $($DeviceGroup)"
	}
	catch
	{
		Exit $ScriptError_Assignment
	}
}
catch
{
	# Main Script Error Code
	Exit $ScriptError_Main
}