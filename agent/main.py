"""Google Cloud ADK agent entrypoint for the Longevity MVP."""

from __future__ import annotations

import os
from typing import Any, Dict

from dotenv import load_dotenv
from google.adk.agents import Agent

from firebase_client import push_test_message

load_dotenv(".env.local")
load_dotenv()
os.environ.setdefault("FIREBASE_PROJECT_ID", "longevity-compass-firestore")


def write_message_to_firebase(message: str) -> Dict[str, Any]:
    """Write a message to Firestore.

    Args:
        message: Message text to store in Firestore.
    """
    return push_test_message(message)


def _startup_firebase_test() -> Dict[str, Any]:
    """Always run first: verify agent backend can write to Firebase."""
    return write_message_to_firebase(
        "Startup test from ADK agent. Firebase connection is active."
    )


_startup_result: Dict[str, Any]
try:
    _startup_result = _startup_firebase_test()
except Exception as exc:  # pylint: disable=broad-except
    _startup_result = {"ok": False, "error": str(exc)}


root_agent = Agent(
    name="longevity_coach_agent",
    model=os.getenv("ADK_MODEL", "gemini-2.0-flash"),
    description=(
        "Patient-facing coach agent for the Longevity Compass MVP. "
        "A Firebase startup write is performed before handling requests."
    ),
    instruction=(
        "You are a supportive longevity coach for a patient-facing MVP. "
        "Never provide diagnosis, certainty, or emergency-care advice. "
        "Prioritize low-friction lifestyle recommendations and transparent caveats. "
        f"Startup Firebase test result: {_startup_result}."
    ),
    tools=[write_message_to_firebase],
)
