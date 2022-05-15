using namespace System.Net
param($Request, $TriggerMetadata)

try {
    # get params from query
    $Command = $Request.Query.command

    # get subcommand and call related function script
    $subCommand = ($Command -split ' ')[0]

    $baseScriptPath = $PSScriptRoot
    if (($null -ne $psEditor) -and ([string]::IsNullOrEmpty($baseScriptPath))) {
        $baseScriptPath = ([Io.FileInfo]$psEditor.GetEditorContext().CurrentFile.Path).Directory.FullName
    }

    switch ($subCommand) {
        'new' {
            $commandPayload = $Command.Substring(4) -split '\|' | ForEach-Object {$_.Trim()}
            [string]$question  = $commandPayload[0]
            [string[]]$options = $commandPayload[1..($commandPayload.Count - 1)]
            & "$baseScriptPath/../new/run.ps1" -Request @{Body = @{
                skipAnswer = $true
                question   = $question
                options    = $options
            } | ConvertTo-Json}
        }
    }

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = 'Command executed.'
    })
}
catch {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body       = 'Command failed.'
    })
}
