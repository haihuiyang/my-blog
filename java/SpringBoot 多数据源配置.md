#### SpringBoot 多数据源配置

最近在项目中需要连两个 `mysql` 数据库，即需要配置多数据源。

关于多数据源的配置网上还是有一大堆资料的，在搜寻一番过后，开始进行配置。虽然配置过程中也遇到过一些坑，但总体上还算比较简单。

大体步骤如下：（文末附有项目 `github` 地址）

##### 一、`application.yml` 中添加数据库配置（两个数据库，分别为：primary、secondary）

```yml
spring:
  datasource:
    primary:
      hikari:
        driver-class-name: com.mysql.cj.jdbc.Driver
        connection-test-query: SELECT 1 FROM DUAL
        minimum-idle: 1
        maximum-pool-size: 5
        pool-name: bosPoolName
        max-lifetime: 180000000
        jdbcUrl: jdbc:mysql://${mysqlHost1:localhost}:3306/test1?useSSL=false&useUnicode=true&characterEncoding=UTF-8
        username: ${mysqlUsername1:root}
        password: ${mysqlPassword1:123456}
    secondary:
      hikari:
        driver-class-name: com.mysql.cj.jdbc.Driver
        connection-test-query: SELECT 1 FROM DUAL
        minimum-idle: 1
        maximum-pool-size: 5
        pool-name: bosPoolName
        max-lifetime: 180000000
        jdbcUrl: jdbc:mysql://${mysqlHost2:localhost}:3306/test2?useSSL=false&useUnicode=true&characterEncoding=UTF-8
        username: ${mysqlUsername2:root}
        password: ${mysqlPassword2:123456}
```

##### 二、添加 `PrimaryDataSourceConfig` 和 `SecondaryDataSourceConfig` 配置类

##### PrimaryDataSourceConfig.java

```java
@Configuration
@EnableTransactionManagement
@EnableJpaRepositories(entityManagerFactoryRef = "primaryEntityManagerFactory",
        transactionManagerRef = "primaryTransactionManager",
        basePackages = {"com.yhh.primary.**.dao"}//primary数据库对应dao所在的package
)
public class PrimaryDataSourceConfig {

    @Bean(name = "primaryDataSource")
    @Primary
    @ConfigurationProperties(prefix = "spring.datasource.primary.hikari")//primary数据库配置
    public DataSource getDataSource() {
        return DataSourceBuilder.create().type(HikariDataSource.class).build();
    }

    @Primary
    @Bean
    public JdbcTemplate getJdbcTemplate() {
        return new JdbcTemplate(getDataSource());
    }

    @Primary
    @Bean(name = "primaryEntityManagerFactory")
    public LocalContainerEntityManagerFactoryBean entityManagerFactory(EntityManagerFactoryBuilder builder,
                                                                       @Qualifier("vendorProperties") Map<String, ?> vendorProperties) {//自己定义的Bean：vendorProperties
        return builder
                .dataSource(getDataSource())
                .properties(vendorProperties)
                .packages("com.yhh.primary.**.entity")//primary数据库对应entity所在的package
                .persistenceUnit("primary")//persistence unit，随便给，须唯一
                .build();
    }

    @Primary
    @Bean(name = "primaryTransactionManager")
    public PlatformTransactionManager transactionManager(
            @Qualifier("primaryEntityManagerFactory") EntityManagerFactory entityManagerFactory) {
        return new JpaTransactionManager(entityManagerFactory);
    }

}
```

##### SecondaryDataSourceConfig.java

```java
@Configuration
@EnableTransactionManagement
@EnableJpaRepositories(entityManagerFactoryRef = "secondaryEntityManagerFactory",
        transactionManagerRef = "secondaryTransactionManager",
        basePackages = "com.yhh.secondary.**.dao"//secondary数据库对应dao所在的package
)
public class SecondaryDataSourceConfig {

    @Bean(name = "secondaryDataSource")
    @ConfigurationProperties(prefix = "spring.datasource.secondary.hikari")//secondary数据库配置
    public DataSource secondaryDataSource() {
        return DataSourceBuilder.create().type(HikariDataSource.class).build();
    }


    @Bean(name = "secondaryJdbcTemplate")
    public JdbcTemplate secondaryJdbcTemplate() {
        return new JdbcTemplate(secondaryDataSource());
    }

    @Bean(name = "secondaryEntityManagerFactory")
    public LocalContainerEntityManagerFactoryBean entityManagerFactory(EntityManagerFactoryBuilder builder,
                                                                       @Qualifier("vendorProperties") Map<String, ?> vendorProperties) {//自己定义的Bean：vendorProperties
        return builder
                .dataSource(secondaryDataSource())
                .properties(vendorProperties)
                .packages("com.yhh.secondary.**.entity")//secondary数据库对应entity所在的package
                .persistenceUnit("secondary")//persistence unit，随便给，须唯一
                .build();
    }

    @Bean(name = "secondaryTransactionManager")
    public PlatformTransactionManager transactionManager(
            @Qualifier("secondaryEntityManagerFactory") EntityManagerFactory entityManagerFactory
    ) {
        return new JpaTransactionManager(entityManagerFactory);
    }

}
```

