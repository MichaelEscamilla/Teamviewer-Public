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

#############################
# Device Assignment
#############################
# Assignment ID
$AssignmentID = ""
    
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
    Exit 1
}
