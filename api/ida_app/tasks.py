from email.mime.text import MIMEText
import smtplib
from firebase_admin import messaging
from apscheduler.schedulers.background import BackgroundScheduler
from django_apscheduler.jobstores import DjangoJobStore
import datetime
import os
# from dotenv import load_dotenv

# load_dotenv()

GMAIL_PASSWORD = os.getenv("GMAIL_PASSWORD")

scheduler = BackgroundScheduler()

def start_scheduler():
    scheduler.add_jobstore(DjangoJobStore(), "default")
    scheduler.start()
    print("Scheduler started successfully")

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
    job_id = f"notif_{topic}"
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
    
    print(f"Successfully scheduled notification to topic '{topic}'")

def delete_topic_notification(topic: str):
    job_id = f"notif_{topic}"

    try:
        scheduler.remove_job(job_id=job_id)
        print(f"Job {job_id} successully deleted")
    except:
        print("Job does not exist")

    if not scheduler.running:
        start_scheduler()

def send_verification_code(name: str, code: int, email: str):
    text = f"""
    <html>
    <body>
        <p>
        Hi {name}!
        <br><br>
        Your verification code is <b>{code}</b>. Do not share this code with anyone else.
        <br><br>
        This email was sent automatically, do not reply to it.
        </p>
        <br>
        <img src="https://i.imgur.com/0FHQKN4.png" alt="image">
    </body>
    </html>
    """

    message = MIMEText(text, "html")
    message["Subject"] = "IDA App Verification Code"
    message["From"] = "communications@illinidads.com"
    message["To"] = email

    session = smtplib.SMTP("smtp.gmail.com", 587)
    session.starttls()
    session.login("communications@illinidads.com", GMAIL_PASSWORD)
    session.sendmail("communications@illinidads.com", email, message.as_string())
    session.quit()

    print("Verification code sent successfully")