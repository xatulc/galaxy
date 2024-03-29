## 全局锁
全局锁就是对整个数据库实例加锁。

全局锁的典型使用场景是，做全库逻辑备份。

官方自带的逻辑备份工具是mysqldump。 当mysqldump使用参数–single-transaction的时候，导数据之前就会启动一个事务，来确保拿到一致性视图。 而由于MVCC的支持，这个过程中数据是可以正常更新的。

## InnoDB的锁类型
* 共享锁（读锁-s锁）/排他锁（写锁-x锁）
* 意向锁
* MDL锁

### 读锁
读锁简称S锁，Shared Lock

共享锁既有表级别的也有行级别的；表级别锁定的范围是整个表；行级别的锁定的行

一个事务获取了一个数据行的读锁后，其他事务也可以获取该行的读锁。但是不能获取写锁（增删改）

读锁有两种select的应用：
* 自动提交模式下的select语句，不需要加任何锁，直接返回查询结果，这是一致性非锁定读
* 通过 select...lock in share mode 在被读取的行记录或行记录范围加一个读锁

### 写锁
写锁又称为X锁，exclusive /ɪkˈskluːsɪv/ 独有的，专用的

排他锁既有表级别的也有行级别的；表级别锁定的范围是整个表；行级别的锁定的行

一个事务获取了一行数据的写锁，其他事务就不能再获取该行的其他锁，会去阻塞等待锁。写锁优先级最高。

增删改这样的DML语句操作都会对行记录加写锁

比较特殊的是select语句后加上for update也会对读取对行记录加上写锁。 select * from students where id =15 for update;

**看到事务下获取锁可能有点晕乎，那就明确下：**
**单独的语句会默认开启一个事务并进行自动提交，多个语句以原子操作方式执行，需要显式地开启事务，并手动提交或回滚事务。**

### MDL锁
MySql5.5引入了meta data lock，简称MDL锁，用于管理对象的元数据访问，保证表中的元数据信息。也可以理解为表级别的锁

在会话A中，开启事务后，会自动获取一个MDL锁，会话B就不能再执行任何DDL语句的操作。（DDL语句主要用于定义数据库的结构和组织方式）
因此因此，事务B中执行 DDL 语句会被阻塞，直到当前事务A提交或回滚才能继续执行。

### 意向锁
InnoDB中，意向锁是表级锁。意向锁有：意向共享锁\意向排他锁

* 意向共享锁（IS）：给一个数据行加共享锁前必须先获取该表的IS锁
* 意向排他锁（IX）：给一个数据行加排他锁前必须先获取该表的IX锁

意向锁作用和MDL锁类似，都是防止在事务进行过程中，执行DDL语句的操作而导致数据的不一致

意向排他锁并不会对整个表进行锁定，而是通过表级别的锁提示来协调事务之间的排他访问需求，以提高并发性能和减少不必要的阻塞。

## InnoDB 行锁种类
InnoDB的行锁是针对索引加的锁，不是针对记录加的锁，并且该索引不能失效，否则都会从行锁升级为表锁。

InnoDB默认的事务隔离级别为 可重复读。行锁的种类有：
* 记录锁（record lock）
单个行记录的锁。主键和唯一索引都是记录锁
* 间隙锁（gap lock）
* 临键锁（next-key lock）
普通索引默认的是next-key

### 记录锁
属于单个行记录上的锁。

### 间隙锁
锁定一个范围，不包括记录本身。

### 临键锁
Record Lock+Gap Lock，锁定一个范围，包含记录本身，主要目的是为了解决幻读问题。记录锁只能锁住已经存在的记录，为了避免插入新记录，需要依赖间隙锁。

## 锁总结
* MySql中锁主要分为三类：全局锁、表级锁、行锁。

* 表级锁有 意向锁 、MDL锁、表级别的共享锁\排他锁；想要获取对应的行锁就要先获取到对应的意向锁 IS-S/IX-X；在事务开启后就会获取到MDL锁，防止其他事务进行DDL语句更改表的结构；意向锁和MDL锁都是为了进行事务中，防止其他事务执行DDL语句，改变表结构或数据。

* 对于开启事务就加锁需要明白：单独的语句会默认开启一个事务并进行自动提交，多个语句以原子操作方式执行，需要显式地开启事务，并手动提交或回滚事务。

* 行锁有共享锁（S锁\读锁）和排他锁（X锁\写锁）；多个事务可以获取共享锁；排他锁只能被一个事务获取，且其他事务再也不能获取任何锁，级别最高。其他事务获取锁只能阻塞等待到获取锁的事务提交或回滚。

