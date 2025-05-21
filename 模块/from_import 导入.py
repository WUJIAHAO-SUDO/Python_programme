#注意！自定义模块一定不要和系统模块重名，因为↓
#导入模块时，系统会先搜索当前目录是否有同名模块，搜索不到才会在系统目录内搜索

from 测试模块1 import Dog
from 测试模块1 import say_hello
#后导入的工具会覆盖掉已有的工具
from 测试模块2 import say_hello
#通过起别名来导入相同名称函数
from 测试模块1 import say_hello as tool1
#从模块导入所有工具: from 模块名 import *
say_hello()
tool1()
wangcai = Dog()
print(wangcai)

import random
#通过系统内置inspect模块可以获得模型源码
import inspect
#通过.__file__可以获得模块的路径
print(random.__file__)
print(inspect.getsource(random.randrange))