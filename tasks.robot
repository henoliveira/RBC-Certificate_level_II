# +
*** Settings ***
Documentation   Certification level II
...             Download orders.csv file
...             Orders robots from RobotSpareBin Industries Inc.
...             Saves the order HTML receipt as a PDF file.
...             Saves the screenshot of the ordered robot.
...             Embeds the screenshot of the robot to the PDF receipt.
...             Creates ZIP archive of the receipts and the images.

Library         RPA.Browser.Selenium
Library         RPA.HTTP
Library         OperatingSystem
Library         RPA.Tables
Library         RPA.PDF
Library         RPA.Archive
Library         RPA.Dialogs
Library         RPA.Robocloud.Secrets
# -


*** Variables ***
${fileName}=            orders.csv
${downloadDir}=         ${CURDIR}${/}Downloads
${receiptsDir}=         ${CURDIR}${/}Receipts
${fileNameDir}=         ${downloadDir}${/}${fileName}

# +
*** Keywords ***
Startup
    Create Directory    ${downloadDir}
    Create Directory    ${receiptsDir}
    ${url}=    Get Secret    website
    Open Chrome Browser     ${url}[url]
    Wait Until Keyword Succeeds     2 min   5 sec   Click Button When Visible   xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Download CSV
    Set Download Directory  ${downloadDir}
    Download    https://robotsparebinindustries.com/orders.csv  target_file=${downloadDir}  verify=True  overwrite=True
    Wait Until Keyword Succeeds     2 min   5 sec   File Should Exist   ${fileNameDir}
    
Order
    Click Element When Visible      id:order
    Wait Until Element Is Visible   id:receipt

Loop CSV
    ${orders}=      Read Table From Csv    ${fileNameDir}
    FOR    ${order}    IN    @{orders}
        Select From List By Value   id:head     ${order}[Head]
        Click Element When Visible  id:id-body-${order}[Body]
        Input Text    xpath://*[@id="root"]/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
        Input Text    xpath://*[@id="root"]/div/div[1]/div/div[1]/form/div[4]/input    ${order}[Address]
        Click Element When Visible  id:preview
        Wait Until Keyword Succeeds    10x   1 sec    Order
        ${receiptHTML}=    Get Element Attribute    id:receipt    outerHTML
        Add heading       Name the robot file
        Add text input    robotName    label=Name
        ${receiptName}=    Run dialog
        Html To Pdf    ${receiptHTML}    ${downloadDir}${/}receipt_${order}[Order number]_${receiptName.robotName}.pdf
        Screenshot    id:robot-preview-image    ${downloadDir}${/}robot${order}[Order number].png
        Open Pdf    ${downloadDir}${/}receipt_${order}[Order number]_${receiptName.robotName}.pdf
        ${robotPNG}=     Create List    ${downloadDir}${/}robot${order}[Order number].png
        ...     ${downloadDir}${/}receipt_${order}[Order number]_${receiptName.robotName}.pdf
        Add Files To Pdf    ${robotPNG}     ${downloadDir}${/}receipt_${order}[Order number]_${receiptName.robotName}.pdf
        Close Pdf   ${downloadDir}${/}receipt_${order}[Order number]_${receiptName.robotName}.pdf
        Move File    ${downloadDir}${/}receipt_${order}[Order number]_${receiptName.robotName}.pdf     ${receiptsDir}
        Click Element When Visible  id:order-another
        Wait Until Keyword Succeeds     2 min   5 sec   Click Button When Visible   xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    END
    Archive Folder With Zip     ${receiptsDir}  ${OUTPUT_DIR}${/}receipts.zip

Close Down
    Remove Directory    Downloads   True
    Remove Directory    Receipts   True
    [Teardown]  Close Browser
# -

*** Tasks ***
Blabla
    Startup
    Download CSV
    Loop CSV
    Close Down