* 我一直不理解 共享锁\排他锁 和行锁种类 记录锁\间隙锁\临键锁 到底是什么关系？
```text
举例：
    记录锁 用于控制对数据行的并发读写操作，按照类型 有共享锁也有排他锁。进行读操作获取到某行的记录锁，它的类型是共享锁；
    
    同理：进行update操作时获取到某行记录锁，它的类型是排他锁。可以理解为 共享锁\排他锁 是行锁的一个类型的属性，记录锁\间隙锁\临键锁 是行锁的具体种类。
     
    可以这样理解：记录锁-共享锁，记录锁-排他锁
```

## next-key lock 加锁范围探究

### 创建一个表并插入语句
```text
mysql> show create table students \G
*************************** 1. row ***************************
       Table: students
Create Table: CREATE TABLE `students` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `age` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
1 row in set (0.01 sec)


insert into students (id,name,age) values
(5, 'b', 5),
(10, 'c', 10),
(15, 'd', 15),
(20, 'e', 20),
(25, 'f', 25);
```

```text
mysql> select * from students;
+----+------+------+
| id | name | age  |
+----+------+------+
|  5 | b    |    5 |
| 10 | c    |   10 |
| 15 | d    |   15 |
| 20 | e    |   20 |
| 25 | f    |   25 |
+----+------+------+
```

### 主键等值查询-数据存在
```
mysql> begin;
Query OK, 0 rows affected (0.00 sec)

mysql> select * from students where id =15 for update;
+----+------+------+
| id | name | age  |
+----+------+------+
| 15 | d    |   15 |
+----+------+------+
1 row in set (0.00 sec)
```

### 获取当前正在被锁定的数据
```
mysql> select * from performance_schema.data_locks\G
*************************** 1. row ***************************
               ENGINE: INNODB
       ENGINE_LOCK_ID: 281472482111488:1069:281472493743024
ENGINE_TRANSACTION_ID: 1876
            THREAD_ID: 48
             EVENT_ID: 68
        OBJECT_SCHEMA: test
          OBJECT_NAME: students
       PARTITION_NAME: NULL
    SUBPARTITION_NAME: NULL
           INDEX_NAME: NULL
OBJECT_INSTANCE_BEGIN: 281472493743024
            LOCK_TYPE: TABLE
            LOCK_MODE: IX
          LOCK_STATUS: GRANTED
            LOCK_DATA: NULL
*************************** 2. row ***************************
               ENGINE: INNODB
       ENGINE_LOCK_ID: 281472482111488:4:4:5:281472493740112
ENGINE_TRANSACTION_ID: 1876
            THREAD_ID: 48
             EVENT_ID: 68
        OBJECT_SCHEMA: test
          OBJECT_NAME: students
       PARTITION_NAME: NULL
    SUBPARTITION_NAME: NULL
           INDEX_NAME: PRIMARY
OBJECT_INSTANCE_BEGIN: 281472493740112
            LOCK_TYPE: RECORD
            LOCK_MODE: X,REC_NOT_GAP
          LOCK_STATUS: GRANTED
            LOCK_DATA: 15
2 rows in set (0.01 sec)
```
解释：
```text
ENGINE_TRANSACTION_ID : 表示表的存储引擎
ENGINE_LOCK_ID : ENGINE_LOCK_ID 是表示锁定对象的唯一标识符。它由三个部分组成，分别是锁所属的事务 ID、线程 ID 和对象实例 ID。
ENGINE_TRANSACTION_ID : 表示当前事务的唯一标识符
THREAD_ID : 表示当前线程的唯一标识符
EVENT_ID : 表示当前事件的唯一标识符
OBJECT_SCHEMA : 表示锁定对象所属的数据库
OBJECT_NAME : 表示锁定对象的名称-表名
PARTITION_NAME : 表示锁定对象所属的分区名称
SUBPARTITION_NAME : 表示锁定对象所属的子分区名称
INDEX_NAME : 表示锁定对象所使用的索引名称
OBJECT_INSTANCE_BEGIN : 表示锁定对象实例的起始位置
LOCK_TYPE : 表示锁的类型（允许的值为 RECORD 行级锁 和 TABLE 表级锁）
LOCK_MODE : 表示锁的模式 (S, X, IS, IX, and gap locks（【行锁：record 记录锁，gap 间隙锁，Next-key 临键锁】【表锁&行锁：共享锁(S锁)，排他锁（X锁）】【表锁：意向共享锁（IS锁），意向排他锁（IX锁）】）)
LOCK_STATUS : 表示锁的状态
LOCK_DATA : 表示锁的数据；对于InnoDB，当LOCK_TYPE是RECORD（行锁）的，则显示值。当锁在主键索引时，则值锁定的是主键值。当锁是在辅助索引上是，则显示辅助索引值，并附加主键值。
```
查询到的结果解释： 
```text
第一行数据是事务中加了一个表锁（IX）意向排他锁；意味着当前线程获取到了IX锁，其他线线程会阻塞着等待IX锁释放。

第二行是一个行锁 X,REC_NOT_GAP ，select * from students where id =15 for update;锁住了第15行数据  记录锁-写锁
```

