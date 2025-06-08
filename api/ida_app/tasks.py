from firebase_admin import messaging
from apscheduler.schedulers.background import BackgroundScheduler
from django_apscheduler.jobstores import DjangoJobStore
import datetime

scheduler = BackgroundScheduler()

def start_scheduler():
    scheduler.add_jobstore(DjangoJobStore(), "default")
    scheduler.start()

def send_topic_notification(topic: str, title: str, body: str):
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body
        ),
        topic=topic
    )
    
    response = messaging.send(message)
    print(f"Successfully sent message to topic '{topic}': {response}")

def schedule_topic_notification(topic: str, title: str, body: str, run_time: datetime.datetime):
    job_id = f"notif_{topic}_{int(run_time.timestamp())}"
    scheduler.add_job(
        send_topic_notification,
        'date',
        run_date=run_time,
        args=[topic, title, body],
        id=job_id,
        replace_existing=True
    )

    if not scheduler.running:
        start_scheduler()

