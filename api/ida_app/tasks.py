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
    <img src="https://i.imgur.com/0FHQKN4.png" alt="ida-logo">
</body>
</html>
"""

    message = MIMEText(text, "html")
    message["Subject"] = "Illini Dads App Verification Code"
    message["From"] = "illinidadsassociation@gmail.com"
    message["To"] = email

    with smtplib.SMTP("smtp.gmail.com", 587) as session:
        session.starttls()
        session.login("illinidadsassociation@gmail.com", GMAIL_PASSWORD)
        session.sendmail("illinidadsassociation@gmail.com", email, message.as_string())

    print("Verification code sent successfully")

def send_subscriber(name: str, email: str, subscribe: bool):
    if subscribe:
        text = f"""
<html>
<body>
    <p>
    You have a new subscriber!
    <br><br>
    <b>{name} ({email})</b> just subscribed to your mailing list!
    <br><br>
    This email was sent automatically, do not reply to it.
    </p>
    <br>
    <img src="https://i.imgur.com/0FHQKN4.png" alt="ida-logo">
</body>
</html>
"""
    
    else:
        text = f"""
<html>
<body>
    <p>
    You lost a subscriber :(
    <br><br>
    <b>{name} ({email})</b> just unsubscribed from your mailing list.
    <br><br>
    This email was sent automatically, do not reply to it.
    </p>
    <br>
    <img src="https://i.imgur.com/0FHQKN4.png" alt="ida-logo">
</body>
</html>
"""

    message = MIMEText(text, "html")
    message["Subject"] = "You've got a new subscriber!" if subscribe else "You've lost a subscriber"
    message["From"] = "illinidadsassociation@gmail.com"
    message["To"] = "communications@illinidads.com"

    with smtplib.SMTP("smtp.gmail.com", 587) as session:
        session.starttls()
        session.login("illinidadsassociation@gmail.com", GMAIL_PASSWORD)
        session.sendmail("illinidadsassociation@gmail.com", "communications@illinidads.com", message.as_string())

    print("Subscriber mail sent successfully")

def send_donation(name: str, email: str, amount: float):
    text = f"""
<html>
<body>
    <p>
    Hi {name}!
    <br><br>
    Thank you so much for your donation! Here is a copy of your receipt:
    <br><br>
    <b>Name:</b> {name}
    <br>
    <b>Email:</b> {email}
    <br>
    <b>Amount:</b> ${amount:.2f}
    <br><br>
    This email was sent automatically, do not reply to it.
    </p>
    <br>
    <img src="https://i.imgur.com/0FHQKN4.png" alt="ida-logo">
</body>
</html>
"""
    
    message = MIMEText(text, "html")
    message["Subject"] = "Thank you for your donation!"
    message["From"] = "illinidadsassociation@gmail.com"
    message["To"] = email

    with smtplib.SMTP("smtp.gmail.com", 587) as session:
        session.starttls()
        session.login("illinidadsassociation@gmail.com", GMAIL_PASSWORD)
        session.sendmail("illinidadsassociation@gmail.com", [email, "communications@illinidads.com"], message.as_string())

    print("Donation mail sent successfully")