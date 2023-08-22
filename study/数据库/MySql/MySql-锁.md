## 全局锁
全局锁就是对整个数据库实例加锁。

全局锁的典型使用场景是，做全库逻辑备份。

官方自带的逻辑备份工具是mysqldump。 当mysqldump使用参数–single-transaction的时候，导数据之前就会启动一个事务，来确保拿到一致性视图。 而由于MVCC的支持，这个过程中数据是可以正常更新的。

## InnoDB的锁类型
* 共享锁（读锁-s锁）/排他锁（写锁-锁）
* 意向锁
* MDL锁

### 读锁
读锁简称S锁，Shared Lock

一个事务获取了一个数据行的读锁后，其他事务也可以获取该行的读锁。但是不能获取写锁（增删改）

读锁有两种select的应用：
* 自动提交模式下的select语句，不需要加任何锁，直接赶回查询结果，这是一致性非锁定读
* 通过 select...lock in share mode 在被读取的行记录或行记录范围加一个读锁

### 写锁
写锁又称为X锁，exclusive /ɪkˈskluːsɪv/ 独有的，专用的

一个事务获取了一行数据的写锁，其他事务就不能再获取该行的其他锁，会去阻塞等待锁。写锁优先级最高。

增删改这样的DML语句操作都会对行记录加写锁

比较特殊的是select语句后加上for update也会对读取对行记录加上写锁。 select * from students where id =15 for update;

**看到事务下获取锁可能有点晕乎，那就明确下：**
**单独的语句会默认开启一个事务并进行自动提交，多个语句以原子操作方式执行，需要显式地开启事务，并手动提交或回滚事务。**

### MDL锁
MySql5。5引入了meta data lock，简称MDL锁，用于管理对象的元数据访问，保证表中的元数据信息。也可以理解为表级别的锁

在会话A中，开启事务后，会自动获取一个MDL锁，会话B就不能再执行任何DDL语句的操作。（DDL语句主要用于定义数据库的结构和组织方式）
因此因此，事务B中执行 DDL 语句会被阻塞，直到当前事务A提交或回滚才能继续执行。

### 意向锁
InnoDB中，意向锁是表级锁。意向锁有：意向共享锁\意向排他锁

* 意向共享锁（IS）：给一个数据行加共享锁前必须先获取该表的IS锁
* 意向排他锁（IX）：给一个数据行加排他锁前必须先获取该表的IX锁

意向锁作用和MDL锁类似，都是防止在事务进行过程中，执行DDL语句的操作而导致数据的不一致

## InnoDB 行锁种类
InnoDB的行锁是针对索引加的锁，不是针对记录加的锁，并且该索引不能失效，否则都会从行锁升级为表锁。

InnoDB默认的事务隔离级别为 可重复读。行锁的种类有：
* 记录锁（record lock）
单个行记录的锁。主键和唯一索引都是记录锁
* 间隙锁（gap lock）
* 临键锁（next-key lock）
普通索引默认的是next-key

### 记录锁
也被称为记录锁，属于单个行记录上的锁。

### 间隙锁
锁定一个范围，不包括记录本身。

* 临键锁
Record Lock+Gap Lock，锁定一个范围，包含记录本身，主要目的是为了解决幻读问题。记录锁只能锁住已经存在的记录，为了避免插入新记录，需要依赖间隙锁。


### 锁总结
* MySql中锁主要分为三类：全局锁、表级锁、行锁。

* 表级锁有 意向锁 和 MDL锁；想要获取对应的行锁就要先获取到对应的意向锁 IS-S/IX-X；在事务开启后就会获取到MDL锁，防止其他事务进行DDL语句更改表的结构；意向锁和MDL锁都是为了进行事务中，防止其他事务执行DDL语句，改变表结构或数据。

* 对于开启事务就加锁需要明白：单独的语句会默认开启一个事务并进行自动提交，多个语句以原子操作方式执行，需要显式地开启事务，并手动提交或回滚事务。

* 行锁有共享锁（S锁\读锁）和排他锁（X锁\写锁）；多个事务可以获取共享锁；排他锁只能被一个事务获取，且其他事务再也不能获取任何锁，级别最高。其他事务获取锁只能阻塞等待到获取锁的事务提交或回滚。

* 我一直不理解 共享锁\排他锁 和行锁种类 记录锁\间隙锁\临键锁 到底是什么关系？
```text
举例：
    记录锁 用于控制对数据行的并发读写操作，按照类型 有共享锁也有排他锁。进行读操作获取到某行的记录锁，它的类型是共享锁；
    
    同理：进行update操作时获取到某行记录锁，它的类型是排他锁。可以理解为 共享锁\排他锁 是行锁的一个类型的属性，记录锁\间隙锁\临键锁 是行锁的具体种类。
     
    可以这样理解：记录锁-共享锁，记录锁-排他锁
```













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

### 开始一个事务
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
LOCK_DATA : 表示锁的具体数据
```
查询到的结果解释： 
```text
第一行数据是事务中加了一个表锁（IX）意向排他锁；意味着当前线程获取到了IX锁，其他线线程会阻塞着等待IX锁释放。

第二行是一个行锁 X,REC_NOT_GAP 
```


