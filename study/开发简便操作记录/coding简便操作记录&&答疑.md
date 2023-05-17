## FeignClient的巧用
### FeignClient中填写url
> 微服务之前调用时，在Feign接口可以写上url，将来如果本地debug需要调用该服务的远程接口，直接在本地配置文件中配置service.asSql.feign.url=http://ip:port

```java
@FeignClient(value = ServiceConstant.ServiceName, contextId = "asSql", url = "${service.asSql.feign.url:}", configuration = FeignConfigInterceptor.class)
```
* value：指定要调用的外部服务的名称。在Feign中，每个服务都需要有一个唯一的名称来标识。
* url：指定要调用的外部服务的URL。可以使用占位符${}来引用配置文件中的属性值。如果没有指定URL，则Feign会根据value属性中指定的服务名和Eureka注册中心中的信息来自动构建URL。
* name：与value属性相同，都是用于指定要调用的外部服务的名称。在某些情况下，这两个属性可以互相替代使用
* 当name和url属性同时存在时，name属性会被忽略。在使用name属性时，Feign会自动从注册中心中获取服务实例列表，并根据负载均衡算法选择一个可用的实例。而当使用url属性时，则直接使用指定的URL来作为请求地址，不需要进行服务发现和负载均衡。

### Feign接口塞入请求头
```java
test(@RequestBody JSONObject req, @RequestHeader MultiValueMap<String, String> headers)
```
## 分片调用数据库

* (int)Math.ceil(list.size * 1.0 / 500) 向上取值
* Lists.partition();

## 巧用sql
### 1. 查询两种结果集的合集
```sql
UNION ALL
```


## Mybatis-plus常用技巧

### 1. include标签-将复用的sql抽取出来
```sql
<!-- 定义 SQL 片段 -->
<sql id="selectColumns">
  column1, column2, column3
</sql>

<!-- 使用 SQL 片段 -->
<select id="exampleQuery" resultType="ResultType">
  SELECT
    <include refid="selectColumns"/>
  FROM SomeTable
  WHERE ...
</select>
```
### 2. mybatis-plus自动填充pojo数据
> https://www.baomidou.com/pages/4c6bcf/
```java
@Component
public class AutomaticInsertionHandler implements MetaObjectHandler {
    @Override
    public void insertFill(MetaObject metaObject) {
        UserContext userContext = UserContextHelper.get();
        this.strictInsertFill(metaObject, "createTime", Date.class, DateUtil.date());
        this.strictUpdateFill(metaObject, "updateTime", Date.class, DateUtil.date());
        this.setFieldValByName("deleteInd",0,metaObject);
        if (Objects.isNull(userContext)) {
            return;
        }
        this.setFieldValByName("createId", userContext.getUserId(),metaObject);
        this.setFieldValByName("updateId", userContext.getUserId(),metaObject);
    }

    @Override
    public void updateFill(MetaObject metaObject) {
        UserContext userContext = UserContextHelper.get();
        this.strictUpdateFill(metaObject, "updateTime", Date.class, DateUtil.date());
        if (Objects.isNull(userContext)) {
            return;
        }
        this.setFieldValByName("updateId", userContext.getUserId(),metaObject);
        this.setFieldValByName("updateName", userContext.getUsername(),metaObject);
    }
}
```

```java
@Data
public class Activity implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 创建人id
     */
    @TableField(fill = FieldFill.INSERT)
    private String createId;

    /**
     * 创建时间
     */
    @TableField(fill = FieldFill.INSERT)
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8")
    private Date createTime;

    /**
     * 更新人id
     */
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private String updateId;

    /**
     * 更新人姓名
     */
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private String updateName;

    /**
     * 更新时间
     */
    @TableField(fill = FieldFill.INSERT_UPDATE)
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8")
    private Date updateTime;

    /**
     * 是否被删除 0-否;1-是 (yesornoind)
     */
    @TableField(fill = FieldFill.INSERT)
    private Integer deleteInd;
}
```

### 3. mybatis-plus使用分页
正常的写页面查询sql即可，然后在service层new一个Page对象 传入分页参数，向下传入该参数即可自动分页

#### 3.1 Controller
```java
@ApiOperation("列表")
@PostMapping("/xxxxxx")
public RespBody<Page<ProductListVo>> getList(@RequestBody ProductListQo qo) {
    return RespBody.ok(service.getList(qo));
}
```
#### 3.2 service层
```java
public Page<ProductListVo> getList(ProductListQo qo) {
    Page<Product> page = new Page<>(qo.getOffset(), qo.getPageSize());
    return getBaseMapper().getList(page, qo);
}
```
#### 3.3 mapper层
```java
public interface ProductMapper extends BaseMapper<Product> {
    Page<ProductListVo> getList(Page<Product> page, @Param("qo") ProductListQo qo);
}
```
#### 3.4 xml文件
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="xxxxxxx.ProductMapper">
    
    <select id="getList" resultType="xxxxxxx.ProductListVo">
        SELECT
        *
        FROM
        product SP
        WHERE
        SP.delete_ind = 0
        <if test="qo.productStatus!=null">
            and sp.product_status = #{qo.productStatus}
        </if>
    </select>
</mapper>
```

## IDEA使用
### mac快捷键
* 代码自动补全：Command + option + V
* 复制 Command+C，剪切 Command+X，粘贴 Command+V
* 撤销 Command-Z, 全选 Command-A（All,）查找（Find）Command-F

### ChatGPT插件-Bito
https://docs.bito.ai/
https://blog.csdn.net/weixin_44727080/article/details/130365108


## Linux相关
### 启动jar时 & 和 2>&1 作用
java -jar & 命令只是将Java应用程序放在后台运行，而不会输出任何信息到终端；
java -jar 2>&1 命令会将应用程序的输出信息都打印到终端上，包括日志和错误信息。

### 获取pod中环境变量传递给jvm环境变量
java -DMY_POD_NAME=${MY_POD_NAME} -jar xxx.jar
或
-DMY_POD_NAME=$(env | grep MY_POD_NAME)

### 查看JVM GC和内存情况
```shell
# 启动jar同时启动jvm监控命令
java -jar xxxx.jar & 
jstat -gc `pgrep -f app.jar` 1000 > jst.log &
```

