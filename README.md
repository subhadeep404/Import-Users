# Import-Users

Bulk Active Directory user onboarding from a CSV file, using PowerShell.

> **Note:** This script is for **lab purposes only**. It is not intended for production use.

---

## 1. Overview

`Import-Users.ps1` automates onboarding of bulk users into Active Directory. It reads user records from a CSV file and creates each account in the department OU that sits under a base Organizational Unit you specify. Before creating a user, the script checks that the department OU exists and that the account is not already present, and skips the record if either check fails. New accounts are created enabled, with the "change password at next logon" flag set.

### Requirements

| Item | Details |
|---|---|
| PowerShell version | Tested On: Windows PowerShell 5.1 |
| Operating system | Windows machine with the Active Directory PowerShell module |
| Modules | `ActiveDirectory` (the script uses `Get-ADUser`, `Get-ADOrganizationalUnit` and `New-ADUser`) |
| Permissions | An account allowed to create user objects in the target OUs |
| Environment | Department OUs must already exist directly under the base OU |

### Installation

```powershell
git clone https://github.com/subhadeep404/Import-Users.git
cd Import-Users
```

Alternatively, download `Import-Users.ps1` and `sample-users.csv` from the repository.

---

## 2. Flags

| Flag | Type | Required | Default | Description |
|---|---|---|---|---|
| `-Csv` | Not declared (path to a CSV file) | Yes | None | Path to the CSV file containing the user records. |
| `-BasePath` | `String` | Yes | None | Distinguished name of the base OU. A department OU must exist under it for each department in the CSV. Example: `OU=Users,OU=Contoso,DC=contoso,DC=local` |

The script has no switches, parameter sets or `ValidateSet` values.

### Required CSV columns

The first row must contain these column headers:

| Column | Description |
|---|---|
| `First Name` | Given name |
| `Last Name` | Surname |
| `Display Name` | Display name; also used as the account's `Name` (CN) |
| `Department` | Name of the department OU under `-BasePath` where the account is created |
| `Title` | Job title |
| `SAM` | `SamAccountName` |
| `UPN` | `UserPrincipalName` |
| `Password` | Initial password, read as plain text |

Example (use dummy data only):

```csv
First Name,Last Name,Display Name,Department,Title,SAM,UPN,Password
Jane,Doe,Jane Doe,HR,HR Manager,jane.doe,jane.doe@contoso.local,<temp-password>
```

---

## 3. Examples

### Basic: import the sample file

Imports the users from the sample CSV into the department OUs under the base OU.

```powershell
.\Import-Users.ps1 -Csv .\sample-users.csv -BasePath "OU=Users,OU=Contoso,DC=contoso,DC=local"
```

Expected result: each record prints `[+] Importing User: <Display Name>` and the account is created in `OU=<Department>` under the base OU.

### Using an absolute CSV path

```powershell
.\Import-Users.ps1 -Csv C:\Temp\users.csv -BasePath "OU=Users,OU=Contoso,DC=contoso,DC=local"
```

Expected result: the accounts are created enabled, with a password change required at first logon.

### Re-running the same file

```powershell
.\Import-Users.ps1 -Csv C:\Temp\users.csv -BasePath "OU=Users,OU=Contoso,DC=contoso,DC=local"
```

Expected result: users already found under the base OU are reported as `[-] <name> already exists in <Department>` and skipped.

### Handling a missing department OU

```powershell
.\Import-Users.ps1 -Csv C:\Temp\users.csv -BasePath "OU=Users,OU=Contoso,DC=contoso,DC=local"
```

Expected result: if a record's department has no matching OU, the script prints `[!] <Department> does not exist.` and skips that record. Be aware of the password exposure described under [Known Bugs](#4-known-bugs).

---
