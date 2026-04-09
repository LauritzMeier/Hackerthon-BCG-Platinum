"""Firestore helper utilities for the ADK agent."""

from __future__ import annotations

import os
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

import firebase_admin
from google.auth.exceptions import DefaultCredentialsError
from firebase_admin import credentials, firestore


def _get_env_value(*names: str) -> Optional[str]:
    """Return the first non-empty environment value for the provided names."""
    for name in names:
        value = os.getenv(name)
        if value:
            return value
    return None


def _get_project_id() -> Optional[str]:
    """Resolve the Firebase project id from explicit config or Cloud Run defaults."""
    return _get_env_value("FIREBASE_PROJECT_ID", "GOOGLE_CLOUD_PROJECT", "GCLOUD_PROJECT")


def _get_database_id() -> str:
    """Resolve the Firestore database id, defaulting to the standard database."""
    return os.getenv("FIRESTORE_DATABASE_ID", "(default)")


def _get_or_init_app() -> firebase_admin.App:
    """Initialize Firebase Admin once, then reuse the existing app."""
    if firebase_admin._apps:  # pylint: disable=protected-access
        return firebase_admin.get_app()

    project_id = _get_project_id()
    cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")

    if cred_path:
        cred = credentials.Certificate(cred_path)
        if project_id:
            return firebase_admin.initialize_app(cred, {"projectId": project_id})
        return firebase_admin.initialize_app(cred)

    # Uses Application Default Credentials when no explicit JSON key path is set.
    if project_id:
        return firebase_admin.initialize_app(options={"projectId": project_id})
    return firebase_admin.initialize_app()


def get_firestore_client() -> firestore.Client:
    """Return a Firestore client with initialized Firebase app."""
    _get_or_init_app()
    database_id = _get_database_id()
    if database_id == "(default)":
        return firestore.client()
    return firestore.client(database_id=database_id)


def push_test_message(message: str) -> Dict[str, Any]:
    """Write a test payload to Firestore and return metadata about the write."""
    client = get_firestore_client()
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
        "project_id": _get_project_id() or "auto-detect",
        "database_id": _get_database_id(),
    }


def get_patient_firebase_context(patient_id: str) -> Dict[str, Any]:
    """Fetch patient-specific context from common Firestore collections."""
    collections: List[str] = [
        "patients",
        "patient_profiles",
        "coach_context",
        "goals",
        "care_plans",
    ]

    try:
        client = get_firestore_client()
    except Exception as exc:  # pylint: disable=broad-except
        return {
            "patient_id": patient_id,
            "project_id": os.getenv("FIREBASE_PROJECT_ID", "longevity-compass-firestore"),
            "collections_checked": collections,
            "collections_found": [],
            "data": {},
            "firebase_available": False,
            "warning": _firebase_unavailable_reason(exc),
        }

    data: Dict[str, Any] = {}

    for collection_name in collections:
        snapshot = client.collection(collection_name).document(patient_id).get()
        if snapshot.exists:
            data[collection_name] = snapshot.to_dict()

    return {
        "patient_id": patient_id,
        "project_id": _get_project_id() or "auto-detect",
        "database_id": _get_database_id(),
        "collections_checked": collections,
        "collections_found": list(data.keys()),
        "data": data,
        "firebase_available": True,
    }


def _firebase_unavailable_reason(exc: Exception) -> str:
    if isinstance(exc, DefaultCredentialsError):
        return "Application Default Credentials are not configured."
    return str(exc)
