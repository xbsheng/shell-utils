#!/bin/sh

# 重新设置用户名和邮箱
git filter-branch --env-filter '

OLD_EMAIL="xbsheng@126.com" # 旧的邮箱
CORRECT_NAME="xbsheng" # 新的用户名
CORRECT_EMAIL="xxbsheng@gmail.com" # 新的邮箱

if [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_COMMITTER_NAME="$CORRECT_NAME"
    export GIT_COMMITTER_EMAIL="$CORRECT_EMAIL"
fi
if [ "$GIT_AUTHOR_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_AUTHOR_NAME="$CORRECT_NAME"
    export GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
fi
' --tag-name-filter cat -- --branches --tags
