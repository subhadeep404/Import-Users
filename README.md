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

## 4. Known Bugs

| # | Title | Affected | Impact | Workaround |
|---|---|---|---|---|
| 1 | Plaintext password printed on skip | Main loop, "Skipping record for $user" message | When a record is skipped because its department OU is missing, the whole CSV row is written to the console, including the `Password` value. | Use throwaway lab passwords only; clear the console and any transcript afterwards. |
| 2 | Department check does not match creation path | `Test-DepartmentExists`, `New-ADUser -Path` | The check searches the whole subtree under `-BasePath`, but the user is created in `OU=<Department>,<BasePath>`. A department OU nested deeper passes the check, then user creation fails. | Keep department OUs as direct children of `-BasePath`. |
| 3 | Duplicate check limited to the base OU | `Test-UserExists` | `SamAccountName` must be unique across the domain. An existing account elsewhere in the domain is not detected, and creation fails. | Make sure SAM values are unique domain-wide before importing. |
| 4 | Wildcard matching in lookups | `Test-UserExists`, `Test-DepartmentExists` (`-like`) | Values containing `*` can match unintended accounts or OUs. | Avoid wildcard characters in the `SAM` and `Department` columns. |
| 5 | Common name collisions | `-Name` is set to `Display Name` | Two users with the same Display Name in the same department OU collide, and the SAM check does not catch it. | Use unique Display Names within a department. |
| 6 | No CSV validation | Main loop | Missing columns or blank values are not checked. A blank `Password` makes `ConvertTo-SecureString` throw. Blank or over-long `SAM` values are not checked either. | Check the CSV for blank fields and SAM names over 20 characters before running. |
| 7 | Department name not escaped in the DN | `-Path "OU=$Department,$BasePath"` | A department name containing a comma or other special DN character produces a malformed path. | Use simple department names without special characters. |

### Limitations

- No `-WhatIf` / `-Confirm` support; the script creates accounts immediately.
- No `try/catch` error handling or log file; output is console text only, and there is no summary of created, skipped or failed records.
- Passwords are stored in plain text in the CSV.
- Supported PowerShell and OS versions are not documented (TBD).

Found another issue? Please open an issue on the repository.
