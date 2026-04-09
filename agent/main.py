"""Google Cloud ADK agent entrypoint for the Longevity MVP."""

from __future__ import annotations

import os
from typing import Any, Dict

from dotenv import load_dotenv
from google.adk.agents import Agent

try:
    from .firebase_client import push_test_message
    from .pillar_analysis import (
        analyze_patient_six_pillars,
        explain_single_pillar,
        generate_tailored_explanation,
    )
except ImportError:  # pragma: no cover - fallback for direct script execution
    from firebase_client import push_test_message
    from pillar_analysis import (
        analyze_patient_six_pillars,
        explain_single_pillar,
        generate_tailored_explanation,
    )

load_dotenv(".env.local")
load_dotenv()

# Prioritize environment variable, fallback to the hackathon default
PROJECT_ID = os.getenv("FIREBASE_PROJECT_ID", "longevity-compass-firestore")
os.environ["FIREBASE_PROJECT_ID"] = PROJECT_ID

print(f"--- Agent initialized for Project: {PROJECT_ID} ---")


def write_message_to_firebase(message: str) -> Dict[str, Any]:
    """Write a message to Firestore.

    Args:
        message: Message text to store in Firestore.
    """
    return push_test_message(message)


def analyze_six_pillars(patient_id: str) -> Dict[str, Any]:
    """Analyze all six longevity pillars for one patient.

    Args:
        patient_id: Patient identifier, e.g. PT0001.
    """
    return analyze_patient_six_pillars(patient_id)


def explain_pillar(patient_id: str, pillar_id: str) -> Dict[str, Any]:
    """Explain one longevity pillar using CSV and Firestore context.

    Args:
        patient_id: Patient identifier, e.g. PT0001.
        pillar_id: One of sleep_recovery, cardiovascular_health, metabolic_health,
            movement_fitness, nutrition_quality, mental_resilience.
    """
    return explain_single_pillar(patient_id, pillar_id)


def build_tailored_explanation(patient_id: str) -> Dict[str, Any]:
    """Create personalized evidence package for advanced coach responses.

    Args:
        patient_id: Patient identifier, e.g. PT0001.
    """
    return generate_tailored_explanation(patient_id)


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
    model=os.getenv("ADK_MODEL", "gemini-2.5-flash-lite"),
    description=(
        "Patient-facing coach agent for the Longevity Compass MVP. "
        "It analyzes and explains six longevity pillars using raw CSV data plus "
        "patient context from Firestore. A Firebase startup write is performed first."
    ),
    instruction=(
        "You are a supportive longevity coach for a patient-facing MVP. "
        "Never provide diagnosis, certainty, or emergency-care advice. "
        "Use tool evidence to generate personalized explanations with trade-offs and "
        "next-best actions. Cite which measured data points support each claim. "
        "Always include one short uncertainty statement, especially when Firebase "
        "context is missing or conflicting with CSV signals. "
        "Prioritize low-friction lifestyle recommendations and transparent caveats. "
        "If risk appears elevated, suggest clinician follow-up without diagnosing. "
        f"Startup Firebase test result: {_startup_result}."
    ),
    tools=[
        write_message_to_firebase,
        analyze_six_pillars,
        explain_pillar,
        build_tailored_explanation,
    ],
)
