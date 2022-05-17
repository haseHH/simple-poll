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
            $pollObject = & "$baseScriptPath/../new/run.ps1" -Request @{Body = @{
                skipAnswer = $true
                question   = $question
                options    = $options
            } | ConvertTo-Json}
            $formattedOptions = [System.Collections.ArrayList]@()
            foreach ($option in $pollObject.options) {
                $formattedOptions += "#$($option.answer) `"$($option.text)`""
            }
            $responseMessage = "$($pollObject.question) - $($formattedOptions -join " - ") - Stimmt ab mit `"!vote`" und der Nummer eurer Wahl, zum Beispiel `"!vote 2`""
        }
        'results' {
            $pollResults = & "$baseScriptPath/../results/run.ps1" -Request @{Query = @{skipAnswer = $true}}
            $votesGiven = ($pollResults.results.votes | Measure-Object -Sum).Sum
            $formattedResults = [System.Collections.ArrayList]@()
            foreach ($option in $pollResults.results) {
                $formattedResults += "#$($option.answer) `"$($option.text)`" $($option.votes) Stimmen ($(
                    if ($votesGiven -eq 0) {
                        '0'
                    } else {
                        [string]$percentage = (([decimal]$option.votes / $votesGiven) * 100)
                        $percentage = $percentage.Replace('.', ',')
                        $decimalIndex = $percentage.IndexOf(',')
                        if ($decimalIndex -eq -1) {
                            $percentage
                        } else {
                            $percentage[0..($decimalIndex + 2)] -join ''
                        }
                    }
                )%)"
            }
            $responseMessage = "Ergebnisse zu `"$($pollResults.question)`" Es wurden $($votesGiven.ToString()) Stimmen abgegeben: $($formattedResults -join " - ")"
        }
        default {
            $responseMessage = "Unbekanntes Subkommando `"${subCommand}`" - keine Aktion ausgeführt."
        }
    }

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = (@{message = $responseMessage} | ConvertTo-Json)
    })
}
catch {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body       = (@{message = 'Command failed.'} | ConvertTo-Json)
    })
}
