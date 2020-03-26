## 分割文件

将rhv-4.3-2020-03-24.tgz文件分割成若干文件，每个文件大小为2G
```
split -b 2G rhv-4.3-2020-03-24.tgz rhv-4.3-2020-03-24.tgz

ls -lh rhv-4.3-2020-03-24.tgz*
...
-rw-r--r--. 1 root root 22385768944 Mar 25 13:45 rhv-4.3-2020-03-24.tgz
-rw-r--r--. 1 root root  2147483648 Mar 26 22:25 rhv-4.3-2020-03-24.tgzaa
-rw-r--r--. 1 root root  2147483648 Mar 26 22:25 rhv-4.3-2020-03-24.tgzab
-rw-r--r--. 1 root root  2147483648 Mar 26 22:26 rhv-4.3-2020-03-24.tgzac
-rw-r--r--. 1 root root  2147483648 Mar 26 22:26 rhv-4.3-2020-03-24.tgzad
-rw-r--r--. 1 root root  2147483648 Mar 26 22:26 rhv-4.3-2020-03-24.tgzae
-rw-r--r--. 1 root root  2147483648 Mar 26 22:27 rhv-4.3-2020-03-24.tgzaf
-rw-r--r--. 1 root root  2147483648 Mar 26 22:27 rhv-4.3-2020-03-24.tgzag
-rw-r--r--. 1 root root  2147483648 Mar 26 22:27 rhv-4.3-2020-03-24.tgzah
-rw-r--r--. 1 root root  2147483648 Mar 26 22:27 rhv-4.3-2020-03-24.tgzai
-rw-r--r--. 1 root root  2147483648 Mar 26 22:28 rhv-4.3-2020-03-24.tgzaj
-rw-r--r--. 1 root root   910932464 Mar 26 22:28 rhv-4.3-2020-03-24.tgzak
```

## 合并文件

```
cat rhv-4.3-2020-03-24.tgza* > rhv-4.3-2020-03-24.tgz
```

## 生成文件checksum
```
sha256sum -b rhv-4.3-2020-03-24.tgza* > SHA256SUMS
```

## 检查checksum
```
sha256sum -c SHA256SUMS
```