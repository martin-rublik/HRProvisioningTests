Function New-HRProvisioningRulesTestSuite
{
    param(
        # Brief description of what this test is checking.
        # Markdown is supported.
        [Parameter(Mandatory = $true)]
        [string] $TestSuiteDirectory,
        [Parameter(Mandatory = $true)]
        [string] $HRApplicationDisplayName
    )        
    try {

        $context=Get-MgContext

        if(-not $context)
        {
            Write-Warning "You are not connected to MGGraph. Please run: 'Connect-MGGraph -Scopes Synchronization.Read.All'"
            return
        }else
        {
            if (-not ('Synchronization.Read.All' -in $context.Scopes))
            {
                Write-Warning "Missing Synchronization.Read.All context. Please run: 'Connect-MGGraph -Scopes Synchronization.Read.All'"
                return    
            }
        }

        if ([System.IO.Directory]::Exists($TestSuiteDirectory) -and (Test-Path -Path "$TestSuiteDirectory\*"))
        {
            Write-Warning "The destination directory already exists and is not empty."
            return
        }
        
        mkdir -Force -Path $TestSuiteDirectory | Out-Null
        mkdir -Force -Path $TestSuiteDirectory\Config | Out-Null
        mkdir -Force -Path $TestSuiteDirectory\Tests | Out-Null
        
        # Searching for servicePrincipalId
        Write-Verbose "Searching for HR Provisioning application service principal: $HRApplicationDisplayName"
        $servicePrincipalId =  Get-MgServicePrincipal -Filter "displayName eq '$HRApplicationDisplayName'" | select -ExpandProperty Id
        if ((-not $servicePrincipalId) -or ($servicePrincipalId.count -gt 1))
        {
            throw "HR Provisioning application service principal mismatch."
        }
        # Searching for synchronization job
        Write-Verbose "Getting synchronization job"
        $synchronizationJob = Get-MgServicePrincipalSynchronizationJob -ServicePrincipalId $servicePrincipalId 
        # get the schema
        Write-Verbose "Getting synchronization job schema"
        $syncrhonizationJobSchema = Get-MgServicePrincipalSynchronizationJobSchema -ServicePrincipalId $servicePrincipalId -SynchronizationJobId  $synchronizationJob.Id
        # get the template
        Write-Verbose "Getting synchronization template"
        $syncTemplates = Get-MgServicePrincipalSynchronizationTemplate -ServicePrincipalId $servicePrincipalId
        
        # write config
        Write-Verbose "Saving config to: $TestSuiteDirectory\Config\config.json"
        @{
            'ServicePrincipalId' = $servicePrincipalId
            'SynchronizationTemplateId' = $syncTemplates.Id
            'HRApplicationDisplayName' = $HRApplicationDisplayName
        } | ConvertTo-Json | Out-File "$TestSuiteDirectory\Config\config.json" -Encoding utf8
        
        $testTemplate = get-content "$($PSScriptRoot)\..\private\TestName.tests.ps1.txt"
        
        $regex=new-object System.Text.RegularExpressions.Regex("\[[a-zA-Z0-9_]+\]")
        
        foreach($rule in $syncrhonizationJobSchema.SynchronizationRules[0].ObjectMappings[0].AttributeMappings)
        {
            # TODO: we generate test cases only for functions
            #   maybe it would be nice to include others (constants and attributes) as well
            if ($rule.Source.Type -eq 'Function')
            {
                $targetAttributeName=$rule.TargetAttributeName.ToString()
                Write-Verbose "Generating tests and generic test cases for: $targetAttributeName"
        
                $attributes=$regex.Matches($rule.Source.Expression) | select -ExpandProperty Value | %{$_.Trim('[').Trim(']')} | sort -Unique
                $attributesHT=new-object pscustomobject
                foreach($attr in $attributes)
                {
                    $attributesHT | Add-Member -NotePropertyName $attr -NotePropertyValue "Please-Fill-In"
                }
        
                $rules=[pscustomobject]@{
                    'TargetAttributeName'=$targetAttributeName
                    'Description'='Please-Fill-In'
                    'ExpectedResult'="Please-Fill-In"
                    'Expression'=$rule.Source.Expression
                    'InputAttributes'= $attributesHT
                }
                mkdir -force $TestSuiteDirectory\Tests\$targetAttributeName\Data | Out-Null
        
                $rules | ConvertTo-Json | Out-File -Encoding utf8 $TestSuiteDirectory\Tests\$targetAttributeName\Data\case1.json
                $rules | ConvertTo-Json | Out-File -Encoding utf8 $TestSuiteDirectory\Tests\$targetAttributeName\Data\case2.json
                #$rules | ConvertTo-Json | Out-File -Encoding utf8 $TestSuiteDirectory\Tests\$targetAttributeName\Data\case2.json
                
                $testTemplate.Replace('%TESTNAME%',$targetAttributeName) | Out-File -Encoding utf8 "$TestSuiteDirectory\Tests\$targetAttributeName\$targetAttributeName.tests.ps1"
        
                cp "$($PSScriptRoot)\..\private\Invoke-HRTests.ps1.txt" "$TestSuiteDirectory\Invoke-HRTests.ps1"
            }
        }
        Write-Host "Test cases generated in $TestSuiteDirectory"
        Write-Host " Modify expected results and parameters in respective Data subdirectories located in $TestSuiteDirectory\Data"
        Write-Host "When ready, run:"    
        Write-Host " $TestSuiteDirectory\Invoke-HRTests.ps1"    
    }
    catch {
        throw $_
    }
}