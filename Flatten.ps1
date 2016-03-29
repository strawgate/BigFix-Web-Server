#----------------------------------------------[Declarations]----------------------------------------------
$InputDir = ".\Original\"
$StagingDir = ".\Staging\"
$OutputDir = ".\Hashed\"

$FileTranslationTable = @()
$Global:ID = 0;

#----------------------------------------------[Environment Preperation]----------------------------------------------
if (!(test-path $InputDir)) {throw "Invalid input directory" }
if (!(test-path $OutputDir)) {new-item "$OutputDir" -ItemType directory -ErrorAction SilentlyContinue}
if (!(test-path $StagingDir)) {new-item "$StagingDir" -ItemType directory -ErrorAction SilentlyContinue}
remove-item $StagingDir -Recurse -force
remove-item $OutputDir -Recurse -force
new-item "$outputdir" -itemtype directory -ErrorAction SilentlyContinue
new-item "$outputdir\Hash" -itemtype directory -ErrorAction SilentlyContinue
new-item "$outputdir\ID" -itemtype directory -ErrorAction SilentlyContinue
copy-item $InputDir $StagingDir -recurse -force

#----------------------------------------------[Functions]----------------------------------------------
function get-relativepath {
    param (
        $File
    )
    $SanitizePath = resolve-path $File -relative
    $SanitizePath = $SanitizePath.replace($InputDir.ToString(),"")
    $SanitizePath = $SanitizePath.replace($StagingDir.ToString(),"")

    return $SanitizePath
}

function get-filetranslation{
    param (
        $File
    )
    $File = get-item $File

    $SanitizePath = get-relativepath $File
    $SanitizePath = $SanitizePath.replace("../", "")
    $SanitizePath = $SanitizePath.replace("\", "/")

    $FileTranslation = @{
        "ID" = (get-nextid)
        "Name"= $File.name
        "OriginalPath" = $File.FullName
        "RelativePath" = $SanitizePath
        "Hash" = (get-filehash $File.FullName -Algorithm SHA1).hash
        "Size" = $File.Length
    }

    return $FileTranslation

}

function get-nextid {
    $Global:ID += 1

    return $Global:ID
}

function invoke-findreplace {
    param(
        $Body,
        $FileTranslationTable
    )

    foreach ($filetranslation in $FileTranslationTable) {
        $Body = $Body.replace($FileTranslation.relativepath,$FileTranslation.ID)
    }
    
    #Flatten
    $Body = $Body.replace("../", "")
    
    return $Body
}

#----------------------------------------------[Body]----------------------------------------------

#Generate files that just need to be moved (no file references need to be changed)
foreach ($file in get-childitem $StagingDir -recurse -file -include "*.jpg","*.woff*","*.ttf") {
    $FileTranslationTable += get-filetranslation $File
}

#Fix CSS, and JS files
foreach ($File in get-childitem $StagingDir -include "*.css","*.js" -recurse -file ) {

    #Get the file
    $FileContents = get-content $File

    #Loop through file translation table and replace relative path with ID
    $FileContents = invoke-findreplace -Body $FileContents -FileTranslationTable $FileTranslationTable
    
    #Write out file temporarily so we can get hash
    set-content $File -value $FileContents
    
    #Add final form to FileTranslationTable
    $FileTranslationTable += get-filetranslation $File
}

#Fix HTML files
foreach ($File in get-childitem $StagingDir -include "*.html" -recurse -file ) {
    #Get the file
    $FileContents = get-content $File

    #Loop through file translation table and replace relative path with ID
    $FileContents = invoke-findreplace -Body $FileContents -FileTranslationTable $FileTranslationTable
    
    #Write out file temporarily so we can get hash
    set-content $File -value $FileContents
    
    #Add final form to FileTranslationTable
    $FileTranslationTable += get-filetranslation $File
}

#Run Translation
foreach ($FileTranslation in $FileTranslationTable) {
    copy-item (get-item $FileTranslation.OriginalPath) "$outputdir\Hash\$($filetranslation.hash)" -force # -ErrorAction SilentlyContinue
    copy-item (get-item $FileTranslation.OriginalPath) "$outputdir\ID\$($filetranslation.ID)" -force # -ErrorAction SilentlyContinue

    write-host "prefetch $($FileTranslation.Hash) sha1:$($FileTranslation.Hash) size:$($FileTranslation.size) http://iem-prod.ad.avnet.weaston.org:52311/uploads/$($FileTranslation.Hash)/$($FileTranslation.name)"

    if ($filetranslation.OriginalPath -like("*.html")) { write-host "HTML File: $($filetranslation.id)" }
}