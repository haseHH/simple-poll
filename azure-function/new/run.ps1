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
    # get highest question ID
    $questionPartitionKey = 'question'
    $table = Get-AzStorageTable -Name $env:StorageTableName
    $questions = $table.CloudTable.ExecuteQuery(
        (New-Object -TypeName 'Microsoft.Azure.Cosmos.Table.TableQuery').Where(
            "PartitionKey eq '${questionPartitionKey}'"
        )
    )
    [int32[]]$questionIds = $questions | Select-Object -ExpandProperty 'RowKey'
    if ($questionIds.Count -lt 1) {
        [int32]$highestQuestionId = 0
    } else {
        [int32]$highestQuestionId = $questionIds | Sort-Object -Descending | Select-Object -First 1
    }

    # add question to table
    [int32]$newQuestionId = $highestQuestionId + 1
    $newQuestionEntity = New-Object -TypeName 'Microsoft.Azure.Cosmos.Table.DynamicTableEntity' -ArgumentList @($questionPartitionKey, $newQuestionId.ToString())
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
