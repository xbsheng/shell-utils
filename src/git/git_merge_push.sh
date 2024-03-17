#!/bin/bash

# 用于合并当前分支到目标分支，并推送到远程仓库，然后切换回原来的分支

# ============== 使用：==============
# 执行本地的 shell 脚本
# chmod +x ./git_merge_push.sh # 添加执行权限
# ./git_merge_push.sh -f test # 执行, -f 参数可以跳过commit msg 的输入, test 为要合并的目标分支名称，默认test

# 执行远程的 shell 脚本
# /bin/bash -c "$(curl -fsSL https://xxx.com/xxx/git_merge_push.sh)" -- "$@"
# ===================================

echo "
 
           GGGGGGGGGGGGG     MMMMMMMM               MMMMMMMM     PPPPPPPPPPPPPPPPP
        GGG::::::::::::G     M:::::::M             M:::::::M     P::::::::::::::::P
      GG:::::::::::::::G     M::::::::M           M::::::::M     P::::::PPPPPP:::::P
     G:::::GGGGGGGG::::G     M:::::::::M         M:::::::::M     PP:::::P     P:::::P
    G:::::G       GGGGGG     M::::::::::M       M::::::::::M       P::::P     P:::::P
   G:::::G                   M:::::::::::M     M:::::::::::M       P::::P     P:::::P
   G:::::G                   M:::::::M::::M   M::::M:::::::M       P::::PPPPPP:::::P
   G:::::G    GGGGGGGGGG     M::::::M M::::M M::::M M::::::M       P:::::::::::::PP
   G:::::G    G::::::::G     M::::::M  M::::M::::M  M::::::M       P::::PPPPPPPPP
   G:::::G    GGGGG::::G     M::::::M   M:::::::M   M::::::M       P::::P
   G:::::G        G::::G     M::::::M    M:::::M    M::::::M       P::::P
    G:::::G       G::::G     M::::::M     MMMMM     M::::::M       P::::P
     G:::::GGGGGGGG::::G     M::::::M               M::::::M     PP::::::PP
      GG:::::::::::::::G     M::::::M               M::::::M     P::::::::P
        GGG::::::GGG:::G     M::::::M               M::::::M     P::::::::P
           GGGGGG   GGGG     MMMMMMMM               MMMMMMMM     PPPPPPPPPP

"

# 默认提交信息
default_commit_msg="commit by gmp"

# 文字颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE="\033[34m"
NC='\033[0m' # No Color

# 输出颜色文字
echo_red() {
  echo_color "$RED" "$1"
}

echo_green() {
  echo_color "$GREEN" "$1"
}

echo_yellow() {
  echo_color "$YELLOW" "$1"
}

echo_blue() {
  echo_color "$BLUE" "$1"
}

echo_color() {
  echo -e "$1$2$NC"
}

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo_red "🚫 当前目录不是Git仓库。"
  exit 1
fi

# 函数：显示改动并请求用户确认
function confirm_changes() {
  if [ "$force_flag" = false ]; then
    git status
    read -p "确认提交以上改动？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo_red "🚫 取消提交。"
      exit 1
    fi
  fi
}

# 函数：安全地执行git命令并检查结果
function safe_git() {
  if ! git "$@"; then
    # shellcheck disable=SC2145
    echo_red "❗ Git操作失败: $@"
    exit 1
  fi
}

# 处理参数
force_flag=false # 默认不强制提交, 如果指定了-f参数则强制提交：不需要确认操作和提交信息
while getopts "f" opt; do
  case $opt in
  f)
    force_flag=true
    ;;
  \?)
    echo_red "❗️ 无效选项: -$OPTARG" >&2
    exit 1
    ;;
  esac
done

# 默认合并到的分支是test，但可以通过参数传递其他分支名称
shift $((OPTIND - 1))
target_branch=${1:-test}

# 当前分支名
current_branch=$(git rev-parse --abbrev-ref HEAD)

# 检查目标分支是否和当前分支相同
if [ "$current_branch" = "$target_branch" ]; then
  echo_red "❗️ 目标分支和当前分支相同，无需操作。"
  exit 0
fi

# 检查是否有未提交的代码
if [[ $(git diff --stat) != '' ]] || [[ $(git diff --cached --stat) != '' ]] || [[ $(git status --porcelain) != '' ]]; then
  # 添加所有改动到暂存区
  echo_blue "📦 正在添加改动到暂存区..."
  safe_git add .

  # 显示改动并请求用户确认
  confirm_changes

  # 用户确认后，输入提交信息
  if [ "$force_flag" = false ]; then
    while true; do
      read -rp "📝 请输入提交信息: " commit_msg
      if [ -z "$commit_msg" ]; then
        echo_yellow "🔔 提交信息不能为空，请重新输入。"
      else
        break
      fi
    done
  else
    echo_blue "📝 使用默认提交信息: $default_commit_msg"
    commit_msg=$default_commit_msg
  fi
  safe_git commit -m "$commit_msg"

  # 推送当前分支到远程仓库
  echo_blue "⬆️ 正在推送当前分支到远程仓库..."
  safe_git push origin "$current_branch"
fi

# 切换到目标分支
echo_blue "🔄 正在切换到目标分支 $target_branch ..."
safe_git checkout "$target_branch"

# 拉取最新的目标分支
echo_blue "🔄 正在更新 $target_branch 分支..."
safe_git pull --rebase origin "$target_branch"

# 如果当前分支有提交，则合并当前分支的改动到目标分支
if [[ $(git log "$target_branch".."$current_branch" --oneline) != '' ]]; then
  echo_blue "🔀 正在合并 $current_branch 到 $target_branch ..."
  safe_git merge "$current_branch" --no-edit # 使用默认的合并提交信息
  # 推送合并后的改动
  echo_blue "⬆️ 推送 $target_branch 到远程仓库..."
  safe_git push origin "$target_branch"
else
  echo_yellow "🔍 没有发现 $current_branch 分支的新改动。"
fi

# 切换回原来的分支
echo_blue "🔄 切换回 $current_branch 分支..."
safe_git checkout "$current_branch"

echo_green "✅ 操作完成~~"
