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
find ./rule/Clash/ -type f -exec mv -t ./rule/Clash/ {} +
find ./rule/Clash/ -mindepth 1 -type d -exec rmdir {} +

# 重命名文件
for file in ./rule/Clash/*/*_Classical.yaml; do
  if [ -f "$file" ]; then
    mv "$file" "${file/_Classical.yaml/.yaml}"
  fi
done

# 处理文件部分
for dir in ./rule/Clash/*/; do
  if [ -d "$dir" ]; then
    name=$(basename "$dir")
    mkdir -p "$dir"

    # 归类处理不同类型的规则
    while IFS= read -r line; do
      case "$line" in
      *PROCESS*.*)
        cat "$dir/$name.yaml" | grep -v '#' | grep PROCESS | grep -v '\.exe' | grep -v '/' | grep '\.' | sed 's/  - PROCESS-NAME,//g' >"$dir/package.json"
        ;;
      *PROCESS*)
        cat "$dir/$name.yaml" | grep -v '#' | grep PROCESS | grep -v '/' | grep -v '\.' | sed 's/  - PROCESS-NAME,//g' >"$dir/process.json"
        cat "$dir/$name.yaml" | grep -v '#' | grep PROCESS | grep '\.exe' | sed 's/  - PROCESS-NAME,//g' >>"$dir/process.json"
        ;;
      *DOMAIN-SUFFIX*)
        cat "$dir/$name.yaml" | grep -v '#' | grep '\- DOMAIN-SUFFIX,' | sed 's/  - DOMAIN-SUFFIX,//g' >"$dir/domain.json"
        cat "$dir/$name.yaml" | grep -v '#' | grep '\- DOMAIN-SUFFIX,' | sed 's/  - DOMAIN-SUFFIX,/./g' >"$dir/suffix.json"
        ;;
      *DOMAIN*)
        cat "$dir/$name.yaml" | grep -v '#' | grep '\- DOMAIN,' | sed 's/  - DOMAIN,//g' >"$dir/domain.json"
        ;;
      *DOMAIN-KEYWORD*)
        cat "$dir/$name.yaml" | grep -v '#' | grep '\- DOMAIN-KEYWORD,' | sed 's/  - DOMAIN-KEYWORD,//g' >"$dir/keyword.json"
        ;;
      esac
    done <"$dir/$name.yaml"

    # 将处理后的规则转换成 JSON 格式
    for json_file in "$dir"/*.json; do
      if [ -f "$json_file" ]; then
        sed -i '1s/^/{\n  "version": 1,\n  "rules": [\n    {\n/g' "$json_file"
        sed -i '$ s/,$/\n    }\n  ]\n}/g' "$json_file"
      fi
    done

    # 合并文件
    json_files=("$dir"/*.json)
    if [ ${#json_files[@]} -gt 1 ]; then
      cat "${json_files[@]}" >"$dir/$name.json"
      rm "${json_files[@]}"
    fi

    # 使用 sing-box 命令对生成的 JSON 文件进行编译，生成 srs 规则文件
    ./sing-box rule-set compile "$dir/$name.json" -o "$dir/$name.srs"
  fi
done
