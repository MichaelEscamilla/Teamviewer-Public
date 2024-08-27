# Teamviewer-Device-Assignment_Legacy.ps1
This script Assigns the device to your TeamViewers "Computers & Contacts" list.

[More Info on Assignment Options](https://www.teamviewer.com/en-us/global/support/knowledge-base/teamviewer-classic/deployment/mass-deployment-on-windows-user-guide-legacy/assignment-options-5-6-legacy/)

## SYNTAX

```powershell
Teamviewer-Device-Assignment_Legacy.ps1 [-APIScriptToken] [-AssignmentToken] [-DefaultGroupID]
```

## DESCRIPTION

Will assign a Windows Teamviewer device to your account using the legacy method

## Example

### Example 1

```powershell
PS /> .\Teamviewer-Device-Assignment_Legacy.ps1 -APIScriptToken 'ScriptToken' -AssignmentToken 'AssignmentToken' -DefaultGroupID 'g123456789'
```

## PARAMETERS

### -APIScriptToken

Specify the API Token to use for authentication

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

### -AssignmentToken

Specify the Assignment Token

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

### -DefaultGroupID

The default Group ID to assign the device if no other groups are found. eg:'g123456789'

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