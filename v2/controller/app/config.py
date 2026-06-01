"""Controller configuration, sourced from environment with sensible local-dev defaults."""
import os
from pathlib import Path

# Repo roots (baked into the image; overridable for local dev runs).
BASE_DIR = Path(os.environ.get("SLH_BASE_DIR", "/app"))
PLATFORM_DIR = Path(os.environ.get("SLH_PLATFORM_DIR", BASE_DIR / "platform"))
EXERCISES_DIR = Path(os.environ.get("SLH_EXERCISES_DIR", BASE_DIR / "exercises"))

# Image registry/tag the controller stamps into exercise + Kali manifests.
REGISTRY = os.environ.get("SLH_REGISTRY", "slh")
TAG = os.environ.get("SLH_TAG", "dev")
KALI_IMAGE = os.environ.get("SLH_KALI_IMAGE", f"{REGISTRY}/kali-ttyd:{TAG}")

# Tenant namespace naming. ns = f"{PREFIX}{username}".
NS_PREFIX = os.environ.get("SLH_NS_PREFIX", "lab-")
CONTROLLER_NS = os.environ.get("SLH_CONTROLLER_NS", "slh-system")

# ttyd is served under this sub-path behind the controller's reverse proxy.
SHELL_BASE_PATH = "/shell"
TTYD_PORT = 7681

# Session + auth.
SESSION_SECRET = os.environ.get("SLH_SESSION_SECRET", "dev-insecure-change-me")
# Dev bootstrap accounts: "user1:pass1,user2:pass2" (hashed in memory at startup).
BOOTSTRAP_USERS = os.environ.get("SLH_BOOTSTRAP_USERS", "")
# Optional production users file: YAML { username: {password_hash: "<bcrypt>"} }.
USERS_FILE = os.environ.get("SLH_USERS_FILE", "")

# Idle culling.
IDLE_TIMEOUT_MIN = int(os.environ.get("SLH_IDLE_TIMEOUT_MIN", "60"))
CULL_INTERVAL_SEC = int(os.environ.get("SLH_CULL_INTERVAL_SEC", "60"))

# Annotations used to track tenant state on the namespace.
ANNO_EXERCISE = "slh.io/exercise"
ANNO_OWNER = "slh.io/owner"
ANNO_LAST_ACTIVITY = "slh.io/last-activity"


def tenant_ns(username: str) -> str:
    """Map a username to its namespace (sanitised to a DNS-1123 label)."""
    safe = "".join(c if c.isalnum() else "-" for c in username.lower()).strip("-")
    return f"{NS_PREFIX}{safe}"
