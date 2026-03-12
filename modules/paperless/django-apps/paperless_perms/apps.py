"""Auto-manage permissions for Remote-User accounts in Paperless-ngx.

Loaded as a Django app via PAPERLESS_APPS. On startup it:

1. Creates an "editors" group with full CRUD permissions on all models.
2. Adds all non-service Remote-User accounts to the editors group.
3. Installs a post_save signal so new accounts are handled automatically.
"""

import logging

from django.apps import AppConfig
from django.db.models.signals import post_save

logger = logging.getLogger(__name__)

SERVICE_ACCOUNTS = {"consumer", "AnonymousUser"}


def _setup_editors_group():
    from django.contrib.auth.models import Group, Permission
    from django.contrib.contenttypes.models import ContentType

    editors_group, _ = Group.objects.get_or_create(name="editors")
    permissions = []
    for ct in ContentType.objects.all():
        permissions.extend(
            Permission.objects.filter(
                content_type=ct,
                codename__regex=r"^(view|change|add|delete)_",
            )
        )
    editors_group.permissions.set(permissions)
    return editors_group


def _promote_user(user, editors_group):
    if not user.groups.filter(name="editors").exists():
        user.groups.add(editors_group)
        logger.info("Added user %s to editors group", user.username)


def _on_user_created(sender, instance, created, **kwargs):
    if not created or instance.username in SERVICE_ACCOUNTS:
        return
    from django.contrib.auth.models import Group

    try:
        editors = Group.objects.get(name="editors")
    except Group.DoesNotExist:
        return
    _promote_user(instance, editors)


class PaperlessPermsConfig(AppConfig):
    name = "paperless_perms"
    verbose_name = "Paperless permission management"

    def ready(self):
        from django.contrib.auth.models import User

        post_save.connect(_on_user_created, sender=User)
        try:
            editors_group = _setup_editors_group()
            for user in User.objects.exclude(username__in=SERVICE_ACCOUNTS):
                _promote_user(user, editors_group)
        except Exception:
            logger.exception("Failed initial permission setup")
