<#Param(
    [Parameter(Mandatory=$true)]$Csv,
    [string][Parameter(Mandatory=$true)]$BasePath
)
#>

$users = Import-Csv -Path 'C:\Users\John Doe\Documents\Scripts\Import-Users\users.csv'
$BasePath = "OU=Users,OU=Corporation,DC=home,DC=local"

function User-Banner {
    Param([string]$Username)
    Write-Host -foreground Gray "[+] Importing User: $Username"
}


function Check-UserExists {
    Param(
        [string][Parameter(Mandatory=$true)]$Username,
        [string][Parameter(Mandatory=$true)]$BasePath
    )
    if (Get-ADUser -Filter {DisplayName -like $Username} -SearchBase $BasePath) {return 0}
}

function Check-DepartmentExists {
    Param(
        [string][Parameter(Mandatory=$true)]$Department,
        [string][Parameter(Mandatory=$true)]$BasePath
    )
    if (Get-ADOrganizationalUnit -Filter 'Name -like $Department'-SearchBase $BasePath `
    | Select-Object -Property DistinguishedName) {
        return 0
    } else {
        return -1
    }

}

foreach ($user in $users) {
    # Display the user to be imported
    User-Banner $user.'Display Name'
    
    # Retrieve the properties of each user record
    $Displayname = $user.'Display Name'
    $Username = $displayname
    $Firstname = $user.'First Name'
    $Lastname = $user.'Last Name'
    $SAM = $user.'SAM '
    $UPN = $user.UPN
    $Department = $user.Department
    $Title = $user.Title

    # Covert the plaintext password to a securestring object
    $SecurePassword = ConvertTo-SecureString "$user.'Account Password'" -AsPlainText -Force


    # If the Department OU does not exist break the operation
    if ((Check-DepartmentExists $Department $BasePath) -eq -1) {
        Write-Host -ForegroundColor Red "[-] $Department does not exist.`n"
        return
    }

    # If the user already exists in the department continue with the next user
    if ((Check-UserExists $Username $BasePath) -eq 0) {
        Write-Host -ForegroundColor Blue "[-] $Username already exists in $Department`n"
        continue
    }
    
    # Cerate the user if Department OU exists and the user is not already present
    New-ADUser -Name $Username -GivenName $Firstname -Surname $Lastname `
    -DisplayName $Displayname `
    -SamAccountName $SAM `
    -UserPrincipalName $UPN `
    -Department $Department `
    -Title $Title `
    -Path "OU=$Department,$BasePath" `
    -AccountPassword $SecurePassword `
    -PasswordNeverExpires $true `
    -Enabled $true
}