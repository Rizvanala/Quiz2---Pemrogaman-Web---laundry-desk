package laundry.desk;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

@WebListener
public class AppStart implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent event) {
        try {
            Seed.reset();
            event.getServletContext().log("Laundry Desk database ready at " + Db.path());
        } catch (Exception e) {
            throw new IllegalStateException("Could not prepare the database", e);
        }
    }
}
