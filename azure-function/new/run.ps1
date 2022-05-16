using namespace System.Net
param($Request, $TriggerMetadata)

try {
    # get params from body
    [PSCustomObject]$RequestBody = $Request.Body | ConvertFrom-Json -Depth ([Int32]::MaxValue)
    [string]$Question            = $RequestBody.question
    [string[]]$Options           = $RequestBody.options

    # connect to Storage Account
    $PSDefaultParameterValues["Get-AzStorage*:Context"] = Get-StorageContext

    #region registerQuestion
    # get new question ID
    $table = Get-AzStorageTable -Name $env:StorageTableName
    [int32]$newQuestionId = (Get-HighestQuestionId -Table $table) + 1

    # add question to table
    $newQuestionEntity = New-Object -TypeName 'Microsoft.Azure.Cosmos.Table.DynamicTableEntity' -ArgumentList @($env:QuestionPartitionKey, $newQuestionId.ToString())
    $newQuestionEntity.Properties.Add('questionText', $Question)
    $table.CloudTable.Execute(
        [Microsoft.Azure.Cosmos.Table.TableOperation]::Insert($newQuestionEntity)
    ) | Out-Null
    #endregion registerQuestion

    #region registerOptions
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $optionPartitionKey = "optionFor$($newQuestionId.ToString())"
        $newOptionEntity = New-Object -TypeName 'Microsoft.Azure.Cosmos.Table.DynamicTableEntity' -ArgumentList @($optionPartitionKey, ($i+1).ToString())
        $newOptionEntity.Properties.Add('optionText', $Options[$i])
        $newOptionEntity.Properties.Add('optionVotes', 0)
        $table.CloudTable.Execute(
            [Microsoft.Azure.Cosmos.Table.TableOperation]::Insert($newOptionEntity)
        ) | Out-Null
    }
    #endregion registerOptions

    #region prepareResult
    $result = [ordered]@{
        question = $Question
        options  = [System.Collections.ArrayList]@()
    }
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $option = $Options[$i]
        $result.options.Add([ordered]@{
            answer = ($i + 1)
            text   = $option
        }) | Out-Null
    }
    #endregion prepareResult

    # answer has to be skipped when called as a script
    if ($RequestBody.skipAnswer) {
        return $result
    } else {
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = $result | ConvertTo-Json -Depth 100
        })
    }
}
catch {
    # answer has to be skipped when called as a script
    if ($RequestBody.skipAnswer) {
        throw 'Poll creation failed.'
    } else {
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::InternalServerError
            Body       = 'Poll creation failed.'
        })
    }
}