### 主键等值查询-数据不存在
```text
mysql> begin;select * from students where id = 16 for update;
```
```text
mysql> select * from performance_schema.data_locks\G
*************************** 2. row ***************************
               ENGINE: INNODB
       ENGINE_LOCK_ID: 281472482111488:4:4:6:281472493740112
ENGINE_TRANSACTION_ID: 1879
            THREAD_ID: 48
             EVENT_ID: 85
        OBJECT_SCHEMA: test
          OBJECT_NAME: students
       PARTITION_NAME: NULL
    SUBPARTITION_NAME: NULL
           INDEX_NAME: PRIMARY
OBJECT_INSTANCE_BEGIN: 281472493740112
            LOCK_TYPE: RECORD
            LOCK_MODE: X,GAP
          LOCK_STATUS: GRANTED
            LOCK_DATA: 20
2 rows in set (0.01 sec)
```
可以看到 主键等值查询，查询id=16时，是LOCK_TYPE: RECORD；LOCK_MODE: X,GAP；LOCK_DATA: 20；

等值主键查询，数据不存在；为间隙锁，且锁的区间为（15，20）；间隙锁是由于next-key lock退化而来，next-key lock区间为前开后闭(15,20],退化后为间隙锁就为（15，20）

### 范围查询1
```text
mysql> begin; select * from students where id >= 10 and id < 11 for update;
```
```text
mysql>  select * from performance_schema.data_locks\G
*************************** 2. row ***************************
               ENGINE: INNODB
       ENGINE_LOCK_ID: 281472482111488:4:4:4:281472493740112
ENGINE_TRANSACTION_ID: 1881
            THREAD_ID: 48
             EVENT_ID: 95
        OBJECT_SCHEMA: test
          OBJECT_NAME: students
       PARTITION_NAME: NULL
    SUBPARTITION_NAME: NULL
           INDEX_NAME: PRIMARY
OBJECT_INSTANCE_BEGIN: 281472493740112
            LOCK_TYPE: RECORD
            LOCK_MODE: X,REC_NOT_GAP
          LOCK_STATUS: GRANTED
            LOCK_DATA: 10
*************************** 3. row ***************************
               ENGINE: INNODB
       ENGINE_LOCK_ID: 281472482111488:4:4:5:281472493740456
ENGINE_TRANSACTION_ID: 1881
            THREAD_ID: 48
             EVENT_ID: 95
        OBJECT_SCHEMA: test
          OBJECT_NAME: students
       PARTITION_NAME: NULL
    SUBPARTITION_NAME: NULL
           INDEX_NAME: PRIMARY
OBJECT_INSTANCE_BEGIN: 281472493740456
            LOCK_TYPE: RECORD
            LOCK_MODE: X,GAP
          LOCK_STATUS: GRANTED
            LOCK_DATA: 15
3 rows in set (0.00 sec)
```
```text
通过sql可以分析到 id>=10 --> （10，+∞） -->  [10，+∞）; id<11  -->  (10,15] (范围查询，最基本的锁一般为next-key lock, 是前开后闭) 最后推出锁的范围是：[10,15]

实际通过查询锁发现，有两个锁：
行锁（记录锁）锁数据10  
间隙锁 锁(10,15)

具体锁的[10,15) 
```

### 范围查询2
```text
mysql> begin; select * from students where id > 10 and id <= 15 for update;
```
```text
mysql>  select * from performance_schema.data_locks\G
*************************** 2. row ***************************
               ENGINE: INNODB
       ENGINE_LOCK_ID: 281472482111488:4:4:5:281472493740112
ENGINE_TRANSACTION_ID: 1880
            THREAD_ID: 48
             EVENT_ID: 90
        OBJECT_SCHEMA: test
          OBJECT_NAME: students
       PARTITION_NAME: NULL
    SUBPARTITION_NAME: NULL
           INDEX_NAME: PRIMARY
OBJECT_INSTANCE_BEGIN: 281472493740112
            LOCK_TYPE: RECORD
            LOCK_MODE: X
          LOCK_STATUS: GRANTED
            LOCK_DATA: 15
2 rows in set (0.01 sec)
```
```text
mysql> begin;update students set age = 1 where id =15;
Query OK, 0 rows affected (0.00 sec)
^C^C -- query aborted
ERROR 1317 (70100): Query execution was interrupted

mysql> begin;insert into students values(11,'m',30);
Query OK, 0 rows affected (0.00 sec)
^C^C -- query aborted
ERROR 1317 (70100): Query execution was interrupted
```
这是一个next-key lock 锁住了（10，15]

