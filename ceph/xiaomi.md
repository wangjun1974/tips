### s3fs 简单测试

```
# 安装
dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum install s3fs-fuse

# 查看用户信息
radosgw-admin user info --uid test_user
...
    "keys": [
        {
            "user": "test_user",
            "access_key": "JKT0TCBHNQPAZ8BGH9SP",
            "secret_key": "aBm3DNOwicyhgy9EBNTWLISQBvZeJgNA5ArUTp1K"
        }
    ],
...

# 配置 s3fs 标准 AWS credentials file 
cat ~/.aws/credentials 
[default]
aws_access_key_id = JKT0TCBHNQPAZ8BGH9SP
aws_secret_access_key = aBm3DNOwicyhgy9EBNTWLISQBvZeJgNA5ArUTp1K

ACCESS_KEY_ID="JKT0TCBHNQPAZ8BGH9SP"
SECRET_ACCESS_KEY="aBm3DNOwicyhgy9EBNTWLISQBvZeJgNA5ArUTp1K"

echo ${ACCESS_KEY_ID}:${SECRET_ACCESS_KEY} > ${HOME}/.passwd-s3fs
chmod 600 ${HOME}/.passwd-s3fs

# 查看 ceph rgw bucket
aws --endpoint=https://jwang-ceph04.example.com:443 s3 ls
2021-12-06 13:50:00 test

# 挂载 ceph s3 文件系统
mkdir -p /mnt/s3
s3fs test /mnt/s3 -o passwd_file=${HOME}/.passwd-s3fs -o url=https://jwang-ceph04.example.com -o use_path_request_style

# 查看文件系统内容
# ls /mnt/s3 -l 
total 44581
-rw-r-----. 1 root root        8 Dec  6 14:41 aaa
-rw-r-----. 1 root root        7 Dec 10 11:14 bbb
-rw-r-----. 1 root root        0 Dec 10 11:14 ccc
-rw-r-----. 1 root root  3083264 Dec 10 11:14 putty-64bit-0.76-installer.msi
-rw-r-----. 1 root root 42564608 Dec  6 14:04 rclone.exe

# 创建，删除，修改，复制文件，设置权限
# 创建文件
touch /mnt/s3/ddd
ls -l /mnt/s3
total 44581
-rw-r-----. 1 root root        8 Dec  6 14:41 aaa
-rw-r-----. 1 root root        7 Dec 10 11:14 bbb
-rw-r-----. 1 root root        0 Dec 10 11:14 ccc
-rw-r--r--. 1 root root        0 Feb 24 09:33 ddd
-rw-r-----. 1 root root  3083264 Dec 10 11:14 putty-64bit-0.76-installer.msi
-rw-r-----. 1 root root 42564608 Dec  6 14:04 rclone.exe

# 修改文件
echo '123' > /mnt/s3/ddd
ls -l /mnt/s3/ddd
-rw-r--r--. 1 root root 4 Feb 24 09:34 /mnt/s3/ddd
cat /mnt/s3/ddd 
123

# 复制文件
cp /mnt/s3/ddd /mnt/s3/eee
ls -l /mnt/s3/ddd /mnt/s3/eee
-rw-r--r--. 1 root root 4 Feb 24 09:34 /mnt/s3/ddd
-rw-r--r--. 1 root root 4 Feb 24 09:34 /mnt/s3/eee

# 修改文件属性
chmod 0400 /mnt/s3/ddd
ls -l /mnt/s3/ddd 
-r--------. 1 root root 4 Feb 24 09:34 /mnt/s3/ddd

# 删除文件
rm /mnt/s3/ddd
rm: remove regular file '/mnt/s3/ddd'? y
ls -l /mnt/s3
total 44581
-rw-r-----. 1 root root        8 Dec  6 14:41 aaa
-rw-r-----. 1 root root        7 Dec 10 11:14 bbb
-rw-r-----. 1 root root        0 Dec 10 11:14 ccc
-rw-r--r--. 1 root root        4 Feb 24 09:34 eee
-rw-r-----. 1 root root  3083264 Dec 10 11:14 putty-64bit-0.76-installer.msi
-rw-r-----. 1 root root 42564608 Dec  6 14:04 rclone.exe

# 创建目录
mkdir -p /mnt/s3/test1  
ls -l /mnt/s3
total 44582
-rw-r-----. 1 root root        8 Dec  6 14:41 aaa
-rw-r-----. 1 root root        7 Dec 10 11:14 bbb
-rw-r-----. 1 root root        0 Dec 10 11:14 ccc
-rw-r--r--. 1 root root        4 Feb 24 09:34 eee
-rw-r-----. 1 root root  3083264 Dec 10 11:14 putty-64bit-0.76-installer.msi
-rw-r-----. 1 root root 42564608 Dec  6 14:04 rclone.exe
drwxr-xr-x. 1 root root        0 Feb 24 09:36 test1

# 复制文件到目录
# 可复制文件到目录
cp /mnt/s3/rclone.exe /mnt/s3/test1
ls -l /mnt/s3/test1 
total 41568
-rw-r-----. 1 root root 42564608 Feb 24 09:37 rclone.exe

# 修改目录权限
# 权限已修改
chmod 0700 /mnt/s3/test1 
ls -l /mnt/s3
total 44582
-rw-r-----. 1 root root        8 Dec  6 14:41 aaa
-rw-r-----. 1 root root        7 Dec 10 11:14 bbb
-rw-r-----. 1 root root        0 Dec 10 11:14 ccc
-rw-r--r--. 1 root root        4 Feb 24 09:34 eee
-rw-r-----. 1 root root  3083264 Dec 10 11:14 putty-64bit-0.76-installer.msi
-rw-r-----. 1 root root 42564608 Dec  6 14:04 rclone.exe
drwx------. 1 root root        0 Feb 24 09:36 test1

# 复制目录
# 新复制出来的目录是 test2
cp -a /mnt/s3/test1 /mnt/s3/test2 
ls -l /mnt/s3
total 44582
-rw-r-----. 1 root root        8 Dec  6 14:41 aaa
-rw-r-----. 1 root root        7 Dec 10 11:14 bbb
-rw-r-----. 1 root root        0 Dec 10 11:14 ccc
-rw-r--r--. 1 root root        4 Feb 24 09:34 eee
-rw-r-----. 1 root root  3083264 Dec 10 11:14 putty-64bit-0.76-installer.msi
-rw-r-----. 1 root root 42564608 Dec  6 14:04 rclone.exe
drwx------. 1 root root        0 Feb 24 09:36 test1
drwx------. 1 root root        0 Feb 24 09:36 test2

ls -l /mnt/s3/test2
total 41568
-rw-r-----. 1 root root 42564608 Feb 24 09:37 rclone.exe

# 删除目录
# 目录已删除
rm -rf /mnt/s3/test2
ls -l /mnt/s3 
total 44582
-rw-r-----. 1 root root        8 Dec  6 14:41 aaa
-rw-r-----. 1 root root        7 Dec 10 11:14 bbb
-rw-r-----. 1 root root        0 Dec 10 11:14 ccc
-rw-r--r--. 1 root root        4 Feb 24 09:34 eee
-rw-r-----. 1 root root  3083264 Dec 10 11:14 putty-64bit-0.76-installer.msi
-rw-r-----. 1 root root 42564608 Dec  6 14:04 rclone.exe
drwx------. 1 root root        0 Feb 24 09:36 test1


```