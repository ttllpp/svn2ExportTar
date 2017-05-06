#!/bin/bash
#这里填svn地址 this is svn path
SVN_URL="svn://xxx.xxx.xxx.xxx"
 
if [ $# -eq 0 ] ; then
  echo "You must useage like $0 old_version1(不包括) new_version(包括)"
  exit 1
fi
 
if [ $1 -gt $2 ] ; then
  echo "You must useage like $0 old_version1(不包括) new_version(包括)"
  exit 1
fi
 
OLD_VERSION=$1
NEW_VERSION=$2
SVN_USER=$3
SVN_PASSWORD=$4
 
#导出的目标路径 Export the target path
WORK_PATH="/data/"
# rm -rf ${WORK_PATH}
 
echo "开始分析版本差异..."

DIFF_URL="svn diff -r ${OLD_VERSION}:${NEW_VERSION} --summarize --username ${SVN_USER} --password ${SVN_PASSWORD} ${SVN_URL}"
echo ${DIFF_URL}
 
if test ! -e "${WORK_PATH}"; then
  mkdir -p ${WORK_PATH}
fi

 
DIFF_NUM=`${DIFF_URL} |wc -l`
if [ ${DIFF_NUM} -ne 0 ]; then
  echo "差异文件共${DIFF_NUM}个,准备导出.">> "${WORK_PATH}../svn_logs.txt"
  DIFF_LIST=`${DIFF_URL}`
  
  NUM=0
  SKIP=0
    for FIELD in ${DIFF_LIST} ; do
        #长度小于3（A、M、D、AM即增加且修改）即是更新标识，否则为url
        if [ ${#FIELD} -lt 3 ]; then
            let NUM+=1
            SKIP=0
            if [ "${FIELD}" == "D" ]; then
            #下一个应该跳过
            SKIP=1
            fi
            continue
        fi

        #若为删除文件则不必导出
        if [ ${SKIP} -eq 1 ]; then
            echo ${NUM}.'是删除操作,跳过:'${FIELD}>> "${WORK_PATH}../svn_logs.txt"
            continue
        fi

        #替换得到相对路径
        DIFF_FILE=${FIELD//${SVN_URL}/}
        #过滤
        if [[ "$DIFF_FILE" =~ "jpg" ]];then 
            echo ${NUM}.'过滤:'${FIELD}>> "${WORK_PATH}../svn_logs.txt"
            continue
        fi
        echo ${NUM}.' '${DIFF_FILE}>> "${WORK_PATH}../svn_logs.txt"

        FILE_NAME=`basename ${DIFF_FILE}`
        FOLDER_NAME=`dirname ${DIFF_FILE}`
        FOLDER_PATH="${WORK_PATH}${FOLDER_NAME}"

        if test ! -e "${FOLDER_PATH}"; then
            mkdir -p ${FOLDER_PATH}
        fi

        CMD="svn export -r ${NEW_VERSION} '${SVN_URL}${DIFF_FILE}'  '${FOLDER_PATH}/${FILE_NAME}' --force"
        echo ${CMD}|sh
    done
    echo -e "版本号:"${OLD_VERSION}"->"${NEW_VERSION} "\t时间:" $(date +"%Y-%m-%d %H:%M:%S")>> "${WORK_PATH}../svn_logs.txt"
    echo -e "完成" >> "${WORK_PATH}../svn_logs.txt"
    chmod -R 774 ${WORK_PATH}
    TAR="tar -czvf ${WORK_PATH}../pub.tar.gz -C ${WORK_PATH} ./"
    echo ${TAR}|sh
   
else
    echo "版本间没有差异">> "${WORK_PATH}../svn_logs.txt"
fi