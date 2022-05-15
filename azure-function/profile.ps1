# Azure Functions profile.ps1
#
# This profile.ps1 will get executed every "cold start" of your Function App.
# "cold start" occurs when:
#
# * A Function App starts up for the very first time
# * A Function App starts up after being de-allocated due to inactivity
#
# You can define helper functions, run commands, or specify environment variables
# NOTE: any variables defined that are not environment variables will get reset after the first execution

# Authenticate with Azure PowerShell using MSI.
# Remove this if you are not planning on using MSI or Azure PowerShell.
if ($env:MSI_SECRET) {
    Disable-AzContextAutosave -Scope Process | Out-Null
    Connect-AzAccount -Identity | Out-Null
}

function Get-StorageContext {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $ConnectionString = $env:AzureWebJobsStorage
    )
    New-AzStorageContext -ConnectionString $ConnectionString
}

function Get-HighestQuestionId {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable] $Table
    )

    $questions = $Table.CloudTable.ExecuteQuery(
        (New-Object -TypeName 'Microsoft.Azure.Cosmos.Table.TableQuery').Where(
            "PartitionKey eq '${env:QuestionPartitionKey}'"
        )
    )

    [int32[]]$questionIds = $questions | Select-Object -ExpandProperty 'RowKey'
    if ($questionIds.Count -lt 1) {
        [int32]$highestQuestionId = 0
    } else {
        [int32]$highestQuestionId = $questionIds | Sort-Object -Descending | Select-Object -First 1
    }

    return $highestQuestionId
}
