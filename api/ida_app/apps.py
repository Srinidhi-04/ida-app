from django.apps import AppConfig
import os

class IdaAppConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'ida_app'

    def ready(self):
        if os.getenv("RUN_MAIN") == "true":
            from ida_app.tasks import scheduler, start_scheduler

            if not scheduler.running:
                start_scheduler()