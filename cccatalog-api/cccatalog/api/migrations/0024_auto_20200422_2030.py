# Generated by Django 2.2.10 on 2020-04-22 20:30

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0023_auto_20200412_2017'),
    ]

    operations = [
        migrations.CreateModel(
            name='MatureImages',
            fields=[
                ('identifier', models.UUIDField(primary_key=True, serialize=False, unique=True)),
                ('created_on', models.DateTimeField(auto_now_add=True)),
            ],
        ),
        migrations.RemoveField(
            model_name='deletedimages',
            name='deleted_id',
        ),
        migrations.RemoveField(
            model_name='deletedimages',
            name='deleting_user',
        ),
        migrations.RemoveField(
            model_name='deletedimages',
            name='id',
        ),
        migrations.AddField(
            model_name='deletedimages',
            name='identifier',
            field=models.UUIDField(default='f', help_text='The identifier of the deleted image.', primary_key=True, serialize=False, unique=True),
            preserve_default=False,
        ),
    ]
