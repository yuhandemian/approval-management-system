package egovframework.guide.helloworld;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.ApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;

public class HelloWorldClient {
	
	private static final Logger LOGGER = LoggerFactory.getLogger(HelloWorldClient.class);

	/**
	 * @param args
	 */
	@SuppressWarnings("resource")
	public static void main(String[] args) {
				
		String configLocation = "context-helloworld.xml"; 
		ApplicationContext context = new ClassPathXmlApplicationContext(configLocation);
		HelloWorldService helloworld = (HelloWorldService)context.getBean("helloworld");
		
		LOGGER.debug(helloworld.sayHello());
	}

}
