require 'optparse'
require File.dirname(__FILE__) + '/build_object'
require File.dirname(__FILE__) + '/LogDetector'

$project_path = Dir.pwd
$default_export_path = File::dirname($project_path)
$default_logout_path = File::dirname($project_path)

options = {}
option_parser = OptionParser.new do |opts|
  # 这里是这个命令行工具的帮助信息
  opts.banner = 'this is help tool line'
  
  # Option 打包多个 非必须
  options[:isgroup] = false
  opts.on('-g', '--group', '是否打包多个 默认不是') do
      options[:isgroup] = true
  end
  
  # Option 输入配置文件夹路径 必须
  opts.on('-d VALUE', '--directory Value', '配置文件夹路径 必须') do |value|
    options[:directory] = value
  end
  
  # Option 输出ipa路径 可选
  opts.on('-o VALUE', '--output Value', '输出ipa文件路径 可选') do |value|
    options[:export_path] = value
  end

  # Option 输出日志路径
  opts.on('-l VALUE', '--log Value', '输出日志路径 可选') do |value|
      options[:log_path] = value
  end


end.parse!

def analyze_and_build(directory , isgroup = false , export_path , log_path )
    raise "目录未指定" if not directory
    LogDetector::configure(log_path)
    if isgroup
        object_array = Array.new
        if File.directory?(directory)
            Dir.foreach(directory) do |subpath|
                newpath = directory + '/' + subpath
                filetype = File.ftype(newpath)
                if File.directory?(newpath)
                    configure_info_path = newpath + '/configure_info.plist'
                    unless File.exist?(configure_info_path)
                        puts "#{subpath}目录配置文件configure_info不存在"
                    else
                        object = BuildObject.new(newpath , export_path)
                        object_array.push(object)
                    end
                end
            end
        end
        i = 0 ;
        while i < object_array.size
            object = object_array[i];
            object.prepare
            object.start_xcodebuild { |code|
                i += 1
                if code == true
                end
            }
        end
    else
        object = BuildObject.new(directory , export_path)
        object.prepare
        object.start_xcodebuild { |code|
            
        }
    end
end

if options[:export_path] != nil && options[:log_path] != nil

    analyze_and_build(options[:directory] , options[:isgroup] , options[:export_path] , options[:log_path])
    
elsif options[:export_path] != nil && options[:log_path] == nil

    analyze_and_build(options[:directory] , options[:isgroup] , options[:export_path] , $default_logout_path)

elsif options[:export_path] == nil && options[:log_path] != nil

    analyze_and_build(options[:directory] , options[:isgroup] , $default_export_path , options[:log_path])
else
    analyze_and_build(options[:directory] , options[:isgroup] , $default_export_path , $default_logout_path)
end


