"""Standalone account auth (Phase-2 v1). Pluggable: swap this module for an SSO/OIDC
backend later without touching the routes.

Accounts come from either:
  * SLH_BOOTSTRAP_USERS="user:pass,user2:pass2"  (dev; hashed in memory at startup), or
  * SLH_USERS_FILE -> YAML { username: { password_hash: "<bcrypt>" } }  (production).
Passwords are never stored in plaintext at rest in the production path.
"""
import logging

import bcrypt
import yaml

from . import config

log = logging.getLogger("slh.auth")

# username -> bcrypt hash (bytes)
_USERS: dict[str, bytes] = {}


def _hash(pw: str) -> bytes:
    return bcrypt.hashpw(pw.encode(), bcrypt.gensalt())


def load_users() -> None:
    _USERS.clear()
    if config.USERS_FILE:
        try:
            data = yaml.safe_load(open(config.USERS_FILE)) or {}
            for user, rec in data.items():
                h = (rec or {}).get("password_hash")
                if h:
                    _USERS[user] = h.encode() if isinstance(h, str) else h
            log.info("Loaded %d users from %s", len(_USERS), config.USERS_FILE)
        except Exception as e:  # noqa: BLE001
            log.error("Failed to read users file %s: %s", config.USERS_FILE, e)
    if config.BOOTSTRAP_USERS:
        for pair in config.BOOTSTRAP_USERS.split(","):
            if ":" in pair:
                user, pw = pair.split(":", 1)
                user = user.strip()
                if user and user not in _USERS:
                    _USERS[user] = _hash(pw)
        log.info("Total accounts after bootstrap: %d", len(_USERS))
    if not _USERS:
        log.warning("No accounts configured — set SLH_BOOTSTRAP_USERS or SLH_USERS_FILE.")


def verify(username: str, password: str) -> bool:
    h = _USERS.get(username)
    if not h:
        return False
    try:
        return bcrypt.checkpw(password.encode(), h)
    except Exception:  # noqa: BLE001
        return False


def usernames() -> list[str]:
    return sorted(_USERS.keys())
