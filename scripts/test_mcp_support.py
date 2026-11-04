#!/usr/bin/env python3
"""Check the support MCP server, or ask it a question through OpenCode and OpenRouter."""

import asyncio
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

from dotenv import load_dotenv

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client


CONFIG = "/app/mcp/aihub-support.toml"
ROOT = Path(__file__).resolve().parents[1]
EXPECTED_TOOLS = {"GetOrder", "GetProduct", "GetShipment", "ListOutOfStock"}


def ask_with_opencode(question: str, json_output: bool = False) -> int:
    """Launch the real OpenCode CLI. It owns model requests and MCP tool calls."""
    load_dotenv(ROOT / ".env")
    if not os.environ.get("OPENROUTER_API_KEY"):
        print("Configura OPENROUTER_API_KEY en .env antes de preguntar.", file=sys.stderr)
        return 2
    executable = shutil.which("opencode")
    if executable is None:
        print("Instala OpenCode según el Lab 06 antes de preguntar.", file=sys.stderr)
        return 2
    model = os.environ.get("OPENROUTER_MODEL") or "openai/gpt-oss-20b"
    config = {
        "provider": {
            "openrouter": {"options": {"apiKey": "{env:OPENROUTER_API_KEY}"}}
        },
        "mcp": {
            "aihub_support": {
                "type": "local",
                "command": [
                    "docker", "exec", "-i", "iris-aihub",
                    "/usr/irissys/bin/iris-mcp-server", "--config", CONFIG, "run",
                ],
                "enabled": True,
            }
        },
        "permission": {"*": "deny", "aihub_support_*": "allow"},
        "autoupdate": False,
    }
    environment = os.environ.copy()
    environment["OPENCODE_CONFIG_CONTENT"] = json.dumps(config)
    prompt = (
        "Responde en español usando exclusivamente las herramientas MCP aihub_support. "
        "Para localizar un pedido, consulta primero GetOrder y usa su trackingNumber "
        "para consultar GetShipment después. No inventes datos ni fechas. "
        "Si una herramienta no existe, indica esa limitación. Pregunta: " + question
    )
    print(f"OpenCode → OpenRouter ({model}) → MCP aihub_support", file=sys.stderr)
    result = subprocess.run(
        [executable, "run", "--model", f"openrouter/{model}",
         "--format", "json" if json_output else "default", prompt],
        cwd=ROOT,
        env=environment,
        check=False,
    )
    return result.returncode


def short_name(tool_name: str) -> str:
    """Return the AI Hub tool name after the endpoint prefix, if present."""
    return tool_name.rsplit("_", maxsplit=1)[-1]


async def check_calls(session: ClientSession, names: dict[str, str]) -> None:
    """Exercise the published read-only tools against the synthetic course data."""

    async def invoke(name: str, arguments: dict) -> object:
        result = await session.call_tool(names[name], arguments)
        if result.isError:
            raise RuntimeError(f"{name} failed: {result.content}")
        payload = json.loads(
            "\n".join(item.text for item in result.content if item.type == "text")
        )
        print(f"{name}: call passed.")
        return payload

    order = await invoke("GetOrder", {"orderRef": "ORD-002"})
    if not isinstance(order, dict) or order.get("orderRef") != "ORD-002":
        raise RuntimeError("GetOrder did not return the expected demo order")
    if order.get("purchaseDate") != "2026-08-18" or "orderDate" in order:
        raise RuntimeError("The purchase date must be exposed explicitly as purchaseDate")
    product = await invoke("GetProduct", {"sku": "SKU-AUD-001"})
    if not isinstance(product, dict) or product.get("sku") != "SKU-AUD-001":
        raise RuntimeError("GetProduct did not return the expected demo product")
    shipment = await invoke("GetShipment", {"trackingNumber": order["trackingNumber"]})
    if not isinstance(shipment, dict) or shipment.get("orderRef") != "ORD-002":
        raise RuntimeError("GetShipment did not return the expected demo shipment")
    for facts in (order, shipment):
        for field in ("shippedDate", "actualDeliveryDate", "returnDeadline", "sourceUrl"):
            if field not in facts or facts[field] is not None:
                raise RuntimeError(f"Unknown evidence must remain explicit null: {field}")
        if facts.get("returnEligibility") != "unknown" or not facts.get("sourceRef"):
            raise RuntimeError("Missing evidence limitations or record citation")
    products = await invoke("ListOutOfStock", {})
    if not isinstance(products, list) or not products:
        raise RuntimeError("ListOutOfStock did not return the demo stock list")


async def main(call_tools: bool = False) -> None:
    """Discover the published MCP tools without calling a language model."""
    parameters = StdioServerParameters(
        command="docker",
        args=[
            "exec",
            "-i",
            "iris-aihub",
            "/usr/irissys/bin/iris-mcp-server",
            "--config",
            CONFIG,
            "run",
        ],
    )

    async with stdio_client(parameters) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            tools = await session.list_tools()
            names = {tool.name for tool in tools.tools}
            published = {short_name(name) for name in names}
            missing = EXPECTED_TOOLS - published
            unexpected = published - EXPECTED_TOOLS
            if missing or unexpected:
                raise RuntimeError(
                    "Unexpected MCP catalog. "
                    f"Missing: {', '.join(sorted(missing)) or 'none'}. "
                    f"Unexpected: {', '.join(sorted(unexpected)) or 'none'}."
                )
            if call_tools:
                await check_calls(session, {short_name(name): name for name in names})

    print("Published MCP tools:")
    for name in sorted(names):
        print(f"- {name}")
    print("Catalog validation passed: only the read-only support tools are exposed.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument(
        "--call-tools",
        action="store_true",
        help="Also call the four read-only tools. Load demo data first.",
    )
    mode.add_argument("--ask", help="Pregunta a OpenCode usando OpenRouter y el MCP del curso. Consume créditos.")
    parser.add_argument("--json", action="store_true", help="Muestra los eventos JSON de OpenCode. Requiere --ask.")
    args = parser.parse_args()
    if args.json and args.ask is None:
        parser.error("--json requiere --ask")
    if args.ask is not None:
        if not args.ask.strip():
            parser.error("--ask necesita una pregunta")
        raise SystemExit(ask_with_opencode(args.ask, args.json))
    asyncio.run(main(call_tools=args.call_tools))
