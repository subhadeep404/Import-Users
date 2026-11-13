<#
.SYNOPSIS
Imports bulk users into Active Directory.

.DESCRIPTION
Import-Users automates the process of onboarding bulk users into active directory. Requires a CSV file containing the records of the users and the location/basepath of the Organization Unit where the users are to be imported.

.PARAMETER Csv
CSV file containing the records of the users. Required columns: First Name, Last Name, Display Name, Department, Title, SAM, UPN, Password.
Ex:
    First Name,Last Name,Display Name,Department,Title,SAM,UPN,Password,
    Steve,Rogers,Steve Rogers,HR,HR Manager,steve.rogers,steve.rogers@home.local,P@ssword@123,

.PARAMETER BasePath
Location of the Orgaizational Unit for importing the users. 
NOTE: Must have Department OUs under this BasePat, the script checks for the OUs before inserting the users into their respective departments.
Ex: OU=Users,OU=Avengers,DC=avengers,DC=com
#>

Param(
    [Parameter(Mandatory=$true)]$Csv,
    [string][Parameter(Mandatory=$true)]$BasePath
)

function Get-UserBanner {
    <#
    .DESCRIPTION
    Print banner for the current user.

    .PARAMETER Username
    Username of the user.
    #>
    Param([string]$Username)
    Write-Host -foreground Gray "[+] Importing User: $Username"
}


function Test-UserExists {
    <#
    .DESCRIPTION
    Check if the user account already exists by checking against the SamAccountName.

    .PARAMETER SAM
    SamAccountName to be checked for the user.

    .PARAMETER BASEPATH
    BasePath of the Organizational Unit to check for the user.
    #>

    Param(
        [string][Parameter(Mandatory=$true)]$SAM,
        [string][Parameter(Mandatory=$true)]$BasePath
    )
    if (Get-ADUser -Filter {SamAccountName -like $SAM} -SearchBase $BasePath) {return [bool]$true}
}

function Test-DepartmentExists {
    <#
    .DESCRIPTION
    Checks if the sub-department OUs exist in the Department OU.

    .PARAMETER Department
    Department name to be checked.

    .PARAMETER Basepath
    Basepath to check for the department.
    #>

    Param(
        [string][Parameter(Mandatory=$true)]$Department,
        [string][Parameter(Mandatory=$true)]$BasePath
    )
    if (Get-ADOrganizationalUnit -Filter 'Name -like $Department' -SearchBase $BasePath `
    | Select-Object -Property DistinguishedName) {
        return [bool]$true
    } else {
        return [bool]$false
    }

}

# Import all the user records from the csv file, if file is empty display error and exit the script.
$users = @(Import-Csv -Path $Csv)
if ($users.Count -eq 0) {
    Write-Host -ForegroundColor red "[-] The CSV file $Csv has no records"
    return
}

# Main loop for inserting all the users.
foreach ($user in $users) {
    # Display the user to be imported.
    Get-UserBanner $user.'Display Name'
    
    # Retrieve the properties from the current user's record.
    $Displayname = $user.'Display Name'
    $Username = $displayname
    $Firstname = $user.'First Name'
    $Lastname = $user.'Last Name'
    $SAM = $user.'SAM'
    $UPN = $user.UPN
    $Department = $user.Department
    $Title = $user.Title

    # Convert the plaintext password to a securestring object.
    $SecurePassword = ConvertTo-SecureString $user.'Password' -AsPlainText -Force


    # Check if the Department OU exists in the hierarchy, else continue with the next record.
    if ((Test-DepartmentExists $Department $BasePath) -eq $false) {
        Write-Host -ForegroundColor Red "[!] $Department does not exist."
        Write-Host -ForegroundColor Red "[!] Skipping record for $user"
        continue
    }

    # Check if the user already exists by checking against the SAM database, if present continue with the next user.
    if ((Test-UserExists $SAM $BasePath)) {
        Write-Host -ForegroundColor Blue "[-] $Username already exists in $Department`n"
        continue
    }
    
    # Create the user if Department OU exists and the User is not already present under the department.
    New-ADUser -Name $Username `
    -GivenName $Firstname `
    -Surname $Lastname `
    -DisplayName $Displayname `
    -SamAccountName $SAM `
    -UserPrincipalName $UPN `
    -Department $Department `
    -Title $Title `
    -Path "OU=$Department,$BasePath" `
    -AccountPassword $SecurePassword `
    -ChangePasswordAtLogon $true `
    -Enabled $true
}