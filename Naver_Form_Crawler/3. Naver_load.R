library(RSelenium)

# 1. 네이버 페이지 로드
remDr <- remoteDriver(port=4445, browserName='chrome')

remDr$open()
url_main <- 'https://form.office.naver.com/form/editor.cmd?initialView=summary&docId=MGViZDZhOWQtYzRmZS00ZmY4LWJiYmYtYjdlZDUwYWE2ZGZh&baseFolder=%252F%25EB%2582%25B4%2B%25EB%25AC%25B8%25EC%2584%259C%252F'
remDr$navigate(url_main)
Sys.sleep(2)


# 2. 아이디, 비밀번호 자동 입력
id <- readline('id >>> ')
password <- readline('password >>> ')

tmp_input <- remDr$findElement('xpath','//*[@id="id"]')
tmp_input$sendKeysToElement(sendKeys = list(id))
Sys.sleep(1)

tmp_input <- remDr$findElement('xpath','//*[@id="pw"]')
tmp_input$sendKeysToElement(sendKeys = list(password))
Sys.sleep(1)

tmp_btn <- remDr$findElement('css','#frmNIDLogin > fieldset > input')
tmp_btn$clickElement()
Sys.sleep(2)

tmp_input <- remDr$findElement('xpath','//*[@id="pw"]')
tmp_input$sendKeysToElement(sendKeys = list(password))
Sys.sleep(1)

