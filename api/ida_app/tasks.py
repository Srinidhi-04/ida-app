from email.mime.text import MIMEText
import smtplib
from firebase_admin import messaging
import asyncio
from apscheduler.schedulers.background import BackgroundScheduler
from django_apscheduler.jobstores import DjangoJobStore
from ida_app.models import UserTokens
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

async def send_user_notification(user_id: int, tokens: list[UserTokens], title: str, body: str):
    messages = []
    for token in tokens:
        messages.append(
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body
                ),
                token=token.token
            )
        )

    response = await messaging.send_each_async(messages)
    for i, r in enumerate(response.responses):
        if not r.success:
            if isinstance(r.exception, messaging.UnregisteredError):
                await tokens[i].adelete()

    print(f"Successfully sent message to user '{user_id}': {response.responses}")

async def send_topic_notification(topic: str, title: str, body: str):
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body
        ),
        topic=topic
    )
    
    response = await messaging.send_each_async([message])
    print(f"Successfully sent message to topic '{topic}': {response.responses}")

def send_notif(topic, title, body):
    asyncio.run(send_topic_notification(topic, title, body))

def schedule_topic_notification(topic: str, title: str, body: str, run_time: datetime.datetime):
    job_id = f"notif_{topic}"
    scheduler.add_job(
        send_notif,
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

def send_mail(recipients: list, message: str):
    with smtplib.SMTP("smtp.gmail.com", 587) as session:
        session.starttls()
        session.login("illinidadsassociation@gmail.com", GMAIL_PASSWORD)
        session.sendmail("illinidadsassociation@gmail.com", recipients, message)

async def send_verification_code(name: str, code: int, email: str):
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

    await asyncio.to_thread(lambda: send_mail([email], message.as_string()))

    print("Verification code sent successfully")

async def send_subscriber(name: str, email: str, subscribe: bool):
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

    await asyncio.to_thread(lambda: send_mail(["communications@illinidads.com"], message.as_string()))

    print("Subscriber mail sent successfully")

async def send_donation(name: str, email: str, amount: float):
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

    await asyncio.to_thread(lambda: send_mail([email, "communications@illinidads.com"], message.as_string()))

    print("Donation mail sent successfully")

async def send_question(name: str, email: str, question: str):
    text = f"""
<html>
<body>
    <p>
    <b>{name} ({email})</b> has asked the following question:
    <blockquote>
    {question}
    </blockquote>
    This email was sent automatically, do not reply to it.
    </p>
    <br>
    <img src="https://i.imgur.com/0FHQKN4.png" alt="ida-logo">
</body>
</html>
"""
    
    message = MIMEText(text, "html")
    message["Subject"] = "New question"
    message["From"] = "illinidadsassociation@gmail.com"
    message["To"] = "communications@illinidads.com"

    await asyncio.to_thread(lambda: send_mail(["communications@illinidads.com", email], message.as_string()))

    print("Question mail sent successfully")

async def send_order(name: str, email: str, total: float, order: list):
    rows = ""
    for x in order:
        rows += f'''
        <tr>
            <td>{x["name"]}</td>
            <td>{x["quantity"]}</td>
            <td>${x["price"]:.2f}</td>
            <td>${x["amount"]:.2f}</td>
        </tr>'''

    text = f"""
<html>
<body>
    <p>
    Hi {name}!
    <br><br>
    Your order has been placed successfully! Here is a copy of your receipt:
    <br>
    <table border="1" cellpadding="10" cellspacing="0" style="border-collapse: collapse; width:100%; max-width:500px; text-align:center; vertical-align:middle;">
	    <tr>
            <th>Item</th>
            <th>Quantity</th>
            <th>Unit Price</th>
            <th>Amount</th>
        </tr>
{rows}
	    <tr>
            <td></td>
            <td></td>
            <td><b>Total</b></td>
            <td>${total:.2f}</td>
        </tr>
    </table>
    <br><br>
    This email was sent automatically, do not reply to it.
    </p>
    <br>
    <img src="https://i.imgur.com/0FHQKN4.png" alt="ida-logo">
</body>
</html>
"""
    
    message = MIMEText(text, "html")
    message["Subject"] = "Illini Dads Association Order Receipt"
    message["From"] = "illinidadsassociation@gmail.com"
    message["To"] = email

    await asyncio.to_thread(lambda: send_mail([email, "communications@illinidads.com"], message.as_string()))

    print("Order mail sent successfully")

async def send_refund(name: str, email: str, total: float, order: list):
    rows = ""
    for x in order:
        rows += f'''
        <tr>
            <td>{x["name"]}</td>
            <td>{x["quantity"]}</td>
            <td>${x["price"]:.2f}</td>
            <td>${x["amount"]:.2f}</td>
        </tr>'''

    text = f"""
<html>
<body>
    <p>
    Hi {name}!
    <br><br>
    Your refund has been processed successfully! Here is the order that was refunded:
    <br>
    <table border="1" cellpadding="10" cellspacing="0" style="border-collapse: collapse; width:100%; max-width:500px; text-align:center; vertical-align:middle;">
	    <tr>
            <th>Item</th>
            <th>Quantity</th>
            <th>Unit Price</th>
            <th>Amount</th>
        </tr>
{rows}
	    <tr>
            <td></td>
            <td></td>
            <td><b>Total</b></td>
            <td>${total:.2f}</td>
        </tr>
    </table>
    <br><br>
    This email was sent automatically, do not reply to it.
    </p>
    <br>
    <img src="https://i.imgur.com/0FHQKN4.png" alt="ida-logo">
</body>
</html>
"""
    
    message = MIMEText(text, "html")
    message["Subject"] = "Illini Dads Association Refund Confirmation"
    message["From"] = "illinidadsassociation@gmail.com"
    message["To"] = email

    await asyncio.to_thread(lambda: send_mail([email, "communications@illinidads.com"], message.as_string()))

    print("Refund mail sent successfully")