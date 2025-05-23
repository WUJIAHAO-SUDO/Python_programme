card_list = []

def show_menu():
    # 显示菜单
    print("*"*50)
    print("欢迎使用【名片管理系统】v 1.0")
    print("")
    print("1：新增名片")
    print("2：显示全部")
    print("3：搜索名片")
    print("")
    print("0：退出系统")
    print("*"*50)

def new_card():
    #新增名片
    print("-"*50)
    print("新增名片")
    #提示用户输入用户的详细信息
    name = input("请输入姓名：")
    phone = input("请输入电话：")
    qq = input("请输入QQ号码：")
    email = input("请输入邮箱：")
    #使用新用户信息建立一个新的名片字典
    card_dict = {"name":name,
                 "phone":phone,
                 "qq":qq,
                 "email":email}
    #将新的用户字典添加到列表里
    card_list.append(card_dict)

    print(card_list)
    #提示用户添加成功
    print("添加%s的名片成功"%name)

def show_all():
    #显示所有名片
    print("-"*50)
    print("显示所有名片")

    #判断是否存在名片记录，如果没有，提示用户并返回
    if len(card_list) == 0:
        print("当前没有任何名片记录，请使用新增功能添加名片！")
        #return可以返回一个函数的执行结果，下方的函数代码不会被执行
        #如果return后没有任何内容，表示会返回到执行函数的位置，并且不返回任何的结果
        return
    
    #打印表头
    for name in ("姓名","电话","QQ","邮箱"):
        print(name,end="\t\t")
    print("")
    
    print("="*50)
    
    for car_dict in card_list:
        print("%s\t\t%s\t\t%s\t\t%s"%(car_dict["name"],
                                      car_dict["phone"],
                                      car_dict["qq"],
                                      car_dict["email"]))

    

def search_card():
    #搜索名片
    print("-"*50)
    print("搜索名片")

    #1.提示用户输入要搜索的姓名
    find_name = input("请输入要搜索的姓名")
    for card_dict in card_list:
        if card_dict["name"] == find_name:
            print("找到了！")
            print("姓名\t\t电话\t\tQQ\t\t邮箱")
            print("="*50)
            print("%s\t\t%s\t\t%s\t\t%s"%(card_dict["name"],
                                          card_dict["phone"],
                                          card_dict["qq"],
                                          card_dict["email"]))
            #针对找到的名片执行修改和删除的操作
            deal_card(card_dict)
            break
    else:
        print("抱歉！没有找到%s" % find_name)

def deal_card(find_dict):
    print(find_dict)
    action_str = input("请选择要执行的操作：1.修改 2.删除 0.返回上级")
    if action_str == "1":
        print("修改名片")
        for item in find_dict:
            print("请输入新的%s:" % item)
            find_dict[item] = input_card_info(find_dict[item])
        print("修改名片成功！")

    elif action_str == "2":
        print("删除名片")
        card_list.remove(find_dict)
        print("删除名片成功")
    elif action_str == "0":
        print("返回上级")

def input_card_info(dict_value):
    #1.提示用户输入内容
    result_str = input()
    #2.如果输入内容，直接返回结果
    if len(result_str) > 0:
        return result_str
    #3.如果没有输入内容，返回字典原有的值
    else:
        return dict_value
