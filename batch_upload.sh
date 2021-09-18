#!/bin/bash

# #######################配置开始#######################
# jar包根目录，从本地仓库copy出来的目录，不能是本地仓库。我本地仓库在/Users/xuhj/.m2/repository，所以我直接copy了个/Users/xuhj/.m2/repository2
dir=/Users/xuhj/.m2/repository2
# maven远程仓库的地址
url=http://localhost:8081/repository/maven-releases/
# maven远程仓库的ID
repositoryId=maven-releases
# #######################配置结束#######################


# 去掉最后一个斜线（如果有/的话）
dir_fix=${dir%*/}
# 目录数组，用于之后的路径解析
dir_array=(${dir_fix//// })
# 目录数组的长度，用于之后的路径解析
dir_length=${#dir_array[*]}

# 遍历目录及子目录的文件
function read_dir(){
    for file in `ls $1`
    do
        if [ -d $1"/"$file ]
        then
            read_dir $1"/"$file
        else
            parse_path $1 $1"/"$file 
        fi
    done
}

# 解析文件路径，参数1为文件所在目录，参数2为文件的完整路径
function parse_path(){
    # 因为只是上传jar包，所以判断文件是不是以jar结尾
    if echo "$2" | grep -q -E '\.jar$'
    then
        string=$1
        array=(${string//// })
        length=${#array[*]}
        # /Users/xuhj/.m2/repository2/org/apache/commons/commons-lang3/3.12.0
        # jar包根目录之后，到倒数第三个之间的是包名，做个字符串拼接
        groupId=''
        for ((i=$dir_length; i<$length-2; i++))
        do
            groupId=$groupId"."${array[$i]}
        done

        # 去掉拼接的第一个"."
        groupId=${groupId#*.}
        # 倒数第二个是artifactId
        artifactId=${array[$length-2]}
        # 倒数第一个是version
        version=${array[$length-1]}

        upload_file $groupId $artifactId $version $2
        echo '--------'
    fi
}

function upload_file(){
    echo $1
    echo $2
    echo $3
    echo $4
    groupId=$1
    artifactId=$2
    version=$3
    file=$4

    mvn deploy:deploy-file -e -DgroupId=$groupId -DartifactId=$artifactId -Dversion=$version -Dpackaging=jar -Dfile=$file -Durl=$url -DrepositoryId=$repositoryId
}

read_dir $dir