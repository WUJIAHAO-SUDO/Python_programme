#导入相关模块
import requests
import re
from bs4 import BeautifulSoup
import json
from tqdm import tqdm

class CoronaVirusSpider(object):
    def __init__(self):
        self.home_url = "https://data.who.int/dashboards/covid19/cases"
    def get_content_from_url(self,url):
        #发送请求，获取疫情首页
        response = requests.get(url)
        return response.content.decode()
    def parse_home_page(self,home_page,tag_id):
        #从疫情首页，通过beautifulsoup提取最近一日的各国疫情数据
        #构建对象
        soup = BeautifulSoup(home_page,'lxml')
        #根据id查找标签
        script = soup.find(id=tag_id)
        #获取标签中文本信息
        text = script.string
        print(text)
        #使用正则表达式从疫情数据中提取json字符串
        json_str = re.findall(r'\[.+\]',text)
        print(json_str)
        #把json字符串转变为python格式
        data = json.loads(json_str)
        return data
    def save(self,data,savepath):
        #以json格式保存各国疫情数据
        with open(savepath,'w') as fp:
            json.dumps(data,fp,ensure_ascii=False)

    #获取最近一日各国疫情数据
    def crawl_last_day_corona_virus(self):
        #1.获取首页内容
        home_page = self.get_content_from_url(self.home_url)
        #2.解析首页内容
        last_day_corona_virus = self.parse_home_page(home_page, tag_id='')
        self.save(last_day_corona_virus,'D:/竞赛和课程文件/编程语言/Python/基本编程语法学习笔记\爬虫/last_day_corona_virus.json')

    def crawl_corona_virus(self,readpath,savepath):
        """采集从1月23号以来各国的疫情数据
        :return:"""
        #1.加载各国数据
        with open(readpath) as fp:
            last_day_corona_virus = json.loads(fp)
        print(last_day_corona_virus)
        #定义列表，用于存储
        corona_virus = []

        #2.遍历各国数据，获取统计的url
        for country in tqdm(last_day_corona_virus,"采集1月23号以来各国疫情数据"):
        #3.发送请求，获取json数据
            statistics_data_url = country["statisticsAata"]#找到这个键
            statistics_data_json_str = self.get_content_from_url(statistics_data_url)
            print(statistics_data_json_str)
        #4.把json转变为python，并存储到列表里
            statistics_data = json.loads(statistics_data_json_str)
            print(statistics_data)
        #5.把总数据列表以json格式保存为文件
            for oneday in statistics_data:
                oneday["provinceName"] = country["provinceName"]
                oneday["countryShortCode"] = country["countryShortCode"]
            print(statistics_data)
            corona_virus.extend(statistics_data)
        self.save(corona_virus,savepath)
    
    #采集最近一日全国各省疫情数据
    def crawl_last_day_corona_virus_of_china(self,savepath,tag_id):
        #1.发送请求，获取疫情首页
        home_page = self.get_content_from_url(self.home_url)
        #2.从疫情首页解析提取最近一日的各省疫情数据
        #构建对象
        soup = BeautifulSoup(home_page,'lxml')
        #根据id查找标签
        script = soup.find(id=tag_id)
        #获取标签中文本信息
        text = script.string
        print(text)
        #使用正则表达式从疫情数据中提取json字符串
        json_str = re.findall(r'\[.+\]',text)
        data = json.loads(json_str)
        #3.保存疫情数据
        self.save(data,savepath)



    def run(self):
        self.crawl_last_day_corona_virus()
        self.crawl_corona_virus()
        self.crawl_last_day_corona_virus_of_china()

if __name__ == '__main__':
    spider = CoronaVirusSpider()
    spider.run()


        