### 结论：
```
select * from performance_schema.data_locks;(/pərˈfɔːrməns/)查询看到
LOCK_MODE = X 是前开后闭区间； next-key lock
X,GAP 是前开后开区间（间隙锁）；
X,REC_NOT_GAP 行锁。
```

```
加锁时，会先给表添加意向锁，IX 或 IS；
加锁是如果是多个范围，是分开加了多个锁，每个范围都有锁；（这个可以实践下 id < 20 的情况）
主键等值查询，数据存在时，会对该主键索引的值加行锁 X,REC_NOT_GAP；
主键等值查询，数据不存在时，会对查询条件主键值所在的间隙添加间隙锁 X,GAP；
主键等值查询，范围查询时情况则比较复杂：
    不同版本有不同的优化。上面用的是8.0.33 有记录锁+间隙锁的也有直接是next-key lock的
```

《MySql45讲》中总结过；
### 两原则，两优化，一个bug
> 原则1：加锁基本单位是next-key lock 范围是前开后闭
> 
> 原则2：查询过程中访问到的对象才会加锁
> 
> 优化1：索引上的等值查询，给唯一索引加锁时，next-key lock会退化为行锁
> 
> 优化2：索引上的等值查询，向右遍历时且最后一个值不满足等值条件，next-key lock会退化为间隙锁
> 
> 一个bug：唯一索引上的范围查询会访问到不满足条件的第一个值为止
> 
> 但是bug在我测试的8.0.33已经被使用

## 锁等待 & 死锁
### 锁等待

一个事务过程中产生锁，其他事务需要等待上一个事务释放它的锁，该能占有该资源。如果事务一直不释放锁，就要一直持续等待下去，直到超过锁等待时间，报错。

MySql通过innodb_lock_wait_timeout参数控制，单位是秒

```text
mysql> show variables like '%innodb_lock_wait%';
+--------------------------+-------+
| Variable_name            | Value |
+--------------------------+-------+
| innodb_lock_wait_timeout | 50    |
+--------------------------+-------+
```

### 死锁
死锁指两个或两个以上的进程在执行过程中，因争夺资源而造成一种互相等待的现象。A需要B持有的锁，B需要A持有的锁，两个互相等待，死锁了。

查看死锁
```text
show engine innodb status \G;
```

## 锁问题的监控
### 查看当前 MySQL 数据库中所有活动进程的命令
```text
mysql> show full processlist;
+----+-----------------+-----------+------+---------+--------+------------------------+-----------------------+
| Id | User            | Host      | db   | Command | Time   | State                  | Info                  |
+----+-----------------+-----------+------+---------+--------+------------------------+-----------------------+
|  5 | event_scheduler | localhost | NULL | Daemon  | 604538 | Waiting on empty queue | NULL                  |
|  9 | root            | localhost | test | Query   |      0 | init                   | show full processlist |
| 10 | root            | localhost | test | Sleep   |  13281 |                        | NULL                  |
+----+-----------------+-----------+------+---------+--------+------------------------+-----------------------+
```

## 补充
### 当前读和快照读
快照读（一致性非锁定读）就是单纯的 SELECT 语句，但不包括下面这两类
```text
SELECT 语句：SELECT ... FOR UPDATE
# 共享锁 可以在 MySQL 5.7 和 MySQL 8.0 中使用
SELECT ... LOCK IN SHARE MODE;
# 共享锁 可以在 MySQL 8.0 中使用
SELECT ... FOR SHARE;
```

快照即记录的历史版本，每行记录可能存在多个历史版本（多版本技术）。

快照读的情况下，如果读取的记录正在执行 UPDATE/DELETE 操作，读取操作不会因此去等待记录上 X 锁的释放，而是会去读取行的一个快照。

只有在事务隔离级别 RC(读取已提交) 和 RR（可重读）下，InnoDB 才会使用一致性非锁定读：
* 在 RC 级别下，对于快照数据，一致性非锁定读总是读取被锁定行的最新一份快照数据。
* 在 RR 级别下，对于快照数据，一致性非锁定读总是读取本事务开始时的行数据版本。

快照读比较适合对于数据一致性要求不是特别高且追求极致性能的业务场景。当前读 （一致性锁定读）就是给行记录加 X 锁或 S 锁。

当前读的一些常见 SQL 语句类型如下：# 对读的记录加一个X锁
```text
SELECT...FOR UPDATE
# 对读的记录加一个S锁
SELECT...LOCK IN SHARE MODE
# 对读的记录加一个S锁
SELECT...FOR SHARE
# 对修改的记录加一个X锁
INSERT...
UPDATE...
DELETE...
```