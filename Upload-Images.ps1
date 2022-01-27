$apikey = 'XXXXXXXXXX'
$folder = 'c:\Folder Of Items To Upload\'
$log_file = 'c:\temp\log.csv'

# Set file extensions to check for
$extension_list = @(
    ".jpg",
    ".jpeg",
    ".png",
    ".gif"
)

# Set API URL
$imgbb_uri = 'https://api.imgbb.com/1/upload?key=' + $apikey

# Get items
$ItemsToPost = Get-ChildItem $folder -File | Where-Object {$extension_list -contains $_.Extension}

# If more than 0 items
if($ItemsToPost.count -gt 0){
    $ItemsToPost | ForEach-Object {

        # Put the image into a form
        $Form = @{
            image = $_
        }
        
        # Write some stuff to output
        Clear-Host
        if($failedUploadCount -gt 0){ Write-Host "Total failed count:" $failedUploadCount }
        Write-Host $_.BaseName
        Write-Host "Uploading Image..."

        # Clear varibles from last run
        $upload_retry_count = $null
        $upload_status = $null
        
        # Attempt upload
        while($null -eq $upload_status){
            try {
                $imgbb_response = Invoke-RestMethod -Method Post -Form $Form -Uri $imgbb_uri
                $imgbb_response.data.url
                $upload_status = 0
                $errorMessage = ''
            } catch {
                ## Failed Web Request - Invail URL, lack of network access, etc
                if( ($_.Exception.GetType().FullName) -eq 'System.Net.Http.HttpRequestException') {
                    Write-Host "Failed Web Request:"
                    if($upload_retry_count -lt 2){
                        Write-Host "StatusCode:" $_.Exception.StatusCode
                        Write-Host "StatusDescription:" $_.Exception.Message
                        $upload_retry_count += 1
                        Write-Host "Upload failed... Attempts -" $upload_retry_count"/3"
                        Start-Sleep -Seconds 15
                    } else {
                        $upload_status = $false
                        $error_id = $_.Exception.StatusCode
                        $errorMessage = $_.Exception.Message
                        Write-Host "Retry count reached... Skipping file"
                        $skipped_item_count += 1
                    }
                } elseif ( ($_.Exception.GetType().FullName) -eq 'Microsoft.PowerShell.Commands.HttpResponseException' ) {
                    ## API Error - Invail api-key, hit rate limt, etc
                    Write-Host "IMG BB Error:"
                    if($upload_retry_count -lt 2){
                        # $errorDetails = $_
                        Write-Host "StatusCode:" ($_.ErrorDetails.Message | ConvertFrom-Json).error.code
                        Write-Host "StatusDescription:" ($_.ErrorDetails.Message | ConvertFrom-Json).error.message
                        $upload_retry_count += 1
                        Write-Host "Upload failed... Attempts -" $upload_retry_count"/3"
                        Start-Sleep -Seconds 15
                    } else {
                        $upload_status = $false
                        $error_id = ($_.ErrorDetails.Message | ConvertFrom-Json).error.code
                        $errorMessage = ($_.ErrorDetails.Message | ConvertFrom-Json).error.message
                        Write-Host "StatusCode:" $errorCode
                        Write-Host "StatusDescription:" $errorMessage
                        Write-Host "Retry count reached... Skipping file"
                        $skipped_item_count += 1
                    }
                }
            }
        }

        # Export to log file
        $obj = [PSCustomObject]@{
            date = Get-Date
            file = $_.Name
            url = $imgbb_response.data.url
            status = $upload_status
            error_id = $error_id
            error = $errorMessage
        }
        $obj | Export-csv -path $log_file -Append -NoTypeInformation
    }
    # Start-Sleep -Seconds 15
    # Uncomment and set seconds value to limit upload rate
}
