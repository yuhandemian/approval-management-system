package egovframework.guide.helloworld;

import static org.junit.Assert.assertEquals;
import javax.annotation.Resource;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;

@RunWith(SpringJUnit4ClassRunner.class)
@ContextConfiguration(locations = { "/context-helloworld.xml" })
public class HelloWorldServiceTest {
	private HelloWorldService helloworld;

	@Resource(name = "helloworld")
	public void setHelloWorld(HelloWorldService hello) {
		this.helloworld = hello;
	}

	@Test
	public void SayHello() {
		assertEquals("Hello eGovFrame!!!", helloworld.sayHello());
	}
}