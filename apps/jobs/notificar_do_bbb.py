#!/usr/bin/env python3
"""Extrai a programacao da Globo Minas a partir do JSON embutido em data-props."""

from __future__ import annotations

import argparse
import csv
import html
import json
import sys
import random
from dataclasses import asdict, dataclass
from datetime import datetime, timedelta, date
from html.parser import HTMLParser
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


DEFAULT_URL = "https://redeglobo.globo.com/globominas/programacao/"
DEFAULT_USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
NTFY_TOPIC = "heitorfreitasf"


@dataclass(slots=True)
class ProgramImages:
    image_now_on_tv: str | None
    image_url: str | None
    image_url_mobile: str | None
    image_url_tablet: str | None
    logo_url: str | None
    poster_url: str | None
    teams_url: str | None


@dataclass(slots=True)
class ProgramInfo:
    id: float | None
    name: str | None
    duration: str | None
    start_time: str | None
    synopsis: str | None
    summary_highlight: str | None
    program_url: str | None
    trailler: str | None
    images: ProgramImages | None


@dataclass(slots=True)
class ProgramSlot:
    id: float | None
    guia_slot_id: float | None
    title: str | None
    name: str | None
    show_name: str | None
    content_type: str | None
    duration: str | None
    scheduled_date: str | None
    logo_url: str | None
    program: ProgramInfo | None


@dataclass(slots=True)
class FlatScheduleEntry:
    date: datetime | None
    start: datetime | None
    end: datetime | None
    program: str | None


@dataclass(slots=True)
class ScheduleDay:
    date: str | None
    release_date: str | None
    ending_time: str | None
    channel: str | None
    holidays: list[Any]
    slots: list[ProgramSlot]


@dataclass(slots=True)
class ScheduleGrid:
    days: list[ScheduleDay]

    def flat_slots(self) -> list[FlatScheduleEntry]:
        slots: list[FlatScheduleEntry] = []
        for day in self.days:
            date_dt = _parse_iso_datetime(day.date)
            for slot in day.slots:
                start_dt = _parse_iso_datetime(slot.scheduled_date)
                end_dt = _calculate_end_datetime(start_dt, slot.duration)
                program_name = None
                if slot.program and slot.program.name:
                    program_name = slot.program.name
                elif slot.title:
                    program_name = slot.title
                elif slot.name:
                    program_name = slot.name

                slots.append(
                    FlatScheduleEntry(
                        date=date_dt,
                        start=start_dt,
                        end=end_dt,
                        program=program_name,
                    )
                )
        return slots


