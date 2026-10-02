#############################
# Install TeamviewerPS Module
#############################
# Set Module Name
$ModuleName = "TeamviewerPS"

# Ensure TLS 1.2 is used for the PowerShell Gallery (required under SYSTEM/5.1)
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

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
    # Install PackageManagement Module
    if (-not (Get-Module -Name PackageManagement -ListAvailable | Where-Object { $_.Version -ge '1.4.7' })) {
        Install-Module -Name "PackageManagement" -Force -Scope AllUsers -AllowClobber -ErrorAction Stop -Verbose:$false
    }
    # Install PowerShellGet Module
    if (-not (Get-Module -Name PowerShellGet -ListAvailable | Where-Object { $_.Version -ge '2.2.5' })) {
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
# Check Device Management
#############################
# Managed Device V2 model
# Device Groups
#   Read operations
#   modifying operations

# API Token
$scriptToken = ""

# Ensure an API token is configured before attempting to connect
if (-not $scriptToken) {
    Write-Warning "No API token configured"
    Exit 1
}

# Connect Teamviewer API
try {
    Connect-TeamViewerApi -ApiToken $($scriptToken | ConvertTo-SecureString -AsPlainText -Force) -ErrorAction Stop
}
catch {
    Write-Warning "Unable to connect to TeamViewer API. Error message: $($_.Exception.Message)"
    Exit 1
}

# Verify the connection succeeded (token is stored as a default parameter on success)
if (-not $global:PSDefaultParameterValues['*-Teamviewer*:APIToken']) {
    Write-Warning "TeamViewer API token is invalid or the connection failed"
    Exit 1
}

# Get Local Device Management ID
$TVManagementID = Get-TeamViewerManagementId
if ($TVManagementID) {
    # Get TeamViewer Managed Device
    $TVManagedDevice = Get-TeamViewerManagedDevice -Id "$($TVManagementID)"
    if ($TVManagedDevice) {
        # Check device is Online
        if ($TVManagedDevice.IsOnline) {
            # Device Found and Online
            Write-Output "Success: Device is Managed [$($TVManagedDevice.Name)]"
            Exit 0
        }
        else {
            # Device Found but is Offline, assume Assignment is Corrupted
            Write-Warning "Device Found but Uncompliant"
            Exit 1
        }
    }
    else {
        # Device is Managed but not within Current Company
        Write-Warning 'Device Not Managed by Company'
        Exit 1
    }
}
else {
    # Device is not currently being Managed
    Write-Warning "Device not Managed"
    Exit 1
}

# Disconnect Teamviewer API
Disconnect-TeamViewerApi
