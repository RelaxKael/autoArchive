************************************************************************************************************************************************************************ruby打包工具***************************************************
**********************************************************************************************************************

一、资源准备
1.打开资源文件夹
2.创建配置文件 打开终端 cd到资源目录,输入命令 vim configure_info创建配置文件。按I插入 添加配置信息(亦可以在finder中使用文本编辑器打开输入),完成后esc输入:wq保存并退出
*********************
eg.cd /Users/XXXX/Documents/XXXX
*********************
使用者根据自身情况，对build_object.rb中prepare函数进行修改，调试
*********************
本文仅供参考
********************

配置信息中如果证书描述跟unionName相同则profileName不需要指定，不相同则需要指定profileName参数

二、打包流程
1.打开工程 添加在preference添加企业账户，完成后选择下载手动证书(Download Manual Profiles)
2.[sudo] gem install open4 安装open4
3.[sudo] gem install xcodeproj 安装xcodeproj
4.打开终端cd到工程目录 (eg.cd /Users/xxxx/Documents/XXXXX)
5.执行命令ruby build.rb后加入参数
*********************
-d, --directory Value            配置文件夹路径 必须
-o, --output Value               输出ipa文件路径 可选
-l, --log Value                  输出日志路径 可选
-g, --group                      是否打包多个 可选 默认不是
*********************

*********************简便命令
eg .ruby build.rb -d /Users/xxxx/Documents/xx
(这条不指定日志和ipa包输出路径情况下会默认输出到工程同级目录下)
*********************

*********************完整命令
eg.ruby build.rb -d /Users/xxxx/Documents/xx打包资源/xx -l /Users/xxxx/Documents -o /Users/xxxx/Documents/xxIPA
eg.ruby build.rb -d /Users/xxxx/Documents/xx打包资源 -l /Users/xxxx/Documents -o /Users/xxxx/Documents/xxIPA -g
*********************

*********************
指定打包资源目录 -d /Users/xxxx/Documents/xx打包资源/xx
指定IPA导出目录 -o /Users/xxxx/Documents/xxIPA
指定日志路径 -l /Users/xxxx/Documents
*********************

*********************
-g 打包目录下所有资源 不指定则默认单个
*********************
以上命令也可以通过-h在终端中查看

THANKS!