def _parse_iso_datetime(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        return datetime.fromisoformat(value)
    except ValueError:
        return None


def _calculate_end_datetime(
    start: datetime | None, duration: str | None
) -> datetime | None:
    if not start or not duration:
        return None
    try:
        hours, minutes, seconds = (int(part) for part in duration.split(":"))
        return start + timedelta(hours=hours, minutes=minutes, seconds=seconds)
    except (TypeError, ValueError):
        return None


def _parse_program_images(value: Any) -> ProgramImages | None:
    if not isinstance(value, dict):
        return None
    return ProgramImages(
        image_now_on_tv=value.get("imageNowOnTv"),
        image_url=value.get("imageUrl"),
        image_url_mobile=value.get("imageUrlMobile"),
        image_url_tablet=value.get("imageUrlTablet"),
        logo_url=value.get("logoUrl"),
        poster_url=value.get("posterUrl"),
        teams_url=value.get("teamsUrl"),
    )


def _parse_program_info(value: Any) -> ProgramInfo | None:
    if not isinstance(value, dict):
        return None
    return ProgramInfo(
        id=value.get("id"),
        name=value.get("name"),
        duration=value.get("duration"),
        start_time=value.get("startTime"),
        synopsis=value.get("synopsis"),
        summary_highlight=value.get("summaryHighlight"),
        program_url=value.get("programUrl"),
        trailler=value.get("trailler"),
        images=_parse_program_images(value.get("images")),
    )


class GradeAreaParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.data_props: str | None = None

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag != "main" or self.data_props is not None:
            return

        attrs_map = dict(attrs)
        class_attr = attrs_map.get("class", "") or ""
        data_props = attrs_map.get("data-props")

        if "grade-area" in class_attr.split() and data_props:
            self.data_props = data_props


def fetch_page(url: str, timeout: int) -> str:
    request = Request(url, headers={"User-Agent": DEFAULT_USER_AGENT})
    try:
        with urlopen(request, timeout=timeout) as response:
            charset = response.headers.get_content_charset() or "utf-8"
            return response.read().decode(charset, errors="replace")
    except HTTPError as exc:
        raise RuntimeError(f"HTTP {exc.code} ao acessar {url}") from exc
    except URLError as exc:
        raise RuntimeError(f"Falha de rede ao acessar {url}: {exc.reason}") from exc


def extract_embedded_props(page_html: str) -> dict[str, Any]:
    parser = GradeAreaParser()
    parser.feed(page_html)

    if not parser.data_props:
        raise ValueError("Elemento main.grade-area[data-props] nao encontrado.")

    decoded_data = html.unescape(parser.data_props)
    return json.loads(decoded_data)


def normalize_schedule(props: dict[str, Any]) -> ScheduleGrid:
    output_days = (
        props.get("context", {}).get("gridData", {}).get("data", {}).get("output", [])
    )

    if not isinstance(output_days, list):
        raise ValueError("Estrutura inesperada: output nao e uma lista.")

    days: list[ScheduleDay] = []
    for day in output_days:
        if not isinstance(day, dict):
            continue

        date = day.get("date")
        release_date = day.get("releaseDate")
        ending_time = day.get("endingTime")
        channel = day.get("channel")
        holidays_value = day.get("holidays")
        holidays: list[Any] = holidays_value if isinstance(holidays_value, list) else []
        slots = day.get("slots", [])
        if not isinstance(slots, list):
            continue

        day_slots: list[ProgramSlot] = []

        for slot in slots:
            if not isinstance(slot, dict):
                continue

            day_slots.append(
                ProgramSlot(
                    id=slot.get("id"),
                    guia_slot_id=slot.get("guiaSlotId"),
                    title=slot.get("title"),
                    name=slot.get("name"),
                    show_name=slot.get("showName"),
                    content_type=slot.get("contentType"),
                    duration=slot.get("duration"),
                    scheduled_date=slot.get("scheduledDate"),
                    logo_url=slot.get("logoUrl"),
                    program=_parse_program_info(slot.get("program")),
                )
            )

        days.append(
            ScheduleDay(
                date=date,
                release_date=release_date,
                ending_time=ending_time,
                channel=channel,
                holidays=holidays,
                slots=day_slots,
            )
        )

    return ScheduleGrid(days=days)


def save_json(data: list[FlatScheduleEntry], path: Path) -> None:
    serialized: list[dict[str, Any]] = []
    for slot in data:
        payload = asdict(slot)
        payload["date"] = slot.date.isoformat() if slot.date else None
        payload["start"] = slot.start.isoformat() if slot.start else None
        payload["end"] = slot.end.isoformat() if slot.end else None
        serialized.append(payload)

    path.write_text(
        json.dumps(serialized, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def save_csv(data: list[FlatScheduleEntry], path: Path) -> None:
    with path.open("w", encoding="utf-8", newline="") as csv_file:
        writer = csv.DictWriter(
            csv_file, fieldnames=["date", "start", "end", "program"]
        )
        writer.writeheader()
        for slot in data:
            writer.writerow(
                {
                    "date": slot.date.isoformat() if slot.date else None,
                    "start": slot.start.isoformat() if slot.start else None,
                    "end": slot.end.isoformat() if slot.end else None,
                    "program": slot.program,
                }
            )


def send_ntfy_message(topic: str, title: str, message: str) -> None:
    request = Request(
        url=f"https://ntfy.sh/{topic}",
        data=message.encode("utf-8"),
        headers={
            "Title": title,
            "Tags": "tv,alarm_clock",
            "Priority": "3",
        },
        method="POST",
    )

    try:
        with urlopen(request, timeout=10):
            return
    except HTTPError as exc:
        raise RuntimeError(f"Falha ao enviar ntfy (HTTP {exc.code})") from exc
    except URLError as exc:
        raise RuntimeError(f"Falha de rede ao enviar ntfy: {exc.reason}") from exc


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Faz scraping da programacao da Globo Minas e salva em JSON/CSV."
    )
    parser.add_argument(
        "--url", default=DEFAULT_URL, help="URL da pagina de programacao"
    )
    parser.add_argument(
        "--format",
        choices=["json", "csv"],
        default="json",
        help="Formato de saida",
    )
    parser.add_argument(
        "--output",
        default="programacao_globo_minas.json",
        help="Arquivo de saida",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=20,
        help="Timeout da requisicao HTTP em segundos",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    try:
        page_html = fetch_page(args.url, args.timeout)
        props = extract_embedded_props(page_html)
        schedule_grid = normalize_schedule(props)
        schedule = schedule_grid.flat_slots()

        today = date.today()
        bbb = next(
            (
                slot
                for slot in schedule
                if slot.start
                and slot.program
                and slot.start.date() == today
                and "Big Brother" in slot.program
            ),
            None,
        )

        if not bbb:
            return 1

        start_time = bbb.start.strftime("%H:%M") if bbb.start else "--:--"
        end_time = bbb.end.strftime("%H:%M") if bbb.end else "--:--"
        program_name = bbb.program or "Programa"

        participantes = [
            "Jordan",
            "Cuboy",
            "22ª série",
            "Plantieli",
            "Camacita",
            "#TIMETIAMILENA",
            "Samyra",
            "BadJura",
            "Breno",
            "Gratichay",
            "Marino Seno",
            "Ricardinho Freestyle",
        ]
        participante = participantes[random.randint(0, len(participantes) - 1)]
        send_ntfy_message(
            topic=NTFY_TOPIC,
            title=f"Big {participante} Brasil",
            message=f"{program_name} hoje de {start_time} ate {end_time}.",
        )

        return 0
    except Exception as exc:  # noqa: BLE001
        print(f"Erro: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

