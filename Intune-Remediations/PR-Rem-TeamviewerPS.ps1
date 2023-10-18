# Enable TLS 1.2 support for downloading modules from PSGallery (Required)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Set Module Name
$ModuleName = "TeamviewerPS"

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
            Exit 0
        }
        else {
            Update-Module -Name "$($ModuleName)" -Scope AllUsers -Force -Verbose:$false
            Write-Output "[$($ModuleName)] [$($InstalledModule.Version)] Module has been Updated"
            Exit 0
        }
    }
    else {
        # Install Module
        try {
            Install-Module -Name "$($ModuleName)" -Scope AllUsers -Force -Verbose:$false
            Write-Output "[$($ModuleName)] [$($InstalledModule.Version)] Module has been Installed"
            Exit 0
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