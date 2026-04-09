from typing import Dict, List, Optional

from .config import AppPaths
from .pipeline import _require_duckdb


def _rows_to_dicts(cursor) -> List[Dict]:
    columns = [column[0] for column in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


class WarehouseRepository:
    def __init__(self, db_path=None):
        self.paths = AppPaths.from_repo_root()
        self.db_path = str(db_path or self.paths.warehouse_path)

    def _connect(self):
        duckdb = _require_duckdb()
        return duckdb.connect(self.db_path, read_only=True)

    def list_patients(self, limit: int = 25) -> List[Dict]:
        connection = self._connect()
        try:
            cursor = connection.execute(
                """
                SELECT
                    patient_id,
                    age,
                    sex,
                    country,
                    estimated_biological_age,
                    sleep_recovery_score,
                    cardiovascular_fitness_score,
                    lifestyle_behavior_score,
                    metabolic_health_score,
                    primary_focus_area
                FROM curated.coach_context
                ORDER BY patient_id
                LIMIT ?
                """,
                [limit],
            )
            return _rows_to_dicts(cursor)
        finally:
            connection.close()

    def get_patient_profile(self, patient_id: str) -> Optional[Dict]:
        connection = self._connect()
        try:
            cursor = connection.execute(
                """
                SELECT
                    profile.*,
                    metrics.* EXCLUDE (patient_id),
                    coach_context.* EXCLUDE (patient_id, age, sex, country, latest_wearable_date,
                                             estimated_biological_age, sleep_recovery_score,
                                             cardiovascular_fitness_score, lifestyle_behavior_score,
                                             metabolic_health_score)
                FROM curated.patient_profile AS profile
                LEFT JOIN curated.patient_metrics AS metrics
                    USING (patient_id)
                LEFT JOIN curated.coach_context AS coach_context
                    USING (patient_id)
                WHERE profile.patient_id = ?
                """,
                [patient_id],
            )
            rows = _rows_to_dicts(cursor)
            return rows[0] if rows else None
        finally:
            connection.close()

    def get_age_peer_profiles(
        self,
        patient_id: str,
        age: int,
        age_band: int = 5,
        limit: int = 200,
    ) -> List[Dict]:
        connection = self._connect()
        try:
            cursor = connection.execute(
                """
                SELECT
                    profile.*,
                    metrics.* EXCLUDE (patient_id),
                    coach_context.* EXCLUDE (patient_id, age, sex, country, latest_wearable_date,
                                             estimated_biological_age, sleep_recovery_score,
                                             cardiovascular_fitness_score, lifestyle_behavior_score,
                                             metabolic_health_score)
                FROM curated.patient_profile AS profile
                LEFT JOIN curated.patient_metrics AS metrics
                    USING (patient_id)
                LEFT JOIN curated.coach_context AS coach_context
                    USING (patient_id)
                WHERE profile.patient_id <> ?
                  AND profile.age BETWEEN ? AND ?
                ORDER BY ABS(profile.age - ?), profile.patient_id
                LIMIT ?
                """,
                [patient_id, age - age_band, age + age_band, age, limit],
            )
            return _rows_to_dicts(cursor)
        finally:
            connection.close()

    def get_patient_timeline(self, patient_id: str, days: int = 30) -> List[Dict]:
        connection = self._connect()
        try:
            cursor = connection.execute(
                """
                SELECT *
                FROM curated.wearable_daily
                WHERE patient_id = ?
                ORDER BY reading_date DESC
                LIMIT ?
                """,
                [patient_id, days],
            )
            return _rows_to_dicts(cursor)
        finally:
            connection.close()

    def get_patient_flags(self, patient_id: str) -> List[Dict]:
        connection = self._connect()
        try:
            cursor = connection.execute(
                """
                SELECT *
                FROM curated.risk_flags
                WHERE patient_id = ?
                ORDER BY
                    CASE severity
                        WHEN 'high' THEN 2
                        WHEN 'medium' THEN 1
                        ELSE 0
                    END DESC,
                    flag_code
                """,
                [patient_id],
            )
            return _rows_to_dicts(cursor)
        finally:
            connection.close()

    def get_patient_offers(self, patient_id: str) -> List[Dict]:
        connection = self._connect()
        try:
            cursor = connection.execute(
                """
                SELECT *
                FROM curated.offer_opportunities
                WHERE patient_id = ?
                ORDER BY priority, offer_code
                """,
                [patient_id],
            )
            return _rows_to_dicts(cursor)
        finally:
            connection.close()

    def get_patient_bundle(self, patient_id: str, days: int = 30) -> Optional[Dict]:
        profile = self.get_patient_profile(patient_id)
        if profile is None:
            return None

        age = profile.get("age")
        age_peers = (
            self.get_age_peer_profiles(patient_id, int(age))
            if age is not None
            else []
        )
        return {
            "profile": profile,
            "flags": self.get_patient_flags(patient_id),
            "offers": self.get_patient_offers(patient_id),
            "timeline": self.get_patient_timeline(patient_id, days=days),
            "age_peers": age_peers,
        }
