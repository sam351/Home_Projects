library(dplyr)
library(xlsx)

# 3. 응답 결과창 로드
tmp_btn <- remDr$findElement('css','#promotion_layer > div.closeBtn.ui_button > img')
tmp_btn$clickElement()
Sys.sleep(1)

tmp_btn <- remDr$findElement('css','#menu_summary > a > span')
tmp_btn$clickElement()
Sys.sleep(1)

tmp_elem <- remDr$findElement('css','#summaryViewIframe')
tmp_url <- unlist(tmp_elem$getElementAttribute(attrName = 'src'))

remDr$navigate(tmp_url)
Sys.sleep(2)
# url_main <- paste0('https://form.office.naver.com/form/',
#                    'summaryViewByDocId.cmd?docId=ZTFiNTI5NzYtODNlMy00MmUwLWJjODktMjQ2NThiNDkwZjZi&timestamp=1573472680424')

tmp_btn <- remDr$findElement('css','#viewByResponses')
tmp_btn$clickElement()
Sys.sleep(1)


# 4. 응답 10개씩 수집 - 0 입력하면 계속, 끝낼 번호 입력하면 중단
prev_btn <- remDr$findElement('css','#prevResponse')
prev_btn$clickElement()
Sys.sleep(1)

cnt <- 0
성명 <- NULL
성별 <- NULL
학교 <- NULL
핸드폰번호 <- NULL

while (T) {
  tmp_elem <- remDr$findElement('css','#formItem_1 > ul > div > div > div')
  tmp_txt <- unlist(tmp_elem$getElementText())
  # tmp_txt <- substr(tmp_txt,1,3) - 나중에 수행
  성명 <- c(성명, tmp_txt)

  tmp_elem <- remDr$findElement('css','#formItem_15 > ul > div > div > div')
  tmp_txt <- unlist(tmp_elem$getElementText())
  # tmp_txt <- substr(tmp_txt,1,1) - 나중에 수행
  성별 <- c(성별, tmp_txt)

  tmp_elem <- remDr$findElement('css','#formItem_14 > ul > div > div > div')
  tmp_txt <- unlist(tmp_elem$getElementText())
  학교 <- c(학교, tmp_txt)

  tmp_elem <- remDr$findElement('css','#formItem_13 > ul > div > div > div')
  tmp_txt <- unlist(tmp_elem$getElementText())
  핸드폰번호 <- c(핸드폰번호, tmp_txt)
  
  
  cnt <- cnt + 1
  prev_btn <- remDr$findElement('css','#prevResponse')
  prev_btn$clickElement()
  
  if (cnt==10) {
    print( data.frame(성명, 성별, 학교, 핸드폰번호) )
    select_num <- readline('몇 번까지 수집하고 끝낼까요? (0 입력하면 10개 더 수집) : ')
    select_num <- as.numeric(select_num)
    
    if (select_num==0) {
      cnt <- 0
    } else {
      break
    }
  }
}


# 5. new_df 생성, old_df 로드
성명 <- 성명[1:select_num]
직급 <- ""
성별 <- 성별[1:select_num]
학교 <- 학교[1:select_num]
핸드폰번호 <- 핸드폰번호[1:select_num]
비고 <- "미등록 신규 회원"

new_df <- data.frame(성명, 직급, 성별, 
                     학교, 핸드폰번호, 비고,
                       stringsAsFactors=F)
old_df <- read.csv('1. old_members.csv', stringsAsFactors=F)


# 6. new_df 데이터 가공 - 성명, 성별, 학교, 핸드폰번호 정리
## 성명 열 정리
new_df$성명 <- substr(new_df$성명, 1,3)

## 성별 열 정리
new_df$성별 <- substr(new_df$성별, 1, 1)
for (idx in 1:length(new_df$성별)) {
  if ( !new_df$성별[idx] %in% c('남','여') ) {
    print( t(new_df[idx, c(1,3:5)]) )
    Sys.sleep(1)
    tmp_chr <- readline('위 응답지의 성별이 이상합니다. 성별을 무엇으로 저장할까요? (남/여를 입력하지 않으면 최종 파일 final_df.csv에서 배제됩니다.) : ')
    new_df$성별[idx] <- tmp_chr
  }
}

## 학교 열 정리
for (idx in 1:length(new_df$학교)) {
  if (grepl('/', new_df$학교[idx])) {
    new_df$학교[idx] <- unlist(strsplit(new_df$학교[idx], '/'))[1]
  } else if(grepl('대학교', new_df$학교[idx])) {
    new_df$학교[idx] <- unlist(strsplit(new_df$학교[idx], '대학교'))[1]
  } else {
    new_df$학교[idx] <- unlist(strsplit(new_df$학교[idx], ' '))[1]
  }
}
new_df$학교 <- trimws(new_df$학교)

for (idx in 1:length(new_df$학교)) {
  if ( endsWith(new_df$학교[idx], '교대') ) {
    new_df$학교[idx] <- gsub('교대','교육대학교', new_df$학교[idx])
  } else if ( endsWith(new_df$학교[idx], '대') ) {
    new_df$학교[idx] <- paste0(new_df$학교[idx], '학교')
  } else if ( !endsWith(new_df$학교[idx], '대학교') ) {
    new_df$학교[idx] <- paste0(new_df$학교[idx], '대학교')
  }
}

## 핸드폰번호 열 정리
new_df$핸드폰번호 <- trimws(new_df$핸드폰번호)
for ( idx in 1:length(new_df$핸드폰번호) ) {
  if ( !startsWith(new_df$핸드폰번호[idx], '0') ) {
    new_df$핸드폰번호[idx] <- paste0('0',new_df$핸드폰번호[idx])
  }
  
  if ( grepl('\\.', new_df$핸드폰번호[idx]) & !endsWith(new_df$핸드폰번호[idx], '\\.') ) {
    tmp_chr <- unlist(strsplit(new_df$핸드폰번호[idx], '.'))
    new_df$핸드폰번호[idx] <- paste0(tmp_chr[1], '-',tmp_chr[2], '-',tmp_chr[3])
  } else if ( grepl(' ', new_df$핸드폰번호[idx]) ) {
    tmp_chr <- unlist(strsplit(new_df$핸드폰번호[idx], ' '))
    new_df$핸드폰번호[idx] <- paste0(tmp_chr[1], '-',tmp_chr[2], '-',tmp_chr[3])
  } else if( !grepl('-', new_df$핸드폰번호[idx]) ) {
    tmp_chr <- new_df$핸드폰번호[idx]
    new_df$핸드폰번호[idx] <- paste0( substr(tmp_chr,1,3) , '-',
                                 substr(tmp_chr,4,7), '-',
                                 substr(tmp_chr,8,11) )
  }
}


# 7. new_df, old_df 합치고 저장
final_df <- rbind(old_df, new_df)

women_df <- final_df %>% filter(성별=='여') %>% arrange(성명)
men_df <- final_df %>% filter(성별=='남') %>% arrange(성명)

final_df <- rbind(women_df, men_df)

write.csv(final_df, '5. final_df.csv', row.names = F)
write.csv(new_df, '5-2. new_df(검토용).csv', row.names = F)
