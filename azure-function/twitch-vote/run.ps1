using namespace System.Net
param($Request, $TriggerMetadata)

try {
    # get params from query
    $OptionId = $Request.Query.optionId

    # call related function script
    $baseScriptPath = $PSScriptRoot
    if (($null -ne $psEditor) -and ([string]::IsNullOrEmpty($baseScriptPath))) {
        $baseScriptPath = ([Io.FileInfo]$psEditor.GetEditorContext().CurrentFile.Path).Directory.FullName
    }

    & "$baseScriptPath/../vote/run.ps1" -Request @{Body = @{
        skipAnswer = $true
        optionId   = $OptionId
    } | ConvertTo-Json}

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = (@{message = 'Deine Stimme wurde gezählt.'} | ConvertTo-Json)
    })
}
catch {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body       = (@{message = 'Command failed.'} | ConvertTo-Json)
    })
}
