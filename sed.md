# sed
1. 函数所有不是/bin/bash的行
   把full name替换成first name
    ```bash
    john:x:1001:1001:John Doe:/home/john:/bin/bash
    mary:x:1002:1002:Mary Smith:/home/mary:/bin/bash
    daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
    guest:x:1003:1003:Guest User:/home/guest:/bin/sh  
    ```
    ```bash
    sed '/:\/bin\/bash$/!d'                                                           # 第一问
    sed -n 's/^\([^:]*:[^:]*:[^:]*:[^:]*:\)\([^ ]*\) [^:]*:/\1\2:/p' sed_example.txt  # 第二问
    # 思路: 匹配前面冒号分隔的4个字段, 后向引用
    # 匹配第5个字段中的first name, 后向引用, last name不要  
    ```
2. 只保留登录失败（status:fail）的记录
   将 user:xxx 替换为 account=xxx
   去掉 IP 地址字段（ip:...）
   ```bash
   2025-06-10 09:12:33 | user:alice | ip:192.168.1.10 | status:success
   2025-06-10 09:14:55 | user:bob | ip:192.168.1.22 | status:fail
   2025-06-10 09:16:01 | user:carol | ip:192.168.1.33 | status:success
   2025-06-10 09:17:45 | user:dave | ip:192.168.1.44 | status:fail
   ```
   ```bash
   sed是基本正则, + {3} 是扩展正则,  ()要转义 \( \)
   sed -n '/fail/s/ *| *ip:[0-9.]* *|/ |/p' sed_example.txt | sed -n 's/user:\([a-z]*\)/account=\1/p'
   # *| *ip:[^|]* *| 
   #                  用来匹配: 空格 后面可能有多个空格 | 空格 后面可能多个空格 ip: 匹配192.168.1.10 空格 后面可能有多个空格 |
   # user:\([a-z]*\)/account=\1
   #                  用来匹配: user:(人名) 后面要\1 前向引用
   ```
3. (1) 只保留POST请求; (2) 把POST替换成METHOD=POST; (3) 只保留IP，请求方法，路径
    ```bash
    192.168.1.10 - - [10/Jun/2025:10:12:34 +0800] "GET /index.html HTTP/1.1" 200 5123
    192.168.1.22 - - [10/Jun/2025:10:13:01 +0800] "POST /login HTTP/1.1" 403 1024
    192.168.1.33 - - [10/Jun/2025:10:13:27 +0800] "GET /about.html HTTP/1.1" 200 2560
    192.168.1.44 - - [10/Jun/2025:10:14:02 +0800] "POST /admin HTTP/1.1" 500 128
    ```
    ```bash
    (1) 只保留POST，且把POST替换成METHOD=POST
    sed -n '/POST/s/"\(POST\)/METHOD=\1/p' sed_example.txt
    (2) 仅保留ip, METHOD=POST, 路径

    整体的解决方法： sed -n '/POST/s/^\([^ ]*\).*"POST \([^ ]*\).*$/\1 METHOD=POST \2/p' sed_example.txt
    ^\([^ ]*\) 匹配ip地址    192.168.1.44
    .*"POST    匹配的是       - - [10/Jun/2025:10:14:02 +0800] "POST
    \([^ ]*\)  匹配的是路径   /admin 
    .*$        匹配到末尾      HTTP/1.1" 500 128
    ```
4. 替换以下每行的文本
   ```bash
   [INFO] user:alice ip:192.168.1.10 action:login
   [WARN] user:bob ip:10.0.0.5 action:failed
   [INFO] user:charlie ip:172.16.0.3 action:login
   [ERROR] user:david ip:192.168.2.2 action:error
   ```
   替换成: ```user=<用户名> ip=<IP地址>```
   并且action字段是failed或者error, 在行尾加上[!warning]

   ```bash
            sed -n '
                /action:\(failed\|error\)/ {
                s/.*user:\([a-zA-Z0-9_]*\) ip:\([0-9.]*\).*/user=\1 ip=\2 [!warning]/p
                b
                }
                s/.*user:\([a-zA-Z0-9_]*\) ip:\([0-9.]*\).*/user=\1 ip=\2/p
                ' sed_example.txt

    # action:\(failed\|error\)    匹配action:failed或error
    # .*                          一直匹配到 [INFO] 
    # user:                       直接匹配user:
    # \([a-zA-Z0-9_]*\)           匹配用户名, sed不能使用\w和+
    # 空格ip:                     匹配 ip:
    # \([0-9.]*\)                 匹配192.168.1.10
    # 空格                        匹配空格
    # action:                     匹配action:
    # 
    # 
    # 执行流程: sed读取一行判断是否匹配failed或者error, 如果匹配执行{ }里面的语句, 最后break
                如果不匹配直接默认的s/.../.../p
   ```
   5. 文本如下
      (1) 每行提取用户名和shell
      (2) 如果shell是nologin, 后面加上[disabled]
   ```bash
   root:x:0:0:Superuser:/root:/bin/bash
   daemon:x:1:1:Daemon User:/usr/sbin:/usr/sbin/nologin
   alice:x:1000:1000:Alice Smith:/home/alice:/bin/bash
   bob:x:1001:1001:Bob Jones:/home/bob:/bin/zsh
   nobody:x:65534:65534:Nobody:/nonexistent:/usr/sbin/nologin
   ```

   ```bash
   第一个需求: sed -n 's/^\([^:]*\):[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:\(.*$\)/user=\1 shell=\2/p' sedExample.txt
   需要注意: 最后的如果要想匹配 /, 一定要转义, 因为 / 会被理解为分隔符
   第二个需求: 
   sed -n '
        /:nologin$/ {
        s/^\([^:]*\):[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:\([^:]*\)$/user=\1 shell=\2 [disabled]/p
        b
        }
        s/^\([^:]*\):[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:\([^:]*\)$/user=\1 shell=\2/p
        ' sedExample.txt
    注意: 多行写法, 不能用\换行, 整个脚本包括在单引号内
    多行书写不方便, 可以写在一个脚本内, sed调用脚本
   ```

