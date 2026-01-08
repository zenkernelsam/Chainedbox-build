#!/bin/bash
origin="Rock64"
target="Chainedbox"
WORK_DIR=$(pwd)
echo "$WORK_DIR"
mount_point="tmp"

DTB=dtbs/5.15.y-bsp
IDB=loader/idbloader.bin
UBOOT=loader/uboot.img
TRUST=loader/trust.bin

echo -e "01.01 读取镜像"
#设置镜像路径
imgdir=~/chainedbox/
imgfile="$(ls ${imgdir}/*.img)"
echo "找到镜像: $imgfile"

echo -e "01.02 识别镜像名称"
#获取镜像名称
imgname=`basename $imgfile`
echo "镜像名称: $imgname"
echo -e "完成"

echo -e "02.01 挂载镜像"

umount -f tmp
losetup -D
echo "挂载镜像 ... "
losetup -D
losetup -f -P ${imgfile}

BLK_DEV=$(losetup | grep "$imgname" | head -n 1 | gawk '{print $1}')
echo "挂载镜像成功 位置："${BLK_DEV}""

echo "设置卷标"
e2label ${BLK_DEV}p1 ROOTFS
tune2fs ${BLK_DEV}p1 -L ROOTFS

lsblk -l
mkdir -p ${WORK_DIR}/tmp
mount ${BLK_DEV}p1 ${WORK_DIR}/$mount_point
echo "挂载镜像根目录到 ${WORK_DIR}/$mount_point "

echo -e "完成"

echo -e "03.01 添加硬件控制功能(风扇控制)"
echo "复制风扇控制文件"
cp -v ${WORK_DIR}/l1pro/pwm-fan.service $mount_point/etc/systemd/system/
cp -v ${WORK_DIR}/l1pro/pwm-fan.pl $mount_point/usr/bin/ && chmod 700 $mount_point/usr/bin/pwm-fan.pl

echo -e "完成"

echo -e "04.01 启用风扇控制服务"
echo "进入 CHROOT 模式启用服务"

chroot $mount_point <<EOF
su
systemctl enable pwm-fan.service
exit
EOF
sync

echo -e "完成"

cd ${WORK_DIR}

umount -f $mount_point

echo "添加引导项： idb,uboot,trust"

dd if=${IDB} of=${imgfile} seek=64 bs=512 conv=notrunc status=none && echo "idb patched: ${IDB}" || { echo "idb patch failed!"; exit 1; }
dd if=${UBOOT} of=${imgfile} seek=16384 bs=512 conv=notrunc status=none && echo "uboot patched: ${UBOOT}" || { echo "u-boot patch failed!"; exit 1; }
dd if=${TRUST} of=${imgfile} seek=24576 bs=512 conv=notrunc status=none && echo "trust patched: ${TRUST}" || { echo "trust patch failed!"; exit 1; }

imgname_new=`basename $imgfile | sed "s/${origin}/${target}/"`
echo "新文件名: $imgname_new"
mv $imgfile ${imgdir}/${imgname_new}
rm -rf ${tmpdir}

losetup -D
blkid
echo "ok"