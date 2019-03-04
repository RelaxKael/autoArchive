#!/usr/bin/ruby -w
# -*- coding: UTF-8 -*-
require 'fileutils'
require 'open4'
require 'xcodeproj'
require 'plist'
require File.dirname(__FILE__) + '/LogDetector'
#自行修改你的工程名
$ProjectName = "ProjectName"
#需要替换的配置信息
$app_project_dir = Dir.pwd + "/#{$ProjectName}.xcodeproj"
#你的工程Info.plist
$app_info_dir = "#{$ProjectName}/Info.plist"
$export_options = 'ExportOptions.plist'
$PgyUkey = ""
$PgyApiKey = ""
class BuildObject
    @file_diretory = ''
    @logout_directory = ''
    @bundleId = ''
    @profileName = ''
    @displayName = ''
    @wechatAppKey = ''
    #默认需要上传
    @needUpload = true
    def initialize(path , logout = File.dirname(Dir.pwd))
        @file_diretory = path
        @logout_directory = logout
        configure_info_path = path + '/configure_info.plist'
        plist_data = Plist.parse_xml(configure_info_path)
        @bundleId = plist_data['bundleId']
        @displayName = plist_data['displayName']
        @profileName = plist_data['profileName']
        @wechatAppKey = plist_data['wechatAppKey']
        @needUpload = plist_data['needUpload']
    end
    def prepare
        #Appicon文件路径 替换icon 如不需要注释掉调用replace_image方法
        common_icon_dir  = Dir.pwd + "/#{$ProjectName}/Assets.xcassets/AppIcon.appiconset"
        configure_export_options
        replace_project_info
        replace_plist_info
        replace_image(common_icon_dir,@file_diretory)
    end
    #修改exportOption的键值
    def configure_export_options
        # #读取info
        export_option_plist = Plist.parse_xml($export_options)
        hash = Hash[@bundleId => @profileName]
        export_option_plist['provisioningProfiles'] = hash
        Plist::Emit.save_plist(export_option_plist , $export_options , {})
      
        if block_given?
          yield
        end
    end
    #修改bundid和描述文件名称
    def replace_project_info
        
        project = Xcodeproj::Project.open($app_project_dir)
        project.targets[0].build_configurations.each do |config|
              config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = @bundleId
              config.build_settings["PROVISIONING_PROFILE_SPECIFIER"] = @profileName
        end
        project.save
        
        if block_given?
            yield
        end
    end
        
    #修改displayname url_scheme
    def replace_plist_info
        # #读取info
        
        plist_data = Plist.parse_xml($app_info_dir)
        
        plist_data.delete('CFBundleURLTypes')
        plist_data.delete('LSApplicationQueriesSchemes')
        plist_data['CFBundleDisplayName'] = @displayName
        #这是url scheme设置微信支付宝拉起 如需要在configure_info.plist设置wechatAppKey
        # schemes_array = Array.new()
        #
        # if @wechatAppKey != nil
        #   # 微信url_scheme
        #   scheme_hash_wechat = Hash.new("")
        #   scheme_hash_wechat['CFBundleTypeRole'] = "Editor"
        #   scheme_hash_wechat['CFBundleURLName'] = "weixin"
        #   scheme_hash_wechat['CFBundleURLSchemes'] = [@wechatAppKey]
        #   schemes_array.push(scheme_hash_wechat)
        # end
        #
        # # 支付宝url_scheme
        # scheme_hash_alipay = Hash.new("")
        # scheme_hash_alipay['CFBundleTypeRole'] = "Editor"
        # scheme_hash_alipay['CFBundleURLSchemes'] = ["comAlipay#{@profileName}"]
        # schemes_array.push(scheme_hash_alipay)
        #
        # plist_data['CFBundleURLTypes'] = schemes_array
        # if schemes_array.length > 1
        #     #添加LSApplicationQueriesSchemes
        #     plist_data['LSApplicationQueriesSchemes'] = ["weixin"]
        # end
        
        # puts plist_data.to_plist #String类型 直接读写文件
        Plist::Emit.save_plist(plist_data , $app_info_dir , {})
        
        if block_given?
            yield
        end
    end
            
    #复制新资源
    def replace_image(origin_path , source_path)
        if File.directory?(origin_path)
            Dir.foreach(origin_path) do |file|
                newpath = origin_path + "/" + file
                filetype = File.ftype(newpath)
                    if filetype.eql?("file") && file.include?("png")
                        newsourcepath = source_path + "/" + file
                        FileUtils.cp(newsourcepath , newpath)
                    end
                end
        end
        if block_given?
            yield
        end
    end

    def start_xcodebuild(&finish_block)
        #xcodebuild打包参数 如需要调整 自行查阅文档修改
        command = "xcodebuild clean -workspace #{$ProjectName}.xcworkspace -scheme #{$ProjectName}"
        pid, stdin , stdout ,stderr = Open4::popen4 command
            puts "开始clean进程"
            stdin.close
            stdout.close
        _, status = Process::waitpid2 pid
        
        if status.success?
            archive(&finish_block)
        else
            LogDetector::log_info(stderr.read.strip , @displayName)
            finish_block.call(false)
        end
    end
    
    def archive(&finish_block)
        command = "xcodebuild archive -workspace #{$ProjectName}.xcworkspace -scheme #{$ProjectName} -configuration Release -archivePath " + @logout_directory + "/Archive/" + @displayName + "/#{$ProjectName}.xcarchive"
        pid, stdin , stdout ,stderr = Open4::popen4 command
        puts "开始archive进程"
        stdin.close
        stdout.close
        _, status = Process::waitpid2 pid

        if status.success?
            export(&finish_block)
        else
            LogDetector::log_info(stderr.read.strip , @displayName)
            finish_block.call(false)
        end
    end
    
    def export(&finish_block)
        command = "xcodebuild -exportArchive -archivePath "+ @logout_directory + "/Archive/" + @displayName + "/#{$ProjectName}.xcarchive -exportPath " +  + @logout_directory + "/ipa/" + @displayName + " -exportOptionsPlist " + Dir.pwd + "/ExportOptions.plist -allowProvisioningUpdates"
        pid, stdin , stdout ,stderr = Open4::popen4 command
        puts "开始export进程"
        stdin.close
        stdout.close
        _, status = Process::waitpid2 pid
        if status.success?
            puts  "#{@displayName}打包完成"
            if @needUpload 
              upload_pgy(@logout_directory + "ipa/#{@displayName}/#{$ProjectName}.ipa" , &finish_block)
            else
              finish_block.call(true)
            end
        else
            LogDetector::log_info(stderr.read.strip , @displayName)
            finish_block.call(false)
        end
    end
    def upload_pgy(path , &finish_block)
      # file = File.open(path , 'r')
      #参数详情参考pgy文档
      # params = {:uKey => "" , :_api_key => "" , :file => file}
#       uri = URI("https://qiniu-storage.pgyer.com/apiv1/app/upload")
#
#       req = Net::HTTP::Post.new(uri)
#       req.set_form_data(params)
#
#       res = Net::HTTP.start(uri.hostname, uri.port) do |http|
#         http.request(req)
#       end
#       res.code
      command = "curl -F \"file=@#{path}\" -F \"uKey=#{$PgyUkey}\" -F \"_api_key=#{$PgyApiKey}\" https://qiniu-storage.pgyer.com/apiv1/app/upload"
      pid, stdin , stdout ,stderr = Open4::popen4 command
      puts "开始上传"
      stdin.close
      stdout.close
      _, status = Process::waitpid2 pid
      if status.success?
          puts  "#{@displayName}上传完成"
          finish_block.call(true)
      else
          LogDetector::log_info(stderr.read.strip , @displayName)
          finish_block.call(false)
      end
    end
end

