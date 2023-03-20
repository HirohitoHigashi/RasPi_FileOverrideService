#!/bin/bash
#
# Confirm read all sectors.
#
#  This software is distributed under BSD license.
#
#  Copyright (c) 2023 Shimane IT Open-Innovation Center All right reserved.
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#
#  1. Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#
#  2. Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#
#  3. Neither the name of the copyright holder nor the names of its
#     contributors may be used to endorse or promote products derived from
#     this software without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


WORK_MODE=used_sector_mode	# options: file_mode all_sector_mode used_sector_mode

DEV_NODE="/dev/mmcblk0"
PROC_NAME=confirm_sd
PID_FILE=/tmp/${PROC_NAME}.pid
DD_OPT="bs=10k conv=noerror status=none iflag=direct"


#
# 簡易二重起動阻止
#
prevent_double_activation() {
    if [ -e $PID_FILE ]; then
	if ps `cat $PID_FILE` | tail -n +2 | grep -q $0; then
	    echo "${PROC_NAME}: still work."
	    exit 1
	fi
    fi
    echo $$ > $PID_FILE
    exitcode=$?
    if [ $exitcode -ne 0 ]; then
	exit $exitcode
    fi
}

#
# ファイルモード　メイン
#
work_file_mode() {
    trap 'terminate' HUP INT QUIT TERM
    read_files &
    child_pid=$!
    wait $child_pid
}

# 終了シグナルハンドラ
terminate() {
    kill $child_pid
}

# ファイル読み捨てサブプロセス
read_files() {
    exec nice -n 10 \
	find / -xdev -type f \
	-exec dd if='{}' of=/dev/null $DD_OPT \; \
	-exec sleep 0.2 \;
}


#
# 全セクタモード　メイン
#
work_all_sector_mode() {
    trap ':' HUP INT QUIT TERM
    dd if=${DEV_NODE} ${DD_OPT} | slowly
}

#
# 使用セクタモード　メイン
#
work_used_sector_mode() {
    trap ':' HUP INT QUIT TERM
    (
	# パーティションテーブル
	dd if=${DEV_NODE} ${DD_OPT} count=1 | slowly

	# fat32 ブートパーティション
	dd if=${DEV_NODE}p1 ${DD_OPT} | slowly

	# ext2 ルートパーティション
	e2image -r -a -f ${DEV_NODE}p2 - 2>/dev/null | slowly
    )
}

# 速度調整
slowly() {
    while read -s -N 10240; do
	sleep 0.05
    done
}

#
# main
#
prevent_double_activation
work_${WORK_MODE}
rm -f ${PID_FILE}
