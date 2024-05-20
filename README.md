# HRProvisioningTests
A tool for generation HR Provisioning pester unit test suite.

## Installation
```powershell
Install-Module HRProvisioningTests
```

## Usage

### Tests generation
```powershell
Connect-MgGraph Synchronization.Read.All
New-HRProvisioningRulesTestSuite -TestSuiteDirectory D:\Data\SF2ADUnitTests-2024-05 -HRApplicationDisplayName 'SuccessFactors to Active Directory User Provisioning'
 
```

### Tests modification / preparation
The ```New-HRProvisioningRulesTestSuite``` generates a test suite with following directory structure:
```
Invoke-HRTests.ps1 
+---Config
| config.json 
+---Tests
    +---givenName
    | givenName.tests.ps1 
    | +---Data   
    | case1.json 
    | case2.json 
    |
    +---sAMAccountName
    | sAMAccountName.tests.ps1 
    | +---Data        
    | case1.json      
    | case2.json      
    |    
    +---sn
    | sn.tests.ps1 
    | +---Data   
    | case1.json 
    | case2.json 
    ...

```

You need to modify JSON files inside the ```Data``` subdirectories to create
your test cases. You can add as many JSON files as you need. If you believe you
don't need to test a particular flow just delete the entire directory (not only
the data subdirectory).

Examples of JSON structure test case definition are listed below
```json
{
    "TargetAttributeName":  "givenName",
    "Description":  "When name is 'Lukáš'",
    "ExpectedResult":  "Lukas",
    "Expression":  "NormalizeDiacritics([firstName])",
    "InputAttributes":  {
                            "firstName":  "Lukáš"
                        }
}
```
or a better one
```json
{
    "TargetAttributeName":  "givenName",
    "Description":  "When name is 'Something-like-čšťžřľ-etc...'",
    "ExpectedResult":  "Something-like-cstzrl-etc...",
    "Expression":  "NormalizeDiacritics([firstName])",
    "InputAttributes":  {
                            "firstName":  "Something-like-čšťžřľ-etc..."
                        }
}
```

### Tests execution
```powershell
Connect-MgGraph Synchronization.ReadWrite.All
D:\Data\SF2ADUnitTests-2024-05\Invoke-HRTests.ps1
```

## More information
unit testing your HR driven provisioning rules [blog post](https://martin.rublik.eu/2024/04/22/editing-XML-files.html).