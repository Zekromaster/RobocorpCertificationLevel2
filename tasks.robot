*** Settings ***
Documentation	Orders robots from RobotSpareBin Industries Inc.
...				Saves the order HTML receipt as a PDF file.
...				Saves the screenshot of the ordered robot.
...				Embeds the screenshot of the robot to the PDF receipt.
...				Creates ZIP archive of the receipts and the images.
Library	RPA.Browser.Selenium
Library	RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.FileSystem
Library    RPA.Archive

*** Tasks ***
Order robot from RobotSpareBin Industries Inc
	${orders}	Download orders
	Open the order page
	${output_location}	Set Variable	${OUTPUT_DIR}${/}receipts
	FOR	${order}	IN	@{orders}
		Run the order	${order}
		${receipt_file}=	Generate the receipt	${order}[Order number]	${output_location}
		Restart the process
	END
	Create zip file of all receipts	${output_location}
	[Teardown]
	Close Browser
	Remove Directory    ${output_location}	recursive=True


*** Keywords ***
Download orders
	Download	https://robotsparebinindustries.com/orders.csv	overwrite=True
	${orders}=	Read table from CSV	orders.csv
	RETURN	${orders}

Open the order page
	Open Browser	https://robotsparebinindustries.com/#/robot-order	headlesschrome
	Set Window Size    1920    1080

Run the order
	[Arguments]	${order}
	Close the modal
	Insert Order	${order}
	
Close the modal
	${locator}=	Set Variable	//*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
	Wait Until Element Is Visible    ${locator}
	Click Button    ${locator}

Insert Order
	[Arguments]	${order}
	Select From List By Value    head	${order}[Head]
	Click Element    id-body-${order}[Body]
	Input Text	xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input	${order}[Legs]
	Input Text    address    ${order}[Address]
	Click Button    id:preview
	Wait Until Keyword Succeeds    100	1s	Submit Order

Submit Order
	Click Button    id:order
	Page Should Not Contain Element    css:div > div.container > div > div.col-sm-7 > div.alert-danger


Generate the receipt
	[Arguments]	${order_number}	${output_location}
	${base_pdf}=	Capture the receipt	${order_number}	${output_location}
	${screenshot}=	Take a screenshot of the robot	${order_number}	${output_location}
	Add the screenshot to the PDF	${base_pdf}	${screenshot}
	RETURN	${base_pdf}

Capture the receipt
	[Arguments]	${order_number}	${output_location}
	Wait Until Element Is Visible	id:receipt
	${filename}=	Set Variable	${output_location}${/}${order_number}.pdf
	${html}=	Get Element Attribute	id:receipt	outerHTML
	Html To Pdf	${html}	${filename}
	RETURN	${filename}

Take a screenshot of the robot
	[Arguments]	${order_number}	${output_location}
	${filename}=	Set Variable	${output_location}${/}${order_number}.png
	Capture Element Screenshot    id:robot-preview-image	${filename}
	RETURN	${filename}

Add the screenshot to the PDF
	[Arguments]	${pdf}	${screenshot}
	${asList}=	Create List	${screenshot}
	Open Pdf    ${pdf}
	Add Files To Pdf	${asList}	${pdf}	append=True
	Close Pdf	${pdf}
	Remove File    ${screenshot}

Restart the process
	Click Button    id:order-another

Create zip file of all receipts
	[Arguments]	${output_location}
	Archive Folder With Zip	${output_location}	${OUTPUT_DIR}${/}receipts.zip