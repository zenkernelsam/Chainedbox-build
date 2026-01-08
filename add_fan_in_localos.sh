#!/bin/bash
set -e

echo "==========================================="
echo "   PWM风扇控制系统安装脚本 - Chainedbox"
echo "==========================================="

# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
   echo "错误: 此脚本需要root权限运行！" 
   echo "请使用 sudo $0 命令重新运行"
   exit 1
fi

# 定义文件位置
SCRIPT_DIR=$(pwd)
FAN_SCRIPT="l1pro/pwm-fan.pl"
SERVICE_FILE="l1pro/pwm-fan.service"

# 检查必需的文件是否存在
if [[ ! -f "$FAN_SCRIPT" ]]; then
    echo "错误: 风扇控制脚本 $FAN_SCRIPT 不存在!"
    echo "请确保脚本文件在正确位置，或修改脚本中的路径"
    exit 1
fi

if [[ ! -f "$SERVICE_FILE" ]]; then
    echo "错误: 服务文件 $SERVICE_FILE 不存在!"
    echo "请确保服务文件在正确位置，或修改脚本中的路径"
    exit 1
fi

echo -e "\n1. 安装必要的依赖..."
# 安装Perl和必要的模块
apt update
apt install -y perl libdevice-serialport-perl

echo -e "\n2. 复制风扇控制脚本..."
mkdir -p /usr/bin
cp -v "$FAN_SCRIPT" /usr/bin/pwm-fan.pl
chmod 700 /usr/bin/pwm-fan.pl

echo -e "\n3. 复制并配置systemd服务..."
mkdir -p /etc/systemd/system
cp -v "$SERVICE_FILE" /etc/systemd/system/pwm-fan.service

echo -e "\n4. 启用并启动风扇控制服务..."
systemctl daemon-reload
systemctl enable pwm-fan.service
systemctl start pwm-fan.service

echo -e "\n5. 检查服务状态..."
sleep 2  # 给服务一点启动时间
systemctl status pwm-fan.service --no-pager

echo -e "\n6. 验证风扇控制脚本是否正常运行..."
if /usr/bin/pwm-fan.pl status; then
    echo -e "\n✓ PWM风扇控制系统安装成功！"
    echo "服务已启用并正在运行。"
    echo "系统重启后风扇控制将自动启动。"
else
    echo -e "\n⚠️ 风扇控制脚本执行成功，但可能需要进一步配置。"
    echo "服务已安装并启动，请检查日志了解详情:"
    echo "journalctl -u pwm-fan.service -b --no-pager"
fi

echo -e "\n==========================================="
echo "安装完成！如需调试，可使用以下命令查看服务日志:"
echo "journalctl -u pwm-fan.service -f"
echo "==========================================="