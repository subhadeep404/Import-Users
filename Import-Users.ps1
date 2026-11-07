Param(
    [Parameter(Mandatory=$true)]$Csv,
    [string][Parameter(Mandatory=$true)]$BasePath
)

function Get-UserBanner {
    Param([string]$Username)
    Write-Host -foreground Gray "[+] Importing User: $Username"
}


function Test-UserExists {
    Param(
        [string][Parameter(Mandatory=$true)]$SAM,
        [string][Parameter(Mandatory=$true)]$BasePath
    )
    if (Get-ADUser -Filter {SamAccountName -like $SAM} -SearchBase $BasePath) {return 0}
}

function Test-DepartmentExists {
    Param(
        [string][Parameter(Mandatory=$true)]$Department,
        [string][Parameter(Mandatory=$true)]$BasePath
    )
    if (Get-ADOrganizationalUnit -Filter 'Name -like $Department' -SearchBase $BasePath `
    | Select-Object -Property DistinguishedName) {
        return 0
    } else {
        return -1
    }

}

$users = @(Import-Csv -Path $Csv)
if ($users.Count -eq 0) {
    Write-Host -ForegroundColor red "[-] The CSV file $Csv has no records"
    return
}


# Loop for inserting all the users
foreach ($user in $users) {
    # Display the user to be imported
    Get-UserBanner $user.'Display Name'
    
    # Retrieve the properties of each user record
    $Displayname = $user.'Display Name'
    $Username = $displayname
    $Firstname = $user.'First Name'
    $Lastname = $user.'Last Name'
    $SAM = $user.'SAM'
    $UPN = $user.UPN
    $Department = $user.Department
    $Title = $user.Title

    # Covert the plaintext password to a securestring object
    $SecurePassword = ConvertTo-SecureString $user.'Account Password' -AsPlainText -Force


    # If the Department OU does not exist continue to the next record
    if ((Test-DepartmentExists $Department $BasePath) -eq -1) {
        Write-Host -ForegroundColor Red "[!] $Department does not exist.`n"
        Write-Host -ForegroundColor Red "[!] Skipping record for $user"
        continue
    }

    # If the user already exists in the department continue with the next user
    if ((Test-UserExists $SAM $BasePath) -eq 0) {
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
    -ChangePasswordAtLogon $true `
    -Enabled $true
}