##### 三、`vendorProperties` Bean 配置

```java
    @Autowired
    private JpaProperties jpaProperties;

    @Bean(name = "vendorProperties")
    public Map<String, Object> getVendorProperties() {
        return jpaProperties.getHibernateProperties(new HibernateSettings());
    }
```

实际上这里配置的是下面这三个属性：

```java
"hibernate.id.new_generator_mappings" -> "true"
```

```java
"hibernate.physical_naming_strategy" -> "org.springframework.boot.orm.jpa.hibernate.SpringPhysicalNamingStrategy"
```

```java
"hibernate.implicit_naming_strategy" -> "org.springframework.boot.orm.jpa.hibernate.SpringImplicitNamingStrategy"
```

文末有两个参考链接，按照这两个链接基本上就可以将其配置出来，不过当数据库字段名命名规则为**下划线命名法**时会有问题。异常如下：

```java
o.h.engine.jdbc.spi.SqlExceptionHelper   : SQL Error: 1054, SQLState: 42S22
o.h.engine.jdbc.spi.SqlExceptionHelper   : Unknown column 'teacherdo0_.teacherName' in 'field list'
```

原因是代码中是**驼峰命名法**，而数据库中命名是**下划线命名法**，二者无法相互映射，会报 `Unknown column` 异常。当时为这个问题找了好半天，后来通过添加 `vendorProperties` 解决。

##### 四、添加 entity 及 dao （需要注意的是：entity 与 dao 的 package 位置须与前面配置一致）

##### StudentDO.java
```java
package com.yhh.primary.entity;

import lombok.Data;

import javax.persistence.*;


@Data
@Entity
@Table(name = "student")
public class StudentDO {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    private String studentName;
    private Integer age;
}

```

##### StudentDao.java

```java
package com.yhh.primary.dao;

import com.yhh.primary.entity.StudentDO;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface StudentDao extends JpaRepository<StudentDO, Integer> {
}

```

##### TeacherDO.java

```java
package com.yhh.secondary.entity;

import lombok.Data;

import javax.persistence.*;

@Entity
@Data
@Table(name = "teacher")
public class TeacherDO {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    private String teacherName;
    private Integer age;
}

```

##### TeacherDao.java

```java
package com.yhh.secondary.dao;

import com.yhh.secondary.entity.TeacherDO;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TeacherDao extends JpaRepository<TeacherDO, Integer> {
}

```

##### 五、测试与验证（需要数据库有与之对应的 table 及数据，在 github 项目的 README 文件中有现成的 sql 语句）

可以通过添加 `IT` 或 `Controller` 的方式验证是否配置成功。

##### 1、`IT` （集成测试），跑集成测试，两个 dao 都可以查出数据。

```java
package com.yhh.dao;

import com.yhh.primary.dao.StudentDao;
import com.yhh.primary.entity.StudentDO;
import com.yhh.secondary.dao.TeacherDao;
import com.yhh.secondary.entity.TeacherDO;
import lombok.extern.slf4j.Slf4j;
import org.junit.Assert;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

import java.util.List;

@Slf4j
@RunWith(SpringRunner.class)
@SpringBootTest
@EnableAutoConfiguration
public class MutiDaoIT {

    @Autowired
    private StudentDao studentDao;

    @Autowired
    private TeacherDao teacherDao;

    @Test
    public void muti_dao_IT() {
        List<TeacherDO> teacherDOList = teacherDao.findAll();

        List<StudentDO> studentDOList = studentDao.findAll();

        Assert.assertFalse(teacherDOList.isEmpty());
        Assert.assertFalse(studentDOList.isEmpty());
    }
}
```

##### 2、`Controller`，通过启动 SpringBoot 应用，请求 `http://localhost:8888/api/muti-data` 会得到一个  `json` 数组，里面有四条数据。

```java
package com.yhh.rest;

import com.yhh.primary.dao.StudentDao;
import com.yhh.secondary.dao.TeacherDao;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import java.util.ArrayList;
import java.util.List;

@Controller
@RequestMapping(value = "/api")
@Slf4j
public class ShowController {

    private final StudentDao studentDao;
    private final TeacherDao teacherDao;

    public ShowController(StudentDao studentDao, TeacherDao teacherDao) {
        this.studentDao = studentDao;
        this.teacherDao = teacherDao;
    }

    @GetMapping(value = "/muti-data")
    public ResponseEntity queryMutiData() {
        log.info("query muti-data.");

        List result = new ArrayList<>();

        result.addAll(studentDao.findAll());
        result.addAll(teacherDao.findAll());

        log.info("result size is {}.", result.size());

        return ResponseEntity.ok(result);
    }

}

```

以上所有代码均可在 `github` 上找到：[spring-muti-datasource-config](https://github.com/haihuiyang/spring-muti-datasource-config)

参考资料：

（1）[Spring Boot Configure and Use Two DataSources](https://stackoverflow.com/questions/30337582/spring-boot-configure-and-use-two-datasources)

（2）[Using multiple datasources with Spring Boot and Spring Data](https://medium.com/@joeclever/using-multiple-datasources-with-spring-boot-and-spring-data-6430b00c02e7)