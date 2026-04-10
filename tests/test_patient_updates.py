import unittest
from datetime import datetime, timezone

from agent.coach_voice import compose_patient_update_sections
from agent.patient_updates import (
    apply_patient_reported_updates,
    derive_patient_reported_update,
)


def _score_to_state(score: float) -> str:
    if score >= 75:
        return "strong"
    if score >= 55:
        return "watch"
    return "needs_focus"


class PatientUpdateTests(unittest.TestCase):
    def test_walk_message_becomes_patient_update(self) -> None:
        update = derive_patient_reported_update("I went for a walk today")

        self.assertIsNotNone(update)
        self.assertIn("movement_fitness", update["pillar_impacts"])
        self.assertGreater(update["pillar_impacts"]["movement_fitness"]["score_delta"], 0)
        self.assertIn("mental_resilience", update["pillar_impacts"])

    def test_question_is_not_treated_as_patient_update(self) -> None:
        update = derive_patient_reported_update("Should I go for a walk today?")

        self.assertIsNone(update)

    def test_recent_updates_nudge_pillar_scores(self) -> None:
        pillars = [
            {
                "id": "movement_fitness",
                "name": "Movement and Fitness",
                "score": 60.0,
                "state": "watch",
                "trend": "stable",
                "explanation": "Movement baseline.",
                "key_signals": {},
                "data_sources": ["curated.patient_metrics"],
            },
            {
                "id": "mental_resilience",
                "name": "Mental Resilience",
                "score": 70.0,
                "state": "watch",
                "trend": "stable",
                "explanation": "Mental baseline.",
                "key_signals": {},
                "data_sources": ["curated.patient_profile"],
            },
        ]
        update = derive_patient_reported_update("I went for a walk today")
        stored_update = {
            **update,
            "created_at": "2026-04-10T08:00:00+00:00",
        }

        result = apply_patient_reported_updates(
            pillars,
            [stored_update],
            score_to_state=_score_to_state,
            now=datetime(2026, 4, 10, 12, 0, tzinfo=timezone.utc),
        )
        updated_lookup = {pillar["id"]: pillar for pillar in result["pillars"]}

        self.assertGreater(updated_lookup["movement_fitness"]["score"], 60.0)
        self.assertEqual(updated_lookup["movement_fitness"]["trend"], "improving")
        self.assertIn(
            "patient_reported_chat_updates",
            updated_lookup["movement_fitness"]["data_sources"],
        )
        self.assertEqual(
            updated_lookup["movement_fitness"]["key_signals"]["patient_reported_updates_14d"],
            1,
        )

    def test_patient_update_sections_acknowledge_effect(self) -> None:
        saved_update = {
            "message": "I went for a walk today",
            "normalized_message": "i went for a walk today",
            "events": [
                {
                    "event_type": "walk",
                    "label": "walking or light movement",
                    "pillar_deltas": {
                        "movement_fitness": 6.0,
                        "mental_resilience": 1.5,
                    },
                }
            ],
            "pillar_impacts": {
                "movement_fitness": {
                    "score_delta": 6.0,
                    "reason": "walking or light movement",
                },
                "mental_resilience": {
                    "score_delta": 1.5,
                    "reason": "walking or light movement",
                },
            },
            "summary": "Recent chat update mainly affects Movement and Fitness and Mental Resilience.",
            "created_at": "2026-04-10T08:00:00+00:00",
        }
        analysis = {
            "ok": True,
            "pillars": [
                {
                    "id": "movement_fitness",
                    "name": "Movement and Fitness",
                    "score": 66.0,
                    "trend": "improving",
                },
                {
                    "id": "mental_resilience",
                    "name": "Mental Resilience",
                    "score": 71.5,
                    "trend": "stable",
                },
            ],
            "patient_update_effect": {
                "affected_pillars": ["movement_fitness", "mental_resilience"],
            },
            "firebase_context_summary": "Found data in: patients.",
            "patient_profile": {},
            "persona_context": {},
        }
        sections = compose_patient_update_sections(saved_update, analysis, saved=True)

        self.assertEqual(
            sections[0],
            "I logged that update from chat and folded it into your current picture.",
        )
        self.assertIn("Movement and Fitness", sections[1])
        self.assertIn("Movement and Fitness is sitting near 66.0", sections[2])


if __name__ == "__main__":
    unittest.main()
