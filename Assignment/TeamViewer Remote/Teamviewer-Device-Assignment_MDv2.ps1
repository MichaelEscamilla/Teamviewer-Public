<#
	.SYNOPSIS
		Assign device to your Teamviewer Account as a Managed Devices. Uses the ComputerName for Assignment.
	
	.DESCRIPTION
		Will assign a Windows Teamviewer device to your account using the MDv2 method of Managed Groups
	
	.PARAMETER AssignmentID
		Assignment ID from the Teamviewer portal
	
	.EXAMPLE
		PS C:\> .\Teamviewer-Device-Assignment_MDv2.ps1 -AssignmentID 'Value1'
	
	.NOTES
		Will Install and use the TeamviewerPS module.
#>
param
(
	[Parameter(Mandatory = $true)]
	[string]$AssignmentID
)

#region TeamviewerPS

#############################
# Install TeamviewerPS Module
#############################
# Set Module Name
$ModuleName = "TeamviewerPS"

# Install latest NuGet package provider
try {
	if (-not (Get-PackageProvider -Name "NuGet" -ListAvailable -ErrorAction SilentlyContinue | Where-Object { $_.Version -ge '2.8.5' })) {
		# Install PackageProvider
		Install-PackageProvider -Name "NuGet" -Force -ErrorAction Stop -Verbose:$false
	}
}
catch [System.Exception] {
	Write-output "Unable to install latest NuGet package provider. Error message: $($_.Exception.Message)"
	Exit 1
}

# Install the Latest PowershellGet Module
try {
	if (-not (Get-Module -Name PowerShellGet -ListAvailable | Where-Object { $_.Version -ge '2.2.5' })) {
		# Install PackageManagement Module
		Install-Module -Name "PackageManagement" -Force -Scope AllUsers -AllowClobber -ErrorAction Stop -Verbose:$false
		# Install PowerShellGet Module
		Install-Module -Name "PowerShellGet" -Force -Scope AllUsers -AllowClobber -ErrorAction Stop -Verbose:$false
	}
}
catch {
	Write-output "Unable to install latest PowershellGet Module. Error message: $($_.Exception.Message)"
	Exit 1
} 

# Install the Latest Module
$InstalledModule = Get-InstalledModule -Name "$($ModuleName)" -ErrorAction SilentlyContinue -Verbose:$false
try {
	if (($InstalledModule)) {
		# Get the most recent version of the Module
		$LatestModuleVersion = Find-Module -Name $ModuleName -ErrorAction Stop -Verbose:$false
		# Check if Installed Module is the current version
		if ($InstalledModule.Version -ge $LatestModuleVersion.Version) {
			Write-Output "[$($ModuleName)] [$($InstalledModule.Version)] Module is Installed"
		}
		else {
			Update-Module -Name "$($ModuleName)" -Scope AllUsers -Force -Verbose:$false
			# Verify the module is installed
			$InstalledModuleVerify = Get-InstalledModule -Name "$($ModuleName)" -ErrorAction SilentlyContinue -Verbose:$false
			Write-Output "[$($ModuleName)] [$($InstalledModuleVerify.Version)] Module has been Updated"
		}
	}
	else {
		# Install Module
		try {
			Install-Module -Name "$($ModuleName)" -Scope AllUsers -Force -Verbose:$false
			# Verify the module is installed
			$InstalledModuleVerify = Get-InstalledModule -Name "$($ModuleName)" -ErrorAction SilentlyContinue -Verbose:$false
			Write-Output "[$($ModuleName)] [$($InstalledModuleVerify.Version)] Module has been Installed"
		}
		catch {
			Write-output "Unable to Install [$($ModuleName)] Module. Error message: $($_.Exception.Message)"
			Exit 1
		}
	}
}
catch {
	Write-output "Unable to Install or Update [$($ModuleName)] Module. Error message: $($_.Exception.Message)"
	Exit 1
}

#endregion


#region ErrorCode
# 99 - Main error
$ScriptError_Main = 99
# 79 - TV Assignment error
$ScriptError_Assignment = 79
#endregion

# Main Script
try {
	#############################
	# Device Assignment
	#############################
    
	# Assign Device
	$DevieAliasName = $($env:COMPUTERNAME)
	$AssignmentStatus = Add-TeamViewerAssignment -AssignmentId "$AssignmentID" -DeviceAlias "$($DevieAliasName)" -Retries 3

	# Verify AssignmentStatus
	if ($AssignmentStatus -eq 'Operation successful') {
		Write-Output "[SUCCESS] Device Assignment was Successful [$($DevieAliasName)]"
		Exit 0
	}
	else {
		Write-Error "Failed to Assign Device to Company: [$($AssignmentStatus)]"
		# 79 - TV Assignment error
		Exit $ScriptError_Assignment
	}
}
catch {
	# Main Script Error Code
	Exit $ScriptError_Main
}