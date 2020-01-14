
# coding: utf-8

# In[1]:


import pandas as pd
import numpy as np


# In[2]:


# 1. preprocessing report statement xlsx
system_df = pd.read_excel('./결의서전표.xlsx')
system_df = system_df.iloc[ :-1][['결의일자-번호','수입금액','지출금액']]
system_df['결의일자'] = [ string[:-2] for string in system_df['결의일자-번호'] ]
system_df = system_df.drop('결의일자-번호', axis=1)
system_df = system_df.set_index('결의일자')
# system_df


# In[3]:


# 2. preprocessing account xls
account_df = pd.read_excel('./통장거래내역.xls', skiprows = 9)[['거래일자','입금금액(원)','출금금액(원)']]
account_df = account_df.set_index('거래일자').fillna(0).astype(int)
# account_df


# In[4]:


# 3. comparing total amount of income & spending
print('<<<<<<< 전표 점검을 시작합니다 >>>>>>>\n')

print('1. 수입/지출 총액 비교\n')

system_income = sum(system_df.수입금액)
account_income = sum(account_df["입금금액(원)"])
print(f'(1) 결의서전표 수입총액 : { system_income }원, 통장거래내역 입금총액 : { account_income }원')
print('>>> 수입총액은 정상입니다.\n') if system_income == account_income else print('>>> 경고!!! 수입총액이 다릅니다!\n')

system_spending = sum(system_df.지출금액)
account_spending = sum(account_df['출금금액(원)'])
print(f'(2) 결의서전표 지출총액 : { system_spending }원, 통장거래내역 출금총액 : { account_spending }원')
print('>>> 지출총액은 정상입니다.\n') if system_income == account_income else print('>>> 경고!!! 지출총액이 다릅니다!\n')

print('='*70, end='\n'*2)


# In[5]:


# 4. migrating rows with same date - calcaulating total amount of each date
system_df_groupby = system_df.groupby('결의일자')[['수입금액','지출금액']].sum()
# system_df_groupby

account_df_groupby = account_df.groupby('거래일자')[['입금금액(원)','출금금액(원)']].sum()
# account_df_groupby


# In[6]:


# 5. merging two df
merge_df = system_df_groupby.merge(account_df_groupby, how='outer',left_on=system_df_groupby.index, right_on=account_df_groupby.index)
merge_df = merge_df.rename(columns={'key_0':'날짜'}).set_index('날짜')
merge_df = merge_df.fillna(0).astype(int)
# merge_df


# In[9]:


# 6. comparing incomes of each date
print('2. 수입결의서 날짜별 총액 비교\n')
unmatch_income = [ (idx, item1, item2) for (idx, item1, item2) 
     in zip(merge_df.index, merge_df['수입금액'], merge_df['입금금액(원)'])
     if item1 != item2 ]

if not unmatch_income:
    print('>>> [수입 결의서] 정상입니다.\n')
else:
    print('>>> 경고!!! [수입 결의서] 문제가 발견되었습니다!\n')
    for idx, line in enumerate(unmatch_income):
        print(f'({idx+1}) {line[0]} 날짜 : [수입 결의서] {line[1]}원 → [통장 거래내역] {line[2]}원입니다.\n')
        pass
    pass

print('='*70, end='\n'*2)

# 7. comparing spendings of each date
print('3. 지출결의서 날짜별 총액 비교\n')
unmatch_cost = [ (idx, item1, item2) for (idx, item1, item2) 
     in zip(merge_df.index, merge_df['지출금액'], merge_df['출금금액(원)'])
     if item1 != item2 ]

if not unmatch_cost:
    print('>>> [지출 결의서] 정상입니다.\n')
else:
    print('>>> 경고!!! [지출 결의서] 문제가 발견되었습니다!\n')
    for idx, line in enumerate(unmatch_cost):
        print(f'({idx+1}) [지출 결의서] {line[0]} 날짜에 {line[1]}원으로 입력된 부분은 통장 거래내역에 {line[2]}원입니다.\n')
        pass
    pass

print('='*70, end='\n'*2)


# In[8]:


end_input = input('종료하시려면 아무 키나 입력하세요 >>> ')

