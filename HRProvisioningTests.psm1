$modulePath = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)

# Export functions
foreach($importScript in $(ls "$modulePath\public\*.ps1"))
{
    try
    {
        . $importScript.fullName
        Export-ModuleMember -Function $importScript.Name.Replace(".ps1","")		
    }catch
    {
        Write-Error "Failed to import $($importScript.FullName): $_"
    }
}
