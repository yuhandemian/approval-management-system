package egovframework.example.common;

import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;

@ExtendWith(SpringExtension.class)
@ContextConfiguration(locations = {
    "classpath:egovframework/spring/context-common.xml",
    "classpath:egovframework/spring/context-datasource.xml",
    "classpath:egovframework/spring/context-transaction.xml",
    "classpath:egovframework/spring/context-mapper.xml",
    "classpath:egovframework/spring/context-idgen.xml"
})
public abstract class AbstractServiceTest {
}
