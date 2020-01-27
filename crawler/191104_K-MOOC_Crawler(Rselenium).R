library(rvest)
library(RSelenium)
library(httr)

remDr <- remoteDriver(port=4445, browserName='chrome')

# 1. 크롤링 할 페이지 로드 (K-MOOC 선형대수학 강의실)
remDr$open()
url_main <- 'http://www.kmooc.kr/'
remDr$navigate(url_main)

tmp_btn <- remDr$findElement('xpath','/html/body/div[2]/header/div[1]/section/section[2]/section/div/div[2]/div/div[2]/a')
tmp_btn$clickElement()
Sys.sleep(1)

tmp_input <- remDr$findElement('xpath','//*[@id="login-email"]')
tmp_input$sendKeysToElement(sendKeys = list('ksmo9191@gmail.com') )
Sys.sleep(1)

# --------------- stop and input password -----
tmp_input <- remDr$findElement('xpath','//*[@id="login-password"]')
tmp_input$sendKeysToElement(  ) # list(password)
Sys.sleep(1)
# ----------------------------------------------

tmp_btn <- remDr$findElement('xpath','//*[@id="login"]/button')
tmp_btn$clickElement()
Sys.sleep(2)

url_lecture_room <- 'http://www.kmooc.kr/courses/course-v1:UOSk+ACE_UOS06+2019_T2/course/'
remDr$navigate(url_lecture_room)
Sys.sleep(2)

tmp_btn <- remDr$findElement('xpath','//*[@id="expand-collapse-outline-all-button"]')
tmp_btn$clickElement()
Sys.sleep(1)


# 2. 각 강좌 제목, 링크 수집해 df에 저장
title_elems <- remDr$findElements('xpath','//ol[@class="outline-item accordion-panel"]/li[@class="subsection accordion "]/ol[@class="outline-item accordion-panel"]')

link_elems <- remDr$findElements('xpath','//ol[@class="outline-item accordion-panel"]/li[@class="subsection accordion "]/ol[@class="outline-item accordion-panel"]//a[@class="outline-item focusable"]')

titles <- NULL
links <- NULL

for (idx in 1:length(title_elems)) {
  tmp_title <- title_elems[[idx]]$getElementText()
  tmp_title <- as.character(tmp_title)
  titles <- c(titles, tmp_title)
  
  # ------------- 문제 발생 : <a>를 못 찾음
  # tmp_elem <- tmp_elems[[idx]]$findElement('css','a')
  # tmp_link <- tmp_elem$getElementAttribute(attrName = 'href')
  # -------------------   
  
  tmp_link <- link_elems[[idx]]$getElementAttribute(attrName = 'href')
  tmp_link <- as.character(tmp_link)
  links <- c(links, tmp_link)
  
  # 100번째마다 알림
  if (idx%%10==0) {
    cat(idx, '번째 강좌 정보 수집함.\n')
  }
}
res_df <- data.frame(titles, links, stringsAsFactors = F)


# 3-1. df 가공 - 제목 'n차시~'인 탭만 남기고 세부 가공
res_df <- res_df[ grepl('[1-9]차시',res_df$titles) , ]
row.names(res_df) <- NULL
res_df$titles[8] <- '1차시 nXn 행렬의 행렬식'
res_df$titles[11] <- '1차시 벡터공간 R^n'
res_df$titles[17] <- '1차시 R^n에서의 내적'

# 3-2. df 가공 - 'n강~' 타이틀 크롤링 > 각 제목에 'n강~' 추가
## 'n강~' 타이틀 크롤링
tmp_elems <- remDr$findElements('css','h3.section-title')
meta_titles <- NULL
for (idx in 1:length(tmp_elems)) {
  tmp_chr <- tmp_elems[[idx]]$getElementText()
  tmp_chr <- as.character(tmp_chr)
  meta_titles <- c(meta_titles, tmp_chr)
}
meta_titles <- meta_titles[grepl('[1-8]강', meta_titles)]
meta_titles[4] <- '4강 벡터공간 R^n'
meta_titles[6] <- '6강 R^n의 내적'

## 각 제목에 'n강~' 추가
meta_num <- 1
bfr_num <- 1
now_num <- 1
for (idx in 1:nrow(res_df)) {
  now_num <- as.numeric( substr(res_df$titles[idx],1,1) )
  if (now_num==1 & bfr_num!=1) {
    meta_num <- meta_num + 1
  }
  
  res_df$titles[idx] <- paste(meta_titles[meta_num], res_df$titles[idx])
  bfr_num <- now_num
}

write.csv(res_df, '191104 선형대수학 강의 정보.csv', row.names=F)


# 4. 각 링크에서 동영상 소스 링크 수집해 df에 추가
source_links <- NULL
for (idx in 1:nrow(res_df)) {
  tmp_link <- res_df$links[idx]
  remDr$navigate(tmp_link)
  tmp_elem <- remDr$findElement('css','source')
  
  tmp_src_link <- tmp_elem$getElementAttribute(attrName = 'src')
  tmp_src_link <- as.character(tmp_src_link)
  source_links <- c(source_links, tmp_src_link)
  
  if (idx%%10==0) {
    cat(idx, '번째 소스링크 수집함.\n')
  }
}
res_df <- data.frame(res_df, source_links, stringsAsFactors = F)

write.csv(res_df, '191104 선형대수학 강의 정보.csv', row.names=F)


# 5. 1~3강 영상 cotent response 받아 저장
for (idx in 1:nrow(res_df)) {
  tmp_src <- res_df$source_links[idx]
  tmp_res <- GET(tmp_src)
  
  tmp_fname <- paste0('K-MOOC 선형대수학 강의/', res_df$titles[idx],'.mp4')
  writeBin(content(tmp_res, 'raw'), tmp_fname)
}


