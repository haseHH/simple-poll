using namespace System.Net
param($Request, $TriggerMetadata)

try {
    # get params from body
    [PSCustomObject]$RequestBody = $Request.Body | ConvertFrom-Json -Depth ([Int32]::MaxValue)
    [string]$OptionId            = $RequestBody.optionId

    # connect to Storage Account
    $PSDefaultParameterValues["Get-AzStorage*:Context"] = Get-StorageContext

    # get newest question ID
    $table = Get-AzStorageTable -Name $env:StorageTableName
    [string]$highestQuestionId = Get-HighestQuestionId -Table $table

    # error if no questions are stored
    if ($highestQuestionId -eq '0') {
        throw
    }

    # get current vote count
    $optionPartitionKey = "optionFor${highestQuestionId}"
    $option = $table.CloudTable.ExecuteQuery(
        (New-Object -TypeName 'Microsoft.Azure.Cosmos.Table.TableQuery').Where(
            "PartitionKey eq '${optionPartitionKey}' and RowKey eq '${OptionId}'"
        )
    )
    # error if no option with this ID exists
    if ($null -eq $option) {
        throw
    }
    $voteCount = $option.Properties.optionVotes.Int32Value

    # increase vote count
    $newOptionEntity = New-Object -TypeName 'Microsoft.Azure.Cosmos.Table.DynamicTableEntity' -ArgumentList @($optionPartitionKey, $OptionId)
    $newOptionEntity.Properties.Add('optionText', $option.Properties.optionText.StringValue)
    $newOptionEntity.Properties.Add('optionVotes', ($voteCount + 1))
    $table.CloudTable.Execute(
        [Microsoft.Azure.Cosmos.Table.TableOperation]::InsertOrReplace($newOptionEntity)
    ) | Out-Null

    # answer has to be skipped when called as a script
    if (-not $RequestBody.skipAnswer) {
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = 'Voting succeeded.'
        })
    }
}
catch {
    # answer has to be skipped when called as a script
    if ($RequestBody.skipAnswer) {
        throw 'Voting failed.'
    } else {
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::InternalServerError
            Body       = 'Voting failed.'
        })
    }
}
