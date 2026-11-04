Param(
    [Parameter(Mandatory=$true)]$Csv,
    [string][Parameter(Mandatory=$true)]$BasePath
)

$users = Import-Csv -Path $Csv
$BasePath = "OU=Users,OU=Corporation,DC=home,DC=local"

<# Gets the target OU
Get-ADOrganizationalUnit -Filter 'Name -like "IT"' `
-SearchBase "OU=Users,OU=Corporation,DC=home,DC=local" `
| Select-Object -Property DistinguishedName
#>

<# Creaing new user 
New-ADUser -Name "Pepper Potts" -GivenName "Pepper" -Surname "Potts" 
-DisplayName "Pepper Potts" 
-SamAccountName "pepper.potts" 
-UserPrincipalName "pepper.potts@home.local" 
-Path "OU=Marketting,OU=Users,OU=Corporation,DC=home,DC=local" 
-AccountPassword $SecurePassword 
-PasswordNeverExpires $true 
-Enabled $true
#>


function User-Banner {
    Param(
        [string]$DisplayName
    )
    Write-Host -foreground Gray "[+] Importing User: $DisplayName"
}


foreach ($user in $users) {
    # Display the user to be imported
    User-Banner $user.'Display Name'
    
    $firstname = $user.'First Name'
    Write-Host $firstname

    # If the user already exists in OU=<Department>,OU=<Users OU>..., then continue
    <#if (Get-ADUser -Filter {DisplayName -like $DisplayName} `
    -SearchBase "OU=Users,OU=Corporation,DC=home,DC=local") {
        Write-Host -Foreground Red "[-] $DisplayName already exists!"
        continue
    }#>

    <#
    New-ADUser -Name "Pepper Potts" -GivenName "Pepper" -Surname "Potts" `
    -DisplayName "Pepper Potts" `
    -SamAccountName "pepper.potts" `
    -UserPrincipalName "pepper.potts@home.local" `
    -Path "OU=Marketting,OU=Users,OU=Corporation,DC=home,DC=local" `
    -AccountPassword $SecurePassword `
    -PasswordNeverExpires $true `
    -Enabled $true
    #>
}