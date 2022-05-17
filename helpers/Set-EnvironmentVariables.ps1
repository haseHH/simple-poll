$baseScriptPath = $PSScriptRoot
if (($null -ne $psEditor) -and ([string]::IsNullOrEmpty($baseScriptPath))) {
    $baseScriptPath = ([Io.FileInfo]$psEditor.GetEditorContext().CurrentFile.Path).Directory.FullName
}

$appSettings = Get-Content -Path "${baseScriptPath}\..\azure-function\local.settings.json" | ConvertFrom-Json

foreach ($key in ($appSettings.Values | Get-Member -MemberType NoteProperty).Name) {
    $value = $appSettings.Values.$key
    Write-Verbose "Setting variable [ '`$env:${key}' ]" -Verbose
    New-Item -Path "env:${key}" -Value $value -Force | Out-Null
}
