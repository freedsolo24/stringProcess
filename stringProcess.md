# regex
1. 匹配电邮 john.doe@example.com  alice\_bob123@domain.org  a-b.c@website.net
    ```bash
    ^[a-z0-9]+([.-_]?[a-z0-9]+)*@[a-z]+\.(com|net|org)$
    // [.-_]?                 保证这3个符号可有可无, 且只能有一个, 言外之意不能连续
    // [a-z0-9]+              匹配多个字母或数字
    // ([.-_]?[a-z0-9]+)*     (...)前面的可以有0组或n组, 可以匹配abc_aaa_aa-90
    ```
2. 匹配日期 YYYY-MM-DD
    * 年份（YYYY）：4位数字，如 2025、1999
    * 月份（MM）：01 到 12（注意前导0）
    * 日期（DD）：01 到 31（注意前导0）
    ```bash
    我的想法: [1-2][0-9]{3}-[0|1][0-9]-[0|1|2|3][0-9]  |在[]是普通字符集不是或的意思
    正确写法: ^(19|20)\d{2}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$
    |表示或, 外面要有小括号
    ```
3. 匹配ipv4地址
    * 不应该匹配超过256，只能匹配4段，不能匹配前导0  192.168.001.001
    ```bash
    我的想法：([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]).{3}([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])
    # 1位 | 2位 | 3位 分为 1xx 20x 21x 22x 23x 24x 25[0-5] 
    正确的写法:
    ^(0|[1-9][0-9]?|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.
    (0|[1-9][0-9]?|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.
    (0|[1-9][0-9]?|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.
    (0|[1-9][0-9]?|1[0-9]{2}|2[0-4][0-9]|25[0-5])$
    # 前面有0是为了匹配0.0.0.0
    # [1-9][0-9]?       匹配 1位或2位
    ```
# sed
1. Delete all lines where the shell is not /bin/bash
   Replace all full names (like "John Doe") with just the first name (e.g., "John")
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
