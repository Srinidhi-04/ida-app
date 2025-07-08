from django.apps import AppConfig

scheduler_started = False

class IdaAppConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'ida_app'

    def ready(self):
        global scheduler_started

        if not scheduler_started:
            from ida_app.tasks import scheduler, start_scheduler

            if not scheduler.running:
                start_scheduler()
                scheduler_started = True