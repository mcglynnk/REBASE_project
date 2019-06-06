# -*- coding: utf-8 -*-
"""
Created on Sat Jun  1 21:01:51 2019

@author: Kelly
"""
#%%
# import libraries
import requests
from bs4 import BeautifulSoup
import lxml
import csv
import mechanicalsoup

#%%
#get url
page=mechanicalsoup.StatefulBrowser()
page.open('http://rebase.neb.com/cgi-bin/eyearlist?2')
url = 'http://rebase.neb.com/cgi-bin/eyearlist?2'
# Create a BeautifulSoup object
#soup = BeautifulSoup(page.text, 'lxml')
#print(soup.prettify())

#print(soup.find_all(target='enz'))
#print(soup.find_all('a'))
#enz_names = soup.find_all(target='enz')
#enz2_ = page.get_current_page().find_all('tr')[4:]
#enzx = enz2_[11]
enz3_ = page.get_current_page().find_all('tr')[4:]


#f = csv.writer(open('enz2.csv', 'w', newline=''))
#f.writerow(['REnz', 'Org-', 'Year-','Rec_seq-','Rtype-'])
#f =open('enz.csv', 'w',newline='')
#writer=csv.writer(f)
#writer.writerow(['REnz', 'Org-', 'Year-','Rec_seq-','Rtype-'])

filename = 'enz.csv'
with open(filename, 'w' ,newline='') as f:
    fieldnames= ['REnz', 'Org', 'Year','Rec_seq','Rtype']
    w = csv.DictWriter(f,fieldnames=fieldnames)
    w.writeheader()
    for i in enz3_:
        Enz=i.td.a.contents[0]
        
        #get organism names
        nxt=page.open_relative("http://rebase.neb.com" + i.td.a['href'])
        soupn=BeautifulSoup(nxt.text, 'lxml')
        c=soupn.find_all("i")
        Org=c[0].contents[0]+ " " +c[1].contents[0]
        
        
        Year=i.td.find_next_siblings("td")[0].font.contents[0]
        Rec_seq=i.td.find_next_siblings("td")[1].font.contents[0]
        Rtype=i.td.find_next_siblings("td")[3].font.contents[0]
        #print(Enz, Org, Year, Rec_seq, Rtype)
        #rows=[Enz, Org, Year, Rec_seq, Rtype]
        w.writerow({'REnz':Enz, 'Org':Org, 'Year':Year, 'Rec_seq':Rec_seq, 'Rtype':Rtype})


#f = csv.writer(open('enz2.csv', 'w', newline=''))
#f.writerow(['REnz', 'Org-', 'Year-','Rec_seq-','Rtype-'])

    
    

