# Teamviewer-Device-Assignment_MDv2.ps1
This script Assigns the device to your TeamViewer Account. Utilizes the [TeamViewerPS](https://github.com/teamviewer/TeamViewerPS/tree/main) module.

[More Info on Assignment Options](https://www.teamviewer.com/en-us/global/support/knowledge-base/teamviewer-remote/deployment/mass-deployment-user-guide/assign-a-device-via-command-line-8-10/)  
[More Info on the Add-TeamViewerAssignment function](https://github.com/teamviewer/TeamViewerPS/blob/main/Docs/Help/Add-TeamViewerAssignment.md)

## SYNTAX

```powershell
Teamviewer-Device-Assignment_MDv2.ps1 [-AssignmentID]
```

## DESCRIPTION

Will assign a Windows Teamviewer device to your account using the MDv2 method of Managed Groups

## Example

### Example 1

```powershell
PS /> .\Teamviewer-Device-Assignment_MDv2.ps1 -AssignmentID "0001CoABChCiJnyAKf0R7r6"
```

## PARAMETERS

### -AssignmentID

Object that is required to assign the device to a Company.

```yaml
Type: String
Parameter Sets: (All)
Aliases: None

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```
