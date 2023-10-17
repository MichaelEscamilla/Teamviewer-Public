# Enable TLS 1.2 support for downloading modules from PSGallery (Required)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#region Functions

Function Start-SetExecutionPolicy {
    [CmdletBinding()]
    param ()
    if ((Get-ExecutionPolicy) -ne 'RemoteSigned') {
        Set-ExecutionPolicy RemoteSigned -Force
    }
}

#endregion

# Set Module Name
$ModuleName = "TeamviewerPS"

Start-SetExecutionPolicy

# Get Installed Module
$InstalledModule = Get-InstalledModule -Name "$($ModuleName)" -ErrorAction SilentlyContinue -Verbose:$false

# Check if Module is Installed
if (($InstalledModule)) {
    # Get the most recent version of the Module
    $LatestModuleVersion = Find-Module -Name $ModuleName -ErrorAction Stop -Verbose:$false
    # Check if Installed Module is the current version
    if ($InstalledModule.Version -ge $LatestModuleVersion.Version) {
        Write-Output "[$($ModuleName)] [$($InstalledModule.Version)] Module is Installed"
        Exit 0
    }else {
        Write-Warning "[$($ModuleName)] [$($InstalledModule.Version)] Module needs to be updated."
        Exit 1
    }
}else {
    Write-Warning "[$($ModuleName)] Module not Installed"
    Exit 1
}