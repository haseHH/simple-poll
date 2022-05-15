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
        $newQuestionEntity = New-Object -TypeName 'Microsoft.Azure.Cosmos.Table.DynamicTableEntity' -ArgumentList @($optionPartitionKey, ($i+1).ToString())
        $newQuestionEntity.Properties.Add('optionText', $Options[$i])
        $newQuestionEntity.Properties.Add('optionVotes', 0)
        $table.CloudTable.Execute(
            [Microsoft.Azure.Cosmos.Table.TableOperation]::Insert($newQuestionEntity)
        ) | Out-Null
    }
    #endregion registerOptions

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = 'Poll created.'
    })
}
catch {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body       = 'Poll creation failed.'
    })
}
