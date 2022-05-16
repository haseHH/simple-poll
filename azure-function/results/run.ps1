using namespace System.Net
param($Request, $TriggerMetadata)

try {
    # connect to Storage Account
    $PSDefaultParameterValues["Get-AzStorage*:Context"] = Get-StorageContext

    #region retrieveQuestion
    # get newest question ID
    $table = Get-AzStorageTable -Name $env:StorageTableName
    [string]$highestQuestionId = Get-HighestQuestionId -Table $table

    # error if no questions are stored
    if ($highestQuestionId -eq '0') {
        throw
    }

    # get question
    $question = $table.CloudTable.ExecuteQuery(
        (New-Object -TypeName 'Microsoft.Azure.Cosmos.Table.TableQuery').Where(
            "PartitionKey eq '${env:QuestionPartitionKey}' and RowKey eq '${highestQuestionId}'"
        )
    ).Properties.questionText.StringValue
    #endregion retrieveQuestion

    #region retrieveOptions
    $options = $table.CloudTable.ExecuteQuery(
        (New-Object -TypeName 'Microsoft.Azure.Cosmos.Table.TableQuery').Where(
            "PartitionKey eq 'optionFor${highestQuestionId}'"
        )
    ).Properties
    #endregion retrieveOptions

    #region prepareResult
    $result = [ordered]@{
        question = $question
        results  = [System.Collections.ArrayList]@()
    }
    for ($i = 0; $i -lt $options.Count; $i++) {
        $option = $options[$i]
        $result.results.Add([ordered]@{
            answer = ($i + 1)
            text   = $option.optionText.StringValue
            votes  = $option.optionVotes.Int32Value
        }) | Out-Null
    }
    #endregion prepareResult

    # answer has to be skipped when called as a script
    if ($Request.Query.skipAnswer) {
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
    if ($Request.Query.skipAnswer) {
        throw 'Result retrieval failed.'
    } else {
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::InternalServerError
            Body       = 'Result retrieval failed.'
        })
    }
}
