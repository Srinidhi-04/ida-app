from django.apps import AppConfig

class IdaAppConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'ida_app'

    def ready(self):
        from ida_app.tasks import scheduler, start_scheduler

        if not scheduler.running:
            start_scheduler()