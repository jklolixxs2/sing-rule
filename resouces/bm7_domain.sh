#!/bin/bash

# 拉取文件部分
if [ ! -d rule ]; then
  git init                                                                  # 初始化一个 Git 仓库
  git remote add origin https://github.com/blackmatrix7/ios_rule_script.git # 添加远程仓库地址
  git config core.sparsecheckout true                                       # 配置 Git 使用 sparse checkout 模式
  echo "rule/Clash" >>.git/info/sparse-checkout                             # 将指定的文件/目录写入 .git/info/sparse-checkout，以便只拉取这部分文件
  git pull --depth 1 origin master                                          # 从远程仓库拉取最新的文件，--depth 1 参数表示只拉取最近一次提交的文件历史
  rm -rf .git                                                               # 删除 .git 目录，这样就不会把整个仓库都保留下来，只保留所需的文件
fi

# 移动文件/目录到同一文件夹
list=($(find ./rule/Clash/ | awk -F '/' '{print $5}' | sed '/^$/d' | grep -v '\.' | sort -u)) # 找到 ./rule/Clash/ 目录下所有文件的路径，并提取出文件名
for ((i = 0; i < ${#list[@]}; i++)); do
  path=$(find ./rule/Clash/ -name ${list[i]}) # 获取当前文件的路径
  mv $path ./rule/Clash/                      # 将文件移动到 ./rule/Clash/ 目录下
done

# 清理目录结构
list=($(ls ./rule/Clash/)) # 获取 ./rule/Clash/ 目录下的所有一级子目录
for ((i = 0; i < ${#list[@]}; i++)); do
  if [ -z "$(ls ./rule/Clash/${list[i]} | grep '.yaml')" ]; then # 如果某个子目录下没有以 .yaml 结尾的文件
    directory=($(ls ./rule/Clash/${list[i]}))                    # 获取当前子目录下的所有文件名
    for ((x = 0; x < ${#directory[@]}; x++)); do
      mv ./rule/Clash/${list[i]}/${directory[x]} ./rule/Clash/${directory[x]} # 将子目录下的所有文件移动到 ./rule/Clash/ 目录下
    done
    rm -r ./rule/Clash/${list[i]} # 删除原来的子目录
  fi
done

# 重命名文件
list=($(ls ./rule/Clash/)) # 获取 ./rule/Clash/ 目录下的所有文件
for ((i = 0; i < ${#list[@]}; i++)); do
  if [ -f "./rule/Clash/${list[i]}/${list[i]}_Classical.yaml" ]; then                            # 如果某个文件名以 "_Classical.yaml" 结尾
    mv ./rule/Clash/${list[i]}/${list[i]}_Classical.yaml ./rule/Clash/${list[i]}/${list[i]}.yaml # 将文件重命名为去掉 "_Classical" 部分的文件名
  fi
done

# 处理文件部分
list=($(ls ./rule/Clash/))              # 获取 ./rule/Clash/ 目录下的所有文件/目录列表
for ((i = 0; i < ${#list[@]}; i++)); do # 遍历列表中的每个文件/目录
  mkdir -p ${list[i]}                   # 创建一个同名目录，用于存放处理后的文件

  # 归类处理不同类型的规则

  # 处理 Android 应用程序包规则
  if [ -n "$(cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep -v '#' | grep PROCESS | grep -v '\.exe' | grep -v '/' | grep '\.')" ]; then
    cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep -v '#' | grep PROCESS | grep -v '\.exe' | grep -v '/' | grep '\.' | sed 's/  - PROCESS-NAME,//g' >${list[i]}/package.json
  fi

  # 处理进程名规则
  if [ -n "$(cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep -v '#' | grep PROCESS | grep -v '/' | grep -v '\.')" ]; then
    cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep -v '#' | grep -v '#' | grep PROCESS | grep -v '/' | grep -v '\.' | sed 's/  - PROCESS-NAME,//g' >${list[i]}/process.json
  fi
  if [ -n "$(cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep -v '#' | grep PROCESS | grep '\.exe')" ]; then
    cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep -v '#' | grep -v '#' | grep PROCESS | grep '\.exe' | sed 's/  - PROCESS-NAME,//g' >>${list[i]}/process.json
  fi

  # 处理域名规则
  if [ -n "$(cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep '\- DOMAIN-SUFFIX,')" ]; then
    cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep -v '#' | grep '\- DOMAIN-SUFFIX,' | sed 's/  - DOMAIN-SUFFIX,//g' >${list[i]}/domain.json
    cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep -v '#' | grep '\- DOMAIN-SUFFIX,' | sed 's/  - DOMAIN-SUFFIX,/./g' >${list[i]}/suffix.json
  fi
  if [ -n "$(cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep '\- DOMAIN,')" ]; then
    cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep -v '#' | grep '\- DOMAIN,' | sed 's/  - DOMAIN,//g' >>${list[i]}/domain.json
  fi
  if [ -n "$(cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep '\- DOMAIN-KEYWORD,')" ]; then
    cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep -v '#' | grep '\- DOMAIN-KEYWORD,' | sed 's/  - DOMAIN-KEYWORD,//g' >${list[i]}/keyword.json
  fi

  # 将处理后的规则转换成 JSON 格式

  # 处理 Android 应用程序包规则
  if [ -f "${list[i]}/package.json" ]; then
    sed -i 's/^/        "/g' ${list[i]}/package.json
    sed -i 's/$/",/g' ${list[i]}/package.json
    sed -i '1s/^/      "package_name": [\n/g' ${list[i]}/package.json
    sed -i '$ s/,$/\n      ],/g' ${list[i]}/package.json
  fi

  # 处理进程名规则
  if [ -f "${list[i]}/process.json" ]; then
    sed -i 's/^/        "/g' ${list[i]}/process.json
    sed -i 's/$/",/g' ${list[i]}/process.json
    sed -i '1s/^/      "process_name": [\n/g' ${list[i]}/process.json
    sed -i '$ s/,$/\n      ],/g' ${list[i]}/process.json
  fi

  # 处理域名规则
  if [ -f "${list[i]}/domain.json" ]; then
    sed -i 's/^/        "/g' ${list[i]}/domain.json
    sed -i 's/$/",/g' ${list[i]}/domain.json
    sed -i '1s/^/      "domain": [\n/g' ${list[i]}/domain.json
    sed -i '$ s/,$/\n      ],/g' ${list[i]}/domain.json
  fi
  if [ -f "${list[i]}/suffix.json" ]; then
    sed -i 's/^/        "/g' ${list[i]}/suffix.json
    sed -i 's/$/",/g' ${list[i]}/suffix.json
    sed -i '1s/^/      "domain_suffix": [\n/g' ${list[i]}/suffix.json
    sed -i '$ s/,$/\n      ],/g' ${list[i]}/suffix.json
  fi
  if [ -f "${list[i]}/keyword.json" ]; then
    sed -i 's/^/        "/g' ${list[i]}/keyword.json
    sed -i 's/$/",/g' ${list[i]}/keyword.json
    sed -i '1s/^/      "domain_keyword": [\n/g' ${list[i]}/keyword.json
    sed -i '$ s/,$/\n      ],/g' ${list[i]}/keyword.json
  fi

  # 合并文件

  # 如果同时存在 package.json 和 process.json，则合并成一个 json 文件
  if [ -f "${list[i]}/package.json" -a -f "${list[i]}/process.json" ]; then
    mv ${list[i]}/package.json ${list[i]}.json
    sed -i '$ s/,$/\n    },\n    {/g' ${list[i]}.json
    cat ${list[i]}/process.json >>${list[i]}.json
    rm ${list[i]}/process.json
    # 如果只存在 package.json，则直接重命名
  elif [ -f "${list[i]}/package.json" ]; then
    mv ${list[i]}/package.json ${list[i]}.json
  # 如果只存在 process.json，则直接重命名
  elif [ -f "${list[i]}/process.json" ]; then
    mv ${list[i]}/process.json ${list[i]}.json
  fi

  # 检查目录是否为空
  if [ "$(ls ${list[i]})" = "" ]; then
    sed -i '1s/^/{\n  "version": 1,\n  "rules": [\n    {\n/g' ${list[i]}.json
  # 如果存在已有的 .json 文件，则合并规则到该文件中
  elif [ -f "${list[i]}.json" ]; then
    sed -i '1s/^/{\n  "version": 1,\n  "rules": [\n    {\n/g' ${list[i]}.json
    sed -i '$ s/,$/\n    },\n    {/g' ${list[i]}.json
    cat ${list[i]}/* >>${list[i]}.json
  # 如果不存在 .json 文件，则创建新的文件并合并规则
  else
    cat ${list[i]}/* >>${list[i]}.json
    sed -i '1s/^/{\n  "version": 1,\n  "rules": [\n    {\n/g' ${list[i]}.json
  fi

  # 完成 JSON 文件格式的封装
  sed -i '$ s/,$/\n    }\n  ]\n}/g' ${list[i]}.json

  # 删除临时目录
  rm -r ${list[i]}

  # 使用 sing-box 命令对生成的 JSON 文件进行编译，生成 srs 规则文件
  ./sing-box rule-set compile ${list[i]}.json -o ${list[i]}.srs
done
