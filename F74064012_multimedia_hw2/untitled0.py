# -*- coding: utf-8 -*-
"""
Real Time System Final Project
-----------------------------
        Time-table
-----------------------------
0800
0830
0900
1300
1400
1800
1839
1900
2000
2030
2400
-----------------------------
      Dose Type and Time
-----------------------------
QD      2135     2625
BID     1045     1315
TID     0710     0850
QID     0520     0640
"""
import datetime as dt
from dateutil.parser import parse
from operator import itemgetter
error_rate = 0
miss_rate = 0

#把第一天設為程式運作的那一天的00:00
firstday = dt.date.today()
firstday = firstday.ctime()
firstday = parse(firstday)

#期限設為第一天的0:00往後六天的24:00也就是後七天的00:00
lastday = firstday + dt.timedelta(days = 7)
lastday = lastday.ctime()
lastday = parse(lastday)

#input格式"hour:minute" 轉為 output格式minute
def time_translate(h_m):
    h,m = h_m.strip().split(':')
    return int(h)*60 + int(m)

#Daily 開始時間到結束時間-1，否則會有難以界定像是08:00時到底是type1 還是type0的問題
Daily = [
         ["00:00","07:59","1"],
         ["08:00","08:29","0"],
         ["08:30","08:59","0"],
         ["09:00","12:59","2"],
         ["13:00","13:59","0"],
         ["14:00","17:59","2"],
         ["18:00","18:29","0"],
         ["18:30","18:59","0"],
         ["19:00","19:59","0"],
         ["20:00","20:29","0"],
         ["20:30","23:59","0"],]
Date = []
Daily_time_table = []
for i in range(7):
    Date.append(dt.date.today() + dt.timedelta(days = i))
    for j in range(11):
        day_tmp = Date[i]
        day_tmp = day_tmp.ctime()
        day_tmp = parse(day_tmp)
        Daily_time_table.append([4, day_tmp + dt.timedelta(minutes = time_translate(Daily[j][0])),Daily[j][2]])  
#藥物
QD = [time_translate("21:35"), time_translate("26:25")] #一天一次
BID = [time_translate("10:45"), time_translate("13:15")]#一天兩次
TID = [time_translate("07:10"), time_translate("08:50")]#一天三次
QID = [time_translate("05:20"), time_translate("06:40")]#一天四次
medicine = [TID,QID,BID,QD]


#time_schedule_all用來紀錄各個藥物的已服用時刻 方便盡量排在同一個時間吃藥
time_schedule_all = []
#time_temp用來記錄各個藥前一次是甚麼時候吃的
time_temp = firstday + dt.timedelta(minutes = time_translate("08:00")) 
time_temp = [time_temp,time_temp,time_temp,time_temp,time_temp]

medicine2 = [[time_temp[1],"0"]]#初始選的時間是8:00 類別是0
medicine3 = [[time_temp[2],"0"]]
medicine4 = [[time_temp[3],"0"]]
start_label = 1
for num in (range(4 - start_label)):
    end = 0
    even = 0
    for i in range(7):
        #最小到最打時間可分成幾次五分鐘
        temp_interval = medicine[num+start_label][1] - medicine[num+start_label][0]
        temp_interval /= 5
        temp_interval += 1
        day_tmp = Date[i]
        day_tmp += dt.timedelta(days = 1)
        day_tmp = day_tmp.ctime()
        day_tmp = parse(day_tmp)
        for m in range(int(temp_interval)):
          #由最小的時間開始加 如果加上最小時間後就超出那一天的23:59那就換到隔天去算
          temp = time_temp[num+start_label] + dt.timedelta(minutes = medicine[num+start_label][0])
          find_type = "-1"
          AGAIN = "0"
          if temp < day_tmp :
              FIND = 0
              for n in range(2):
                  if FIND == 0:
                      for j in range(int(temp_interval)):
                          if j != 0:
                              temp += dt.timedelta(minutes = 5)
                          #由最小加到最大時間之前 如果AGAIN == 0 有符合type0的就停止 如果AGAIN == 1 有符合type1的就停止 若只找到type2的print(error)並break
                          l = 0
                          for k in range(11):
                              l = i*11 + k
                              if l != 76:
                                  if temp >= Daily_time_table[l][1] and temp < Daily_time_table[l+1][1]:
                                      if num + start_label == 1 and temp + dt.timedelta(minutes = 5) >= Daily_time_table[l][1] and temp + dt.timedelta(minutes = 5) < Daily_time_table[l+1][1] and even == 1 and j == 0:
                                          temp += dt.timedelta(minutes = 5)
                                      find_type = Daily_time_table[l][2]
                                      break
                              else:
                                  if temp >= Daily_time_table[l][1] and temp < lastday:
                                      find_type = Daily_time_table[l][2]                             
                                      break
                                  else:
                                      end = 1 
                                      break
                          if end == 1:
                              break
                          if find_type == AGAIN:
                              if num+start_label == 1:
                                medicine2.append([temp,find_type])
                                if even == 0:
                                    even = 1
                                elif even == 1:
                                    even = 0
                              elif num+start_label == 2:
                                medicine3.append([temp,find_type])
                              elif num+start_label == 3:
                                medicine4.append([temp,find_type]) 
                              time_temp[num+start_label] = temp
                              AGAIN = "0"
                              FIND = 1
                              #print(find_type)
                              break
                          elif (find_type == "-1" or find_type == "1") and j == (temp_interval - 1) and AGAIN == "0":
                              AGAIN = "1"
                          elif find_type == "-1" and j == (temp_interval - 1) and AGAIN == "1":
                              print("error")
                              break
                      if end == 1:
                          break
                  else:
                      break
          else :
              break                
          if end == 1:
              break     

for i in range(len(medicine2)):
  time_schedule_all.append([medicine2[i][0],"2"])
for i in range(len(medicine3)):
  time_schedule_all.append([medicine2[i][0],"3"])
for i in range(len(medicine4)):
  time_schedule_all.append([medicine4[i][0],"4"])
time_schedule_all = sorted(time_schedule_all,key = itemgetter(0))

#TODO 下面做計算同時間的數量與換算成作業要求的格式