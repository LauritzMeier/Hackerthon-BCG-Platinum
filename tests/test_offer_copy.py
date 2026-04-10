import unittest

from agent.coach_voice import (
    compose_offer_booking_sections,
    compose_offer_recommendation_sections,
    firebase_context_line,
)


class OfferCopyTests(unittest.TestCase):
    def test_recommendation_sections_are_direct_and_scannable(self) -> None:
        offer = {
            "offer_label": "Cardiometabolic recovery review",
            "summary": "Bring your current risk picture, medications, and recovery trends into one practical follow-up plan.",
            "why_now": "It fits the current pattern in your records.",
            "personalization_note": "Best when you need medically grounded prioritization, not a generic wellness package.",
            "missing_data": [
                "A week of meal logging would make any nutrition follow-up more specific.",
            ],
        }
        persona_context = {
            "main_motivation": "stay active and independent as long as possible",
        }
        primary_focus = {"pillar_name": "cardiometabolic health"}

        sections = compose_offer_recommendation_sections(
            offer,
            primary_focus=primary_focus,
            persona_context=persona_context,
            scheduled_label="Sat 11 Apr • 09:00",
        )

        self.assertEqual(
            sections[0],
            "I recommend Cardiometabolic recovery review as the first support option to consider.",
        )
        self.assertIn(
            "It fits your goal to stay active and independent as long as possible, with cardiometabolic health as the main focus.",
            sections,
        )
        self.assertIn(
            "Why it fits: Bring your current risk picture, medications, and recovery trends into one practical follow-up plan.",
            sections,
        )
        self.assertIn("Why now: It fits the current pattern in your records.", sections)
        self.assertIn(
            "It works best when you need medically grounded prioritization, not a generic wellness package.",
            sections,
        )
        self.assertIn(
            "If you want me to book it, the first available slot is Sat 11 Apr • 09:00. Just say 'book it'.",
            sections,
        )
        self.assertIn(
            "To personalize this further: A week of meal logging would make any nutrition follow-up more specific.",
            sections,
        )
        self.assertTrue(all("demo slot" not in section for section in sections))
        self.assertTrue(all("quality-of-life decline" not in section for section in sections))

    def test_recommendation_omits_duplicate_why_now_line(self) -> None:
        offer = {
            "offer_label": "Sleep and recovery reset",
            "summary": "Use recovery habits and sleep structure to improve resilience.",
            "why_now": "Use recovery habits and sleep structure to improve resilience.",
        }

        sections = compose_offer_recommendation_sections(offer)

        self.assertEqual(
            [section for section in sections if section.startswith("Why ")],
            ["Why it fits: Use recovery habits and sleep structure to improve resilience."],
        )

    def test_firebase_context_line_avoids_internal_jargon(self) -> None:
        line = firebase_context_line("Found data in: patients.")

        self.assertEqual(line, "I also used the profile context already linked in the app.")
        self.assertNotIn("Context sync", line)

    def test_booking_sections_use_plain_language(self) -> None:
        offer = {
            "offer_label": "Cardiology follow-up visit",
            "first_week": ["Write down symptoms, questions, or medication concerns"],
        }
        booking = {"scheduled_label": "Tue 14 Apr • 10:00"}

        sections = compose_offer_booking_sections(offer, booking)

        self.assertEqual(sections[0], "I've booked Cardiology follow-up visit for Tue 14 Apr • 10:00.")
        self.assertEqual(sections[1], "It is now saved in your support bookings.")
        self.assertEqual(
            sections[2],
            "Before then, start with this: Write down symptoms, questions, or medication concerns",
        )


if __name__ == "__main__":
    unittest.main()
