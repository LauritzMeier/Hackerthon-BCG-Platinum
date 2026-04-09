"""Firestore helper utilities for the ADK agent."""

from __future__ import annotations

import os
from datetime import datetime, timezone
from typing import Any, Dict

import firebase_admin
from firebase_admin import credentials, firestore


def _get_or_init_app() -> firebase_admin.App:
    """Initialize Firebase Admin once, then reuse the existing app."""
    if firebase_admin._apps:  # pylint: disable=protected-access
        return firebase_admin.get_app()

    project_id = os.getenv("FIREBASE_PROJECT_ID", "longevity-compass-firestore")
    cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")

    if cred_path:
        cred = credentials.Certificate(cred_path)
        return firebase_admin.initialize_app(cred, {"projectId": project_id})

    # Uses Application Default Credentials when no explicit JSON key path is set.
    return firebase_admin.initialize_app(options={"projectId": project_id})


def push_test_message(message: str) -> Dict[str, Any]:
    """Write a test payload to Firestore and return metadata about the write."""
    _get_or_init_app()
    client = firestore.client()
    doc_ref = client.collection("agent_test_messages").document()

    payload = {
        "message": message,
        "source": "gcp-adk-agent",
        "createdAt": datetime.now(timezone.utc).isoformat(),
    }
    doc_ref.set(payload)

    return {
        "ok": True,
        "collection": "agent_test_messages",
        "document_id": doc_ref.id,
        "project_id": os.getenv("FIREBASE_PROJECT_ID", "longevity-compass-firestore"),
    }
