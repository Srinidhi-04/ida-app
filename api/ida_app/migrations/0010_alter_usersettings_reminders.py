# Generated by Django 5.2 on 2025-05-13 19:37

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('ida_app', '0009_alter_usersettings_reminders'),
    ]

    operations = [
        migrations.AlterField(
            model_name='usersettings',
            name='reminders',
            field=models.TextField(choices=[('Off', 'Off'), ('30 minutes before', '30 minutes before'), ('2 hours before', '2 hours before'), ('6 hours before', '6 hours before')], default='30 minutes before'),
        ),
    ]
