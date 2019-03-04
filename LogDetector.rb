#!/usr/bin/ruby -w
# -*- coding: UTF-8 -*-
require 'date'
require 'fileutils'

$logout_path = Dir.pwd[0..Dir.pwd.length-"UnionGroups".length-1-1]
module LogDetector
    def LogDetector.configure(path)
        $logout_path = path
    end
    
    def LogDetector.log_info(s , log_name)
        return if not s
        
        puts log_name + "打包失败日志存储于" + LogDetector.url + log_name
        logger = File.open(LogDetector.url + log_name + ".txt", 'a')
        logger.write ("\n")
        logger.write ("*****************日志内容*****************")
        logger.write ("\n")
        logger.write ("*****************日期#{Time.now.inspect}*****************")
        logger.write ("\n")
        logger.write (s)
        logger.close
        
    end
    def LogDetector.Logdelete(log_name)
        begin
            File.delete(LogDetector.url+ log_name)
        rescue =>ex
            raise Exception, ex.message
        end
    end
    #创建文件夹/result/log/
    def LogDetector.url
        begin
            FileUtils.makedirs($logout_path + "/result/log/")
            return $logout_path + "/result/log/"
        rescue =>ex
            raise Exception,"创建文件夹异常！#{ex.message}"
        end
    end
    #获取当前路径
    def LogDetector.file
        begin
            Dir.pwd
        rescue =>ex
            raise Exception,"当前路径异常!#{ex.message}"
        end
    end
end

