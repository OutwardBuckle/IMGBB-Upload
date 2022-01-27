# IMGBB-Upload
PowerShell script to automate upload to IMGBB.com

https://api.imgbb.com/

Basic single item example:

	$image_file = "c:\temp\img.png"
	$apikey = 'xxxxxxxxxxxxxx'
	####
	$image = Get-Item $image_file
	$uri = 'https://api.imgbb.com/1/upload?key=' + $apikey
	$Form = @{
		image = $image
	}
	$response = Invoke-RestMethod -Method Post -Form $Form -Uri $uri
	$response.data.url
